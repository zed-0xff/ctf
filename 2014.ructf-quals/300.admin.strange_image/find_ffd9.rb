#!/usr/bin/env ruby
#coding: binary
require './_common.rb'
require 'awesome_print'

fname = ARGV.first || "task.ima"
io    = File.open fname, "rb"
@disk = Disk.new io

@disk.each_cluster do |data,idx|
  if data["\xff\xd9"]
    puts "cluster ##{idx}".green
    ZHexdump.dump data
    puts
  end
end
