require 'json'
def get_data(type = :raw)
  input = STDIN.read(4)
  data_length = input ? input.unpack1("L") : nil
  raise "Length of zero means that I should quit" if data_length == 0
  puts "Ready for #{data_length} bytes of data"
  data = STDIN.read(data_length)
  puts "ack #{data_length} bytes at #{Time.now.strftime("%H:%M:%S.%9N")}"

  case type
  when :raw
    return data
  when :json
    return JSON.parse(data)
  end
end

pid = Process.pid
puts "Scan worker id #{pid} initializing. Ready for schema."



# Schema
schema = get_data(:json)
puts schema

puts "EOL"