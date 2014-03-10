#!/usr/bin/env ruby
require 'zpng'

def process_file fname
  img = ZPNG::Image.load fname
  if img[181,30].to_grayscale > 220 && img[197,30].to_grayscale > 220
    @html << "<img src='#{fname}'>\n"
  end
end

STDOUT.sync = true

@html = ''
ARGV.each do |fname|
  putc '.'
  process_file fname
end
File.write "png_out.html", @html
