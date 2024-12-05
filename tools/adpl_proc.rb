# .sif ADPL data rapid processing
require "#{__dir__}/../lib"
require 'pry'

def adpl_proc(adpls, ranges, path)
  puts "Processing..."
  adpls.each_index do |ith|

    normal_fl = adpls[ith].spects.at(adpls[ith].spects.frames/2, 0)
    
    if ranges[ith] == nil
      # Default range: peak +/- 0.5fwhm
      peak = normal_fl.max[0]
      width = normal_fl.fwhm / 2
      range = [peak-width, peak+width]
      puts "#{ith}: #{adpls[ith].name}. Max position: #{peak}, Width: #{width}"
    else
      range = ranges[ith]
    end

    # Construct data rows for plotting and write to datafile
    data = (0..adpls[ith].spects.frames-1).map {|angle| [angle, adpls[ith].spects.at(angle, 0).from_to(*range), adpls[ith].spects.at(angle, 1).from_to(*range)]}
    matrix_write(data.transpose, "#{path}#{adpls[ith].name}.tsv")

    # Construct gnuplot instructions
    gpout = File.open("#{path}#{adpls[ith].name}.gplot", 'w')
    gpout.puts 'set terminal svg'
    gpout.puts "set output '#{path}#{adpls[ith].name}.svg'"
    gpout.puts "set title '#{path}#{adpls[ith].name.gsub('_', '\_')}'"
    
    # Note the ROI numberings being arbitrary
    gpout.puts "plot '#{path}#{adpls[ith].name}.tsv' u 1:2 w lines t 'roi0', '' u 1:3 w lines t 'roi1'"
    gpout.puts "set terminal png lw 2; set output '#{path}#{adpls[ith].name}.png'; replot"
    gpout.close
    
    # Plot
    `gnuplot '#{path}#{adpls[ith].name}.gplot'`
  end

  puts ""
  puts "Done!"
end

path = ARGV[0]
raise "No directory given in ARGV!" unless Dir.exist? path
path += '/' unless path[-1] == '/'
adpl_fs = Dir.glob "#{path}*.sif"

puts "Found SIFs:"
puts adpl_fs
puts "_" * 20

adpls = []
maxpls = []

puts "1st time initializing..."
adpl_fs.each do |adplf|
  # ADPL.initialize options:
  # scans_per_deg, defaults to 1
  adpl = ADPL.new adplf, File.basename(adplf, '.sif')
  adpls.push adpl
  # ADPL overview 2D plot options:
  # plot_width, plot_height, dark_bg(true/false)
  adpl.plot(path+File.basename(adplf, '.sif'), { plot_term: 'png' })

  # Extract and accumulate the center spectra
  maxpl = adpl.spects.at(adpl.spects.frames/2,1)
  maxpls.push maxpl

end


# Plot the 90deg PL spectra
plot_spectra maxpls, {out_dir: path+'maxpls'}

# Initiate intensity summation range selections
ranges = Array.new(adpls.size) {nil}

# Process and plot
adpl_proc(adpls, ranges, path)
puts "1st processing done. Consult maxpls/spectra_plot.svg and select the relevant PL bands."
puts "Then modify ranges[] and call adpl_proc(adpls, ranges) again."


binding.pry
