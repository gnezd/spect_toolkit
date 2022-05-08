require './lib.rb'
require 'gsl'

def loading_test()
  require 'benchmark'
  puts "Starting time: #{Time.now}"
  scan = Scan.new('testdata/csv', 'testdata', 45, 45, 3)
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
  ft[9..19].sum
}
plot_map scan, fft1
scan.name = 'Test_simple_sum'
plot_map scan
end

def fitting_test
  spect = Spectrum.new 'output/10-spect.tsv'
  puts spect.size

  lineshape = Proc.new{|pos, width, height, x|
    Math.exp(-((x - pos) / width)**2) * height
  }
  #puts lineshape[0,1,1,1]
  bases = []
  position_scan_density = 20
  width_scan_density = 50

  # 十分的疊床架屋
  (0..position_scan_density).each do |position|
    pos_column = Array.new()
    (0..width_scan_density).each do |j|
      basis = Spectrum.new
      spect.each do |pt|
        pos = spect.size.to_f * position / (position_scan_density + 1)
        width = spect.size.to_f / (width_scan_density + 1) * j
        height = pt[1]
        basis.push [pt[0], lineshape[pos, width, height, pt[0]]]
      end
      pos_column.push basis
    end
    puts pos_column.class
    puts pos_column.size
    bases.push pos_column
  end

  puts bases.class
  puts bases[0].class
  puts bases[0][0].class
  puts bases[0][0].size
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

#resampling_test
#inner_pdct_test
fitting_test