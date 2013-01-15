#!/usr/bin/env ruby
require 'zpng'
#require 'hexdump'


def process_file fname
  c0 = ZPNG::Color.new 0xd4, 0xd0, 0xc8

  bits = []

  img = ZPNG::Image.load fname
  img.pixels.each do |c|
    bits << (c == c0 ? 1 : 0)
  end

  data = bits.each_slice(8).to_a.map(&:join).map{ |x| x.to_i(2).chr }.join
  #Hexdump.dump data
  print data
end

#ARGV.each do |fname|
#  process_file fname
#end

process_file 'challenge.png'
