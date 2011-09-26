#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'digest/md5'

STDOUT.sync = true

def tag2num tag
  case tag
  when /\d/
    tag
  when /tago/i
    '1'
  when /two/i
    '2'
  when /three/i
    '3'
  when /four/i
    '4'
  when /five/i
    '5'
  when /tagsi/i
    '6'
  else
    nil
  end
end

def extract_tags data
  tags = []
  if data.size >= 3000
    hash = Digest::MD5.hexdigest(data)
    if File.exist?("data/#{hash}") && tags.size == 0
      tags << File.read("data/#{hash}").strip
    end
  end
  (tags + data.scan(/tag[a-z0-9]*/i).map{ |x| tag2num(x) }).flatten.compact
end

$uniqhashes = {}

def go
  host = 'ctf.hack.lu'
  port = 2007

  s = TCPSocket.open(host, port)

  data =''; line =''; tags = []
  flags = "___"
  while true
    begin
      Timeout::timeout(0.2) do
        line = s.read(100)
      end
    rescue Timeout::Error
      puts "[!] time"
      line = ''
    end
    data << line
    if data.size == 3000
      hash = Digest::MD5.hexdigest(data)
      unless $uniqhashes[hash]
        $uniqhashes[hash] = true
#        File.open("data/#{hash}.mp3",'w') do |f|
#          f << data.sub(/010 Welcome, stranger\. Please prove that you are human\s*/m,'')
#        end
      end
    end
    tags = extract_tags data
    #print "\r" + [data.size, tags.size].inspect + "\t#{$uniqhashes.size}"
    printf "datasize=%7d,  utags=%2d, %s\r", data.size, $uniqhashes.size, tags.join
    #break if tags.size <= 2 && data.size>20000
    #break if tags.size <= 1 && data.size>13000
    break if tags.size == 4
    break if line == ''
  end
  if tags.size == 4
    puts "[.] writing #{tags.size} tags"
    s.write(tags.join + "\n")
    puts s.gets
    if ARGV.size > 0
      s.write(ARGV.join("\n") + "\n")
    else
      s.write "quit\n"
    end
    puts s.gets
    while true
      while r=s.gets
        print r
      end
      s.write(gets)
    end
  end
  s.close

  tags.size
end

while true
  ntags = go
  break if ntags == 4
end
