#!/usr/bin/env ruby
#coding: utf-8
require 'zpng'

img  = ZPNG::Image.load "nyan-task.png"
plte = img.plte

puts
puts "this is a DataMatrix code, see http://ru.wikipedia.org/wiki/Data_Matrix"
puts

s = '  '
plte.to_a.each_slice(16) do |slice|
  puts '  ' + slice.map{ |c| c == plte[0] ? '██' : '  ' }.join
end
puts
