#!/usr/bin/env ruby
require 'zpng'
img = ZPNG::Image.load '0.png'

NBITS = 1

def save_bits fname, bits
  data = ''
  data2 = ''
  bits.each_slice(8/NBITS) do |a|
    data  << a.map{|x| x.to_s(2) }.join.to_i(2).chr
    data2 << a.map{|x| x.to_s(2) }.reverse.join.to_i(2).chr
  end

  if data.split('').uniq.size < 2
    puts "[.] #{fname}: nothing to write"
  else
    File.open(fname,"wb"){ |f| f<<data }
    File.open(fname+"2","wb"){ |f| f<<data2 }
  end
end

bits = []
3.times do |y|
  img.width.times do |x|
    bits << (img[x,y].r & (2**NBITS-1))
    bits << (img[x,y].g & (2**NBITS-1))
    bits << (img[x,y].b & (2**NBITS-1))
  end
end
save_bits "4_all.#{NBITS}.dat", bits
save_bits "4_all.#{NBITS}.dat.r", bits.reverse

%w'r g b'.each do |channel|
  bits = []
  3.times do |y|
    img.width.times do |x|
      bits << (img[x,y].send(channel).to_i & (2**NBITS-1))
    end
  end
  save_bits "4_#{channel}.#{NBITS}.dat", bits
  save_bits "4_#{channel}.#{NBITS}.dat.r", bits.reverse
end

