require 'pty'
require 'pry'
require 'json'

def send_data(data, proc_register)
  transfer = [data.size].pack("L")+data
  puts "Transferring #{transfer.size} bytes"
  proc_register[:w].write(transfer)
  2.times {puts proc_register[:r].gets}
  true
end

procs_register = []
(0..0).each do
  r, _s = PTY.open
  _r, w = IO.pipe
  pid = spawn("ruby scan_worker.rb", in: _r, out:_s)
  procs_register.push({pid: pid, r: r, w: w})
  _s.close
  _r.close
end

sif1 = SIF.new '../testdata/Andor/ADPL_test_20frames_2ROIs.sif', 'a'
binding.pry

puts procs_register[0][:r].gets
data_schema = {type: "sif", size: 10}
puts "Sending schema at #{Time.now.strftime("%H:%M:%S.%9N")}"
send_data(data_schema.to_json, procs_register[0])
puts "Done #{Time.now.strftime("%H:%M:%S.%9N")}"



binding.pry