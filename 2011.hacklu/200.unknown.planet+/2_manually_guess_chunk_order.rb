#!/usr/bin/env ruby
STDOUT.sync = true

if ARGV.size == 0
  raise "gimme at least one chunk filename"
end

b0 = "\x80"*8
b1 = "\x27\x01\x27\x80\xd9\xff\xd9\x80"

data = ARGV.map{ |x| File.read(x) }.join.force_encoding('binary')
if data[0,4] == 'RIFF'
  data = data[44..-1]
end

N=120

b0 = b0*N
b1 = b1*N

r = ''
0.step(data.size-1,b0.size) do |i|
  case (d=data[i,b0.size])
  when b0
    print "."
    r << '0'
  when b1
    print "#"
    r << '1'
  else
    raise "SYNC ERROR" if d.size == b0.size
    raise "NOT ENOUGH DATA #{d.size}/#{b0.size}"
    raise "unknown #{d.size} (normal: #{b0.size}) bytes of data #{d.split('').map{|x| "%02x " % x.ord}.join}"
  end
end
