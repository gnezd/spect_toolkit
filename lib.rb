# Script for the processing of micro-PL scann data
# Objective: iterate through lines, assign some sort of sum(s) to frame and output as:
# frame# sum1 sum2 ...

# Todo: classes raw, spect, and....?
# Sum up frame and create pixel value. scan should be array fornow
# format: [path, scan_name, width, height]
# Todo: accecpt code block for summing. Tricky: injection to whole loop
# In general, mode extraction can be representated as a matrix acting on a spectrum but this requires spectrum spectrum constructing and lacks the freedom of passing blocks and conditions
# An even more general way of doing things is to pass into sum_up() a list of criteria on the wavelengths
def sum_up(scan)
  (path, scan_name, width, height, depth) = scan
  raise "wrong number of arguments" unless scan.size == 5
  fin = File.open path, 'r'
  lines = fin.readlines
  fin.close
  
  # Detection of seperator , or tab
  raiese "No seperator found in line 0." unless match = lines[0].match(/[\t,]/)
  seperator = match[0]

  # Extract units from headderline
  if lines[0] =~ /^Frame\t/
    headder_line = lines.shift
    (unit_x, unit_y) = headder_line.split(seperator)[1..2]
  end

  raise "Number of lines is #{lines.size}, not multiplication of width(#{width}) * height(#{height}) * depth(#{depth})!" unless lines.size % (width * height * depth) == 0

  puts "Processing summation of '#{scan_name}' from '#{path}'"
  puts "Got #{lines.size} lines of spectrum to sum up."


  sum = Array.new(width * height * depth) {0.0}
  (0..lines.size-1).each do |ln|
    (frame, wv, intensity) = lines[ln].split seperator
    frame = frame.to_i - 1 # Matter of convention. I count up from 0.
    wv = wv.to_f
    intensity = intensity.to_f

    # Summing, the easiest version
    raise "at frame #{frame} / #{lines[ln].split "\t"}" unless sum[frame]
    sum[frame] += intensity # Full sum
  end

  filenames = []
  (0..depth-1).each do |z| # Each depth one graph
    puts "outputing z = #{z}."
    fout = File.open scan_name + "_#{z}.tsv", 'w'
    (0..height-1).each do |row|
      fout.puts sum[row * width + z * width * height .. (row + 1) * width + z * width * height - 1].join "\t"
    end
    filenames.push scan_name + "_#{z}"
    fout.close
  end
  filenames
end

def plot_map(scan_name, width, height)
  gplot = File.open 'gplot.temp', 'w'
gplot_content =<<GPLOT_HEAD
set terminal svg size #{width * 5},#{height * 5} mouse enhanced standalone
set output '#{scan_name}.svg'
set border 0
unset key
unset xtics
unset ytics
set xrange[-0.5:#{width}-0.5]
set yrange[-0.5:#{height}-0.5]
set title '#{scan_name.sub('_','\_')}'
unset colorbox
set palette cubehelix negative
plot '#{scan_name}.tsv' matrix with image pixels
set terminal png size #{width * 5},#{height * 5}
set output '#{scan_name}.png'
replot
GPLOT_HEAD
  gplot.puts gplot_content
  gplot.close
  puts "Plotting #{scan_name}, W: #{width}, H: #{height}"
  `gnuplot gplot.temp`
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


class Scan < Array
  # Assume all wavelength scales allign across all pixels
  attr_accessor :frames, :wv, :path
  def initialize (path, name, width, height, depth)
    @path = path
    @name = name
    @width = width
    @height = height
    @depth = depth
    @loaded = false
    @spectral_width = 0
    super Array.new(width) {Array.new(height) {Array.new(depth) {Spectrum.new()}}}
  end

  def load
    fin = File.open @path, 'r'
    puts "Reading #{@path}..."
    lines = fin.readlines
    lines.shift if lines[0] =~ /^Frame[\t,]/
    raise "Number of lines is #{lines.size}, not multiplication of width * height * depth!" unless lines.size % (@width * @height * @depth) == 0
    @spectral_width = lines.size / (@width * @height * @depth)
    puts "Got #{lines.size} lines of spectrum to process."

    # Detection of seperator , or tab
    raiese "No seperator found in line 0." unless match = lines[0].match(/[\t,]/)
    seperator = match[0]

    lines.each do |line|
      (frame, wv, intensity) = line.split seperator
      frame = frame.to_i - 1 # Matter of convention. I count up from 0.
      wv = wv.to_f
      intensity = intensity.to_f
      k = frame / (@width * @height)
      j = (frame % (@width * @height)) / @width
      i = (frame % (@width * @height)) % @width
      self[i][j][k].push [wv, intensity]
    end
    @loaded = true
    puts "done"
  end

  def extract_spect(points)
    raise "Not a series of points input." unless (points.is_a? Array) && (points.all? {|item| item.size == 3})
    result = []
    points.each do |pt|
      result.push self[pt[0]][pt[1]][pt[2]]
      result.last.name = pt.join '-'
    end
    result
  end

end

class Spectrum < Array
  attr_accessor :name, :units, :spectral_range, :signal_range, :desc
  def initialize(path=nil)
    @name = ""
    super Array.new() {[0.0, 0.0]}
    # Load from tsv/csv if path given
    if path && (File.exist? path)
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
end

def plot_spectra(spectra)
  raise "Not an array of spectra input." unless (spectra.is_a? Array) && (spectra.all? Spectrum)
  plotdir = "plot-" + Time.now.strftime("%d%b-%H%M%s")
  Dir.mkdir plotdir
  plots = []
  spectra.each do |spectrum|
    spectrum.write_tsv(plotdir + '/' + spectrum.name + '.tsv')
    plots.push "'#{plotdir}/#{spectrum.name}.tsv' with lines"
  end
  plotline = "plot " + plots.join(", \\\n")
  gplot = File.open plotdir + "/gplot", 'w'
  plot_headder = <<GPLOT_HEADER
  set terminal png size 800,600 lw 2
  set output '#{plotdir}/spect_plot.png'
  set xlabel 'wavelength (nm)'
  set ylabel 'intensity (cts)'
GPLOT_HEADER
  gplot.puts plot_headder
  gplot.puts plotline
  plot_replot = <<GPLOT_replot
  set terminal svg mouse enhanced standalone size 800,600 lw 2
  set output '#{plotdir}/spect_plot.svg'
  replot
GPLOT_replot
  gplot.puts plot_replot
  gplot.close
  system("gnuplot #{plotdir}/gplot")
end

# Quick 'n dirty func. to convert plot coord. to piezo coord.
def coord_conv(pl_scan_orig, orig_dim, map_dimension, coord)
  return [coord[0].to_f/map_dimension[0]*orig_dim[0]+pl_scan_orig[0], coord[1].to_f/map_dimension[1]*orig_dim[1]+pl_scan_orig[1]]
end