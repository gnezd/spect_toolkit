require 'pry'
require '~/spect_toolkit/lib'
sifs = Dir.glob(ARGV[0]+'/*.sif').map {|f| SIF.new(f, File.basename(f, '.sif'))}

avgs = []
sifs.each do |sif|
  plot_spectra(sif.spects, {out_dir: sif.name+'_raw'})
  avg = sif.spects.reduce(:+) / (sif.spects.size.to_f)
  avg.name = sif.name + '_avg'
  avgs.push avg
end
plot_spectra(avgs, {out_dir: 'averages'})
binding.pry