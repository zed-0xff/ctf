#!/usr/bin/env ruby
data = File.read(ARGV[0]).force_encoding('binary')

File.open(ARGV[1],'w') do |f|
  f << data.
    gsub(/\x80[\x08\x88]..../m,'').
    gsub(/\x00+/m,'').
    gsub(/...bC/m,'').
    gsub(/..2x../m,'').
#    gsub(/\xd5/m,'').
    gsub(/\x00/m,'')
end
