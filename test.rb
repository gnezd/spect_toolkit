require './lib.rb'
require 'gsl'

def loading_test()
  require 'benchmark'
  puts "Starting time: #{Time.now}"
  scan = Scan.new('testdata/csv.csv', 'testdata', [45, 45, 3])
  puts "Starting to load: #{Time.now}"
  scan.load

  puts "Starting to exise and plot: #{Time.now}"
  #Excise
  spects = []
  (5..20).each do |y|
    spects.push scan[24][y][0]
    spects.last.name = "24_#{y}_0"
  end
  plot_spectra(spects)
  puts "Done at #{Time.now}"
end

def ft_test
  scale = GSL::Vector.linspace(0,1,2048)
  data = GSL::Sf::sin(2*GSL::M_PI*scale*10) + 0.5 * GSL::Sf::sin(2*GSL::M_PI*scale*20)
  y = data.fft
  scan = Scan.new('testdata/64-84.9-w15h15d5-45x45x3 10_36_52 microPL.csv', 'scan1', 45, 45, 3)
  scan.load
  (0..44).each do |x|
    scan[x][23][0].write_tsv "output/#{x}-spect.tsv"
  end

  plotlines = []
  # Across a linescan, skipping last pixel
  (0..44).each_with_index do |x, i|
    next unless i % 5 == 0
    spect = Spectrum.new("output/#{x}-spect.tsv")
    plotlines.push "'output/#{x}-spect.tsv' with lines t 'spect #{x}' lt #{i % 8 +1}"

    #ft = GSL::Vector.alloc(scan[x][23][0].map{|pt| pt[1]}).fft # 究極一行文
    ft = GSL::Vector.alloc(spect.map{|pt| pt[1]}).fft # 究極一行文
    fout = File.new "output/#{x}-ft.tsv", 'w'
    ft = ft.to_complex2.abs # Be positive
    ft.each_index do |i|
      fout.puts "#{i}\t#{ft[i]}"
    end
    plotlines.push "'output/#{x}-ft.tsv' u 1:($2) with lines t 'ft #{x}' axes x2y2 lt #{i % 8 + 1}"
    fout.close

  end
  plotline = "plot " + plotlines.join(", \\\n")

  ft_plot_directive = <<GPLOT
set terminal svg size 800,600 mouse enhanced standalone
set linetype 1 lc rgb "black"
set linetype 2 lc rgb "dark-red"
set linetype 3 lc rgb "olive"
set linetype 4 lc rgb "navy"
set linetype 5 lc rgb "red"
set linetype 6 lc rgb "dark-turquoise"
set linetype 7 lc rgb "dark-blue"
set linetype 8 lc rgb "dark-violet"
set linetype cycle 8
set output 'output/ft.svg'
set title 'FT'
set ylabel 'Spectrum counts'
set y2label 'Normalized FFT intensity'
set y2tics
set x2tics
set yrange [0:*]
#set y2range [0:*]
set x2range [1:50]
GPLOT
  gplot_out = File.open 'output/fft.gplot', 'w'
  gplot_out.puts ft_plot_directive
  gplot_out.puts plotline
  gplot_out.close
  system 'gnuplot output/fft.gplot'

end

def test_fft_map
scan = Scan.new './testdata/csv', 'Test_fft_10_20_sum', 45, 45, 3
scan.load
fft1 = Proc.new{|spect| 
  ft = GSL::Vector.alloc(spect.map{|pt| pt[1]}).fft # 究極一行文
  ft = ft.to_complex2.abs # Be positive
}
  ft[9..19].sum
plot_map scan, fft1
scan.name = 'Test_simple_sum'
plot_map scan
end


def resampling_test
  spect1 = Spectrum.new 'testdata/spectra/24_11_0.tsv'
  spect2 = spect1.ma(2)
  puts spect1.size
  puts spect2.size
  # Show difference in x values
  (0..5).each do |i|
    puts "#{spect1[i].join('-')}"
  end
  puts '-----'
  pick = [27431.83, 27431.93, 27432.03, 27400]
  (0..20).each {|i| pick.push(27400 - 70*i)}
  resmpl = spect1.resample(pick)
  puts resmpl.size
  puts resmpl.spectral_range
  orig_x = spect1.map {|pt| pt[0]}
  puts spect1[0..4]
  puts "-----"
  puts spect1.resample(orig_x)[0..4]
  puts "Resampling test complete."
