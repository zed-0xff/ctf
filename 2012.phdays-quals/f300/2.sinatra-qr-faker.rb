#!/usr/bin/env ruby
require 'sinatra'
require 'zpng'
include ZPNG

# generates PNG image, 25x25, white background and ONE pixel set,
# coord of pixel given by 'data' param: "?data=4x5": x=4, y=5

# put into /etc/hosts:
# 127.0.0.1   api.qrserver.com

get '/v1/create-qr-code/' do
  content_type 'image/png'
  img = Image.new :width => 25, :height => 25, :color => 3, :depth => 1, :bg => Color::WHITE
  x,y = params[:data].split(/x/i).map(&:to_i)
  img[x,y] = Color::BLACK
  img.export
end
