# Script for the processing of micro-PL scann data

# No longer needed as long you export NMATRX=1
# require 'nmatrix'
require 'gsl'
require 'nokogiri'
require 'time'
require 'parallel'

class Scan < Array
  # Assume all wavelength scales allign across all pixels
  attr_accessor :frames, :wv, :spectrum_units,:path, :name, :width, :height, :depth, :loaded
  def initialize (path, name, dim, options = nil)
    @path = path
    @name = name
    @width = dim[0]
    @height = dim[1]
      @depth = dim[2]
    @loaded = false
    @spectral_width = 0
    super Array.new(width) {Array.new(height) {Array.new(depth) {Spectrum.new()}}}
  end

  def load(options = {})
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

  def load_csv(options)
    fin = File.open @path, 'r'
    puts "Reading #{@path}..."
    lines = fin.readlines
    fin.close

    # Detection of seperator , or tab
    raiese "No seperator found in line 0." unless match = lines[0].match(/[\t,]/)
    seperator = match[0]

    # Detection of title line and units
    # Problem: even if the spectrum were in wavenumbers, the unit was still recorded as "Wavelength"
    if lines[0] =~ /^Frame[\t,]/
      title_line = lines.shift
      @spectrum_units = title_line.split(seperator)[1..2]
      puts "Title line detected. Unit identified as #{@wv_unit}"
    else
      puts "No title line detected. Please ensure data format to be <Frame #> <Wavelength/wavenumber> <Intensity>"
      puts "And input <wavelength/wavenumber, intensity> unit below:"
      @spectrum_units = gets.chomp.split /, ?/
    end

    # Framesize and wavelength construction
    @framesize = (lines.index {|ln| ln[0] == '2'})
    @wv = (0.. @framesize -1).map {|i| lines[i].split(seperator)[1]}
    puts "Frame size determined to be #{@framesize}, spectral range being #{@wv[0]} .. #{@wv[-1]}"
    @spectrum_units[0] = 'Wavenumber (cm-1)' if @wv[-1] < @wv[0]
    
    raise "Number of lines is #{lines.size}, not multiplication of given width (#{@width}) * height (#{@height})* depth (#{@depth})!" unless lines.size == @framesize * (@width * @height * @depth)
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
      if j % 2 == 0
        self[i][j][k].push [wv, intensity]
      else
        self[width-1-i][j][k].push [wv, intensity]
      end
    end
    # Update all spectra
    puts "Loading done. Updating info of spectra."
    self.each do |row|
      row.each do |column|
        column.each do |pixel|
          pixel.units = @spectrum_units
          pixel.update_info
        end
      end
    end
    @loaded = true
    puts "done"
  end

  def load_spe(options)
    # File read
    debug = options[:debug]
    puts "loading spe #{@path} with options #{options}."
    puts "Reading spe at #{Time.now}" if debug
    @spe = Spe.new @path, @name, options
    puts "Spe reading complete at #{Time.now}. Start scan building." if debug
    # Spectrum building
    i = 0
    while i < @width
      j = 0
      while j < @height
        if j % 2 == 1 && options[:s_scan] == true
          #puts "Loading with S-shape scan"
          relabel_i = @width - i - 1
        else
          relabel_i = i
        end
        k = 0
        while k < @depth
          #frame_st = (k * (@width * @height) + j * @width + i) * @framesize
          #spe[frame_st .. frame_st + @framesize - 1].each_with_index do |value, sp_index|
          self[relabel_i][j][k] = @spe[k * (@width * @height) + j * @width + i]
          #end
          k += 1
        end
        j += 1
      end
      i += 1
    end
    puts "Scan building complete at #{Time.now}." if debug
  end

  def extract_spect(points)
    raise "Not a series of points input." unless (points.is_a? Array) && (points.all? {|item| item.size == 3})
    if !@loaded
      puts "Scan #{@name} not yet loaded. Loading."
      self.load
    end
    result = []
    points.each do |pt|
      result.push self[pt[0]][pt[1]][pt[2]]
      result.last.name = pt.join '-'
    end 
    result
  end

  # Excise a line of spectra between two points in space
  def excise(points)
    load unless @loaded
    raise "No two points given" unless (points.is_a? Array) && (points.all? {|i| i.is_a? Array}) && (points.size == 2) && (points.all? {|i| i.size == 3})
    raise "Points #{points} out of range #{@wiidth} x #{@height} x #{@depth}" unless \
      points.all? {|pt| pt.all? {|coord| coord >=0 }} && \
      points.all? {|pt| pt[0] < @width} && \
      points.all? {|pt| pt[1] < @height} && \
      points.all? {|pt| pt[2] < @depth}
    diff = (0..2).map{|i| points[1][i] - points[0][i]}
    puts "diff: #{diff}"
    unless varying = diff.find_index {|x| x**2 >= 1} # First varying index, return single point extraction if false
      puts "Not finding any diff"
      return [self[points[0][0]][points[0][1]][points[0][2]]]
    end
    d = (0..2).map{|i| diff[i].to_f / diff[varying]}
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

  # Plot a scanning map with respect to the summation function given in the block
  def plot_map(outdir = nil, options = nil)
    outdir = @name unless outdir
    Dir.mkdir outdir unless Dir.exist? outdir
    map_fout = File.open "#{outdir}/#{@name}.tsv", 'w'
    map = Array.new(@depth) {Array.new(@height) {Array.new(@width) {0.0}}}    

    # Serialize before parallelization
    i = 0
    while i < @width * @height * @depth
      x = i % @width
      y = ((i - x) / @width) % @height
      z = i / (@width * height)
      map[z][y][x] = yield(self[x][y][z])
    i += 1
    end

    z = 0
    while z < @depth
      row = 0
      map_fout.puts "# z = #{z}"
      while row < @height
        map_fout.puts map[z][row].join "\t"
        row += 1
      end
      map_fout.print "\n\n"
      z += 1
    end
