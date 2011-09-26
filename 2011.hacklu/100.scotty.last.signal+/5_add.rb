#!/usr/bin/env ruby

class String
  def add x
    r = ''
    0.upto(self.size-1) do |i|
      begin
        r << (self[i].ord+x).chr
      rescue RangeError
        r << self[i].chr
      end
    end
    r
  end
end

data = File.read('4_bin').force_encoding('binary')
-255.upto(255).each do |x|
  r=data.add(x)
  puts r if r['HELP']
end
