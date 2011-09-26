#!/usr/bin/env ruby

class String
  def revert2!
    0.step(self.size-2,2) do |i|
      self[i+1],self[i] = self[i],self[i+1]
    end
    self
  end
end

puts File.read(ARGV[0]).unpack('m*')[0].revert2!
