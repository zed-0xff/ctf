#!/usr/bin/env ruby
require 'zlib'
require 'stringio'
require 'rubygems'
require 'colorize'

# see alse http://github.com/wvanbergen/chunky_png/

module ZPNG

  class Chunk
    attr_accessor :size, :type, :data, :crc

    def self.from_stream io
      size, type = io.read(8).unpack('Na4')
      io.seek(-8,IO::SEEK_CUR)
      begin
        if const_defined?(type.upcase)
          klass = const_get(type.upcase)
          klass.new(io)
        else
          Chunk.new(io)
        end
      rescue NameError
        # invalid chunk type?
        Chunk.new(io)
      end
    end

    def initialize io
      @size, @type = io.read(8).unpack('Na4')
      @data        = io.read(size)
      @crc         = io.read(4).to_s.unpack('N').first
    end

    def inspect
      size = @size ? sprintf("%5d",@size) : sprintf("%5s","???")
      crc  = @crc  ? sprintf("%08x",@crc) : sprintf("%8s","???")
      type = @type.to_s.gsub(/[^0-9a-z]/i){ |x| sprintf("\\x%02X",x.ord) }
      sprintf("#<ZPNG::Chunk  %4s size=%s, crc=%s >", type, size, crc)
    end

    def crc_ok?
      expected_crc = Zlib.crc32(data, Zlib.crc32(type))
      expected_crc == crc
    end

    class IHDR < Chunk
      attr_accessor :width, :height, :depth, :color, :compression, :filtering, :interlace

      def initialize io
        super
        a = data.unpack('NNC5')
        @width = a[0]
        @height = a[1]
        @depth = a[2]
        @color = a[3]
        @compression = a[4]
        @filtering = a[5]
        @interlace = a[6]
      end

      def inspect
        super.sub(/ *>$/,'') + ", " +
          (instance_variables-[:@type, :@crc, :@data, :@size]).
          map{ |var| "#{var.to_s.tr('@','')}=#{instance_variable_get(var)}" }.
          join(", ") + ">"
      end
    end

    class PLTE < Chunk
    end

    class IEND < Chunk
    end
  end

  class Pixel
    attr_accessor :r, :g, :b, :a
    def initialize s, g=nil, b=nil
      if s.is_a?(String) && s.size == 3
        @r = s[0].ord
        @g = s[1].ord
        @b = s[2].ord
      elsif g && b
        @r = s & 0xff
        @g = g & 0xff
        @b = b & 0xff
      else
        raise "unknown pixel initializer: #{s.inspect}"
      end
    end

    def white?
      to_s == "FFFFFF"
    end

    def black?
      to_s == "000000"
    end

    def to_s
      "%02X%02X%02X" % [r,g,b]
    end
  end

  class Block
    attr_accessor :width, :height, :pixels
    def initialize image, x, y, w, h
      @width, @height = w,h
      @pixels = []
      h.times do |i|
        w.times do |j|
          @pixels << image[x+j,y+i]
        end
      end
    end

    def to_s
      a = []
      height.times do |i|
        b = []
        width.times do |j|
          b << pixels[i*width+j].to_s
        end
        a << b.join(" ")
      end
      a.join "\n"
    end

    def to_binary_string c_white = ' ', c_black = 'X'
      @pixels.each do |p|
        raise "pixel #{p.inspect} is not white nor black" if !p.white? && !p.black?
      end
      a = []
      height.times do |i|
        b = []
        width.times do |j|
          b << (pixels[i*width+j].black? ? c_black : c_white)
        end
        a << b.join(" ")
      end
      a.join "\n"
    end
  end

  class ScanLine
    FILTER_NONE           = 0
    FILTER_SUB            = 1
    FILTER_UP             = 2
    FILTER_AVERAGE        = 3
    FILTER_PAETH          = 4

    attr_accessor :image, :idx, :filter, :offset

    def initialize image, idx
      @image,@idx = image,idx
      @offset = idx*(image.width*3+1)
      @filter = image.imagedata[offset].ord
      @offset +=1
    end

    def inspect
      "#<ZPNG::ScanLine " + (instance_variables-[:@image, :@decoded]).
          map{ |var| "#{var.to_s.tr('@','')}=#{instance_variable_get(var)}" }.
          join(", ") + ">"
    end

    def [] x
      decoded[x]
    end

    def decoded
      @decoded ||= (0...@image.width).map{ |x| decode_pixel(x) }
    end

    def decode_pixel x
      cur = @image.imagedata[@offset+x*3,3]
      case @filter
      when FILTER_NONE
        Pixel.new(cur)
      when FILTER_SUB
        return Pixel.new(cur) if x == 0
        prevpixel = decode_pixel(x-1)
        Pixel.new(
          prevpixel.r + cur[0].ord,
          prevpixel.g + cur[1].ord,
          prevpixel.b + cur[2].ord
        )
      when FILTER_UP
        return Pixel.new(cur) if @idx == 0
        prevpixel = @image.scanlines[@idx-1][x]
        Pixel.new(
          prevpixel.r + cur[0].ord,
          prevpixel.g + cur[1].ord,
          prevpixel.b + cur[2].ord
        )
      when FILTER_PAETH
        a = (x > 0)    ? decode_pixel(x-1) : Pixel.new(0,0,0)
        b = (@idx > 0) ? @image.scanlines[@idx-1][x] : Pixel.new(0,0,0)
        c = (x > 0 && @idx > 0) ? @image.scanlines[@idx-1][x-1] : Pixel.new(0,0,0)
        Pixel.new(
          cur[0].ord + paeth_predictor(a.r,b.r,c.r),
          cur[1].ord + paeth_predictor(a.g,b.g,c.g),
          cur[2].ord + paeth_predictor(a.b,b.b,c.b)
        )
      else
        raise "invalid ScanLine filter #{@filter}"
      end
    end

    def paeth_predictor a,b,c
      p = a + b - c
      pa = (p - a).abs
      pb = (p - b).abs
      pc = (p - c).abs
      (pa <= pb) ? (pa <= pc ? a : c) : (pb <= pc ? b : c)
    end
  end

  class Image
    attr_accessor :data, :header, :chunks, :imagedata, :palette

    PNG_HDR = "\x89PNG\x0d\x0a\x1a\x0a"

    def initialize h = {}
      if h[:file] && h[:file].is_a?(String)
        @data = File.read(h[:file]).force_encoding('binary')
      end

      d = data[0,PNG_HDR.size]
      if d != PNG_HDR
        puts "[!] first #{PNG_HDR.size} bytes must be #{PNG_HDR.inspect}, but got #{d.inspect}".red
      end

      io = StringIO.new(data)
      io.seek PNG_HDR.size
      @chunks = []
      while !io.eof?
        chunk = Chunk.from_stream(io)
        @chunks << chunk
        case chunk
        when Chunk::IHDR
          @header = chunk
        when Chunk::PLTE
          @palette = chunk
        when Chunk::IEND
          break
        end
      end
      unless io.eof?
        offset    = io.tell
        extradata = io.read
        puts "[?] #{extradata.size} bytes of extra data after image end (IEND), offset = 0x#{offset.to_s(16)}".red
      end
    end

    def dump
      @chunks.each do |chunk|
        puts "[.] #{chunk.inspect} #{chunk.crc_ok? ? 'CRC OK'.green : 'CRC ERROR'.red}"
      end
    end

    def width
      @header && @header.width
    end

    def height
      @header && @header.height
    end

    def imagedata
      if @header
        raise "only RGB mode is supported for imagedata" if @header.color != 2
        raise "only non-interlaced mode is supported for imagedata" if @header.interlace != 0
      else
        puts "[?] no image header, assuming non-interlaced RGB".yellow
      end
      @imagedata ||=
        begin
          Zlib::Inflate.inflate(@chunks.find_all{ |c| c.type == "IDAT" }.map(&:data).join)
        end
    end

    def [] x, y
      scanlines[y][x]
    end

    def scanlines
      @scanlines ||=
        begin
          r = []
          height.times do |i|
            r << ScanLine.new(self,i)
          end
          r
        end
    end

    def extract_block x,y=nil,w=nil,h=nil
      if x.is_a?(Hash)
        Block.new(self,x[:x], x[:y], x[:width], x[:height])
      else
        Block.new(self,x,y,w,h)
      end
    end

    def each_block bw,bh, &block
      0.upto(height/bh-1) do |by|
        0.upto(width/bw-1) do |bx|
          b = extract_block(bx*bw, by*bh, bw, bh)
          yield b
        end
      end
    end
  end
