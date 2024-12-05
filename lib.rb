# Script for the processing of micro-PL scann data
VERSION = '2023Mar15-1'.freeze
# No longer needed as long you export NMATRX=1
# require 'nmatrix'
require 'gsl'
require 'nokogiri'
require 'time'
# require 'parallel'
require 'json'
require 'fileutils'
require 'memcached'

class Scan < Array
  # Assume all wavelength scales allign across all pixels
  attr_accessor :frames, :wv, :spectrum_units, :path, :name, :width, :height, :depth, :p_width, :p_height, :p_depth,
                :loaded, :spe, :s_scan, :bin_to_spect, :aspect_ratio

  def initialize(path, name, dim, options = nil)
    @path = path
    @name = name

    @width = dim&.[] 0
    @height = dim&.[] 1
    @depth = dim&.[] 2

    if options&.[](:param_json)
      scan_param = JSON.parse(File.open(options[:param_json]).read)
      @width = scan_param['Points X']
      @height = scan_param['Points Y']
      @depth = scan_param['Points Z']
      @p_width = scan_param['Size X (um)'].to_f
      @p_height = scan_param['Size Y (um)'].to_f
      @p_depth = scan_param['Size Z (um)'].to_f
      @s_scan = scan_param['S-shape scan']
      @bin_to_spect = scan_param['Binning']
    end

    # This will mean the aspect ratio of the mapping image, and not that of the actual scan
    # the image will contain 1 more pixel size both on x and y
    @aspect_ratio = @p_height ? (@p_height + @p_height / @height) / (@p_width + @p_width / @width) : 1

    @loaded = false
    @spectral_width = 0
    super Array.new(width) { Array.new(height) { Array.new(depth) { Spectrum.new } } }
    puts "#{name} to be loaded from #{path}"
  end

  def load(options = {})
    options[:bin_to_spect] = @bin_to_spect
    puts options
    case File.extname @path
    when /\.[cC][sS][vV]/
      load_csv options
    when /\.[sS][pP][eE]/
      load_spe options
    else
      raise "File extension of #{@path} not recognizable."
    end
    @loaded = true
  end

  def load_csv(_options)
    fin = File.open @path, 'r'
    puts "Reading #{@path}..."
    lines = fin.readlines
    fin.close

    # Detection of seperator , or tab
    raiese 'No seperator found in line 0.' unless match = lines[0].match(/[\t,]/)
    seperator = match[0]

    # Detection of title line and units
    # Problem: even if the spectrum were in wavenumbers, the unit was still recorded as "Wavelength"
    if lines[0] =~ /^Frame[\t,]/
      title_line = lines.shift
      @spectrum_units = title_line.split(seperator)[1..2]
      puts "Title line detected. Unit identified as #{@wv_unit}"
    else
      puts 'No title line detected. Please ensure data format to be <Frame #> <Wavelength/wavenumber> <Intensity>'
      puts 'And input <wavelength/wavenumber, intensity> unit below:'
      @spectrum_units = gets.chomp.split(/, ?/)
    end

    # Framesize and wavelength construction
    @framesize = (lines.index { |ln| ln[0] == '2' })
    @wv = (0..@framesize - 1).map { |i| lines[i].split(seperator)[1] }
    puts "Frame size determined to be #{@framesize}, spectral range being #{@wv[0]} .. #{@wv[-1]}"
    @spectrum_units[0] = 'Wavenumber (cm-1)' if @wv[-1] < @wv[0]

    # raise "Number of lines is #{lines.size}, not multiplication of given width (#{@width}) * height (#{@height})* depth (#{@depth})!" unless lines.size == @framesize * (@width * @height * @depth)
    puts "Got #{lines.size} lines of spectrum to process."

    # The real parsing
    lines.each do |line|
      (frame, wv, intensity) = line.split seperator
      frame = frame.to_i - 1 # Matter of convention. I count up from 0.
      wv = wv.to_f
      intensity = intensity.to_f
      k = frame / (@width * @height)
      j = (frame % (@width * @height)) / @width
      i = (frame % (@width * @height)) % @width

      # S-shape scan
      # Todo on the instrument part: make this optional. After that also make this an option here.
      if j.even?
        self[i][j][k].push [wv, intensity]
      else
        self[width - 1 - i][j][k].push [wv, intensity]
      end
    end
    # Update all spectra
    puts 'Loading done. Updating info of spectra.'
    each do |row|
      row.each do |column|
        column.each do |pixel|
          pixel.units = @spectrum_units
          pixel.update_info
        end
      end
    end
    @loaded = true
    puts 'done'
  end

  def load_spe(options)
    # File read
    debug = options[:debug]
    # BIN to spectrum here
    options[:bin_to_spect] = true unless options[:bin_to_spect]

    puts "loading spe #{@path} with options #{options}."
    puts "Reading spe at #{Time.now}" if debug

    @spe = Spe.new @path, @name, options
    puts "Spe reading complete at #{Time.now}. Start scan building." if debug

    # Scan mismatch
    # raise "Spe size (#{@spe.size}) with #{@spe.frames} frames doesn't match that of scan (#{@width} x #{@height} x #{@depth} x #{@spe.framesize})" unless @spe.size == @width * @height * @depth * @spe.framesize

    # Spectrum building
    i = 0
    while i < @width
      puts "i=#{i}" if debug
      j = 0
      while j < @height
        relabel_i = if j.odd? && @s_scan == true
                      # puts "Loading with S-shape scan"
                      @width - i - 1
                    else
                      i
                    end
        k = 0
        while k < @depth
          # self[relabel_i][j][k] = @spe[k * (@width * @height) + j * @width + i]
          self[relabel_i][j][k] = (0..@spe.rois.size - 1).map do |roin|
            @spe.at(k * (@width * @height) + j * @width + i, roin)
          end
          self[relabel_i][j][k].each_with_index do |roi, n|
            roi.name = "#{@name}-#{i}-#{j}-#{k}-#{n}"
            roi.update_info
          end
          k += 1
        end
        j += 1
      end
      i += 1
    end
    @spectrum_units = @spe.spectrum_units
    puts "Scan building complete at #{Time.now}." if debug
  end

  def inspect
    "Scan name: #{@name}, path: #{@path}, dim: #{@width} x #{@height} x #{@depth} pts / #{@p_width} μm x #{@p_height} μm x #{@p_depth} μm,
     ROIs: #{@spe.rois}, units: #{@spectrum_units}"
  end

  def to_s
    inspect
  end

  def extract_spect(points)
    raise 'Not a series of points input.' unless (points.is_a? Array) && (points.all? { |item| item.size == 3 })

    unless @loaded
      puts "Scan #{@name} not yet loaded. Loading."
      self.load
    end
    result = []
    points.each do |pt|
      result += self[pt[0]][pt[1]][pt[2]]
      result.last.name = pt.join '-'
    end
    result.update_info
    result
  end

  # Excise a line of spectra between two points in space
  def excise(points)
    load unless @loaded
    raise 'No two points given' unless (points.is_a? Array) && (points.all? do |i|
                                                                  i.is_a? Array
                                                                end) && (points.size == 2) && (points.all? do |i|
                                                                                                 i.size == 3
                                                                                               end)
    raise "Points #{points} out of range #{@wiidth} x #{@height} x #{@depth}" unless \
      points.all? { |pt| pt.all? { |coord| coord >= 0 } } && \
      points.all? { |pt| pt[0] < @width } && \
      points.all? { |pt| pt[1] < @height } && \
      points.all? { |pt| pt[2] < @depth }

    diff = (0..2).map { |i| points[1][i] - points[0][i] }
    puts "diff: #{diff}"
    unless varying = diff.find_index { |x| x**2 >= 1 } # First varying index, return single point extraction if false
      puts 'Not finding any diff'
      return [self[points[0][0]][points[0][1]][points[0][2]]]
    end
    d = (0..2).map { |i| diff[i].to_f / diff[varying] }
    puts "Direction vector: #{d}"

    result = []
    (0..diff[varying] * (diff[varying].positive? ? 1 : -1)).each do |t| # Parametric sweep
      t /= (diff[varying]**2)**0.5 # Ugly but works
      x = points[0][0] + t * diff[0]
      y = points[0][1] + t * diff[1]
      z = points[0][2] + t * diff[2]
      spect = self[x][y][z]
      spect.name = "#{@name}-#{x}-#{y}-#{z}"
      result.push spect
    end
    result
  end

  # Calculate map
  def build_map(&mapping_function)
    # Building map matrix
    # Note the zyx / xyz index swap for easy z chunk output!
    @map_data = Array.new(@depth) { Array.new(@height) { Array.new(@width) { 0.0 } } }

    # Iteration
    i = 0
    while i < @width * @height * @depth
      x = i % @width
      y = ((i - x) / @width) % @height
      z = i / (@width * height)
      begin
        @map_data[z][y][x] = mapping_function.yield(self[x][y][z], [x, y, z])
      rescue StandardError
        puts "Error at #{x}-#{y}-#{z}"
        @map_data[z][y][x] = 0
      end
      i += 1
    end
  end

  # Plot a scanning map with respect to the summation function given in the block
  def plot_map(outdir = nil, options = {}, &mapping_function)
    # We need a block to calculate the map
    unless block_given?
      puts 'No blocks were given. Assume simple summation across all ROIs.'
      mapping_function = proc { |spects| (spects.map { |spect| spect.sum }).sum }
    end
    if options&.[](:scale).is_a?(Integer) && options[:scale] > 0
      scale = options[:scale] * 5
      puts "Setting map plotting scale to #{scale}"
    else
      scale = 5
    end

    # Building map matrix
    build_map(&mapping_function)

    # Exporting map matrix
    outdir ||= @name
    FileUtils.mkdir_p outdir unless Dir.exist? outdir
    map_fout = File.open "#{outdir}/#{@name}.tsv", 'w'
    z = 0
    while z < @depth
      row = 0
      map_fout.puts "# z = #{z}"
      while row < @height
        map_fout.puts @map_data[z][row].join "\t"
        row += 1
      end
      map_fout.print "\n\n"
      z += 1
    end
    # Export map and push
    map_fout.close
    # Plotting
    gplot = File.open "#{outdir}/#{@name}.gplot", 'w'

    # Caution: variable z reused. Previously a counter for building map matrix, now indicating z layer to plot
    z = nil

    dark_bg = options&.[](:dark_bg)
    case options&.[](:plot_term)
    when nil, 'svg' # Means not indicated or svg
      z = options[:z] if options[:z]
      plot_output = "#{outdir}/#{@name}.svg"
      gplot_terminal = <<~GP_TERM
        set terminal svg size #{@p_width * scale * @depth},#{@p_height * scale} mouse enhanced standalone #{dark_bg ? 'background "black"' : ''}
        set output '#{plot_output}'
        set title '#{@name.gsub('_', '\_')}' #{dark_bg ? "tc 'white'" : ''}
        #{dark_bg ? "set border lc 'white'" : ''}
        unset xtics
        unset ytics
      GP_TERM
    when 'png'
      plot_output = "#{outdir}/#{@name}.png"
      gplot_terminal = <<~GP_TERM
        set terminal png size #{@p_width * scale * @depth},#{@p_height * scale} #{dark_bg ? 'background "black"' : ''}
        set output '#{plot_output}'
        set title '#{@name.gsub('_', '\_')}' #{dark_bg ? "tc 'white'" : ''}
        #{dark_bg ? "set border lc 'white'" : ''}
        unset xtics
        unset ytics
      GP_TERM
    when 'tkcanvas-rb'
      z = options&.[](:z).to_i
      raise 'z unspecified' unless z
      raise 'width and height unspecified' unless options[:plot_width] && options[:plot_height]

      plot_output = "#{outdir}/#{@name}-#{z}.rb"
      gplot_terminal = <<~GP_TERM
        set terminal tkcanvas ruby size #{options[:plot_width]},#{options[:plot_height]}
        set output '#{plot_output}'
        set title '#{@name}'
      GP_TERM
    end

    gplot_style = options&.[](:plot_style)

    gplot_content = <<~GPLOT_HEAD
      # Created by microPL_scan version #{VERSION}
      #{gplot_terminal}
      set size ratio #{@aspect_ratio == 1 ? -1 : @aspect_ratio}
      set border 0
      unset key
      set xrange[-0.5:#{@width - 0.5}]
      set yrange[-0.5:#{@height - 0.5}]
      #set title '#{@name.gsub('_', '\_')}'
      set palette cubehelix
      set cbtics scale 0
      unset grid
      #{gplot_style}
    GPLOT_HEAD

    gplot.puts gplot_content

    if !z && @depth > 1
      # Iterating through z layers
      gplot.puts 'set multiplot'
      (0..@depth - 1).each do |z|
        gplot.puts "set title 'z = #{z}'"
        gplot.puts "set origin #{z.to_f / @depth},0"
        gplot.puts "set size #{1.0 / @depth},1"
        gplot.puts "plot '#{outdir}/#{@name}.tsv' index #{z} matrix with image pixels"
      end
      puts "Plotting #{@name}, W: #{@width}, H: #{@height}"
      gplot.puts 'unset multiplot'

    else
      z ||= 0 # Default layer
      # 1 sheet plotting
      # gplot.puts "set title '#{@name.gsub('_', '\\_')}'"
      gplot.puts "plot '#{outdir}/#{@name}.tsv' index #{z} matrix with image pixels"
    end

    gplot.close
    `gnuplot '#{outdir}/#{@name}.gplot'`
    plot_output
  end

  # Return list of points in rectangular area defined by pt_1(x,y) to pt_2(x,y)
  def select_points(pt_1, pt_2)
    raise 'Not points' unless (pt_1.size == 3) && (pt_2.size == 3)

    result = []
    ([pt_1[0], pt_2[0]].sort[0]..[pt_1[0], pt_2[0]].sort[1]).each do |x|
      ([pt_1[1], pt_2[1]].sort[0]..[pt_1[1], pt_2[1]].sort[1]).each do |y|
        ([pt_1[2], pt_2[2]].sort[0]..[pt_1[2], pt_2[2]].sort[1]).each do |z|
          result.push [x, y, z]
        end
      end
    end
    result
  end

  # Return a list of points in the cross section
  def section(pt1, pt2, _options = {})
    if pt1[0] == pt2[0]
      return (pt1[1].to_i..pt2[1].to_i).map { |y| [pt1[0].to_i, y] } if pt2[1] >= pt1[1]

      return ((pt2[1].to_i..pt1[1].to_i).map { |y| [pt1[0].to_i, y] }).reverse

    end

    # P(t) = (x, y) = <pt1> + t <pt2-pt1>
    list = []
    # x lower and higher bounds
    xlb, xub = [pt1[0], pt2[0]].sort.map { |x| x.to_i }
    (xlb..xub).each do |x|
      xt = (x.to_f - pt1[0]) / (pt2[0] - pt1[0])
      next if xt < 0
      break if xt > 1

      y = pt1[1] + xt * (pt2[1] - pt1[1])
      list.push [x - 1, y.to_i] if x - 1 >= xlb && list.last != [x - 1, y.to_i]
      list.push [x, y.to_i] if list.last != [x, y.to_i]
    end
    list.reverse! if pt1[0] > pt2[0]
    list
  end

  # Return binned spectra across axis with binning span
  def binned_section(axis, span, options = {})
    z = options[:z] || 0
    roi = options[:roi] || 0
    box = [
      [axis[2] + span[0], axis[3] + span[1]],
      [axis[0] + span[0], axis[1] + span[1]],
      [axis[0] - span[0], axis[1] - span[1]],
      [axis[2] - span[0], axis[3] - span[1]]
    ]
    xrange = box.map { |pt| pt[0].to_i }.minmax
    yrange = box.map { |pt| pt[1].to_i }.minmax

    list = []
    (xrange[0]..xrange[1]).each do |x|
      (yrange[0]..yrange[1]).each do |y|
        t = get_t(axis, [x, y])
        this_vec = section_vector(axis, [x, y])
        list.push [x, y, t] if t <= 1 && t > 0 && this_vec[0]**2 + this_vec[1]**2 < span[0]**2 + span[1]**2 # 為了直橫線不得取巧
      end
    end
    list.sort_by! { |pt| pt[2] }

    # Perform t-resampling
    # Approach: we wish to preserve the spacing regardless of section angle orientation
    t_span = (list[-1][2].to_f - list[0][2])
    t_spacing =  t_span / ((axis[2] - axis[0])**2 + (axis[3] - axis[1])**2 / @aspect_ratio**2)**0.5 # This will make trouble when h > w!!

    # Construct binned point list [[pt1, pt2, pt3], [pt4, pt5, pt6, pt7 ... etc]]
    bins = Array.new((t_span / t_spacing).ceil + 1) { [] }
    t = 0.0
    list.each do |pt|
      bins[pt[2] / t_spacing].push pt
    rescue StandardError
      puts bins[pt[2] / t_spacing]
      puts "Broken binning at #{pt} with t_spacing being #{t_spacing}"
    end
    bins = bins.filter { |bin| !bin.empty? }

    # Actual binning
    binned = []
    bins.each do |bin|
      # bin.each {|pt| puts "pt[0] #{pt[0]} pt[1] #{pt[1]}"}
      spect = (bin.map { |pt| self[pt[0]][pt[1]][z][roi] }).reduce(:+) / bin.size
      spect.units = @spectrum_units
      binned.push spect
    end

    binned
  end
end

class Spectrum
  attr_accessor :meta, :wv, :signal

  def initialize(path = nil, wv = nil)
    @meta = {
      name: '',
      desc: '',
      units: ['', 'counts'],
      cache_host: ''
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

  def cache_host
    @meta[:cache_host]
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

  def cache_host=(new_cache_host)
    @meta[:cache_host] = new_cache_host
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
    reverse! unless @meta[:units][0] == 'nm' || @meta[:units][0] == 'px'
  end

  # Data processing methods
  def ma(radius)
    # +- radius points moving average
    # Issue: Radius defined on no of points but not real spectral spread
    raise "Radius should be integer but was given #{radius}" unless radius.is_a?(Integer)
    raise 'Radius larger than half the length of spectrum' if 2 * radius >= size

    result = Spectrum.new
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
    result.units = @units
    result.name = @name + "-ma#{radius}"
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
    loosened.name = name + '-l#{loosen}'
    # start loosening with radius #{loosen}
    i = 0
    while i < size - 1
      if (self[i][0] - self[i + 1][0])**2 + (self[i][1] - self[i + 1][1])**2 > loosen**2
        loosened.push self[i]
        loosened.push self[i + 1] if i == size - 2
        i += 1
      else
        loser = self[i][1] - self[i + 1][1] >= 0 ? i : i + 1
        delete_at loser
        loosened.push self[i] if i == size - 1
      end
    end
    loosened
  end

  def local_max(loosen = nil)
    raise 'Loosen neighborhood should be number of points' unless loosen.is_a? Integer or loosen.nil?

    result = Spectrum.new
    (1..size - 2).each do |i|
      result.push self[i] if self[i][1] > self[i + 1][1] && self[i][1] > self[i - 1][1]
    end

    result = result.peak_loosen(loosen) if loosen
    result
  end

  def local_min(loosen = nil)
    raise 'Loosen neighborhood should be number of points' unless loosen.is_a? Integer or loosen.nil?

    result = Spectrum.new
    (1..size - 2).each do |i|
      result.push self[i] if self[i][1] < self[i + 1][1] && self[i][1] < self[i - 1][1]
    end

    result = result.peak_loosen(loosen) if loosen
    result
  end

  # Resample spectrum at given locations
  def resample(sample_in)
    raise 'Not a sampling 1D array' unless sample_in.is_a? Array
    raise 'Expecting 1D array to be passed in' unless sample_in.all? Numeric

    sample = sample_in.sort # Avoid mutating the resample array

    update_info

    result = Spectrum.new
    result.name = @name + '-resampled'
    result.desc += "/#{sample.size} points"
    result.units = @units

    # Frequency value could be increasing or depending on unit
    # Bare with the ternary for x_polarity will be used later
    x_polarity = self[-1][0] - self[0][0] > 0 ? 1 : -1
    sample.reverse! if x_polarity == -1

    i = 0
    while (sampling_point = sample.shift)
      # Ugly catch for out of range points, throw out zero
      if sampling_point < spectral_range[0] || sampling_point > spectral_range[1]
        result.push [sampling_point, 0.0]
        next
      end

      # self[i][0] need to surpass sampling point to bracket it. Careful of rounding error
      i += 1 while (i < size - 1) && ((sampling_point - self[i][0]) * x_polarity > 0.000001)

      # Could be unnecessarily costly, but I can think of no better way at the moment
      if i == 0
        interpolation = self[0][1]
      else
        interpolation = self[i - 1][1] + (self[i][1] - self[i - 1][1]) * (sampling_point - self[i - 1][0]) / (self[i][0] - self[i - 1][0])
      end
      result.push [sampling_point, interpolation]
    end

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
      each { |pt| result.push([pt[0], pt[1].to_f * other]) }
      result.update_info
      result
    end
  end

  def /(other)
    result = Spectrum.new
    if other.is_a? Numeric
      each { |pt| result.push([pt[0], pt[1].to_f / other.to_f]) }
      result.name = @name + "d#{other}"
      result.units = @units
      result.update_info
    elsif other.is_a? Spectrum
      resampled = align_with(other)
      resampled[0].each_index do |i|
        result[i] = [resampled[0][i][0], resampled[0][i][1] / resampled[1][i][1]]
      end
      result.name = @name + '-' + other.name
      result.units = @units
      result.units[1] = 'a.u.'
    else
      raise "Deviding by sth strange! #{other.class} is not defined as a denominator."
    end
    result
  end

  def align_with(input)
    sample = map { |pt| pt[0] }.union(input.map { |pt| pt[0] })
    self_resampled = resample(sample)
    input_resmpled = input.resample(sample)
    [self_resampled, input_resmpled]
  end

  def +(other)
    old_name = @name # preserve name, not to be changed by resample()
    sample = map { |pt| pt[0] }.union(other.map { |pt| pt[0] })
    self_resampled = resample(sample)
    input_resmpled = other.resample(sample)
    raise 'bang' unless self_resampled.size == input_resmpled.size

    self_resampled.each_index do |i|
      self_resampled[i][1] += input_resmpled[i][1]
    end
    self_resampled.name = old_name # preserve name, not to be changed by resample()
    self_resampled.update_info
    self_resampled
  end

  def -(other)
    update_info
    unless other.is_a? Spectrum
      raise "Expecting Spectrum or Numeric input" unless other.is_a? Numeric
      other_num = other.to_f
      other = Spectrum.new
      other.name = "Constant #{other}"
      other.push [self[0][0], other_num]
      other.push [self[-1][0], other_num]
    end

    sample = map { |pt| pt[0] }.union(other.map { |pt| pt[0] })
    self_resampled = resample(sample)
    input_resmpled = other.resample(sample)
    raise 'bang' unless self_resampled.size == input_resmpled.size

    self_resampled.each_index do |i|
      self_resampled[i][1] -= input_resmpled[i][1]
    end
    self_resampled.name = @name # preserve name, not to be changed by resample()
    self_resampled.update_info
    self_resampled
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
    result.name = name + '-minmax'
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
    sos = 0.0 # sum of squares
    each do |pt|
      sos += pt[1]**2
    end
    ((sos/size - (sum/size)**2))**0.5
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
    @name += '-normalized'
    each do |pt|
      pt[1] = (pt[1] - @signal_range[0]).to_f / (@signal_range[1] - @signal_range[0])
    end
  end

  def normalize
    update_info
    result = Spectrum.new
    result.name = @name + '-normalized'
    each_with_index do |pt, i|
      result[i] = [pt[0], (pt[1] - @signal_range[0]).to_f / (@signal_range[1] - @signal_range[0])]
    end
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

  def to_cache(host = Memcached.new('localhost'))
    if @meta[:name] == ''
      @meta[:name] = 'cache-' + Time.now.strftime("%s.%6N")
    end
    @cache = SpectCache.new(@meta[:name], @signal, host, {wv: @wv})
    @cache
  end
end

class Alignment
  attr_accessor :name, :coords, :control_pts

  # Record alignment with OM pictures named with microstage coordinate: c1-xx.xxx-yy.yyy-zz.zzz.bmp
  def initialize(name, alignment_dir)
    coords_arr = []
    @control_pts = []
    @name = name
    raise "Not valid path: #{alignment_dir}" unless Dir.exist? alignment_dir

    control_point_files = Dir.glob alignment_dir + '/*.bmp'
    control_point_files.sort_by! { |fname| File.basename(fname).split('_')[0].to_f }
    control_point_files.each do |fn|
      # Old alignment name convention
      if match = File.basename(fn).match(/^([^-]+)-(\d+\.\d\d\d)-(\d+\.\d\d\d)-(\d+\.\d\d\d)/)
        # coords_arr.push [match[2].to_f, match[3].to_f, match[4].to_f]
        # 2-dim for now for 3-dim requires more testing. rotator_solve might yet be incompatible
        coords_arr.push [match[2].to_f, match[3].to_f]
        @control_pts.push [match[1], fn]
      elsif match = File.basename(fn, '.bmp').match(/_(-?\d+)_(-?\d+)_?(-?\d\.?\d*)?/)
        coords_arr.push [match[1].to_f, match[2].to_f]
        @control_pts.push [File.basename(fn, '.bmp'), fn]
      end
    end
    @coords = GSL::Matrix.alloc(coords_arr.flatten, coords_arr.size, 2)
  end

  # Express position recorded in alignment x_0 in this alignment coordinate
  def express(x_0, pos)
    rotator, displacement = relative_to(x_0)
    pos * rotator + displacement
  end

  # x1.relative_to(x0) gives the rotation and displacement so that x0*rotation + displacement = x1
  def relative_to(x_0)
    raise 'x_0 is not an Alignment' unless x_0.is_a? Alignment
    raise 'x_0 is not an Alignment' unless x_0.is_a? Alignment
    raise 'Size mismatch' unless x_0.coords.size == coords.size

    (0..x_0.coords.size1 - 1).each do |i|
      raise 'Control points mismatch' unless x_0.control_pts[i][0] == control_pts[i][0]
    end
    rotator = rotator_solve(row_diff(x_0.coords.size1) * x_0.coords) * row_diff(@coords.size1) * @coords
    displacement = center_of_mass(@coords) - center_of_mass(x_0.coords * rotator)
    [rotator, displacement]
  end
end

# Princeton Instruments .spe format
class Spe < Array
  attr_accessor :path, :name, :xml, :frames, :frame_width, :frame_height, :framesize, :wv, :spectrum_units,
                :data_creation, :file_creation, :file_modified, :grating, :center_wavelength, :exposure_time, :rois, :bin_to_spect

  def initialize(path, name, options = {})
    debug = options[:debug]
    @path = path
    @name = name
    raise "No such file #{@path}" unless File.exist? path

    @bin_to_spect = options[:bin_to_spect]

    puts "Loading spe file #{@path} at #{Time.now}" if debug
    fin = File.open @path, 'rb'

    # Rewrite while reading PI documentation on SPE 3.0 format
    # And sluuurp (x)
    # perform a civilized segmented reading (o)
    bin_head = fin.read(4100).freeze
    xml_index = bin_head[678..685].unpack1('Q')
    @bin_data = fin.read(xml_index - 4100).freeze
    xml_raw = fin.read.freeze # All the rest goes to xml
    fin.close

    puts "Finished reading spe at #{Time.now}" if debug
    puts "Binary data has a lenght of: #{@bin_data.size}" if debug

    # Starting position of xml part
    @xml = Nokogiri.XML(xml_raw)

    # Data dimensions
    frame_node = @xml.at_xpath('//xmlns:DataBlock[@type="Frame"]')
    @frames = frame_node.attr('count').to_i
    pixelformat = frame_node.attr('pixelFormat')
    raise "Pixel format #{pixelformat} not supported" unless pixelformat == 'MonochromeUnsigned16'

    # Region of Interest parameters
    @rois = []
    @xml.xpath('//xmlns:SensorMapping').each do |roi|
      @rois.push({
                   id: roi.attr('id').to_i,
                   x: roi.attr('x').to_i,
                   y: roi.attr('y').to_i,
                   width: roi.attr('width').to_i,
                   height: roi.attr('height').to_i,
                   xbinning: roi.attr('xBinning').to_i,
                   ybinning: roi.attr('yBinning').to_i,
                   data_width: roi.attr('width').to_i / roi.attr('xBinning').to_i,
                   data_height: roi.attr('height').to_i / roi.attr('yBinning').to_i
                 })
    end
    puts "ROIs:\n" + @rois.join("\n") if debug

    # Cross check ROIs and sensor map
    data_blocks = @xml.xpath('//xmlns:DataBlock[@type="Region"]')
    raise 'Mismatch of number of blocks and number of sensor mapping information' unless data_blocks.size == @rois.size

    # Wavelength mapping
    begin
      wavelengths_mapping = @xml.at_xpath('//xmlns:Calibrations/xmlns:WavelengthMapping/xmlns:Wavelength').text.split(',').map do |x|
        x.to_f
      end
    rescue StandardError
      puts "Normal wavelength mapping not found for #{@name}. Try WavelengthError"
      wavelengths_mapping = @xml.at_xpath('//xmlns:Calibrations/xmlns:WavelengthMapping/xmlns:WavelengthError').text.split(' ').map do |x|
        x.split(',')[0].to_f
      end
    end

    # Calculating framesize and @wv
    @framesize = 0
    wavelengths_nm = []
    data_blocks.each_with_index do |block, i|
      puts "Checking ROI #{i}" if debug
      raise 'Width mismatch' unless block.attr('width').to_i == @rois[i][:data_width]
      raise 'Height mismatch' unless block.attr('height').to_i == @rois[i][:data_height]

      @framesize += @rois[i][:data_width] * @rois[i][:data_height]
      wavelengths_nm += wavelengths_mapping[@rois[i][:x]..@rois[i][:x] + @rois[i][:data_width] - 1]
      puts "W: #{@rois[i][:width]} / #{@rois[i][:xbinning]} H: #{@rois[i][:height]} / #{@rois[i][:ybinning]}" if debug
    end
    unless @bin_data.size == @frames * @framesize * 2
      raise "0_o binary data have a length of #{@bin_data.size} for #{@name}. With framesize #{@framesize} we expect #{frames} * #{@framesize} * 2 bytes/px."
    end

    # @data_creation, @file_creation, @file_modified
    @data_creation = Time.parse(@xml.at_xpath('//xmlns:Origin').attr('created'))
    @file_creation = Time.parse(@xml.at_xpath('//xmlns:FileInformation').attr('created'))
    @file_modified = Time.parse(@xml.at_xpath('//xmlns:FileInformation').attr('lastModified'))

    exp_ns = 'http://www.princetoninstruments.com/experiment/2009'.freeze # exp namespace
    # @grating @center wavelength
    @grating = @xml.at_xpath('//exp_ns:Grating/exp_ns:Selected', { 'exp_ns' => exp_ns }).text
    @center_wavelength = @xml.at_xpath('//exp_ns:Grating/exp_ns:CenterWavelength', { 'exp_ns' => exp_ns }).text
    # @exposure_time
    @exposure_time = @xml.at_xpath('//exp_ns:ShutterTiming/exp_ns:ExposureTime', { 'exp_ns' => exp_ns }).text.to_f

    # Set unit and name
    case options[:spectral_unit]
    when 'wavenumber'
      @wv = wavelengths_nm.map { |nm| 10_000_000.0 / nm } # wavanumber
      @spectrum_units = %w[wavenumber counts]
    when 'eV'
      @wv = wavelengths_nm.map { |nm| 1239.84197 / nm } # wavanumber
      @spectrum_units = %w[eV counts]
    else
      @wv = wavelengths_nm # nm
      @spectrum_units = %w[nm counts]
    end

    # Paralellization: distribution of frames to process among processes
    parallelize = options[:parallelize] || 1

    # Simple: a line of spectrum per frame
    if @rois.all? { |roi| roi[:data_height] == 1 }
      puts 'All rois contain spectra, a spectra containing spe' if debug
    # Frame contains image
    elsif debug
      puts "#{@name} has images in frames of shape #{@rois}\n Loading."
    end
  end

  # Universal accesor for all regardless of spectrum or image containing Spes
  def at(frame, roin)
    raise 'Roi and frame # must be specified' if frame.nil? || roin.nil?

    # Unbinned ROI, output array
    if @rois[roin][:data_height] > 1 && !@bin_to_spect
      result = Array.new(@rois[roin][:data_height]) { Array.new(@rois[roin][:data_width]) { 0 } }
      yi = 0
      while yi < @rois[roin][:data_height]
        result[yi] =
          @bin_data[(frame * @framesize + yi * @rois[roin][:data_width]) * 2..(frame * @framesize + (yi + 1) * @rois[roin][:data_width] - 1) * 2 + 1].unpack('S*')
        yi += 1
      end
      result.transpose

    # Output Spectrum
    else
      result = Spectrum.new
      xi = 0
      roishift = 0

      roii = 0
      while roii < roin
        roishift += @rois[roii][:data_width] * @rois[roii][:data_height]
        roii += 1
      end

      # Binning needed
      if @bin_to_spect
        bin_range = if @bin_to_spect.is_a? Array
                      @bin_to_spect
                    else
                      [0, @rois[roin][:data_height]]
                    end

        while xi < @rois[roin][:data_width]
          result[xi] = [@wv[xi + roishift], 0]
          yi = bin_range[0]
          while yi < bin_range[1]
            unless @bin_data[(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2..(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2 + 1].unpack1('S')
              raise "frame #{frame} #{xi} #{yi}"
            end

            result[xi][1] += @bin_data[(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2..(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2 + 1].unpack1('S')
            yi += 1
          end
          xi += 1
        end
      # No binning
      else
        while xi < @rois[roin][:data_width]
          result[xi] = [@wv[xi + roishift],
                        @bin_data[(frame * @framesize + roishift + xi) * 2..(frame * @framesize + roishift + xi) * 2 + 1].unpack1('S')]
          xi += 1
        end
      end
      result.name = "#{@name}-#{frame}-roi#{roin}"

      result.units = @spectrum_units
      result.update_info
      result
    end
  end

  def inspect
    # attr_accessor :path, :name, :xml, :frames, :frame_width, :frame_height, :wv, :spectrum_units, :data_creation, :file_creation, :file_modified, :grating, :center_wavelength, :exposure_time
    ["Spe name: #{@name}", "path: #{@path}", "Contining #{@frames} frames of dimension #{@rois.inspect}",
     "Spectral units: #{@spectrum_units}", "Data created: #{@data_creation}, file created: #{@file_creation}, file last modified: #{@file_modified}", "Grating: #{@grating} with central wavelength being #{@center_wavelength} nm", "Exposure time: #{@exposure_time} ms."].join "\n"
  end

  def to_s
    inspect
  end

  def each_frame; end
end

# Andor .sif format
class SIF < Array
  attr_accessor :path, :name, :sif_ver, :frames, :frame_width, :frame_height, :framesize, :wv, :spectrum_units,
                :data_creation, :file_creation, :file_modified, :grating, :center_wavelength, :exposure_time, :cycle_time, :accumulated_cycle_time, :accumulated_cycles, :temperature, :rois, :bin_to_spect, :timestamps, :calib

  def initialize(path, name, options = {})
    debug = options[:debug]
    @path = path
    @name = name
    @spectrum_units = %w[px counts]
    raise "No such file #{@path}" unless File.exist? path

    @bin_to_spect = options[:bin_to_spect]
    @raw = File.open(@path, 'rb') { |f| f.read.freeze }

    puts "Finished reading spe at #{Time.now.strftime('%H:%M:%S.%3N')}" if debug
    puts "Raw data has a lenght of: #{@raw.size}" if debug

    ptr = 0
    unless @raw[ptr..ptr + 35] == "Andor Technology Multi-Channel File\n"
      raise "Magic string not matching, #{@path} is no SIF file"
    end

    ptr += 36

    linel = @raw[ptr..-1].index "\n"
    @ln2 = @raw[ptr..ptr + (linel - 1)]
    ptr += (linel + 1)

    delim = @raw[ptr..-1].index(' ')
    @sif_ver = @raw[ptr..ptr + delim - 1].to_i
    puts "SIF version #{@sif_ver}" if debug
    ptr += (delim + 1)

    raise "Expecting '0 0 1 ' but got '#{@raw[ptr..ptr + 5]}'" unless @raw[ptr..ptr + 5] == '0 0 1 '

    ptr += 6

    match = @raw[ptr..-1].match(/^(\d+)\s(\S+)\s/) # Lazy delimination w/o checking for float string fmt
    raise 'Problem extracting exposure time and temp' unless match

    @data_creation = match[1].to_i
    @temperature = match[2].to_f
    ptr += match[0].size

    match = @raw[ptr..-1].match(/^(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s/)
    raise "Expecting zero at #{ptr}" unless match[6] == '0'

    ptr += match[0].size

    match = @raw[ptr..-1].match(/^(\S+)\s(\S+)\s(\S+)\s(\S+)\s/)
    @exposure_time = match[1].to_f
    @cycle_time = match[2].to_f
    @accumulated_cycle_time = match[3].to_f
    @accumulated_cycles = match[4].to_i
    ptr += match[0].size

    match = @raw[ptr..-1].match(/^\0\s(\S+)\s(\S+)\s\S+\s\S+\s/)
    @stack_cycle_time = match[1]
    @pixel_readout_time = match[2]
    ptr += match[0].size

    match = @raw[ptr..-1].match(/^(\S+)\s\S+\s\S+\s/)
    @dac_gain = match[1]
    ptr += match[0].size

    match = @raw[ptr..-1].match(/^(\S+)\s/)
    @gate_width = match[1]
    ptr += match[0].size

    # 16 more mysterous entries
    puts '16 mysterious entries' if debug
    16.times do
      match = @raw[ptr..-1].match(/^(\S+)\s/)
      ptr += match[0].size
    end

    match = @raw[ptr..-1].match(/^(\S+)[^\n]+\n/)
    @grating_blaze = match[1].to_f
    ptr += match[0].size

    match = @raw[ptr..-1].match(/^(\S+)\s\n\s(\S+)\s(\S+)\s(\S+)\n/)
    @detector_name = match[1]
    @detector_dimension = match[2..3].map { |i| i.to_i }
    orig_filename_length = match[4].to_i
    ptr += match[0].size

    @original_path = @raw[ptr..ptr + orig_filename_length - 1]
    ptr += orig_filename_length

    match = @raw[ptr..-1].match(/\s\n65538\s([^\n]+)\n/)
    user_text_l = match[1].to_i
    ptr += match[0].size
    @user_text = @raw[ptr..ptr + user_text_l - 1]
    ptr += user_text_l
    match = @raw[ptr..-1].match(/\n/)
    raise "Trouble at #{ptr}" unless match

    ptr += 1
    ptr += 13 # 65538 and 8 bits

    match = @raw[ptr..-1].match(/^\s(\S+)\s([^\n\s]+)\n/)
    @shutter_times = match[1..2]
    ptr += match[0].size

    # Skip lines with respect to various SIF version
    if @sif_ver >= 65_548 && @sif_ver <= 65_557
      match = @raw[ptr..-1].match(/[^\n]+\n[^\n]+\n/)
      ptr += match[0].size
    elsif @sif_ver == 65_558
      5.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
    elsif @sif_ver == 65_559 || @sif_ver == 65_564
      8.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
    elsif @sif_ver == 65_565
      15.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
    elsif @sif_ver > 65_565
      8.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
      match = @raw[ptr..-1].match(/([^\n]+)\n/)
      @spectrograph = match[1] # Check content
      9.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
    end

    @spectrograph = 'sif version not checked' unless defined? @spectrograph

    match = @raw[ptr..-1].match(/^(\S+)\s/)
    @sif_calb_ver = match[1].to_i
    ptr += match[0].size
    if @sif_calb_ver == 65_540
      match = @raw[ptr..-1].match(/[^\n+]\n/)
      @calb_line = match[1]
      ptr += match[0].size
    end
    puts "#{ptr} after suspected spectrograph" if debug

    raise 'We do not use Mechelle spectrometers, dropping support' if @spectrograph.match(/Mechelle/)

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    @calibration = match[1]
    ptr += match[0].size

    # Calibration lies within here? Yes
    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    @calib = match[1].split(' ').map { |s| s.to_f } # Calibration comes in polynomial coeffs, raising power
    @spectrum_units = %w[nm counts] unless @calib == [0.0, 1.0, 0.0, 0.0]
    puts "calib: #{@calib.join ', '}" if debug
    ptr += match[0].size

    # And a mysterious line of '0 1 0 0'
    match = @raw[ptr..-1].match(/[^\n]+\n/)
    puts "#{ptr}: #{match}" if debug
    ptr += match[0].size

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    @raman = match[1]
    ptr += match[0].size

    4.times do
      match = @raw[ptr..-1].match(/[^\n]+\n/)
      ptr += match[0].size
    end

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    str_l = match[1].to_i
    ptr += match[0].size
    @frame_axis = @raw[ptr..ptr + str_l - 1]
    ptr += str_l

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    str_l = match[1].to_i
    ptr += match[0].size
    @data_type = @raw[ptr..ptr + str_l - 1]
    ptr += str_l

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    str_l = match[1].to_i
    ptr += match[0].size
    @image_axis = @raw[ptr..ptr + str_l - 1]
    ptr += str_l

    match = @raw[ptr..-1].match(/\S+\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s/)

    # Note that pixels start with the 1st in Andor notation
    @xrange = [match[1], match[3]].map { |i| i.to_i }
    @yrange = [match[4], match[2]].map { |i| i.to_i }
    ptr += match[0].size

    match = @raw[ptr..-1].match(/(\S+)\s(\S+)\s(\S+)\s(\S+)\s/) # \s matches \n !!!
    @frames, roi_n, @total_l, @image_l = match[1..4].map { |i| i.to_i } # Guess that roi_n == no_subimages
    ptr += match[0].size

    @wv = []

    # Construct @rois
    @rois = Array.new(roi_n)
    (0..roi_n - 1).each do |roii|
      match = @raw[ptr..-1].match(/\S+\s(\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+)\n/)
      x0, y1, x1, y0, ybin, xbin = match[1..6].map { |i| i.to_i }
      ptr += match[0].size
      puts "ROI #{roii} ends at #{ptr}: " if debug
      @rois[roii] = {
        id: roii,
        x: x0 - 1,
        y: y0 - 1,
        width: x1 - x0 + 1,
        height: y1 - y0 + 1,
        xbinning: xbin,
        ybinning: ybin,
        data_width: (x1 - x0 + 1) / xbin,
        data_height: (y1 - y0 + 1) / ybin
      }
      puts @rois[roii] if debug
      # Calibration polynomial
      @wv += ((x0..x1).map { |x| (0..3).map { |pwr| @calib[pwr] * (x**pwr) }.reduce(:+) })
    end
    puts 'ROI construction done' if debug

    # Trim spaces
    # match = @raw[ptr..-1].match /\s+/
    # ptr += match[0].size

    @timestamps = []
    no_of_zero = 0
    (0..@frames - 1).each do |frame|
      match = @raw[ptr..-1].match(/^\s?(\S+)\n/)
      ptr += match[0].size
      if match[1].to_f == 0.0
        puts "#{match[0]} deemed to be 0.0 at #{ptr}" if debug
        if no_of_zero > 0
          puts "Second timestamp 0.0. Impossible. Must be the end at #{ptr}" if debug
          break
        end
        no_of_zero += 1
      end
      @timestamps[frame] = match[1].to_f
      puts "Timestame #{@timestamps[frame]} at #{ptr}" if debug
    end

    if @sif_ver == 65_567 # && @raw[ptr..ptr+1] == "1\n"
      # A weird array may occur
      # (0..@rois.size-1).each do |i|
      ptr += 2 if @raw[ptr..ptr + 1] == "0\n"
      puts 'Arraycorrection' if debug
      @frames.times do
        match = @raw[ptr..-1].match(/\s+\d+\n/)
        ptr += match[0].size
      end
      puts "Came to #{ptr}" if debug
      # end
    end
    ptr += 2 if @raw[ptr..ptr + 1] == "0\n"
    @data_offset = ptr
    puts "Raw data offset: #{@data_offset}" if debug
    @framesize = @rois.map { |roi| roi[:data_width] * roi[:data_height] }.sum
    ptr += @frames * @framesize * 4

    # Four lines of 0 lead to xml
    4.times do
      match = @raw[ptr..-1].match(/[^\n]+\n/)
      ptr += match[0].size
      puts "Blank line eaten. ptr: #{ptr}" if debug
    end

    xml_raw = @raw[ptr..-13]
    unless xml_raw.size == @raw[-12..-9].unpack1('L')
      raise "xml size mismatch: should be #{xml_raw.size} but at the end specified as #{@raw[-12..-9].unpack1('L')}. ptr: #{ptr}"
    end

    # Set unit and name
    case options[:spectral_unit]
    when 'wavenumber'
      @wv = @wv.map { |nm| 10_000_000.0 / nm } # wavanumber
      @spectrum_units = %w[wavenumber counts]
    when 'eV'
      @wv = @wv.map { |nm| 1239.84197 / nm } # wavanumber
      @spectrum_units = %w[eV counts]
    else
      # nm
      @spectrum_units = %w[nm counts]
    end

    @xml = Nokogiri.XML(xml_raw)
  end

  def at(frame, roin)
    raise 'Roi and frame # must be specified' if frame.nil? || roin.nil?

    # Unbinned ROI, output array
    if @rois[roin][:data_height] > 1 && !@bin_to_spect
      result = Array.new(@rois[roin][:data_height]) { Array.new(@rois[roin][:data_width]) { 0 } }
      yi = 0
      while yi < @rois[roin][:data_height]
        result[yi] =
          @raw[@data_offset + (frame * @framesize + yi * @rois[roin][:data_width]) * 4..@data_offset + (frame * @framesize + (yi + 1) * @rois[roin][:data_width]) * 4 + 1].unpack('F*')
        yi += 1
      end
      result.transpose

    # Output Spectrum
    else
      result = Spectrum.new
      xi = 0
      roishift = 0

      roii = 0
      while roii < roin
        roishift += @rois[roii][:data_width] * @rois[roii][:data_height]
        roii += 1
      end

      # Binning needed
      if @bin_to_spect
        bin_range = if @bin_to_spect.is_a? Array
                      @bin_to_spect
                    else
                      [0, @rois[roin][:data_height]]
                    end

        while xi < @rois[roin][:data_width]
          result[xi] = [@wv[xi + roishift], 0]
          yi = bin_range[0]
          while yi < bin_range[1]
            unpacked = @raw[@data_offset + (frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 4..@data_offset + (frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 4 + 3].unpack1('F')
            raise "frame #{frame} #{xi} #{yi}" unless unpacked

            result[xi][1] += unpacked
            yi += 1
          end
          xi += 1
        end
      # No binning
      else
        while xi < @rois[roin][:data_width]
          result[xi] = [@wv[xi + roishift],
                        @raw[@data_offset + (frame * @framesize + roishift + xi) * 4..@data_offset + (frame * @framesize + roishift + xi) * 4 + 3].unpack1('F')]
          xi += 1
        end
      end
      result.name = "#{@name}-#{frame}-roi#{roin}"
      result.units = @spectrum_units
      result.update_info
      result
    end
  end

  def inspect; end

  def each_frame; end
end

class ADPL
  attr_reader :name, :spects

  def initialize(path, name, options = {})
    @path = path
    @name = name
    options[:spectrum_unit] = 'nm' # Force to use nm for now

    case File.extname(@path)
    when '.spe'
      @spects = Spe.new path, name, options
    when '.sif'
      @spects = SIF.new path, name, options
    end
    @scans_per_deg = 1
    @scans_per_deg = options[:scans_per_deg] if options[:scans_per_deg]
  end

  # Plotting ADPL data, with given density of scan per degree
  def plot(output_path = nil, options = {})
    FileUtils.mkdir_p output_path unless Dir.exist? output_path
    @spects.rois.each_with_index do |roi, roin|
      data_export = Array.new(@spects.frames) { Array.new(@spects.rois[roin][:data_width]) { 0 } }
      frame = 0
      while frame < @spects.frames
        @spects.at(frame, roin).each_with_index do |pt, j|
          data_export[frame][j] = pt[1]
        end
        frame += 1
      end
      tsv_name = "#{@name}-#{roin}.tsv"
      matrix_write data_export.transpose, "#{output_path}/#{tsv_name}"
      wvslope = (@spects.wv[roi[:x] + roi[:width] - 2] - @spects.wv[roi[:x]]) / roi[:data_width]
      wvoffset = @spects.wv[roi[:x]]

      # Some options
      width = 1000
      height = 800
      dark_bg = false
      width = options[:plot_width] if options&.[](:plot_width)
      height = options[:plot_height] if options&.[](:plot_height)
      dark_bg = true if options&.[](:dark_bg)

      case options&.[](:plot_term)
      when nil, 'svg' # Means not indicated or svg
        plot_output = "#{output_path}/#{@name}-#{roin}.svg"
        gplot_terminal = <<~GP_TERM
          set terminal svg size #{width},#{height} mouse enhanced standalone #{dark_bg ? 'background "black"' : ''}
          set output '#{plot_output}'
          set title '#{@name.gsub('_', '\_')}' #{dark_bg ? "tc 'white'" : ''}
          #{dark_bg ? "set border lc 'white'" : ''}
        GP_TERM
      when 'png'
        plot_output = "#{output_path}/#{@name}-#{roin}.png"
        gplot_terminal = <<~GP_TERM
          set terminal png size #{width},#{height} #{dark_bg ? 'background "black"' : ''}
          set output '#{plot_output}'
          set title '#{@name.gsub('_', '\_')}' #{dark_bg ? "tc 'white'" : ''}
          #{dark_bg ? "set border lc 'white'" : ''}
        GP_TERM
      when 'tkcanvas-rb'
        raise 'width and height unspecified' unless options[:plot_width] && options[:plot_height]

        plot_output = "#{output_path}/#{@name}-#{roin}.rb"
        gplot_terminal = <<~GP_TERM
          set terminal tkcanvas ruby size #{options[:plot_width]},#{options[:plot_height]}
          set output '#{plot_output}'
          set title '#{@name}'
        GP_TERM
      end

      gnuplot_content = <<GPLOTCONTENT
  #{gplot_terminal}
      set xlabel 'wavelength (nm)'
  set ylabel 'angle (°)'
  unset key
  set pm3d map
  set pm3d interpolate 0,0

  set title '#{(@name + '-' + roin.to_s).gsub('_', '\_')}'

  set xrange [400:750]

  splot '#{output_path}/#{@name}-#{roin}.tsv' matrix u ($1*#{wvslope} + #{wvoffset}):(90-$2/#{@scans_per_deg}):3
GPLOTCONTENT

      gnuplot_fout = File.open "#{output_path}/#{@name}-#{roin}.gplot", 'w'
      gnuplot_fout.puts gnuplot_content
      gnuplot_fout.close
      `gnuplot '#{output_path}/#{@name}-#{roin}.gplot'`
    end
  end
end

class RbTkCanvas
  attr_reader :plot, :plotarea, :axisranges, :xrange, :yrange, :target_cv

  def initialize(rbin)
    read_tkcanvas(rbin)
  end

  def read_tkcanvas(rbin)
    raw = File.open(rbin, 'r').read
    str_result = raw.split(/^\s*def[^\n]+\n/)
                    .map { |part| part.chomp "\nend\n" }[1..-1]
    @plot = str_result[0]
    @plotarea = eval(str_result[1].split('return ')[1])
    @axisranges = eval(str_result[2].split('return ')[1])
    @xrange = @axisranges[1] - @axisranges[0]
    @yrange = @axisranges[3] - @axisranges[2]
  end

  def plot_to(cv)
    eval(@plot)
    @target_cv = cv
  end

  # Convert canvas selection to plot coordinates
  def canvas_coord_to_plot_coord(selection_on_canvas)
    plotarea_w = @plotarea[1] - @plotarea[0]
    plotarea_h = @plotarea[3] - @plotarea[2]
    x = (selection_on_canvas[0].to_f / @target_cv.width * 1000 - @plotarea[0]) / plotarea_w * @xrange + @axisranges[0]
    y = (@plotarea[3] - selection_on_canvas[1].to_f / @target_cv.height * 1000) / plotarea_h * @yrange + @axisranges[2]

    [x, y]
  end
end

# Spectrum in memcached
# Inheritance from Array doesn't seem possible anymore
class SpectCache
  attr_accessor :hosts, :name, :meta
  def initialize(name, data, cache = Memcached.new('localhost'), meta = {})
    @name = name
    @hosts = cache.servers
    @meta = meta
    # Determine datafield type. Save space and time on integers! Default to float.
    # See if wv needs to be generated

    cache.set "spect_" + name, data.pack("D*")
    metadata[:type] = 'D'
    cache.set "spect_meta" + name, metadata
  end
end

# Sparse methods below

# Plot the spectra in an array
# Options: debug(true/false), out_dir(str), plotline_inject(str), linestyle(array of str), plot_term(str), plot_width(int), plot_height(int), plot_style(str), raman_line(str)
def plot_spectra(spectra, options = {})
  debug = options[:debug]
  raise 'Not an array of spectra input.' unless (spectra.is_a? Array) && (spectra.all? Spectrum)

  # Check if they align in x_units
  x_units = spectra.map { |spectrum| spectrum.units[0] }
  raise "Some spectra have different units: #{x_units}" unless x_units.all? { |unit| unit == x_units[0] }

  # Prepare output path
  outdir = options[:out_dir] || 'plot-' + Time.now.strftime('%d%b-%H%M%S')
  puts "Ploting to #{outdir}" if debug
  FileUtils.mkdir_p outdir unless Dir.exist? outdir

  # Prepare plots
  plots = []
  spectra.each_with_index do |spectrum, i|
    spectrum.write_tsv(outdir + '/' + spectrum.name + '.tsv')
    linestyle = "lt #{i + 1}"
    linestyle = options[:linestyle][i] if options[:linestyle]
    # Ugly fix
    # Should actually be filtering if enhanced is used
    # reversing raman plot here aswell

    # Take care of Raman plots here
    # Should this be done only once instead of to each spectrum?
    coord_ref = '($1):($2)'
    if options[:raman_line]
      raman_line_match = options[:raman_line].to_s.match(/^(\d+\.? \d*)\s?(nm|cm-1|wavenumber|eV)?$/)
      raman_line = raman_line_match[1].to_f
      raman_line_match[2] = spectrum.units[0] unless raman_line_match[2]

      # Unit conversion if necessary: All be nanometers
      case raman_line_match[2]
      when 'nm'
        # Do nothing
      when 'wavenumber', 'cm-1'
        raman_line = 0.01 / raman_line
      when 'eV'
        raman_line = 1239.84197 / raman_line
      else
        raise "spectral unit unexpected: #{raman_line_match[2]}"
      end

      case spectrum.units[0] # What am I doing?? (08 Aug 2024)
        # Oh no this needs cross conversion...
      when 'nm'
      when 'eV'
      when 'wavenumber', 'cm-1'
        raman_line = 0.01 / raman_line * 1E9
        coord_ref = "(#{raman_line}-$1):($2)"
      end

    end

    # tkcanvas doesn't support enhanced text just yet
    title = if options[:plot_term] == 'tkcanvas-rb'
              spectrum.name
            # plots.push "'#{outdir}/#{spectrum.name}.tsv' u ($1):($2) with lines #{linestyle} t '#{spectrum.name}'"
            else
              spectrum.name.gsub('_', '\_')
            end
    plots.push "'#{outdir}/#{spectrum.name}.tsv' u #{coord_ref} with lines #{linestyle} t '#{title}'"
  end
  plots += options[:plotline_inject] if options[:plotline_inject]
  plotline = 'plot ' + plots.join(", \\\n")

  # Terminal dependent preparations
  case options&.[](:plot_term)
  when nil, 'svg' # Means not indicated or svg
    plot_output = "#{outdir}/spect-plot.svg"
    gplot_terminal = <<~GP_TERM
      set terminal svg size 800,600 mouse enhanced standalone
      set output '#{plot_output}'
    GP_TERM
  when 'png'
    plot_output = "#{outdir}/spect-plot.png"
    gplot_terminal = <<~GP_TERM
      set terminal png size 800,600
      set output '#{plot_output}'
    GP_TERM
  when 'tkcanvas-rb'
    plot_output = "#{outdir}/spect-plot.rb"
    gplot_terminal = <<~GP_TERM
      set terminal tkcanvas ruby size #{options[:plot_width]},#{options[:plot_height]}
      set output '#{plot_output}'
    GP_TERM
  end

  # Writing gnuplot instructions
  # Cleaan these up!
  gplot = File.open outdir + '/gplot', 'w'
  plot_headder = <<~GPLOT_HEADER
    #{gplot_terminal}
    set xlabel '#{x_units[0]}'
    set ylabel 'intensity (cts)'
  GPLOT_HEADER
  gplot.puts plot_headder
  gplot.puts options[:plot_style]
  gplot.puts plotline
  gplot.close

  # Execute and return plot path
  # Catch plotting failure? Err if plot_output not generated?
  `gnuplot '#{outdir}/gplot'`
  plot_output
end

def plot_section(spectra, options = {})
  debug = options[:debug]
  raise 'Not an array of spectra input.' unless (spectra.is_a? Array) && (spectra.all? Spectrum)

  width = options['plot_width'] ? options['plot_width'].to_i : 800
  height = options['plot_height'] ? options['plot_height'].to_i : 600

  # Check if they align in x_units
  x_units = spectra.map { |spectrum| spectrum.units[0] }
  raise "Some spectra have different units: #{x_units}" unless x_units.all? { |unit| unit == x_units[0] }

  outdir = options[:out_dir] || 'section-' + Time.now.strftime('%d%b-%H%M%S')

  puts "Ploting to #{outdir}" if debug
  FileUtils.mkdir_p outdir unless Dir.exist? outdir

  data_fout = File.open(outdir + '/section-matrix.tsv', 'w')
  spectra.each do |spect|
    data_fout.puts (spect.map { |pt| pt[1] }).join ' '
  end
  data_fout.close

  # Construct xtics
  case x_units[0]
  when 'nm'
    tics = []
    spectra[0].each_with_index do |pt, x|
      if x == 0 || x == spectra[0].size - 1 #
      elsif (pt[0] / 100).to_i != (spectra[0][x + 1][0] / 100).to_i # Every 100 nm
        tics.push [((spectra[0][x + 1][0] / 100).to_i * 100).to_s, x]
      end
    end
    set_xticks = "set xtics (#{tics.map { |tic| "\"#{tic[0]}\" #{tic[1]}" }.join(', ')})"
    set_xticks += "\nset xlabel 'wavelength (nm)'"
  when 'wavenumber'
    tics = []
    spectra[0].each_with_index do |pt, x|
      if x == 0 || x == spectra[0].size - 1 #
      elsif (pt[0] / 1000).to_i != (spectra[0][x + 1][0] / 1000).to_i # Every 100 nm
        tics.push [((spectra[0][x + 1][0] / 1000).to_i * 1000).to_s, x]
      end
    end
    set_xticks = "set xtics (#{tics.map { |tic| "\"#{tic[0]}\" #{tic[1]}" }.join(', ')})"
    set_xticks += "\nset xlabel 'wavenumber (cm^{-1})'"
  when 'eV'
    tics = []
    spectra[0].each_with_index do |pt, x|
      if x == 0 || x == spectra[0].size - 1 #
      elsif (pt[0] / 0.5).to_i != (spectra[0][x + 1][0] / 0.5).to_i # Every 100 nm
        tics.push [((spectra[0][x + 1][0] / 0.5).to_i * 0.5).to_s, x]
      end
    end
    set_xticks = "set xtics (#{tics.map { |tic| "\"#{tic[0]}\" #{tic[1]}" }.join(', ')})"
    set_xticks += "\nset xlabel 'eV'"
  else
    set_xticks = ''
  end

  # Switching canvas type
  case options&.[](:plot_term)
  when nil, 'svg' # Means not indicated or svg
    plot_output = "#{outdir}/section.svg"
    set_term = "set terminal svg size #{width},#{height} enhanced standalone"
  when 'png'
  when 'tkcanvas-rb'
    plot_output = "#{outdir}/section.rb"
    set_term = "set terminal tkcanvas ruby size #{width},#{height}"
  end

  # Assemble gplot instructions
  gplot_content = <<~EOGP
    #{set_term}
    set output '#{plot_output}'
    #{options[:plot_style]}
    #{set_xticks}
    plot '#{outdir}/section-matrix.tsv' matrix w image pixel
  EOGP

  gplot_out = File.open(outdir + '/section.gplot', 'w')
  gplot_out.puts gplot_content
  gplot_out.close
  `gnuplot '#{outdir}/section.gplot'`
  plot_output
end

# Data form: [x1 y1-1 y2-1] [x2 y1-2 y2-2 ...]
def quick_plot(data)
  FileUtils.mkdir_p 'output' unless Dir.exist? 'output'
  raise 'Some entries in data are different in length' unless data.all? { |line| line.size == data[0].size }

  data_fname = "data_#{Time.now.strftime('%d%b%Y-%H%M%S')}"
  data_fout = File.open "output/#{data_fname}.tsv", 'w'
  data.each { |line| data_fout.puts line.join("\t") }
  data_fout.close

  plotlines = []
  data[0].each_with_index do |_column, i|
    # Assume for now no headder line
    plotlines.push "u 1:($#{i + 1}) t '#{i + 1}'"
  end

  plot_line = "plot 'output/#{data_fname}.tsv'" + plotlines.join(", \\\n'' ")
  plot_headder = <<GPLOT_HEADER
  set terminal png size 800,600 lw 2
  set output 'output/#{data_fname}.png'
GPLOT_HEADER
  plot_replot = <<GPLOT_REPLOT
  set terminal svg mouse enhanced standalone size 800,600 lw 2
  set output 'output/#{data_fname}.svg'
  replot
GPLOT_REPLOT

  gplot_out = File.new "output/#{data_fname}.gplot", 'w'
  gplot_out.puts plot_headder
  gplot_out.puts plot_line
  gplot_out.puts plot_replot
  gplot_out.close
  `gnuplot 'output/#{data_fname}.gplot'`
  data_fname
end

def matrix_write(matrix, path, delim = "\t")
  matrix = matrix.transpose
  raise 'Some entries in data are different in length' unless matrix.all? { |line| line.size == matrix[0].size }

  matrix_out = File.open path, 'w'
  matrix.each do |line|
    matrix_out.puts line.join delim
  end
  matrix_out.close
end

def gaussian(sample, pos, width, height)
  basis = Spectrum.new
  basis.name = "#{pos}-#{width}-#{height}"
  sample.each do |x|
    basis.push [x, Math.exp(-(((x - pos) / width)**2)) * height]
  end
  basis
end

def lorentzian(sample, pos, width, height)
  basis = Spectrum.new
  basis.name = "lorenzian-#{pos}-#{width}-#{height}"
  sample.each do |x|
    basis.push [x, height.to_f / (1 + (2.0 * (x - pos) / width)**2)]
  end
  basis
end

def gplot_datablock(name, data, options = {})
  puts "Generating datablock named #{name} with #{data.size} lines" if options['verbose']
  output = "$#{name}<<EO#{name}\n"
  data.to_a.each do |pt| # Catch the case if it were a matrix
    output += pt.join "\t"
    output += "\n"
  end
  if options[:polygon] == true
    output += data.to_a[0].join "\t"
    output += "\n"
  end
  output += "EO#{name}\n"
  output
end

# Some geometry stuffs
# Compute section vector
def section_vector(axis, coord)
  # Catch horizontal
  return [0, axis[1] - coord[1]] if axis[1] == axis[3]
  return [axis[0] - coord[0], 0] if axis[0] == axis[2]

  # Compute x and y intersects
  ix = axis[2] - (axis[3].to_f - coord[1]) * (axis[2] - axis[0]) / (axis[3] - axis[1]) - coord[0]
  iy = axis[3] - (axis[2].to_f - coord[0]) * (axis[3] - axis[1]) / (axis[2] - axis[0]) - coord[1]
  return [0, 0] if ix == 0 || iy == 0

  [ix * (iy**2) / (ix**2 + iy**2), iy * (ix**2) / (ix**2 + iy**2)]
end

# Project coord onto axis and get the parameter t
def get_t(axis, coord)
  vec = section_vector(axis, coord)
  pt_aligned = [coord[0] + vec[0], coord[1] + vec[1]]
  c = [pt_aligned[0] - axis[0], pt_aligned[1] - axis[1]]
  return c[1].to_f / (axis[3] - axis[1]) if axis[2] - axis[0] == 0
  return c[0].to_f / (axis[2] - axis[0]) if axis[3] - axis[1] == 0

  (c[0].to_f / (axis[2] - axis[0]) + c[1].to_f / (axis[3] - axis[1])) / 2
end

# 以下 For sample alignment
# Gives the rotation matrix needed to rotate origin to a resulting point set, when acted on that point set

# Quick 'n dirty func. to convert plot coord. to piezo coord.
def coord_conv(pl_scan_orig, orig_dim, map_dimension, coord)
  [coord[0].to_f / map_dimension[0] * orig_dim[0] + pl_scan_orig[0],
   coord[1].to_f / map_dimension[1] * orig_dim[1] + pl_scan_orig[1]]
end

def rotator_solve(origin)
  (origin.transpose * origin).invert * origin.transpose
end

def rotator(angle)
  GSL::Matrix.alloc([Math.cos(angle), Math.sin(angle)], [-Math.sin(angle), Math.cos(angle)]).transpose
end

def row_diff(size)
  result = GSL::Matrix.I(size)
  (0..size - 2).each { |j| result.swap_rows!(j, j + 1) }
  GSL::Matrix.I(size) - result
end

def center_of_mass(x)
  # In form of:
  # [[x1 y1]
  # [x2 y2]]
  # ...
  result = GSL::Vector.alloc(x.size2)
  x.each_row do |row|
    result += row
  end
  result / x.size1
end

def plot_alignments(alignments)
  raise 'Input Alignments!' unless alignments.is_a? Array && alignments.all? { |a| a.is_a? Alignment }

  points_data = ''
  alignments.each do |_alignment|
    points_data
  end
end
