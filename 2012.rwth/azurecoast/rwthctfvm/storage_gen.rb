#!/usr/bin/env ruby

data = File.binread("storage/00000000000000000")
0.upto(data.size) do |i|
  data2 = data.dup
  data2[i] = 0xff.chr
  fname = "storage/%017i" % i
  File.open(fname,"wb") do |f|
    f << data2
  end
end
