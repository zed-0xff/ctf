#!/usr/bin/env ruby

text = File.read "2.txt"

# http://www.blisstonia.com/software/WebDecrypto/index.php

known = " WANT IT TO MEAN SOMETHING OR NOT YOU COULD THINK THAT THE SOLUTION IS HIDDEN IN THIS NONSENSE ALPHABET "

# manually assigned, using eyes(tm)
repl_from = 'UJMNAVG'
repl_to   = 'RXVFQJZ'

text.scan(Regexp.new(known.gsub(/[a-z]/i,'.'))).each do |decoded_part|
  puts known.inspect
  puts decoded_part.inspect
  puts
  known.size.times do |i|
    next if known[i] == ' '
    next if repl_to[known[i]]
    repl_from << decoded_part[i]
    repl_to   << known[i]
  end

  # debug output to be sure that both replacement strings contain all A-Z chars
  p [repl_from, repl_to]
  p [repl_from.size, repl_to.size]
  p repl_from.chars.sort.join
  p repl_to.chars.sort.join
  puts

  # final result
  puts text.tr(repl_from, repl_to)
end
