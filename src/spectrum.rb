require 'gsl'

class Spectrum
  attr_accessor :meta, :wv, :signal, :cache_host

  def initialize(path = nil, wv = nil)
    @meta = {
      name: "#{Time.now.strftime("%Y%b%d-%H%M%S.%6N")}",
      desc: '',
      units: ['', 'counts'],
      type: 'D',
      wv_type: 'D'
    }

    @wv = (wv ? wv : [])
    @signal = []

    # Load from tsv/csv if path given
    if path && (File.exist? path)
      begin
        read_delimited(path)
      rescue
        puts "Unable to parse #{path} as a spectrum"
      end
    end

    update_info
  end

  # Metadata related methods
  def inspect
    { 'name' => @meta[:name], 'size' => size, 'spectral_range' => spectral_range,
      'signal_range' => signal_range, 'desc' => @desc }.to_s
  end

  def signal_range
    @signal.minmax
  end

  def spectral_range
    @wv.minmax
  end

  # Mirroing value retrieval and assignment to @meta
  def name
    @meta[:name]
  end

  def desc
    @meta[:desc]
  end

  def units
    @meta[:units]
  end

  def name=(new_name)
    @meta[:name] = new_name
  end

  def desc=(new_desc)
    @meta[:desc] = new_desc
  end

  def units=(new_units)
    @meta[:units] = new_units
  end

  # Index/Array behavior related methods
  def to_arr
    (0..size-1).map {|i| self[i]}
  end

  def [](i)
    if i.is_a? Integer
      [@wv[i], @signal[i]]
    elsif i.is_a? Range
      i.map {|index| self[index]}
    end
  end

  def []=(i, input)
    raise "Need a duple" unless input.is_a?(Array) && input.size == 2
    @wv[i], @signal[i] = input # Mutating @wv[]
  end

  def size
    @wv.size < @signal.size ? @wv.size : @signal.size
  end

  def each
    # RRRR
    (0..size-1).each {|i| yield [@wv[i], @signal[i]]}
    self
  end
  
  def each_with_index
    (0..size-1).each {|i| yield [@wv[i], @signal[i]], i}
  end
  
  def each_index
    (0..size-1).each {|i| yield i}
  end

  def map
    (0..size-1).map {|i| yield [@wv[i], @signal[i]]}  
  end

  def push(pt)
    raise "Expecting duple" unless pt.is_a?(Array) && pt.size == 2
    @wv.push pt[0]
    @signal.push pt[1]
    [@wv.last, @signal.last]
  end

  def sort!
    order = (0..size-1).to_a.sort_by {|i| @wv[i]}
    @wv = order.map {|i| @wv[i]}
    @signal = order.map {|i| @signal[i]}
  end

  def reverse!
    @wv.reverse!
    @signal.reverse!
  end

  def update_info
    sort!
    reverse! if @meta[:units][0] == 'wavenumber'
  end

  # Data processing methods
  def ma(radius)
    # +- radius points moving average
    # Issue: Radius defined on no of points but not real spectral spread
    raise "Radius should be integer but was given #{radius}" unless radius.is_a?(Integer)
    raise 'Radius larger than half the length of spectrum' if 2 * radius >= size

    result = Spectrum.new
    result.meta = @meta
    (0..size - 2 * radius - 1).each do |i|
      # Note that the index i of the moving average spectrum aligns with i + radius in original spectrum
      x = self[i + radius][0]
      y = 0.0
      (i..i + 2 * radius).each do |origin_i|
        # Second loop to run through the neighborhood in origin
        # Would multiplication with a diagonal stripe matrix be faster than nested loop? No idea just yet.
        y += self[origin_i][1]
      end
      y /= (2 * radius + 1) # Normalization
      result[i] = [x, y]
    end
    result.meta[:units] = @meta[:units]
    result.meta[:name] = @meta[:name] + "-ma#{radius}"
    result.update_info
    result
  end

  def deriv
    result = Spectrum.new
    (0..size - 2).each do |i|
      result.push [(self[i][0] + self[i + 1][0]) / 2, (self[i + 1][1] - self[i][1]) / (self[i + 1][0] - self[i][0])]
    end
    result
  end

  def peak_loosen(loosen)
    loosened = Spectrum.new
    loosened.meta = @meta
    loosened.meta[:name] = name + "l-#{loosen}"
    # start loosening with radius #{loosen}
    i = 0
    while i < size - 1
      if ((@wv[i]-@wv[i+1])**2 + (@signal[i]-@signal[i+1])**2 > loosen**2) || (i == size - 2)
        loosened.signal.push signal[i]
        loosened.wv.push wv[i]
        i += 1
      elsif @signal[i] > @signal[i+1] || (i == size-1)
        loosened.signal.push signal[i]
        loosened.wv.push wv[i]
      end
    end
    loosened.update_info
    loosened
  end

  def local_max(loosen = nil)
    raise 'Loosen neighborhood should be number of points' unless loosen.is_a? Integer or loosen.nil?

    result = Spectrum.new
    result.meta[:units] = @meta[:units]
    (1..size - 2).each do |i|
      if @signal[i] > @signal[i+1] && @signal[i] > @signal[i-1]
        result.signal.push @signal[i]
        result.wv.push @wv[i]
      end
    end

    result = result.peak_loosen(loosen) if loosen
    result.update_info
    result
  end

  def local_min(loosen = nil)
    raise 'Loosen neighborhood should be number of points' unless loosen.is_a? Integer or loosen.nil?

    result = Spectrum.new
    result.meta[:units] = @meta[:units]
    (1..size - 2).each do |i|
      result.push self[i] if self[i][1] <= self[i + 1][1] && self[i][1] <= self[i - 1][1]
    end

    result = result.peak_loosen(loosen) if loosen
    result.update_info
    result
  end

  # Resample spectrum at given locations
  def resample(sample_in, extrapolate = false)
    raise 'Not a sampling 1D array' unless sample_in.is_a? Array
    raise 'Expecting 1D array to be passed in' unless sample_in.all? Numeric

    sample = sample_in.sort # Avoid mutating the resample array

    update_info

    result = Spectrum.new
    result.meta[:name] = @meta[:name] + '-resampled'
    result.meta[:desc] += "/#{sample.size} points"
    result.meta[:units] = @meta[:units]

    # Frequency value could be increasing or depending on unit
    # Bare with the ternary for x_polarity will be used later
    x_polarity = @wv[-1] - @wv[0] > 0 ? 1 : -1
    @wv.reverse! if x_polarity == -1
    @signal.reverse! if x_polarity == -1

    i = 0 # Pointer to self
    while (sampling_point = sample.shift)
      if sampling_point <= @wv.last && sampling_point >= @wv.first # In interpolation range
        # self[i][0] need to surpass sampling point to bracket it. Careful of rounding error
        i += 1 while (i < size - 1) && ((sampling_point - @wv[i]) > 0)

        # Could be unnecessarily costly, but I can think of no better way at the moment
        if i == 0
          interpolation = @signal[0]
        else
          interpolation = @signal[i - 1] + (@signal[i] - @signal[i - 1]) * (sampling_point - @wv[i - 1]) / (@wv[i] - @wv[i - 1])
        end
        result.push [sampling_point, interpolation]
      elsif extrapolate && @wv.size > 1
        # Extrapolate
        if sampling_point < @wv[0] # Left side
          extrapolation = @signal[0] + (@signal[0]-@signal[1])/(@wv[0]-@wv[1])*(sampling_point-@wv[0])
        else # right side
          extrapolation = @signal[-1] + (@signal[-1]-@signal[-2])/(@wv[-1]-@wv[-2])*(sampling_point-@wv[-1])
        end # No 'extrapolation'
        result.push [sampling_point, extrapolation]
      else
        result.push [sampling_point, 0]
      end
    end

    # Restore order
    @wv.reverse! if x_polarity == -1
    @signal.reverse! if x_polarity == -1
    result.update_info

    # sample array is sorted right so the right sequence will follow ^.<
    # result.reverse! if x_polarity == -1
    result
  end

  def *(other)
    # Inner product
    if other.is_a? Spectrum
      sample = map { |pt| pt[0] }.union(other.map { |pt| pt[0] })
      self_resmpled_v = GSL::Vector.alloc(resample(sample).map { |pt| pt[1] })
      input_resmpled_v = GSL::Vector.alloc(other.resample(sample).map { |pt| pt[1] })
      self_resmpled_v * input_resmpled_v.col
    # Scalar product
    elsif other.is_a? Numeric
      result = Spectrum.new
      result.wv = @wv
      result.signal = @signal.map {|pt| pt * other}
      result.update_info
      result
    end
  end

  def /(other)
    result = Spectrum.new
    if other.is_a? Numeric
      result.signal = @signal.map{|x| x/other}
      result.wv = @wv
      result.meta[:name] = @meta[:name] + "d#{other}"
      result.meta[:units] = [@meta[:units][0], 'a.u.']
      result.update_info
    elsif other.is_a? Spectrum
      resampled = align_with(other)
      resampled[0].each_index do |i|
        result[i] = [resampled[0][i][0], resampled[0][i][1] / resampled[1][i][1]]
      end
      result.meta[:name] = @meta[:name] + '-' + other.meta[:name]
      result.meta[:units] = @meta[:units]
      result.meta[:units][1] = 'a.u.'
    else
      raise "Deviding by sth strange! #{other.class} is not defined as a denominator."
    end
    result
  end

  def align_with(input)
    sample = @wv.union input.wv
    self_resampled = resample(sample)
    input_resmpled = input.resample(sample)
    [self_resampled, input_resmpled]
  end

  def +(other)
    old_name = @meta[:name] # preserve name, not to be changed by resample()
    sample = @wv.union(other.wv)
    self_resampled = resample(sample)
    input_resmpled = other.resample(sample)
    binding.pry unless self_resampled.size == input_resmpled.size
    raise "bang, self.size = #{@wv.size}, foreign.size = #{other.wv.size}" unless self_resampled.size == input_resmpled.size

    self_resampled.each_index do |i|
      self_resampled.signal[i] += input_resmpled.signal[i]
    end
    self_resampled.meta[:name] = old_name # preserve name, not to be changed by resample()
    self_resampled.meta[:units] = @meta[:units]
    self_resampled.update_info
    self_resampled
  end

  def -(other)
    if other.is_a? Spectrum
      sample = @wv.union(other.wv)
      self_resampled = resample(sample)
      input_resampled = other.resample(sample)
      begin
      puts "bang self resampled size #{self_resampled.size} and other resampled size #{input_resampled.size}" unless self_resampled.size == input_resampled.size
      rescue
        binding.pry
      end

      self_resampled.each_index do |i|
        self_resampled.signal[i] -= input_resampled.signal[i]
      end
      self_resampled.meta[:name] = @meta[:name] # preserve name, not to be changed by resample()
      self_resampled.update_info
      self_resampled
    elsif other.is_a? Numeric
      result = Spectrum.new
      result.name = @meta[:name]
      result.wv = @wv
      result.signal = @signal.map {|x| x - other}
      result
    else
      raise "Spectrum can only do arithmetics with Spectrum or Numberic"
    end
  end

  def uniform_resample(n)
    spacing = (@spectral_range[1] - @spectral_range[0]).to_f / n
    sample = (0..n - 1).map { |i| @spectral_range[0] + (i + 0.5) * spacing }
    resample sample
  end

  def spikiness(smooth, loosening)
    smoothed = ma(smooth)
    minmax_diff = smoothed.minmax(loosening)
    (minmax_diff * minmax_diff) / minmax_diff.size
    # But not normalized to intensity. Whether this is good...
  end

  def minmax(loosening)
    result = local_max(loosening) - local_min(loosening)
    # Cut off the (bg-zero)s at head and tail
    result.shift
    result.pop
    result.meta[:name] = name + '-minmax'
    result
  end

  def sum
    (map { |pt| pt[1] }).sum
  end

  # For debugging the bg noise sensitivity of minmax spike assay
  def minmax_spike(r, loosen)
    smoothed = ma(r)
    maxes = smoothed.local_max(loosen)
    mins = smoothed.local_min(loosen)
    minmax = (maxes - mins)[1..-2]
    spikiness = (minmax * minmax) / minmax.size
    [smoothed, maxes, mins, minmax, spikiness]
  end

  def stdev
    sum = 0.0
    sos = 0.0 # sum of squares
    each do |pt|
      sum += pt[1]
      sos += pt[1]**2
    end
    ((sos - sum**2) / @size)**0.5
  end

  def fft
    ft = GSL::Vector.alloc(map { |pt| pt[1] }).fft # 究極一行文
    ft.to_complex2.abs # Be positive
  end

  def from_to(from, to=nil)
    result = Spectrum.new
    if from.is_a?(Array) && from.size == 2 && to==nil
      sorted = from.sort
    else
      sorted = [from, to].sort
    end
    each do |pt|
      result.push pt if (pt[0] > sorted[0]) && (pt[0] < sorted[1])
    end
    result.meta[:units] = @meta[:units]
    result
  end

  def max
    memory = self[0]
    each do |pt|
      memory = pt if pt[1] >= memory[1]
    end
    memory
  end

  def min
    memory = self[0]
    each do |pt|
      memory = pt if pt[1] <= memory[1]
    end
    memory
  end

  def normalize!
    update_info
    @meta[:name] += '-normalized'
    @signal_range = signal_range
    each do |pt|
      pt[1] = (pt[1] - @signal_range[0]).to_f / (@signal_range[1] - @signal_range[0])
    end
  end

  def normalize
    update_info
    result = Spectrum.new
    result.meta[:name] = @meta[:name] + '-normalized'
    result.meta[:units] = @meta[:units]
    result.wv = @wv
    @signal_range = signal_range()
    signal_span = @signal_range[1] - @signal_range[0]
    result.signal = @signal.map{|x| (x - @signal_range[0]).to_f/signal_span}
    result.update_info
    result
  end

  # Full width half maximum
  def fwhm(options = {})
    # Defaults
    median = (max[1].to_f + min[1]) / 2
    peak = max[0]
    result = 0

    # If a peak is given
    if options[:peak]
      peak = options[:peak]
      median = resample([peak])[0]
      puts "Value found: #{median}"
      median = (median[1] + min[1]) / 2
    end

    # If spectral scale in reverse
    if self[0][0] > self[-1][0]
      puts 'Spectral scale reverse'
      is_wv = true
      reverse!
    end

    # Find peak index
    each_with_index do |pt, i|
      segment = [pt[0], self[i + 1][0]].sort
      # Segment contains peak
      next unless segment[0] <= peak && peak <= segment[1]

      ls = rs = self[i]
      # Find right shoulder
      self[i..-1].each do |rpts|
        if rpts[1] <= median
          rs = rpts
          break
        end
      end
      # Find left shoulder
      self[0..i].reverse.each do |lpts|
        if lpts[1] <= median
          ls = lpts
          break
        end
      end
      puts "ls: #{ls}"
      puts "rs: #{rs}"
      result = rs[0] - ls[0]
      break
    end
    reverse! if is_wv
    result
  end

  # Substract dark count from baseline segment(s)
  def dark_segments(segments)
    segments = [segments] if !segments[0].is_a? Array
    dark_segments = segments.map{|sg| self.from_to(*sg)}
    sums = dark_segments.map{|dark_segment| dark_segment.sum}
    sizes = dark_segments.map{|dark_segment| dark_segment.size}
    dark_count = sums.sum / sizes.sum
    @signal.map! {|x| x -= dark_count}
    dark_count
  end

  # IO related methods
  def read_delimited(path)
    fin = File.open path, 'r'
    lines = fin.readlines
    lines.shift if lines[0] =~ /^Frame[\t,]/
    # Detection of seperator , or tab
    raise "No seperator found in #{path}" unless match = lines[0].match(/[\t,]/)

    puts "Loading from #{path}"
    seperator = match[0]
    lines.each_index do |i|
      (wv, intensity) = lines[i].split seperator
      wv = wv.to_f
      intensity = intensity.to_f
      @wv[i] = wv
      @signal[i] = intensity
    end
    @meta[:name] = File.basename(path)
  end

  def write_tsv(outname)
    fout = File.open outname, 'w'
    each do |pt|
      fout.puts pt.join "\t"
    end
    fout.close
  end

  def to_cache(host = nil)
    unless host
      if @cache_host
        host = @cache_host 
      else
        host = Memcached::Client.new('localhost')
      end
    end

    # Must be given a name for cache access
    if @meta[:name] == ''
      @meta[:name] = 'cache-' + Time.now.strftime("%s.%6N")
    end

    @cache = SpectCache.new(host, @meta[:name], {meta: @meta, data: @signal, wv:@wv})
    @cache
  end
end