#!/usr/bin/env ruby
data = File.read('strings').strip.gsub(/\.0+$/,'').split("\n")
sum = 0
data.map! do |row|
#  puts row
  sum += row.to_i
#  puts row.to_i.to_s(2).sub(/0+$/,'')
  x = row.to_i.to_s(16)[0..13]
#  puts x
  x
end

#exit

#puts
#puts "[.] sum = #{sum}"
#puts

#data << sum.to_s

data[0] = (data[0].to_i(16) << 1).to_s(16)
data[2] = (data[2].to_i(16) << 1).to_s(16)

r = ''
data.each do |row|
  s = ''
#  puts row
  0.step(row.size,2) do |i|
    char = row[i,2]
#    p char
    next if char == "" || char == "0"
    s = char.to_i(16).chr + s
  end
  p s
  r << s
end
p r