end

def inner_pdct_test
  puts "Inner product tests:"
  spect1 = Spectrum.new 'testdata/spectra/24_11_0.tsv'
  spect2 = spect1.ma(10)
  ipd = spect1 * spect2
  puts "Test: S1*S1, S1*ma10(S1), ma10(S1)*ma10(S1)"
  puts spect1 * spect1
  puts spect1 * spect2
  puts spect2 * spect2
  puts "Test: sin * sin, cos*cos"
  sin = Spectrum.new()
  cos = Spectrum.new()
  (0..9999).each {|i| sin[i] = [i.to_f / 10, Math.sin(i.to_f/10)]}
  (0..9999).each {|i| cos[i] = [i.to_f / 10, Math.cos(i.to_f/10)]}
  puts "Sin*Sin: #{sin * sin}"
  puts "Cos*Cos: #{cos * cos}"
  puts "Cos*Sin: #{sin * cos}, #{cos * sin}"
end

def subtraction_test
  spect = Spectrum.new 'testdata/spectra/24_11_0.tsv'
  puts "spect * spect: #{spect * spect}"
  spect2 = spect-spect
  puts "(spect - spect)^2: #{spect2 * spect2}"
end
#resampling_test
#inner_pdct_test
#fitting_test

#subtraction_test

def quick_plot_test
  data = []
  (0..10).each do |ln|
    data.push (0..3).map {|i| rand(i)}
  end

  puts quick_plot(data)
end

def fitting_test
  spect = Spectrum.new 'output/10-spect.tsv'
  spect = spect.uniform_resample(2000)
  spect.each {|pt| pt[1] -= 600}
    #Math.exp(-((x - pos) / width)**2 / 2) / (width * 2**0.5 * Math::PI)
  lineshape = Proc.new{|pos, width, x|
    Math.exp(-(((x - pos) / width)**2))
  }
  
  # Generation of bases matrix
  bases = []
  position_scan_density = 20
  width_scan_density = 20
  spectral_width = spect.spectral_range[1] - spect.spectral_range[0]
  puts "spectral width: #{spectral_width}"
  # 十分的疊床架屋
  (0..position_scan_density - 1).each do |i|
    pos_column = Array.new()
    (0..width_scan_density - 1).each do |j|
      basis = Spectrum.new
      pos = spect.spectral_range[0] + spectral_width * (i + 0.5) / (position_scan_density)
      height = spect.resample([pos])[0][1]
      width = spectral_width / (j + 2)
      basis.name = "#{pos}-#{width}-#{height}"
      spect.each do |pt|
        basis.push [pt[0], lineshape[pos, width, pt[0]] * height]
      end
      pos_column.push basis
    end
    bases.push pos_column
  end

  puts "bases generated: a 2d array of width #{bases.size} and height #{bases[0].size}"

  # Take a look at some bases
  sample = spect.map {|pt| pt[0]}
  a = gaussian(sample, 19000, 2650, 495)
  b = gaussian(sample, 24700, 1400, 1900)
  to_plot = [spect, a, b, spect - a - b, spect2]
  #to_plot = [spect, ]
  
  #to_plot.each {|basis| puts "Norm of #{basis.name}: #{basis * basis}"}
  #to_plot = [bases[19][19], bases[18][19]]
  #5.times {to_plot.push(bases[rand(bases.size-1)][rand(bases[0].size-1)])}
  #plot_spectra to_plot, {'outdir' =>'./bases_preview', 'plotline_inject' => ["'output/10-spect.tsv' w lines"], 'extra_setup' => ["set y2tics"]}
  plot_spectra to_plot, {'outdir' =>'./bases_preview'}

  # Start plotting some values such as inner product or substraction residual bla bla
  inner_pdct_matrix = Array.new(bases.size) {Array.new(bases[0].size) {0.0}}
  substr_matrix = Array.new(bases.size) {Array.new(bases[0].size) {0.0}}
  (0..bases.size - 1).each do |i|
    (0..bases[0].size - 1).each do |j|
      inner_pdct_matrix[i][j] = (spect * bases[i][j])
      diff = spect - bases[i][j]
      substr_matrix[i][j] = diff * diff
    end
  end

  matrix_write(inner_pdct_matrix, "output/inner_pdct.dat")
  matrix_write(substr_matrix, "output/substr.dat")



  plot_command = <<GPLOT_HEADER
  set terminal svg size 800,1600 lw 2 mouse enhanced standalone
  set output 'output/inner_pdct.svg'
  set size 1.0, 1.0
  set origin 0.0, 0.0
  set multiplot
  set size 1, 0.5
  set origin 0.0, 0.5
  set xrange [-0.5:*]
  set yrange [-0.5:*]
  set title 'Inner product'
  plot 'output/inner_pdct.dat' matrix w image pixels
  set size 1, 0.5
  set origin 0.0, 0.0
  set title 'Diff'
  plot 'output/substr.dat' matrix w image pixels
