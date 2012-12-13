#!/usr/bin/env ruby

data = File.binread("storage/00000000000000000")
32.upto(127) do |i|
  data2 = data.dup
  data2[4] = i.chr
  fname = "storage/Z%016x" % i
  File.open(fname,"wb") do |f|
    f << data2
  end
end
