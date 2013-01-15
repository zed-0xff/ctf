#!/usr/bin/env ruby

r = ''
File.read("6.txt").split.last.bytes.each do |x|
  x += 2
  x -= 26 if x > 'z'.ord
  r << x.chr
end
puts r
