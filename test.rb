require './lib.rb'
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