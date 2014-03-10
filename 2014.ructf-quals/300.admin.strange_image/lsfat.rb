#!/usr/bin/env ruby
require './_common.rb'

fname = ARGV.first || "task.ima"
io    = File.open fname, "rb"
@disk = Disk.new io

pp @disk.bpb
puts

@disk.fats.each_with_index do |fat,idx|
  puts "[.] FAT ##{idx+1}:"
  ZHexdump.dump fat.data[0,0x40]
#  puts fat.values.map{ |x| x.to_s(16) }.join(', ')
  fat.values.each_slice(0x10) do |slice|
    puts slice.map{ |x| "%5d" % x }.join(', ')
  end
  puts
end

printf "pos = %x\n", io.tell
dir_entries = 10.times.map{ DirEntry.read(io) }
dir_entries.each do |dir_entry|
  pp dir_entry
  if dir_entry.first_cluster != 0 && (1..10000).include?(dir_entry.file_size)
    ZHexdump.dump @disk.cluster(dir_entry.first_cluster)
  end
end

@ojpg = File.new("out.jpg", "w")

def write_cluster cluster_id, seq = 0
  printf "[.] seq=%2d, cluster %4d\n", seq, cluster_id
  data = @disk.cluster(cluster_id)
  @ojpg << data
  next_cluster_id = @disk.fats[0].values[cluster_id]
  next_cluster_id2 = @disk.fats[1].values[cluster_id]
#  p [seq, next_cluster_id, next_cluster_id2]

  if seq == 3
    next_cluster_id = next_cluster_id2
  end

  if next_cluster_id == 0
    @ojpg.close
    exit
  else
    write_cluster next_cluster_id, seq+1
  end
end

@disk.each_cluster do |data, idx|
  if data['JFIF']
    puts "cluster ##{idx}"
    #ZHexdump.dump data
    write_cluster idx
  end
end

#@disk.each_cluster do |data, idx|
#  if data.start_with?('JSTUV')
#    puts "cluster ##{idx}"
#    ZHexdump.dump data
#    ojpg << data
#  end
#end
