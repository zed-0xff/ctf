#!/usr/bin/env ruby
data = File.read ARGV[0]
data.force_encoding 'binary'

s1 = "\xd5".force_encoding('binary')
s2 = "\x00".force_encoding('binary')

data.tr! s1,s2
#data.tr! "\x55",""

File.open(ARGV[1],'w'){ |f| f << data }
