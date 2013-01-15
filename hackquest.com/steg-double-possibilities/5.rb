#!/usr/bin/env ruby

data = File.read "4.txt"

text = ''
data.split.each do |word|
  if word == 'between'
    text << ' '
  else
    text << word[0,1]
  end
end

puts text
