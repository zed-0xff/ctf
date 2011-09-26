#!/usr/bin/env ruby
require 'timeout'
require 'digest/md5'

TBL = ("\x21".."\x7e").to_a.join
p TBL

puts "[.] #{TBL.size} chars"

s="____"
0.upto(TBL.size-1) do |i|
  s[0] = TBL[i]
  0.upto(TBL.size-1) do |j|
    s[1] = TBL[j]
    0.upto(TBL.size-1) do |k|
      s[2] = TBL[k]
      0.upto(TBL.size-1) do |l|
        s[3] = TBL[l]
        print "\r#{s}"
        r = nil
        begin
          Timeout::timeout(1) { r = system("./borgbinary", s) }
        rescue Timeout::Error
        end
        if r
          puts "[*] #{s.inspect} #{Digest::MD5.hexdigest(s)}"
        end
      end
    end
  end
end

