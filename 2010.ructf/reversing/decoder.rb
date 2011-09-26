#!/usr/bin/ruby

TBL = <<EOF.split.map{ |x| x.to_i(16) }
0e 79 ca e2 48 8e 3f 66 d8 8c 7c 50 31 5c 06 62
7d e7 12 46 b8 1e cd bc b5 51 78 86 bd 95 5a 42
e4 96 45 98 53 30 02 b3 df cf 57 c0 15 4f 09 a8
f6 85 67 8a 5f 94 c4 ee 64 a5 9c 6a ae 55 ed e9
08 b2 03 3d d9 8d 3a 43 38 69 59 82 05 71 b6 13
ec d3 47 07 4a f0 6f 10 75 1b 70 4e 26 0b 90 34
0f f1 ea a0 28 65 c9 16 f2 52 e5 6d 41 eb fb 61
e6 9f e0 58 c2 74 a9 73 0c d0 2e 77 b0 3e d6 b1
c8 d7 6c 7f 1f 19 84 72 fa 27 fc 2b 32 c7 88 fd
49 e3 23 af f5 fe 3c 1d 4c ad 21 00 8f f9 2f d5
68 9e ba 29 7e 83 b7 8b e1 2a 7b ac a3 56 aa f4
63 db de 1a d2 99 d1 cc 4b 39 c1 24 14 dc 6b bf
89 91 a7 5e d4 ff 18 ab 17 2d 76 92 1c 9b b9 7a
dd 44 4d 11 81 93 5d 04 c5 54 a4 b4 ce 33 da 22
9d 20 cb 60 5b 25 e8 a6 2c f7 0d 01 a2 f8 35 be
f3 a1 3b 0a c6 36 9a 6e 37 ef bb 40 80 87 97 c3
EOF

if ARGV.empty?
  puts "gimme an arg!"
  exit
end

def calc_add arg
  add = 0
  n = 1
  arg.each_byte do |b|
    add += b*n
    n += 1
  end
  add & 0xff
end

# XXX: WARNING: encode works only at ~98%
# it treats zero chars at end of string wrong
def encode arg
  r = ''
  add = calc_add(arg)
  n = 0
  while n<32
    arg.each_byte do |b|
      r += "%02x" % TBL[(b+add)&0xff]
      n += 1
#      r += ' ' if n%4==0
      break if n==32
    end
  end
  r
end

def decode arg, add = nil
  if add
    arg = arg.strip.tr(' ','')
    r = ''
    0.step(62,2) do |i|
      c = arg[i,2].to_i(16)
      r += (((TBL.index(c)-add))&0xff).chr
      #r += ((TBL.index(c)-0xcd)&0xff).chr
    end
    return r
  else
    0.upto(255) do |add|
      r = decode(arg,add)
#      p r
#      p encode(r)
#      p r.tr((32..127).map(&:chr).join,'')
#      puts
      return r if encode(r) == arg #&& r.tr((32..127).map(&:chr).join,'') == ''
    end
  end
  return "cannot decode :("
end

arg = ARGV.first

if arg.strip.tr(' ','').size == 64
  puts "[.] decoding.."
  puts decode(arg)
else
  puts "[.] encoding.."
  puts encode(arg)
end
