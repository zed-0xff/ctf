#!/usr/bin/env ruby

puts "<style>div {width:1px; height:1px; background: red}</style>"
puts "<style>body {width:10000px}</style>"

data = File.read(ARGV[0]).force_encoding('binary')
(0..10000).each do |i|
  puts "<div style='width:#{data[i].ord}px'></div>"
end
