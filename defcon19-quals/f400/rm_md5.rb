#!/usr/bin/ruby
require 'digest/md5'

sums = {}

`find wad_jailbreakme -type f`.split("\n").each do |fname|
  sum = Digest::MD5.hexdigest(File.read(fname))
  sums[sum] = 1
end

`find wad_ddtek -type f`.split("\n").each do |fname|
  sum = Digest::MD5.hexdigest(File.read(fname))
  if sums[sum]
    puts "rm #{fname}"
    File.unlink fname
  end
end