=begin
    # Iterate through z layers
    (0..@depth-1).each do |z|
      map = Array.new(@width) {Array.new(@height) {0.0}} # One slice
      (0..@width-1).each do |x|
        (0..@height-1).each do |y|
          map[x][y] = yield(self[x][y][z])
        end
      end

      map_fout.puts "# z = #{z}"
      map.transpose.each do |row|
        map_fout.puts row.join "\t"
      end
      map_fout.print "\n\n"
    end
=end
    # Export map and push
    map_fout.close
      # Plotting
    gplot = File.open "#{outdir}/#{@name}.gplot", 'w'
  gplot_content =<<GPLOT_HEAD
set terminal svg size #{@width * 5 * @depth},#{@height * 5} mouse enhanced standalone
set size ratio -1
set output '#{outdir}/#{@name}.svg'
set border 0
unset key
unset xtics
unset ytics
set xrange[-0.5:#{@width-0.5}]
set yrange[-0.5:#{@height-0.5}]
set title '#{@name.gsub('_','\_')}'
unset colorbox
set palette cubehelix negative
#set terminal png size #{@width * 5},#{@height * 5}
#set output '#{outdir}/#{@name}.png'
set multiplot
GPLOT_HEAD
    gplot.puts gplot_content
    (0..@depth-1).each do |z|
      gplot.puts "set title 'z = #{z}'"
      gplot.puts "set origin #{z.to_f / @depth},0"
      gplot.puts "set size #{1.0/@depth},1"
      gplot.puts "plot'#{outdir}/#{@name}.tsv' index #{z} matrix with image pixels"
    end
    gplot.puts "unset multiplot"
    gplot.close
    puts "Plotting #{@name}, W: #{@width}, H: #{@height}"
    `gnuplot #{outdir}/#{@name}.gplot`
  end

  # Return list of points in rectangular area defined by pt_1(x,y) to pt_2(x,y)
  def select_points(pt_1, pt_2)
    raise "Not points" unless (pt_1.size == 3) && (pt_2.size == 3)
    result = []
    ([pt_1[0], pt_2[0]].sort[0]..[pt_1[0], pt_2[0]].sort[1]).each do |x|
      ([pt_1[1], pt_2[1]].sort[0]..[pt_1[1], pt_2[1]].sort[1]).each do |y|
        ([pt_1[2], pt_2[2]].sort[0]..[pt_1[2], pt_2[2]].sort[1]).each do |z|
          result.push [x,y,z]
        end
      end
    end
    result
  end
end

class Spectrum < Array
  attr_accessor :name, :units, :spectral_range, :signal_range, :desc
  def initialize(path=nil)
    @name = ''
    @desc = ''
    @units = ['', 'counts']
    super Array.new() {[0.0, 0.0]}
    # Load from tsv/csv if path given
    #if path && (File.exist? path) too gracious!
    if path
      fin = File.open path, 'r'
      lines = fin.readlines
      lines.shift if lines[0] =~ /^Frame[\t,]/
      # Detection of seperator , or tab
      if match = lines[0].match(/[\t,]/)
        puts "Loading from #{path}"
        seperator = match[0]
        lines.each_index do |i|
          (wv, intensity) = lines[i].split seperator
          wv = wv.to_f
          intensity = intensity.to_f
          self[i] = [wv, intensity]
        end
        @name = File.basename(path)
        update_info
      else
        puts "No seperator found in #{path}"
      end
    end
  end

  def write_tsv(outname)
    fout = File.open outname, 'w'
    self.each do |pt|
      fout.puts pt.join "\t"
    end
    fout.close
  end

  def inspect
    return { 'name' => @name, 'size' => self.size, 'spectral_range' => @spectral_range, 'signal_range' => @signal_range, 'desc' => @desc }.to_s
  end

  def update_info
    @spectral_range = self.minmax_by { |pt| pt[0] }.map{ |pt| pt[0] }
    @signal_range = self.minmax_by { |pt| pt[1] }.map{ |pt| pt[1] }
  end

  def ma(radius)
    # +- radius points moving average
    # Issue: Radius defined on no of points but not real spectral spread 
    raise "Radius should be integer but was given #{radius}" unless radius.is_a?(Integer)
    raise "Radius larger than half the length of spectrum" if 2*radius >= self.size

    result = Spectrum.new
    (0..self.size-2*radius-1).each do |i|
      # Note that the index i of the moving average chromatogram aligns with i + radius in originaal chromatogram
      x = self[i + radius][0]
      y = 0.0
      (i .. i + 2 * radius).each do |origin_i|
        # Second loop to run through the neighborhood in origin
        # Would multiplication with a diagonal stripe matrix be faster than nested loop? No idea just yet.
        y += self[origin_i][1]
      end
      y = y / (2 * radius + 1) # Normalization
      result[i] = [x, y]
    end
    result.units = @units
    result.name = @name + "-ma#{radius}"
    result.update_info
    result
  end

  def deriv
    result = Spectrum.new
    (0..self.size-2).each do |i|
      result.push [(self[i][0] + self[i+1][0])/2, (self[i+1][1] - self[i][1])/(self[i+1][0] - self[i][0])]
    end
    result
  end

  def local_max(loosen = nil)
    raise "Loosen neighborhood should be number of points" unless loosen.is_a? Integer or loosen == nil
    result = Spectrum.new
    (1..self.size-2).each do |i|
      if self[i][1] > self[i+1][1] && self[i][1] > self[i-1][1]
        result.push self[i]
      end
    end

    loosened = []
    if loosen
      #puts "start loosening with radius #{loosen}"
      i = 0
      while i < result.size - 1
        if (result[i][0] - result[i+1][0])**2 + (result[i][1] - result[i+1][1])**2 > loosen**2
          loosened.push result[i]
          loosened.push result[i+1] if i == result.size-2
          i +=1
        else
          loser = (result[i][1] - result[i+1][1] >= 0) ? i : i+1
          #puts "comparing #{result[i..i+1]}, loser is #{loser}"
          result.delete_at loser
          loosened.push result[i] if i == result.size-1
          #puts "deleting at #{loser}"
        end
      end
      loosened.each {|i| result.push i}
    end
    result
  end

  def local_min(loosen = nil)
    raise "Loosen neighborhood should be number of points" unless loosen.is_a? Integer or loosen == nil
    result = Spectrum.new
    (1..self.size-2).each do |i|
      if self[i][1] < self[i+1][1] && self[i][1] < self[i-1][1]
        result.push self[i]
      end
    end

    loosened = []
    if loosen
      #uts "start loosening with radius #{loosen}"
      i = 0
      while i < result.size - 1
        if (result[i][0] - result[i+1][0])**2 + (result[i][1] - result[i+1][1])**2 > loosen**2
          loosened.push result[i]
          loosened.push result[i+1] if i == result.size-2
          i +=1
        else
          loser = (result[i][1] - result[i+1][1] >= 0) ? i : i+1
          #puts "comparing #{result[i..i+1]}, loser is #{loser}"
          result.delete_at loser
          loosened.push result[i] if i == result.size-1
          #puts "deleting at #{loser}"
        end
      end
      loosened.each {|i| result.push i}
    end
    result
  end

  def resample(sample_in)
    raise "Not a sampling 1D array" unless sample_in.is_a? Array
    raise "Expecting 1D array to be passed in" unless sample_in.all? Numeric
    sample = sample_in.sort # Avoid mutating the resample array
    
    update_info

    result = Spectrum.new
    result.name = @name + '-resampled'
    result.desc += "/#{sample.size} points"

    # Frequency value could be increasing or depending on unit
    x_polarity = (self[-1][0] - self[0][0] > 0 ) ? 1 : -1
    sample.reverse! if x_polarity == -1

    i = 0
    while (sampling_point = sample.shift)
      # Ugly catch for out of range points, throw out zero
      if sampling_point < self.spectral_range[0] || sampling_point > spectral_range[1]
        result.push [sampling_point, 0.0]
        next
      end

      # self[i][0] need to surpass sampling point to bracket it. Careful of rounding error
      while (i < self.size - 1) && ((sampling_point - self[i][0]) * x_polarity > 0.000001)
        i += 1
      end

      # Could be unnecessarily costly, but I can think of no better way at the moment
      if i == 0 
        interpolation = self[0][1]
      else
        interpolation = self[i-1][1] + (self[i][1] - self[i-1][1]) * (sampling_point - self[i-1][0]) / (self[i][0] - self[i-1][0])
      end
      result.push [sampling_point, interpolation]
    end

    result.update_info

    # sample array is sorted right so the right sequence will follow ^.<
    # result.reverse! if x_polarity == -1
    result
  end

  def *(input)
    if input.is_a? Spectrum
      sample = self.map{|pt| pt[0]}.union(input.map{|pt| pt[0]})
      self_resmpled_v = GSL::Vector.alloc(self.resample(sample).map {|pt| pt[1]})
      input_resmpled_v = GSL::Vector.alloc(input.resample(sample).map {|pt| pt[1]})
      self_resmpled_v * input_resmpled_v.col
    elsif input.is_a? Numeric
      self.each {|pt| pt[1] = pt[1].to_f * input}
    end
  end

  def /(input)
    raise "Not being devided by a number." unless input.is_a? Numeric
    self.each {|pt| pt[1] = pt[1].to_f / input}
  end

  def +(input)
    old_name = @name #preserve name, not to be changed by resample()
    sample = self.map{|pt| pt[0]}.union(input.map{|pt| pt[0]})
    self_resampled = self.resample(sample)
    input_resmpled = input.resample(sample)
    raise "bang" unless self_resampled.size == input_resmpled.size
    self_resampled.each_index do |i|
      self_resampled[i][1] += input_resmpled[i][1]
    end
    self_resampled.name = old_name #preserve name, not to be changed by resample()
    self_resampled
  end

  def -(input)
    sample = self.map{|pt| pt[0]}.union(input.map{|pt| pt[0]})
    self_resampled = self.resample(sample)
    input_resmpled = input.resample(sample)
    raise "bang" unless self_resampled.size == input_resmpled.size
    self_resampled.each_index do |i|
      self_resampled[i][1] -= input_resmpled[i][1]
    end
    self_resampled
  end

  def uniform_resample(n)
    spacing = (@spectral_range[1] - @spectral_range[0]).to_f / n
    sample = (0..n-1).map{|i| @spectral_range[0] + (i+0.5) * spacing}
    self.resample sample
  end

  def spikiness(smooth, loosening)
    smoothed = self.ma(3)
    minmax_diff = smoothed.minmax(loosening)
    spikiness = (minmax_diff * minmax_diff) / minmax_diff.size
    # But not normalized to intensity. Whether this is good or not...
    spikiness
  end

  def minmax(loosening)
    result = self.local_max(loosening) - self.local_min(loosening)
    # Cut off the (bg-zero)s at head and tail
    result.shift
    result.pop
    result.name = self.name + '-minmax'
    result
  end

  def sum
    (self.map{|pt| pt[1]}).sum
  end

  # For debugging the bg noise sensitivity of minmax spike assay
  def minmax_spike(r, loosen)
    smoothed = self.ma(r)
    maxes = smoothed.local_max(loosen)
    mins = smoothed.local_min(loosen)
    minmax = (maxes - mins).shift!.pop!
    spikiness = (minmax * minmax) / minmax.size
    [smoothed, maxes, mins, minmax, spikiness]
  end

  def stdev
    sum = 0.0
    sos = 0.0 # sum of squares
    self.each do |pt|
      sum += pt[1]
      sos += pt[1] ** 2
    end
    ((sos - sum**2) / @size) ** 0.5
  end


  def fft 
    ft = GSL::Vector.alloc(self.map{|pt| pt[1]}).fft # 究極一行文
    ft = ft.to_complex2.abs # Be positive
    ft
  end

  def from_to(from, to)
    sum = 0.0
    self.each do |pt|
      sum += pt[1] if ((pt[0] > from) && (pt[0] < to))
    end
    sum
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
    control_point_files = Dir.glob alignment_dir + "/*.bmp"
    control_point_files.each do |fn|
      if match = File.basename(fn).match(/^([^\-]+)\-(\d+\.\d\d\d)-(\d+\.\d\d\d)-(\d+\.\d\d\d)/)
        #coords_arr.push [match[2].to_f, match[3].to_f, match[4].to_f]
        # 2-dim for now for 3-dim requires more testing. rotator_solve might yet be incompatible
        coords_arr.push [match[2].to_f, match[3].to_f]
        @control_pts.push [match[1], fn]
      end
    end
    @coords = GSL::Matrix.alloc(coords_arr.flatten, coords_arr.size, 2)
  end

  # Express position recorded in alignment x_0 in this alignment coordinate
  def express(x_0, pos)
    rotator, displacement = self.relative_to(x_0)
    pos * rotator + displacement
  end

  # x1.relative_to(x0) gives the rotation and displacement so that x0*rotation + displacement = x1
  def relative_to(x_0)
    raise "x_0 is not an Alignment" unless x_0.is_a? Alignment
    raise "x_0 is not an Alignment" unless x_0.is_a? Alignment
    raise "Size mismatch" unless x_0.coords.size == self.coords.size
    (0..x_0.coords.size1-1).each do |i|
      raise "Control points mismatch" unless x_0.control_pts[i][0] == self.control_pts[i][0]
    end
    rotator = rotator_solve(row_diff(x_0.coords.size1)*x_0.coords) * row_diff(@coords.size1) * @coords
    displacement = center_of_mass(@coords) - center_of_mass(x_0.coords * rotator)
    [rotator, displacement]
  end
end

class Spe < Array
  attr_accessor :path, :name, :xml, :frames, :frame_width, :frame_height, :wv, :spectrum_units, :data_creation, :file_creation, :file_modified, :grating, :center_wavelength, :exposure_time, :rois
  
  def initialize(path, name, options={})
    debug = options[:debug]
    @path = path
    @name = name
    raise "No such file #{@path}" unless File.exist? path
    
    puts "Loading spe file #{@path} at #{Time.now}" if debug
    fin = File.open @path, 'rb'
    raw = fin.read(fin.size).freeze
    fin.close
    puts "Finished reading spe at #{Time.now}" if debug
    # Starting position of xml part
    xml_index = raw[678..685].unpack1('Q')
    xml_raw = raw[xml_index..-1]
    binary_data = raw[0x1004..xml_index-1].freeze
    unpacked_counts = binary_data.unpack('S*')
    puts "Unpacked binary has a lenght of: #{unpacked_counts.size}" if debug
    @xml = Nokogiri.XML(xml_raw).remove_namespaces!
    
    # Data format
    @frames = @xml.xpath('//DataFormat/DataBlock').attr('count').value.to_i
    pixelformat = @xml.xpath('//DataFormat/DataBlock').attr('pixelFormat').value
    raise "Pixel format #{pixelformat} not supported" unless pixelformat == 'MonochromeUnsigned16'

    x0 = @xml.xpath('//Calibrations/SensorMapping').attr('x').value.to_i

    @area_width = @xml.xpath('//Calibrations/SensorMapping').attr('width').value.to_i
    @area_height = @xml.xpath('//Calibrations/SensorMapping').attr('height').value.to_i
    @xbinning = @xml.xpath('//Calibrations/SensorMapping').attr('xBinning').value.to_i
    @ybinning = @xml.xpath('//Calibrations/SensorMapping').attr('yBinning').value.to_i

    puts "W: #{@area_width}/#{@xbinning} H: #{@area_height}/#{@ybinning}" if debug
    @frame_width = @area_width / @xbinning
    @frame_height = @area_height / @ybinning
    @framesize = @frame_width * @frame_height
    #raise "0_o unpacked ints has a length of #{unpacked_counts.size} for #{@name}. With framesize #{@framesize} we expect #{frames} * #{@framesize}." unless unpacked_counts.size == @frames * @framesize

    wavelengths_nm = @xml.xpath('//Calibrations/WavelengthMapping/Wavelength').text.split(',')[x0, @framesize].map {|x| x.to_f}
    @wv = wavelengths_nm
    
    # @data_creation, @file_creation, @file_modified
    @data_creation = Time.parse(@xml.xpath('//DataHistories/DataHistory/Origin').attr('created').value)
    @file_creation = Time.parse(@xml.xpath('//GeneralInformation/FileInformation').attr('created').value)
    @file_modified= Time.parse(@xml.xpath('//GeneralInformation/FileInformation').attr('lastModified').value)
    # @grating @center wavelength
    @grating = @xml.xpath('//DataHistories/DataHistory/Origin/Experiment/Devices/Spectrometers/Spectrometer/Grating/Selected').text
    @center_wavelength = @xml.xpath('//DataHistories/DataHistory/Origin/Experiment/Devices/Spectrometers/Spectrometer/Grating/CenterWavelength').text
    # @exposure_time
    @exposure_time = @xml.xpath('//DataHistories/DataHistory/Origin/Experiment/Devices/Cameras/Camera/ShutterTiming/ExposureTime').text.to_f

    # Set unit and name
    case options[:spectral_unit]
    when 'wavenumber'
      @wv = wavelengths_nm.map {|nm| 10000000.0 / nm} # wavanumber
      @spectrum_units = ['wavenumber', 'counts']
    when 'eV'
      @wv = wavelengths_nm.map {|nm| 1239.84197 / nm} # wavanumber
      @spectrum_units = ['eV', 'counts']
    else
      @wv = wavelengths_nm # nm
      @spectrum_units = ['nm', 'counts']
    end

    # Paralellization: distribution of frames to process among processes
    if options[:parallelize]
      parallelize = options[:parallelize]
    else
      parallelize = 1 # Processes
    end
    dist = []
    frames_per_dist = (@frames.to_f / parallelize).ceil
    (0..parallelize-1).each do |process|
      till = (process + 1) * frames_per_dist - 1
      till = @frames - 1 unless till < @frames
      break if dist.last&.end == till
      dist.push(process * frames_per_dist .. till)
    end
    puts "Load distribution: #{dist} under #{parallelize} processes." if debug

    # Simple: a line of spectrum per frame
    if @frame_height == 1
      puts "A spectra containing spe" if debug
      super Array.new(@frames) {Spectrum.new()}
      results = Parallel.map(dist, in_processes: parallelize) do |range|
      #results = Parallel.map(dist, in_threads: parallelize) do |range|
        result = Array.new(range.size) {Spectrum.new()}
      #(0..@frames - 1).each do |i|
        puts "A process is taking care of #{range}" if debug
        i = range.begin
        while i <= range.end
          result[i-range.begin][0..0] = (0..@framesize-1).map{|sp_index| [@wv[sp_index], unpacked_counts[i * @framesize + sp_index]]}
          result[i-range.begin].name = "#{@name}-#{i}"
          result[i-range.begin].spectral_range = [@wv[0], @wv[-1]]
          result[i-range.begin].units = @spectrum_units
          i += 1
        end
        puts "Done #{Time.now}"
        result
      end
      dist.each_with_index {|range, i| self[range] = results[i]}
    # Frame contains image
    else
      puts "#{@name} has images in frames, W: #{@frame_width} H: #{@frame_height}. Loading" if debug
      #super Array.new(@frames) {Array.new(@frame_height) {Array.new(@frame_width) {0}}}
      results = Parallel.map(dist, in_processes: parallelize) do |range|
        result = Array.new(range.size) {Array.new(@frame_height) {Array.new(@frame_width) {0}}}
        (range.begin * @framesize .. (range.end + 1) * @framesize - 1).each do |i|
          result[i / @framesize - range.begin][(i % @framesize) / @frame_width][i % @frame_width] = unpacked_counts[i]
        end
        result
      end

      puts "Loading complete at #{Time.now}" if debug
    end
    super results.reduce(:+)
  end
  
  def inspect
  #attr_accessor :path, :name, :xml, :frames, :frame_width, :frame_height, :wv, :spectrum_units, :data_creation, :file_creation, :file_modified, :grating, :center_wavelength, :exposure_time
    ["Spe name: #{@name}", "path: #{@path}", "Contining #{@frames} frames of dimension #{frame_width} x #{frame_height}", "Spectral units: #{@spectrum_units}", "Data created: #{@data_creation}, file created: #{@file_creation}, file last modified: #{@file_modified}", "Grating: #{@grating} with central wavelength being #{@center_wavelength} nm", "Exposure time: #{@exposure_time} ms."].join "\n"
  end

  def each_frame

  end
end

class ADPL
  def initialize(path, name, options = {})
    @path = path
    @name = name
    options[:spectrum_unit] = 'nm' # Force to use nm for now
    @spe = Spe.new path, name, options
    @scans_per_deg = 1
    @scans_per_deg = options[:scans_per_deg] if options[:scans_per_deg]
  end

  # Plotting ADPL data, with given density of scan per degree
  def plot(output_path)
    data_export = Array.new(@spe.size) {Array.new(@spe[0].size) {0}}
    @spe.each_with_index do |spectrum, i|
      spectrum.each_with_index do |pt, j|
        data_export[i][j] = pt[1]
      end
    end
    tsv_name = output_path + @name + ".tsv"
    matrix_write data_export, tsv_name

gnuplot_content =<<GPLOTCONTENT
set terminal png size 1000,800
set xlabel 'wavelength (nm)'
set ylabel 'angle (°)'
unset key
set pm3d map
set pm3d interpolate 0,0

set output '#{output_path + @name}.png'
set title '#{@name.gsub('_', '\_')}'

set xrange [400:750]

splot '#{output_path + @name}.tsv' matrix u ($1*0.30623 + 364.8464):(90-$2/#{@scans_per_deg}):3
GPLOTCONTENT

    gnuplot_fout = File.open "#{output_path + @name}.gplot", 'w'
    gnuplot_fout.puts gnuplot_content
    gnuplot_fout.close
    `gnuplot #{output_path + @name}.gplot`
  end
end

def plot_spectra(spectra, options = {})
  raise "Not an array of spectra input." unless (spectra.is_a? Array) && (spectra.all? Spectrum)

  # Check if they align in x_units
  x_units = spectra.map {|spectrum| spectrum.units[0]}
  raise "Some spectra have different units!" unless x_units.all? {|unit| unit == x_units[0]}

  if options[:outdir]
    plotdir = options[:outdir]
  else
    plotdir = "plot-" + Time.now.strftime("%d%b-%H%M%S")
  end
  puts plotdir
  Dir.mkdir plotdir unless Dir.exist? plotdir

  plots = []
   plots += options['plotline_inject'] if options['plotline_inject']
  spectra.each_with_index do |spectrum, i|
    spectrum.write_tsv(plotdir + '/' + spectrum.name + '.tsv')
    plots.push "'#{plotdir}/#{spectrum.name}.tsv' with lines lt #{i+1}"
  end
  plotline = "plot " + plots.join(", \\\n")
  gplot = File.open plotdir + "/gplot", 'w'
  plot_headder = <<GPLOT_HEADER
  set terminal png size 800,600 lw 2
  set output '#{plotdir}/spect_plot.png'
  set xlabel '#{x_units[0]}'
  set ylabel 'intensity (cts)'
GPLOT_HEADER
  gplot.puts plot_headder
  gplot.puts plotline
  plot_replot = <<GPLOT_replot
  set terminal svg mouse enhanced standalone size 800,600 lw 2
  set output '#{plotdir}/spect_plot.svg'
  replot
GPLOT_replot
  gplot.puts options['extra_setup'] if options['extra_setup']
  gplot.puts plot_replot
  gplot.close
  system("gnuplot #{plotdir}/gplot")
end

# Quick 'n dirty func. to convert plot coord. to piezo coord.
def coord_conv(pl_scan_orig, orig_dim, map_dimension, coord)
  return [coord[0].to_f/map_dimension[0]*orig_dim[0]+pl_scan_orig[0], coord[1].to_f/map_dimension[1]*orig_dim[1]+pl_scan_orig[1]]
end

# Data form: [x1 y1-1 y2-1] [x2 y1-2 y2-2 ...]
def quick_plot(data)
  Dir.mkdir 'output' unless Dir.exists? 'output'
  raise "Some entries in data are different in length" unless data.all? {|line| line.size == data[0].size}
  data_fname = "data_#{Time.now.strftime("%d%b%Y-%H%M%S")}"
  data_fout = File.open "output/#{data_fname}.tsv", 'w'
  data.each { |line| data_fout.puts line.join("\t")}
  data_fout.close

  plotlines = []
  data[0].each_with_index do |column, i|
    # Assume for now no headder line
    plotlines.push "u 1:($#{i+1}) t '#{i+1}'"
  end
      
  plot_line = "plot 'output/#{data_fname}.tsv'" + plotlines.join(", \\\n'' ")
  plot_headder = <<GPLOT_HEADER
  set terminal png size 800,600 lw 2
  set output 'output/#{data_fname}.png'
GPLOT_HEADER
  plot_replot = <<GPLOT_replot
  set terminal svg mouse enhanced standalone size 800,600 lw 2
  set output 'output/#{data_fname}.svg'
  replot
GPLOT_replot

  gplot_out = File.new "output/#{data_fname}.gplot", 'w'
  gplot_out.puts plot_headder
  gplot_out.puts plot_line
  gplot_out.puts plot_replot
  gplot_out.close
  `gnuplot 'output/#{data_fname}.gplot'`
  data_fname
end

def matrix_write(matrix, path)
  raise "Some entries in data are different in length" unless matrix.all? {|line| line.size == matrix[0].size}
  matrix_out = File.open path, 'w'
  matrix.each do |line|
    matrix_out.puts line.join "\t" 
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
    basis.push [x, height.to_f / (1+ (2.0 * (x - pos) / width)**2)]
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

# Gives the rotation matrix needed to rotate origin to a resulting point set, when acted on that point set
def rotator_solve(origin)
  (origin.transpose * origin).invert * origin.transpose
end

def rotator(angle)
  GSL::Matrix.alloc([Math.cos(angle), Math.sin(angle)], [-Math.sin(angle), Math.cos(angle)]).transpose
end

def row_diff(size)
  result = GSL::Matrix.I(size)
  (0..size-2).each {|j| result.swap_rows!(j, j+1) }
  result = GSL::Matrix.I(size) - result
  result
end

def center_of_mass(x)
# In form of:
# [[x1 y1]
# [x2 y2]]
# ...
  result = GSL::Vector.alloc(x.size2)
  x.each_row do |row|
    result = result + row
  end
  result / x.size1
end

def plot_alignments(alignments)
  raise "Input Alignments!" unless alignments.is_a? Array && alignments.all? {|a| a.is_a? Alignment}
  points_data = ""
  alignments.each do |alignment|
    points_data
  end
end