class Scan < Array
  # Assume all wavelength scales allign across all pixels
  attr_accessor :frames, :wv, :spectrum_units, :path, :name, :width, :height, :depth, :p_width, :p_height, :p_depth, :loaded, :spe, :s_scan, :bin_to_spect, :aspect_ratio, :map_data

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
    puts "#{name} to be loaded from #{path}" if path
  end


  def load(options = {})
    options[:bin_to_spect] = @bin_to_spect
    puts options
    case File.extname @path
    when /\.[cC][sS][vV]/
      load_csv options
    when /\.[sS][pP][eE]/
      load_spe options
    when /\.[sS][iI][fF]/
      load_sif options
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
          pixel.meta[:units] = @meta[:spectrum_units]
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

  def load_sif(options)
    # File read
    debug = options[:debug]
    # BIN to spectrum here
    options[:bin_to_spect] = true unless options[:bin_to_spect]

    puts "loading sif #{@path} with options #{options}."
    puts "Reading sif at #{Time.now}" if debug

    @sif = SIF.new @path, @name, options
    puts "Sif reading complete at #{Time.now}. Start scan building." if debug

    # Scan building
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
          self[relabel_i][j][k] = (0..@sif.meta[:rois].size - 1).map do |roin|
            @sif.at(k * (@width * @height) + j * @width + i, roin)
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
    @spectrum_units = @sif.meta[:spectrum_units]
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
      spect.meta[:name] = "#{@name}-#{x}-#{y}-#{z}"
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
      z = i / (@width * @height)
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
        set terminal svg size #{@width * scale * @depth},#{@height * scale} mouse enhanced standalone #{dark_bg ? 'background "black"' : ''}
        set output '#{plot_output}'
        set title '#{@name.gsub('_', '\_')}' #{dark_bg ? "tc 'white'" : ''}
        #{dark_bg ? "set border lc 'white'" : ''}
        unset xtics
        unset ytics
      GP_TERM
    when 'png'
      plot_output = "#{outdir}/#{@name}.png"
      gplot_terminal = <<~GP_TERM
        set terminal png size #{@width * scale * @depth},#{@height * scale} #{dark_bg ? 'background "black"' : ''}
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
      if self[0][0][0][0].is_a? Spectrum
        units = self[0][0][0][0].meta[:units]
        spect = (bin.map { |pt| self[pt[0]][pt[1]][z][roi] }).reduce(:+) / bin.size
      elsif self[0][0][0].is_a? Spectrum
        units = self[0][0][0].meta[:units]
        spect = (bin.map { |pt| self[pt[0]][pt[1]][z] }).reduce(:+) / bin.size
      else
        raise "?? where is the Spectrum"
      end
      spect.meta[:units] = units
      binned.push spect
    end

    binned
  end
end