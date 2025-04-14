# Plot all spes in the given path, with a reasonable number of frames
require "#{__dir__}/../lib.rb"
require 'pry'
path = ARGV[0]
path = '.' unless path

raise "Path \"#{File.realpath(path)}\" not valid" unless Dir.exist? path
sif_files = Dir.glob(path + '/*.sif')
spects = []
sif_files.each do |file|
  sif = SIF.new(file, File.basename(file, '.sif'))
  
  # Sum and normalize all acquisitions
  spect = sif.spects.reduce(:+) / sif.frames
  spect.name = sif.name

  # Push to array
  spects.push spect
end

# Plot from array
plot_spectra spects, {out_dir: 'summary'}

binding.pry