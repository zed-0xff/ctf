#!/usr/bin/env ruby

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

s = "\x0fp4$-\x064l?\x06 o!h\x17t3`\x10"
0.upto(255) do |x|
  s1 = s.xor(x)
  p s1 if s1[/^[\x20-\x7f]+$/]
end
