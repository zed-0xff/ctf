#!/usr/bin/env ruby
require 'iostruct'
require 'zhexdump'
require 'awesome_print'

# lists contents of HARM file

class FileInfo < IOStruct.new 'A12CvvV',
  :name,
  :mode,        # 1 = raw unpacked data; 3 = packed
  :orig_size,
  :x3,
  :offset

  def packed?
    self.mode == 3
  end
end

class PackedData < IOStruct.new 'vV',
  :packed_size,
  :orig_size,
  :data

  def self.read io
    r = super
    r.data = io.read(r.packed_size)
    r
  end
end

fname = ARGV.first || "HARM.DAT"

io = open(fname, "rb")
io.seek(0x20)

nfiles = io.read(4).unpack('V')[0]
puts "[.] #{nfiles} files"

finfos = []
nfiles.times do
  fi = FileInfo.read(io)
  finfos << fi
  p fi
end

p io.tell

biggest_file        = finfos.sort_by(&:orig_size).last
total_unpacked_size = finfos.map(&:orig_size).inject(:+)
last_file           = finfos.sort_by(&:offset).last

puts
finfos.each do |finfo|
  next unless finfo.packed?

  puts finfo.inspect.green
#  io.seek finfo.offset
#  ZHexdump.dump io.read(0x20)
  io.seek finfo.offset
  pdata = PackedData.read(io)
  printf "[.] %-20s: %5d -> %5d", finfo.name, pdata.packed_size, pdata.orig_size
#  ZHexdump.dump io.read(0x40)
  puts
  puts
end

#puts "[*] biggest file: #{biggest_file.inspect}"
#io.seek biggest_file.offset
#p PackedData.read(io)
