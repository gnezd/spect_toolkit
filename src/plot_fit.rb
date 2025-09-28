# For data plotting, fitting and storing

# For ADPL experiments handling
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
    @spects.meta[:rois].each_with_index do |roi, roin|
      data_export = Array.new(@spects.meta[:frames]) { Array.new(@spects.meta[:rois][roin][:data_width]) { 0 } }
      frame = 0
      while frame < @spects.meta[:frames]
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

# gnuplot TkCanvas for plotting
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
  attr_accessor :cache, :name, :meta, :wv, :data

  def initialize(cache, name, options = {}) # optional data input determins init mode
    @cache = cache
    raise "Not a Memcached client!" unless @cache.is_a? Memcached::Client
    @name = name
    @meta = options[:meta]
    @data = options[:data]
    @wv = options[:wv]
    if @data # Only case that warrants a write at init would be data-containing new()
      puts "Data input at init, writing cache"
      write_cache
    end
    self 
  end

  def read_cache
    @meta = JSON.parse(@cache.get("spect_meta_" + @name)).transform_keys {|k| k.to_sym}
    if @meta[:wv_ref]
      @wv = @cache.get("spect_wv_#{meta[:wv_ref]}").unpack("#{meta[:wv_type]}*")
    else
      @wv = @cache.get("spect_wv_#{@name}").unpack("#{meta[:wv_type]}*")
    end
    @data = @cache.get("spect_#{@name}").unpack("#{meta[:type]}*")
    true
  end

  def write_cache
    # Determine datafield type. Save space and time on integers! Default to double.
    type = @meta[:type] ? @meta[:type] : 'D'
    wvtype = @meta[:wv_type] ? @meta[:wv_type] : 'D'
    @cache.set "spect_" + @name, @data.pack("#{type}*")
    @cache.set "spect_meta_" + @name, @meta.to_json

    # See if wv needs to be set
    # Assume wavelength type to always be double
    if @meta[:wv_ref] == nil
      @cache.set "spect_wv_"+ @name, wv.pack("#{wvtype}*")
    end
    true
  end

  def to_spectrum
    read_cache
    spect = Spectrum.new
    spect.meta = @meta
    spect.wv = @wv if @wv.size > 0
    spect.signal = @data
    spect.cache_host = @cache

    spect
  end

end

# Sparse methods below

# Plot the spectra in an array
# Options: debug(true/false), out_dir(str), plotline_inject(str), linestyle(array of str), plot_term(str), plot_width(int), plot_height(int), plot_style(str), raman_line(str)
def plot_spectra(spectra, options = {})
  debug = options[:debug]
  raise 'Not an array of spectra input.' unless (spectra.is_a? Array) && (spectra.all? Spectrum)

  # Check if they align in x_units
  x_units = spectra.map { |spectrum| spectrum.meta[:units][0] }
  raise "Some spectra have different units: #{x_units}" unless x_units.all? { |unit| unit == x_units[0] }

  # Prepare output path
  outdir = options[:out_dir] || 'plot-' + Time.now.strftime('%d%b-%H%M%S')
  puts "Ploting to #{outdir}" if debug
  FileUtils.mkdir_p outdir unless Dir.exist? outdir

  # Prepare plots
  plots = []
  spectra.each_with_index do |spectrum, i|
    spectrum.write_tsv(outdir + '/' + spectrum.meta[:name] + '.tsv')
    linestyle = "lines lt #{i + 1}"
    linestyle = options[:linestyle][i] if options[:linestyle] && options[:linestyle][i]
    # Ugly fix
    # Should actually be filtering if enhanced is used
    # reversing raman plot here aswell

    # Take care of Raman plots here
    # Should this be done only once instead of to each spectrum?
    coord_ref = '($1):($2)'
    if options[:raman_line]
      raman_line_match = options[:raman_line].to_s.match(/^(\d+\.?\d*)\s?(nm|cm-1|wavenumber|eV)?$/)
      raman_line = raman_line_match[1].to_f

      unit =  raman_line_match[2] ? raman_line_match[2] : spectrum.meta[:units][0]
      puts "unit: #{unit}"

      # Unit conversion if necessary: All be nanometers
      case unit
      when 'nm'
        # Do nothing
      when 'wavenumber', 'cm-1'
        raman_line = 0.01 / raman_line * 1E9
      when 'eV'
        raman_line = 1239.84197 / raman_line
      else
        raise "spectral unit unexpected: #{raman_line_match[2]}"
      end

      case spectrum.meta[:units][0] # What am I doing?? (08 Aug 2024)
        # Oh no this needs cross conversion...
      when 'nm'
      when 'eV'
      when 'wavenumber', 'cm-1'
        puts "Raman line: #{raman_line}"
        coord_ref = "(#{raman_line}-$1):($2)"
      end

    end

    if linestyle == 'labels'
      coord_ref += ':($1)'
    end

    # tkcanvas doesn't support enhanced text just yet
    title = if options[:plot_term] == 'tkcanvas-rb'
              spectrum.meta[:name]
            # plots.push "'#{outdir}/#{spectrum.name}.tsv' u ($1):($2) with lines #{linestyle} t '#{spectrum.name}'"
            else
              spectrum.meta[:name].gsub('_', '\_')
            end
    plots.push "'#{outdir}/#{spectrum.meta[:name]}.tsv' u #{coord_ref} with #{linestyle} t '#{title}'"
  end
  plots += options[:plotline_inject] if options[:plotline_inject]
  plotline = 'plot ' + plots.join(", \\\n")

  # Terminal dependent preparations
  options[:plot_width] = 800 unless options[:plot_width].is_a? Numeric
  options[:plot_height] = 600 unless options[:plot_height].is_a? Numeric
  case options&.[](:plot_term)
  when nil, 'svg' # Means not indicated or svg
    plot_output = "#{outdir}/spect-plot.svg"
    gplot_terminal = <<~GP_TERM
      set terminal svg size #{options[:plot_width]},#{options[:plot_height]} enhanced mouse standalone
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
  x_units = spectra.map { |spectrum| spectrum.meta[:units][0] }
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
      elsif (pt[0] / 1000).to_i != (spectra[0][x + 1][0] / 1000).to_i # Every 1000 cm-1
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
  basis.wv = sample
  basis.signal = sample.map {|x| Math.exp(-(((x - pos).to_f / width)**2)) * height}
  basis.name = "#{pos}-#{width}-#{height}"
  basis
end

def lorentzian(sample, pos, width, height)
  basis = Spectrum.new
  basis.wv = sample
  basis.signal = sample.map {|x| height.to_f / (1 + (2.0 * (x - pos) / width)**2)}
  basis.name = "lorenzian-#{pos}-#{width}-#{height}"
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