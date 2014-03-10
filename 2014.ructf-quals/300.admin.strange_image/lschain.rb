#!/usr/bin/env ruby
require './_common.rb'

fname = ARGV.first || "task.ima"
io    = File.open fname, "rb"
@disk = Disk.new io

@disk.fats.each do |fat|
  p fat.get_chain 1654
end
