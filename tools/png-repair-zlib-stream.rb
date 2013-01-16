#!/usr/bin/env ruby
require 'zpng'
require 'rainbow'

fname = ARGV.first || "b1.png"
@im0 = ZPNG::Image.load fname, :verbose => -2

@idat = @im0.chunks.find{ |c| c.is_a?(ZPNG::Chunk::IDAT) }

#data[9057,498] = data[9057+498,498]
#fname = "out/%06d.png" % 0
#File.open(fname,"wb"){ |f| f<<data }
#exit

#@want_colors = %w'#EC4A0B #D3FFFF #fff #FFFFB8 8E060A'
@want_colors = %w'#EC4A0B C8FAF8 #fff #FFFFB8 8E060A'
@want_colors += ["4f060a"]*5
@want_colors << '3C5116'
@want_colors << '4f060a'

@start = 0x2306; @x,@y = 142,132; img = nil; @bidx = 0
#@bytes = [0] #[0, 20, 0, 0, 1, 0, 0, 0, 0, 2, 0]
@bytes = [0] #, 176]

@want_colors.map!{|c| ZPNG::Color.from_html(c) }

NSEQ = 5

# accepts single color or array of colors
def s256 x
  a = x.is_a?(Array) ? x : [x]
  a.map{ |c| "  ".background(c.to_s) }.join + " " + a.map(&:to_s).join(', ')
end

def get_color h = {}
  img = h[:img] || @im0.clone
  img[@x,@y]
end

def patch!
  return unless @bytes[@bidx]
  puts "[.] patch ##@bidx"
  @idat.data.setbyte(@start+@bidx, @bytes[@bidx])
  @bidx += 1
  true
end

def check_colors
  @want_colors.each_with_index do |wc,idx|
    hc = get_color
    printf "[.] x=#{@x}, y=#{@y}, have=#{s256(hc)} want=#{s256(@want_colors[idx,4])}\n"
    if hc != wc
      if patch!
        redo
      else
        return idx
      end
    end

    @x += 1
    @x,@y=0,@y+1 if @x >= @im0.width
  end
end

def get_colors h = {}
  img = h[:img] || @im0.clone
  NSEQ.times.map{ |i| img[@x+i,@y] }
end

def print_colors colors, title
  printf "  %s : %s\n", s256(colors), title
end

def process
  idx = check_colors

  print_colors @want_colors[idx,NSEQ], "x=#@x, y=#@y"

  h = Hash.new{|k,v| k[v]=[]}
  256.times do |bytevalue|
    @idat.data.setbyte(@start+@bidx, bytevalue)
    h[get_colors] << bytevalue
  end

  puts "  " + ".."*NSEQ
  h.sort_by(&:first).each do |colors,bytes|
    #printf "  %s : %s\n", s256(colors), bytes[0,10].inspect
    print_colors colors, bytes[0,10].inspect
  end
end

process

__END__

    next if @bytes[idx]

    wc = @want_colors[idx]

    idx.times{ |i| @bytes[i] && @idat.data.setbyte(@start+i, @bytes[i]) }

    h = Hash.new{|k,v| k[v]=[]}
    h2 = Hash.new{|k,v| k[v]=[]}

    r = 256.times do |bytevalue|
          @idat.data.setbyte(@start+idx, bytevalue)
          img = @im0.clone
          #img.save "b2.png"
          c = img[@x, @y]
          h[c] << bytevalue

          c2 = img[@x+1, @y]
          h2[[c,c2]] << bytevalue

          #break bytevalue if c == wc
        end

    if r < 256
      # found
      @bytes << r
    else
      @bytes << nil
      puts "[.] select pixel from (#{@x}, #{@y}):"
      h.sort_by(&:first).each do |c,a|
        puts "  #{c.to_html} :#{"  ".background(c.to_html)}: #{a[0,10].inspect}"
      end
      h2.sort_by(&:first).each do |c,a|
        c1,c2 = c
        puts [
          "  " + c.map(&:to_html).join(' '),
          "  ".background(c1.to_html) + "  ".background(c2.to_html),
          a[0,10].inspect
        ].join(": ")
      end
      break
    end
  end

img.save "b2.png"

p @bytes
