#!/usr/bin/env ruby
#coding: binary
require 'zpng'
require 'sugar_png'
require 'pp'

# run "convert task.gif task.png"
# produces 8 PNG frames from animated task.gif

images = Dir["task*.png"].sort.map{ |fname| ZPNG::Image.load(fname) }

w = images[0].width
h = images[0].height

sugar = SugarPNG.new :width => w

w.times do |x|
  h.times do |y|
    a = images.map{ |img| img[x,y] }
    if a.uniq.size != 1
      sugar[x,y] = :black
      #printf "%3d %3d : %d\n",x,y, a.uniq.size
      #p a.map{ |x| x.r & 1 }.join
    end
  end
end

sugar.save "sugar.png"

system "zsteg sugar.png"