GPLOT_HEADER
  gplot_temp = File.new 'output/inner_pdct.gplot', 'w'
  gplot_temp.puts plot_command
  gplot_temp.close
  `gnuplot output/inner_pdct.gplot`
  spect.write_tsv 'bg_corrected.tsv'
end

def only_fit_and_fft
  spect = Spectrum.new 'output/10-spect.tsv'
  spect = spect.uniform_resample(2000)
  spect2 = Spectrum.new('fft_contest/24_11_0.tsv').uniform_resample(2000)
  spect2 = spect2.uniform_resample(2000)
  spect.each {|pt| pt[1] -= 630}
  sample = spect.map {|pt| pt[0]}
  a = gaussian(sample, 19300, 2650, 475)
  b = gaussian(sample, 24800, 1200, 1900)
  substracted = spect - a - b
  substracted.name = 'substracted'
  to_plot = [spect, a, b, substracted, spect2]


  fts = []
  ft_plots = []
  to_plot.each_with_index do |sp, spi|
    ft = GSL::Vector.alloc(sp.map{|pt| pt[1]}).fft
    ft = ft[0..199] #cutoff ^.<
    ft = ft.to_complex2.abs
    fts.push ft

    ftout = File.new "fft_contest/#{sp.name}-ft.tsv" , 'w'
    ft.each_index do |i|
        ftout.puts "#{i}\t#{ft[i]}"
    end
    ftout.close
    ft_plots.push "'fft_contest/#{sp.name}-ft.tsv' u 1:($2) with lines t '#{sp.name}-ft' axes x2y2 lt #{spi+1}"
  end
  ft_plots.reverse!
  plot_spectra to_plot, {'outdir' => './bases_preview', 'plotline_inject' => ft_plots, 'extra_setup' => ['set y2tics', 'set x2tics', 'set x2range [3:*]']}
end

def rule_based_fitting
  spect = Spectrum.new('output/10-spect.tsv').uniform_resample(2000)
  sample = spect.map{|pt| pt[0]}
  ma = spect.ma(5)
  maxes = ma.local_max(100)
  maxes.pop(13)
  puts maxes.size
  maxes_out = File.open './r_b_fitting/maxes.tsv', 'w'
  maxes.each do |pt|
    maxes_out.puts pt.join "\t"
  end
  maxes_out.close
  peaks = []
  maxes.each do |pt|
    peaks.push lorentzian(sample, pt[0], 100, pt[1]-620)
  end 
  #puts maxes.size
  fitted = peaks.reduce :+
  to_plot = [spect, ma, fitted]
  fitted.name = 'fitted'
  fitted_ft = GSL::Vector.alloc(fitted.map{|pt| pt[1]}).fft
  fitted_ft = fitted_ft[0..199]
  fitted_ft = fitted_ft.to_complex2.abs

  ftout = File.open 'r_b_fitting/fitted_ft.tsv', 'w'
  fitted_ft.each_index do |i|
    ftout.puts "#{i}\t#{fitted_ft[i]}"
  end
  ftout.close

  plot_spectra to_plot, {'outdir' => './r_b_fitting', 'plotline_inject' => ["'./r_b_fitting/maxes.tsv' w points t 'peaks'", "'r_b_fitting/fitted_ft.tsv' w lines axes x2y2"]}
