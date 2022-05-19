require './lib.rb'
scan = Scan.new 'testdata/spe.spe', '2566-3-s_scan', [200, 200, 1]
#scan.load({:s_scan => true})
puts "Loading finished, plotting"
#plot_map scan

Dir.mkdir 'output/fighting_hysteresis' unless Dir.exist? 'output/fighting_hysteresis'
=begin
# Let's first play with intensity
fin = File.open 'output/fighting_hysteresis/2566-3-s_scan_0.tsv', 'r'
lines = fin.readlines
fin.close
matrix = lines.map {|line| (line.chomp.split("\t")).map {|e| e.to_i}}


# Summation of even and odd, then plot?
even = GSL::Vector.alloc(matrix[0].size)
odd = GSL::Vector.alloc(matrix[0].size)

(0..lines.size-1).each do |j|
  if j % 2 == 0
    even = even + GSL::Vector.alloc(matrix[j])
  else
    odd = odd + GSL::Vector.alloc(matrix[j])
  end
end

puts even.size
puts odd.size

arr = [even.to_a, odd.to_a].transpose
puts arr.size
puts arr[0].size
#quick_plot arr
=end

