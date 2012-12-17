#!/usr/bin/env ruby
Dir['data?'].sort.each do |fname|
  r = ''
  data = File.read(fname)
  0.upto(data.size/2) do |i|
    r << data[i*2,2].to_i(16).chr
  end
  r = r[0x40..-2]
  if r.size < 1000
    r = r[0..-2] while r[-1..-1].ord == 00
  end
  puts "[.] #{r.size} bytes"
  File.open("#{fname}.bin",'w') do |f|
    f << r
  end
end

`cat data*bin > 1.jpg`
