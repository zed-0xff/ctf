#!/usr/bin/ruby
data = File.read(ARGV.first)
a = ''
data.strip.split("\n").each do |l|
  l.strip!
  if l =~ /^:100/
  else
    $stderr.puts "[?] #{l}"
    next
  end
  l.sub! /^:100...../,''
  l = l[0..-3]
  (0..15).each do |i|
    a << l[i*2,2].to_i(16).chr
  end
end
$stdout << a
