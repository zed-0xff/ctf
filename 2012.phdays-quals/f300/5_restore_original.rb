#!/usr/bin/env ruby
require 'zpng'
require 'yaml'
include ZPNG

img = Image.new :width => 25, :height => 25, :color => 3, :depth => 1, :bg => Color::WHITE

idx2xy = YAML::load_file "4_idx2xy.yml"
data = File.read("0.hilbert").strip

indexes = []
data.split("\n").each_with_index do |line|
  line.split[1..-1].each do |idx|
    indexes << idx
  end
end

indexes.each do |idx|
  x,y = idx2xy[idx]
  img[x,y] = Color::BLACK
end

img.save "5.png"
