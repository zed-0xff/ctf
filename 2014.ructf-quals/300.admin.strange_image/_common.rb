require 'iostruct'
require 'zhexdump'
require 'pp'

MBR = IOStruct.new 'a3a8', 
  :jmp,
  :oem_name

# BIOS Parameter Block
BPB = IOStruct.new 'vCvCvvCvvvVV',
  # DOS 2.0 BPB:
  :bytes_per_sector,
  :sectors_per_cluster,
  :reserved_sectors,
  :number_of_fats,
  :max_root_entries,
  :total_logical_sectors,
  :media_descriptor,
  :sectors_per_fat,
  # DOS 3.31 BPB:
  :sectors_per_track,
  :number_of_heads,
  :hidden_sectors,
  :total_sectors            # Total logical sectors including hidden sectors

# Extended BIOS Parameter Block
EBPB = IOStruct.new 'vCvCvvCvvvVVCCCVa11a8a448a2',
  # DOS 2.0 BPB:
  :bytes_per_sector,
  :sectors_per_cluster,
  :reserved_sectors,
  :number_of_fats,
  :max_root_entries,
  :total_logical_sectors,
  :media_descriptor,
  :sectors_per_fat,
  # DOS 3.31 BPB:
  :sectors_per_track,
  :number_of_heads,
  :hidden_sectors,
  :total_sectors,           # Total logical sectors including hidden sectors
  :physical_drive_number,
  :reserved,
  :extended_boot_signature, # see http://en.wikipedia.org/wiki/File_Allocation_Table#EBPB
  :volume_id,
  :volume_label,
  :file_system_type,
  :boot_code,
  :signature_55AA
  # end of sector, 512 bytes total

class FAT12
  attr_accessor :data, :values

  def initialize data
    @data   = data
    @values = data.each_byte.map{ |x| "%08b" % x }.join.scan(/.{12}/).map{ |x| x.to_i(2) }
    @values = []
    data.bytes.each_with_index do |b,idx|
      case idx % 3
      when 0
        @values << b
      when 1
        @values[-1] += ((b&0x0f)<<8)
        @values << ((b&0xf0)>>4)
      when 2
        @values[-1] += (b<<4)
      end
    end
  end

  def get_chain start_cluster_id
    cluster_id = start_cluster_id
    r = []
    while cluster_id != 0
      r << cluster_id
      cluster_id = @values[cluster_id]
    end
    r
  end
end

class DirEntry < IOStruct.new 'a8a3CCCvvvvvvvV',
  :filename,
  :ext,
  :attr,
  :attr2,
  :x1,     # file create time (10ms units) / first character of a deleted file under Novell DOS, OpenDOS and DR-DOS 7.02+
  :ctime,
  :cdate,
  :atime,  # access time
  :perm,
  :mtime,
  :mdate,
  :first_cluster,
  :file_size
end

class Disk
  attr_accessor :io, :mbr, :bpb, :fats

  def initialize io
    @io  = io
    @mbr = MBR.read io
    @bpb = EBPB.read io

    case @bpb.file_system_type.strip
    when 'FAT12'
      fat_class = FAT12
    else
      raise "unsupported bpb.file_system_type=#{@bpb.file_system_type.inspect}"
    end

    @fats = []
    @bpb.number_of_fats.times do
      @fats << fat_class.new(io.read( @bpb.bytes_per_sector * @bpb.sectors_per_fat ))
    end
  end

  def bytes_per_cluster
    @bpb.bytes_per_sector * @bpb.sectors_per_cluster
  end

  def cluster cluster_id
    # TODO: reserved_sectors
    pos = (@bpb.number_of_fats * @bpb.sectors_per_fat + @bpb.hidden_sectors) * @bpb.bytes_per_sector
    pos += @bpb.max_root_entries * DirEntry::SIZE
    pos += (cluster_id-1)*bytes_per_cluster
    #printf "[d] cluster #%d: seek to %d\n", cluster_id, pos
    @io.seek pos
    @io.read bytes_per_cluster
  end

  def each_cluster
    cluster_id = 1
    loop do
      data = cluster(cluster_id)
      yield data, cluster_id
      break if @io.eof?
      cluster_id += 1
    end
  end
end
