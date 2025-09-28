require 'pty'
require 'pry'

def send_data(data, proc_register)
  proc_register[:w].write([data.size].pack("L")+data)
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

puts procs_register[0][:r].gets

data = "A" * 1E9
puts "Ready to pump data at #{Time.now.strftime("%H:%M:%S.%9N")}"
send_data(data, procs_register[0])
puts "Done #{Time.now.strftime("%H:%M:%S.%9N")}"
binding.pry