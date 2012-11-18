#!/usr/bin/env ruby
s = "10000000 00000111 00110111"
puts s.reverse.split.map{ |x| "%02X" % x.to_i(2) }.join
#puts s.split.map{ |x| "%02X" % x.to_i(2) }.join
#puts s.split.reverse.map{ |x| "%02X" % x.to_i(2) }.join
#puts s.reverse.split.reverse.map{ |x| "%02X" % x.to_i(2) }.join
