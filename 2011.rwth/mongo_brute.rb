#!/usr/bin/env ruby
require 'mongo'

TARGET_AUTH_KEY = '6b079a01f6bb2ca4f158cbadc443fafa'

nonce = '28cf33f22c110199'
user  = 'nfs'
pass  = '1'
i = 0

while true do
  pass = i.to_s
  auth_key = Mongo::Support.auth_key(user, pass, nonce)
  raise auth_key if auth_key == TARGET_AUTH_KEY
  i += 1
  print "#{i}\r" if i%100 == 0
end
