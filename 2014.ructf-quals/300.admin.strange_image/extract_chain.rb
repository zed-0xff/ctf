#!/usr/bin/env ruby
#coding: binary
require './_common.rb'

fname = ARGV.first || "task.ima"
io    = File.open fname, "rb"
@disk = Disk.new io

ios = @disk.fats.size.times.map{ |idx| File.new("chain.fat#{idx+1}.jpg","wb") }
@disk.fats.each_with_index do |fat,idx|
  chain = fat.get_chain 1654
  chain.each do |cluster_id|
    ios[idx] << @disk.cluster(cluster_id)
  end
end
ios.each(&:close)
