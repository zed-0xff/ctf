#!/usr/bin/env ruby
require 'yaml'

h = {}

Dir["data/0000*x*"].each do |fname|
  x,y = fname.split('x').map(&:to_i)
  data = File.read(fname)
  idx = nil
  data.strip.each_line do |line|
    a = line.split
    if a.size == 2
      raise if idx
      idx = a.last
    end
  end
  raise "no idx in #{fname}" unless idx
  raise if h[idx]
  h[idx] = [x,y]
end

File.open("idx2xy.yml","w") do |f|
  f << h.to_yaml
end
