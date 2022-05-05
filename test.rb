require './lib.rb'
require 'gsl'
=begin
require 'benchmark'
puts "Starting time: #{Time.now}"
scan = Scan.new('18Apr-2566-5-scan/2566-5-survey-z0.csv', '2566-5-survey', 90, 90, 1)
puts "Starting to load: #{Time.now}"
scan.load

puts "Starting to exise and plot: #{Time.now}"
#Excise
spects = []
(5..20).each do |y|
  spects.push scan[63][y][0]
  spects.last.name = "68_#{y}_0"
end
plot_spectra(spects)
puts "Done at #{Time.now}"

scale = GSL::Vector.linspace(0,1,2048)
data = GSL::Sf::sin(2*GSL::M_PI*scale*10) + 0.5 * GSL::Sf::sin(2*GSL::M_PI*scale*20)
y = data.fft
scan = Scan.new('testdata/64-84.9-w15h15d5-45x45x3 10_36_52 microPL.csv', 'scan1', 45, 45, 3)
scan.load
=end


plotlines = []
# Across a linescan, skipping last pixel
[0, 7, 12, 15, 29].each_with_index do |x, i|
  spect = Spectrum.new("output/#{x}-spect.tsv")
  plotlines.push "'output/#{x}-spect.tsv' with lines t 'spect #{x}' lt #{i % 8 +1}"

  #ft = GSL::Vector.alloc(scan[x][23][0].map{|pt| pt[1]}).fft # 究極一行文
  ft = GSL::Vector.alloc(spect.map{|pt| pt[1]}).fft # 究極一行文
  fout = File.new "output/#{x}-ft.tsv", 'w'
  ft = (ft * ft).normalize # Be positive
  ft.each_index do |i|
    fout.puts "#{i}\t#{ft[i]}"
  end
  plotlines.push "'output/#{x}-ft.tsv' with lines t 'ft #{x}' axes x2y2 lt #{i % 8 + 1}"
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
set y2tics
set x2tics
set x2range [2:50]
GPLOT
gplot_out = File.open 'output/fft.gplot', 'w'
gplot_out.puts ft_plot_directive
gplot_out.puts plotline
gplot_out.close
system 'gnuplot output/fft.gplot'