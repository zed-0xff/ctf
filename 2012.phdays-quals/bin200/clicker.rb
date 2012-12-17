#!/usr/bin/env ruby

KEYS = "58374612"

def push num
  y = 480 + 51*(num.to_i-1)
  system "xdotool search --name xp mousemove 440 #{y} mousedown 1 sleep 0.25 mouseup 1"
  sleep 0.25
end

KEYS.split('').each do |key|
  push key
end
