#!/usr/bin/env ruby

STDOUT.sync = true

b0 = "\x80"*8
b1 = "\x27\x01\x27\x80\xd9\xff\xd9\x80"

data = Dir['chunks/chunk*'].sort.map{ |x| File.read(x).force_encoding('binary') }.join
if data[0,4] == 'RIFF'
  data = data[44..-1]
end

N=120

b0 = b0*N
b1 = b1*N

r = ''
n = 0
0.step(data.size-1, b0.size) do |i|
  case (d=data[i,b0.size])
  when b0
    print "."
    r << '.'
  when b1
    print "#"
    r << '#'
  else
    raise "SYNC ERROR" if d.size == b0.size
    raise "NOT ENOUGH DATA #{d.size}/#{b0.size}"
    raise "unknown #{d.size} (normal: #{b0.size}) bytes of data #{d.split('').map{|x| "%02x " % x.ord}.join}"
  end
  n += 1
#  puts if n%24==0
end

require 'morse'

puts
puts Morse.decode(r.gsub('......'," ").gsub('######','-').gsub('.','').gsub('##','.'))
