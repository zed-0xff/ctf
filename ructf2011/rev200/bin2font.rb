#!/usr/bin/ruby
data = File.read('key.bin')
i=1
data.each_byte do |b|
  s = "%08b" % b
  puts s.tr('01','.#')
  if i==8
    #puts
    i=0
  end
  i+=1
end
