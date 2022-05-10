require './lib.rb'

spect1 = Spectrum.new 'fft_contest/10-spect.tsv'
windowsize = 800
yvalues = spect1.map {|pt| pt[1]}
segments = []
(0..yvalues.size - 1 - windowsize).each do |i|
    segments.push GSL::Vector.alloc(yvalues[i .. i+windowsize-1])
end

ffts = []
segments.each do |segment|
    ffts.push segment.fft
end

puts ffts.size

result = ffts.reduce :+
puts result.size

fout = File.new 'fft_contest/segmented_sum.tsv', 'w'
result.each_index do |i|
    fout.puts (ffts.map {|segment| segment[i]})[100..110].join "\t"
    #fout.puts result[i]
end

fout.close