end

def the_ft_myth

end

def lorentzian_test
  sample = (0..999).map {|x| x.to_f / 10}
  a = lorentzian(sample, 50, 30, 20)
  b = gaussian(sample, 50, 30, 20)
  plot_spectra [a, b]
end

#rule_based_fitting

def read_spe
  fin = File.open 'testdata/spe'
  raw = fin.read.freeze
  fin.close
  puts "raw size: #{raw.size}"
  xml_index = raw[678..685].unpack1('Q')
  puts "xmlstart: #{xml_index}"

  binary_data = raw[0x1004..xml_index-1]
  xml = Nokogiri.XML(raw[xml_index..-1]).remove_namespaces!
  
  # ROI on CCD determines starting wavelength
  x0 = xml.xpath('//Calibrations/SensorMapping').attr('x').value.to_i
  w = xml.xpath('//Calibrations/SensorMapping').attr('width').value.to_i
  frames = xml.xpath('//DataFormat/DataBlock').attr('count').value.to_i
  wavelengths_nm = xml.xpath('//Calibrations/WavelengthMapping/Wavelength').text.split(',')[x0, w].map {|x| x.to_f}
  wavenumbers = wavelengths_nm.map {|nm| 10000000.0 / nm}

  width = 200
  height = 200

  unpacked_counts = binary_data.unpack('S*')
  raise "0_o unpacked ints has a length of #{unpacked_counts.size}" unless unpacked_counts.size == width * height * w

  random_matrix = Array.new(width) {Array.new(height) {0}}
  (0..width - 1).each do |i|
    #puts "procissing line #{i}"
    (0..height - 1).each do |j|
      sum = unpacked_counts[(j * width + i) * w .. (j * width + i + 1) * w -1].sum
      if j % 2 == 0
        random_matrix[i][j] = unpacked_counts[(j * width + i) * w .. (j * width + i + 1) * w -1].sum
      else
        random_matrix[width - i - 1][j] = unpacked_counts[(j * width + i) * w .. (j * width + i + 1) * w -1].sum
      end

    end
    #random_matrix[i].shift(22)
  end
  matrix_write(random_matrix, 'random.tsv')
  matrix_write(random_matrix.transpose, 'randomt.tsv')

end

def load_spe
  scan = Scan.new 'testdata/2566-3-smparea1-100x100from0-0-w-200x200x1 16_07_22 microPL.spe', '2566-3-survey', [200, 200, 1]
  scan.load({'s_scan' => true})
  plot_map(scan)
end

def test_read_drop
  fin = File.open '/mnt/h/Dropbox/RCAS/Workspace/Q2/14-May/2566-3-smparea1-survey2-noS 02_09_32 microPL.spe', 'rb'
  raw = fin.read
  puts "raw size should be 107165401, found: #{raw.size}"
  fin.close
  xml_index = raw[678..685].unpack1('Q')
  binary_data = raw[0x1004..xml_index-1]
  unpacked_counts = binary_data.unpack('S*')
  puts "xml_index: #{xml_index}, diff with filesize = #{raw.size - xml_index}"
  xml = Nokogiri.XML(raw[xml_index..-1]).remove_namespaces!
  x0 = xml.xpath('//Calibrations/SensorMapping').attr('x').value.to_i
  puts x0
  # Couldn't reproduce the unexpected cutoff QQ
end

def test_la
  # 少時不讀書
  x_0 = GSL::Matrix.alloc([1000, 500], [2000,500], [2000,4500], [1000,4500])
  angle = 2 * Math::PI * 30 / 360
  rotator = GSL::Matrix.alloc([Math.cos(angle), Math.sin(angle)], [-Math.sin(angle), Math.cos(angle)]).transpose
  rotated = x_0 * rotator
  #puts "Rotator:"
  #puts rotator

  # Check rotation with some inner products
  diff_2_0 = rotated.row(2) - rotated.row(0)
  diff_1_3 = rotated.row(1) - rotated.row(3)
