#!/usr/bin/env ruby
require 'open-uri'

while true do
  r = `echo foo | nc ctf.hack.lu 2007`
  r.force_encoding 'binary'
  r.sub!(/010 Welcome, stranger\. Please prove that you are human\s*/m,'')
  puts r.size
  tags = r.scan(/tag[a-z0-9]*/i)
  p tags

  File.open 'data.mp3','w' do |f|
    f<<r
  end

  break if tags.size == 4
end
