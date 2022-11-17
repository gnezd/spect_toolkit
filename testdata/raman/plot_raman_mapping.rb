require '~/microPL_scan.git/lib.rb'
require 'json'



t0 = Time.now
puts "Beginning processing at #{t0.strftime("%H:%M:%S")}"


scan_param = JSON::parse(File.open('./Scan_param165942_261_1 microPL').read)
scan = Scan.new './261_1 11-11-2022 16_59_36 19 microPL.spe', '261_1', [scan_param['Points X'], scan_param['Points Y'], scan_param['Points Z']]
scan.load({s_scan: scan_param['S-shape scan'], spectral_unit: 'wavenumber'})


base_name = scan.name
outdir = "#{base_name}-sum-plots"
Dir.mkdir outdir unless File.exists? outdir
scan.plot_map(outdir, {scale: 4}) {|spects| spects[0].sum}


t1 = Time.now
puts "Finished processing sum at #{t1.strftime("%H:%M:%S")}"

outdir = "#{base_name}-372-545-plots"
Dir.mkdir outdir unless File.exists? outdir
scan.plot_map(outdir, scale: 4) {|spects| spects[0].from_to(18428, 18486)}


t2 = Time.now
puts "Finished processing at #{t1.strftime("%H:%M:%S")}"

outdir = "#{base_name}-1490-plots"
Dir.mkdir outdir unless File.exists? outdir
scan.plot_map(outdir, scale: 4) {|spects| spects[0].from_to(17408, 17204)}

t2 = Time.now
puts "Finished processing at #{t1.strftime("%H:%M:%S")}"

outdir = "#{base_name}-2620-plots"
Dir.mkdir outdir unless File.exists? outdir
scan.plot_map(outdir, scale: 4) {|spects| spects[0].from_to(16352, 16024)}

t2 = Time.now
puts "Finished processing at #{t1.strftime("%H:%M:%S")}"