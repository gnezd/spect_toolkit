# Plot all spes in the given path, with a reasonable number of frames
require "#{__dir__}/../lib.rb"
path = ARGV[0]
path = '.' unless path

raise "Path \"#{File.realpath(path)}\" not valid" unless Dir.exist? path