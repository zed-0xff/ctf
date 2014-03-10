#!/usr/bin/env ruby
#coding: binary
require 'rc4' # ruby-rc4 gem

KEY = '0h,NiC3_k3Y'

ENCRYPTED = <<-EOF.strip.split.map{ |x| x.to_i(16).chr }.join
  CA C8 C7 03 FC 10 28 1F 7A 7F 8C 94 2E F9 69 24
  9F 7D 27 C1 C4 09 45 7F 75 EE 45 97 8D AF 79 1F
EOF

decrypted = RC4.new(KEY).decrypt(ENCRYPTED)
p decrypted 
