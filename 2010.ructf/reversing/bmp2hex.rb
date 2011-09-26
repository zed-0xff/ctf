#!/usr/bin/ruby

W = 500
H = 300

def pixel x,y
  @a[W*y+x]
end

def file2digest fname
  f = File.new(fname)

# grab the bytes as an array
  bytes = f.each_byte.to_a

  @a = bytes[1078..-1]

  a = []
  0.upto(100) do |i|
    a << pixel(i,i)
  end

  r = []

  27.step((14*33),14).each do |x|
    n = 0
    (23..300).each do |y|
      s = pixel(x,y)
      break if s == 33
      n += 1
    end
    r << n
  end
  r.map{ |x| sprintf("%02x",x) }.join
end

if ARGV.size > 0
  fname = ARGV.first
  digest = file2digest(fname)
  puts digest
else
  Dir['../data/*'].each do |fname|
    STDERR.puts(fname)
    begin
      digest = file2digest(fname)
      puts "#{File.basename(fname).ljust(15)} #{digest}"
    rescue
      STDERR.puts($!.message)
    end
  end
end
