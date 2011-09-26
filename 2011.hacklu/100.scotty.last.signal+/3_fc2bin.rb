#!/usr/bin/env ruby
data = File.read(ARGV[0]).strip.
  split("\n").
  map{ |x| x.split(' ')[2] }.
  map{ |x| x.to_i(16).chr }.
  join
print data
