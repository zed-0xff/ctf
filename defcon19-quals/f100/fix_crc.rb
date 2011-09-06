#!/usr/bin/env ruby
require 'zlib'

data = File.read(ARGV[0])

data.force_encoding('ascii-8bit')

crc = Zlib::crc32(data[0x0c,0x0d+4])

p data[0x1d,4]

data[0x1d] = (crc>>24).chr
data[0x1e] = ((crc>>16)&0xff).chr
data[0x1f] = ((crc>>8)&0xff).chr
data[0x20] = (crc&0xff).chr

p data[0x1d,4]

File.open(ARGV[0],'w') do |f|
  f << data
end
