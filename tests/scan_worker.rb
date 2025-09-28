pid = Process.pid
puts "This is scan worker id #{pid} initializing"

# OK get 8 bytes to speak of data length
while true
  input = STDIN.read(4)
  data_length = input ? input.unpack1("L") : nil
  break if data_length == 0
  puts "Ready for #{data_length} bytes of data"
  data = STDIN.read(data_length)
  puts "ack #{data_length} bytes at #{Time.now.strftime("%H:%M:%S.%9N")}"
end

puts "EOL"