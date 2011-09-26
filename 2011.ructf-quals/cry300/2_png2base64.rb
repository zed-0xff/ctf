#!/usr/bin/env ruby
$:.push('.')
require 'zpng'

class String
  def revert2!
    0.step(self.size-2,2) do |i|
      self[i+1],self[i] = self[i],self[i+1]
    end
    self
  end
end

img = ZPNG::Image.new(:file => ARGV[0])
img.dump
puts "[.] image size #{img.width}x#{img.height}"
puts "[.] uncompressed imagedata size=#{img.imagedata.size}"
puts "[.] palette =#{img.palette}"

puts

tbl = (('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a).join + "+/_"

blksz = 8


ipos = 0

0.upto(img.height/blksz-1) do |y|
  r = ''
  0.upto(img.width/blksz-1) do |x|
    b = img.extract_block x*blksz,y*blksz,blksz,blksz
    s = b.to_binary_string('0','1')
    c = s.count '0'
    if c == 0
#      puts "[?] zero block at #{x},#{y}"
    end
    if ipos == 76
      ipos = 0
      next
    end
    ipos+=1
    r << tbl[c]
  end

  puts r

  #puts "[.] y=#{y}: #{r} #{r.size}"
#  s = r.unpack('m*')[0].revert2!
#  puts "[.] " + s.inspect
  #puts s
  #puts r.unpack('m*')[0]
end

