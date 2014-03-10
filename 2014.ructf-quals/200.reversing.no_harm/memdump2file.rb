#!/usr/bin/env ruby
require 'zhexdump'
require 'digest/md5'
require 'awesome_print'

# extract trx-drnk.rus from windows process memory dump file

fname     = "DOSBox-TRX-DRNK.DMP"
offset    = 0x068D41A6
ORIG_SIZE = 63648

def check offset
  @io.seek offset

  data = @io.read ORIG_SIZE

  printf "[.] offset = %x, size = %d, md5 = %s".green, offset, data.size, Digest::MD5.hexdigest(data)
  puts

  ZHexdump.dump(data[0,0x200]) do |row,pos,ascii|
    if pos
      idx = 0
      data[pos, 16].each_byte do |b|
        if b >= 0x80
          ascii[idx] = b.chr('cp866').encode('utf-8')
        end
        idx += 1
      end
    end
  end
  puts "..."
  ZHexdump.dump(data[-0x40..-1]) do |row,pos,ascii|
    if pos
      idx = 0
      data[pos, 16].each_byte do |b|
        if b >= 0x80
          ascii[idx] = b.chr('cp866').encode('utf-8')
        end
        idx += 1
      end
    end
  end
  puts
end

@io = open(fname, "rb")

check offset

#50.times do
#  check offset
#  offset -= 1
#end
