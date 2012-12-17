#!/usr/bin/env ruby
#coding: binary
data = File.binread("4_all.1.dat")
data = data[/[a-z0-9:]+/i]
data = data.split(":")
raise "invalid size: want #{data[0]}, got #{data[1].size}" if data[0].to_i != data[1].size
File.open( "6.rar", "wb" ) do |f|
  f << [data[1]].pack("H*")
end
