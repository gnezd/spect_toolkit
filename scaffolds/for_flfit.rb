# Obj: covnert a .spe file to the format that flfit LabView app acceptso
require './lib'
#fin = 
spe = Spe.new 'testdata/64-84.9-w15h15d5-45x45x3 2022-04-29 10_36_52 microPL.spe', 'the scan'
##puts spe.wv.size
#puts spe.frames

result = Array.new(spe.frames+1) {Array.new(spe.wv.size)}

raise "Spectral range mismatch" unless result[0].size == spe.wv.size
result[0] = spe.wv
(1 .. spe.frames).each do |frame_num|
  result[frame_num] = spe.at(frame_num, 0).map {|point| point[1]}
end

result_t = result.transpose
puts "#{result_t.size} rows of data"
puts "#{result_t[0].size} columns including wavelength"

fout = File.open 'output.tsv', 'w'

result_t.each do |line|
  fout.puts line.join "\t"
end
fout.close