#  puts "Pre-rotation (2-0) . (1-3)"
#  puts diff_2_0 * diff_1_3.transpose
  
  diff_2_0 = x_0.row(2) - x_0.row(0)
  diff_1_3 = x_0.row(1) - x_0.row(3)
#  puts "Post-rotation (2-0) . (1-3)"
#  puts diff_2_0 * diff_1_3.transpose

  reconstructed_r = (x_0.transpose * x_0).invert * (x_0.transpose * rotated)
#  puts "Reconstructed rotator"
 # puts reconstructed_r

  randomized = rotated.clone
  randomized.map! {|e| e+=(100-rand(200))/1000}
#  puts "Random blurring:"
 # puts randomized
  #puts "Reconstruct it:"
  #puts (x_0.transpose * x_0).invert * (x_0.transpose * randomized)

  gplot_out = File.new 'output/sample_alignment_plot.gplot', 'w'
  gplot_out.puts '$original<<ORIG'
  x_0.each_row do |row|
    gplot_out.puts row.to_a.join "\t"
  end
  gplot_out.puts x_0.row(0).to_a.join "\t"
  gplot_out.puts 'ORIG'

  gplot_out.puts '$rotated<<ROT'
  randomized.each_row do |row|
    gplot_out.puts row.to_a.join "\t"
  end
  gplot_out.puts randomized.row(0).to_a.join "\t"
  gplot_out.puts 'ROT'

  gplot_end = <<EOGPL
set terminal svg
set output 'output/sample_alignment.svg'
set size ratio 1
set xrange [0:60]
set yrange [-10:50]
plot $original w lines title 'original', $rotated w lines title 'rotated'
EOGPL
  gplot_out.puts gplot_end
  gplot_out.close
  `gnuplot output/sample_alignment_plot.gplot`

  puts "----------"
  puts "x_0:\n#{x_0}"
  puts "has C. o. M.:"
  puts center_of_mass(x_0)
  displacement = GSL::Vector.alloc([4, 30])
  angle = 50.0 / 360 * 2 * Math::PI
  puts "Now with rotation of #{angle}°` and displacement: #{displacement}"
  displaced = rot_dis(x_0, angle, displacement)
  puts "Displaced: \n#{displaced}"
  puts "has C. o. M.: #{center_of_mass(displaced)}"
  puts "Difference: #{center_of_mass(displaced) - center_of_mass(x_0)}, certainly not the same as #{displacement} 因受旋轉迫害"
  # Solution: rotate back edges rather than vertices
  edging = GSL::Matrix.I(displaced.size1)
  (0..edging.size1-2).each {|j| edging.swap_rows!(j, j+1) }
  edging = GSL::Matrix.I(displaced.size1) - edging
  displaced_edge = edging * displaced
  puts "edging matrix: \n #{edging}"
  puts "edges: \n#{displaced_edge}"
  x_0_edge = edging * x_0
  puts "x_0.edge: \n#{x_0_edge}"
  edge_rotator = rotator_solve(x_0_edge) * displaced_edge
  puts "edge_rotator: \n #{edge_rotator}"
  puts "50° rotator: \n#{rotator(50.0/360*2*Math::PI)}"
  puts "-----All together now-----"
  puts "First perform rotation from x_0:"
  pre_shift = x_0 * edge_rotator
  puts pre_shift
  puts "Then find the move of C. o. M.:"
  puts (center_of_mass(displaced) - center_of_mass(pre_shift))

end

def rot_dis(input, angle, displacement)
  rotator = GSL::Matrix.alloc([Math.cos(angle), Math.sin(angle)], [-Math.sin(angle), Math.cos(angle)]).transpose
  result = input * rotator
  expanded_displacement = GSL::Matrix.alloc(input.size1, 2)
  (0..input.size1-1).each do |j|
    expanded_displacement.set_row(j, displacement)
  end

  #puts displacement
  #puts expanded_displacement
  result + expanded_displacement
end 

# Gives the rotation matrix needed to rotate origin to a resulting point set, when acted on that point set
def rotator_solve(origin)
  (origin.transpose * origin).invert * origin.transpose
end
def rotator(angle)
  GSL::Matrix.alloc([Math.cos(angle), Math.sin(angle)], [-Math.sin(angle), Math.cos(angle)]).transpose
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

test_la