#!/usr/bin/env ruby
require 'open-uri'

URL = 'http://insecure.org/stf/smashstack.html'

class String
  def xor x
    if x.is_a?(String)
      r = ''
      j = 0
      0.upto(self.size-1) do |i|
        r << (self[i].ord^x[j].ord).chr
        j+=1
        j=0 if j>= x.size
      end
      r
    else
      r = ''
      0.upto(self.size-1) do |i|
        r << (self[i].ord^x).chr
      end
      r
    end
  end
end

data1 = File.read('simplexor.txt').unpack('m*')[0]
data2 = open(URL).read.force_encoding('binary')[/<pre>.+<\/pre>/mi].
  sub(/<pre>/i,'').
  sub(/<\/pre>/i,'').
  strip

puts data1[0,64].xor(data2)
