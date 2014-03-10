#!/usr/bin/env ruby
#coding: binary
require './_common.rb'

fname = ARGV.first || "task.ima"
io    = File.open fname, "rb"
@disk = Disk.new io

#chain = @disk.fats[0].get_chain(1654)
chain = [1654, 662, 1092, 1146, 2127, 2832, 1213, 1098]
data0 = chain.map{ |cluster_id| @disk.cluster(cluster_id) }.join

STDOUT.sync = true

fnames = []
@disk.each_cluster do |data,idx|
  fname = "brute.#{idx}.jpg"
  fnames << fname
  File.open("out/#{fname}", "wb") do |io|
    io << data0
    io << data
  end
  system "convert out/#{fname} out_png/#{fname.sub('jpg','png')}"
  putc '.'
end

html_idx = 0
fnames.each_slice(1000) do |slice|
  html = ''
  slice.each do |fname|
    html << "<img title='#{fname}' src='#{fname}'>\n"
  end
  html_fname = "out/#{html_idx}.html"
  puts "[=] #{html_fname}"
  File.write html_fname, html
  html_idx += 1
end

