#!/usr/bin/env ruby
data = File.read "img.go"
out = ''
data.scan(/0x[a-f0-9]+/i).each do |num|
  out << [num.to_i(16)].pack('L')
end

File.open("out.bin","wb") do |f|
  f << out
end
