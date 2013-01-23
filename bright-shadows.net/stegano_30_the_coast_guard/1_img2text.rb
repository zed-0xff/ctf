#!/usr/bin/env ruby
require 'zpng'

img = ZPNG::Image.load "stegano33.png"

# extract every 50-th pixel
a = []
img.pixels.each_with_index do |c,idx|
  if idx%50 == 0
    a << c
  end
end

# last pixel is a lie
a.pop

# note that there's 27 unique colors - letters A..Z + space
#p a.uniq.size

# try to stupidly convert colors to a letters
r = ''
h = {}
char = 'A'
a.each do |c|
  if c.black?
    s = " "
  elsif h[c]
    s = h[c]
  else
    raise char if char.size > 1
    s = h[c] = char.dup
    char.succ!
    s
  end
  r << s
end

puts r
