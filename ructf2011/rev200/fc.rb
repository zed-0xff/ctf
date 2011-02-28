#!/usr/bin/ruby
# simple binary file compare (c) http://zed.0xff.me
# like good old DOS "fc /b"

if ARGV.size < 2
  puts("[!] gimme at least two filenames")
  exit
end

handles = ARGV.map{ |fname| open(fname) }

while !handles.any?(&:eof)
  bytes = handles.map(&:readbyte)
  if bytes.uniq.size > 1
    @diff = true
    printf "%08x:"+" %02x"*handles.size+"\n", handles[0].pos-1, *bytes
  end
end

unless handles.all?(&:eof)
  @diff = true
  puts
  ARGV.each do |fname|
    printf "[!] %20s is %8d bytes long\n", fname, File.size(fname)
  end
end

puts "[.] all files are identical" unless @diff
