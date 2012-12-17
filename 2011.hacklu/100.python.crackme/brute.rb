#!/usr/bin/env ruby

STDOUT.sync = true

def check a,d,e,f,i
  return if  3*a + 12*d +   e + 4*f + 6*i != 2194
  return if -6*a +  2*d - 4*e -   f + 9*i != -243
  return if    a +  6*d + 2*e + 7*f +11*i != 2307
  return if  5*a -  2*d - 7*e +76*f + 8*i != 8238
  return if  2*a -  2*d - 2*e - 2*f + 2*i != -72
  puts [a,0,0,d,e,f,0,0,i].join(' ')
end


while(true) do
  check rand(256), rand(256), rand(256), rand(256), rand(256),
end

puts "[.] rand fail"

0.upto(255) do |a|
  0.upto(255) do |d|
    0.upto(255) do |e|
      0.upto(255) do |f|
        0.upto(255) do |i|
          check a,d,e,f,i
        end
      end
    end
  end
end
