#!/usr/bin/env ruby

# get roms from http://www.emu-land.net/consoles/dendy/roms/top

Dir['orig/*.nes'].each do |fname|
  system %Q|fc.rb "#{fname}" mario.nes > "#{fname}.fc"|
end