end

if $0 == __FILE__
  if ARGV.size == 0
    puts "gimme a png filename!"
  else
    img = ZPNG::Image.new(:file => ARGV[0])
    img.dump
    puts "[.] image size #{img.width}x#{img.height}"
    puts "[.] uncompressed imagedata size=#{img.imagedata.size}"
    puts "[.] palette =#{img.palette}"
#    puts "[.] imagedata: #{img.imagedata[0..30].split('').map{|x| sprintf("%02X",x.ord)}.join(' ')}"


#    img.each_block(8,8) do |b|
#      s = b.to_binary_string('0','1')
#      p [s.count('0'), s.count('1')]
#    end

    puts

    tbl = (('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a).join + "+/_"

    blksz = 8

    #31.upto(img.height/blksz) do |y|
    31.upto(35) do |y|
      r = ''
      0.upto(img.width/blksz-1) do |x|
        b = img.extract_block x*blksz,y*blksz,blksz,blksz
        s = b.to_binary_string('0','1')
        c = s.count '0'
        r << tbl[c]
      end
      puts "[.] y=#{y}: #{r} #{r.size}"
      s = r.unpack('m*')[0]
      0.step(s.size-1,2) do |i|
        s[i+1],s[i] = s[i],s[i+1]
      end
      puts "[.] " + s.inspect
      #puts s
      #puts r.unpack('m*')[0]
    end

  end
end

