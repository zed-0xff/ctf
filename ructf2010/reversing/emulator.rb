#!/usr/bin/ruby

STDOUT.sync = true

class Emulator
  attr_accessor :do_run, :output, :do_memdump

  def initialize
    @do_run = false
    @stop   = false
    @prg    = 0.chr * 0x10000
    @output = ''

    def @prg.store_word(ptr, word)
      self[ptr]   = word & 0xff
      self[ptr+1] = word >> 8
      word
    end

    def @prg.get_word(ptr)
      raise "Memory access out of range: #{ptr.inspect}" if ptr < 0 || ptr >= 0xffff
      self[ptr] + (self[ptr+1] << 8)
    end

    if "a"[0] == 'a'
      # ruby1.9
      STDERR.puts "[!] WARNING! there's some uncatched bug when using ruby 1.9 with 'set' program"
      def @prg.[](idx,size=nil)
        if size
          super
        else
          getbyte(idx)
        end
      end
      def @prg.[]=(idx,b)
        setbyte(idx,b.is_a?(String) ? b.getbyte(0) : b)
      end
    end
  end

  def prg; @prg; end
  def program; @prg; end

  def program= prg
    #@prg[0,prg.size] = prg
    0.upto(prg.size-1) do |i|
      @prg[i] = prg[i]
    end
  end

  # установка внешнего аргумента программы ( аналог &arg=XXXXXXXXX в урле )
  def arg= arg
    #@prg[0x8000,arg.size] = arg
    0.upto(arg.size-1) do |i|
      @prg[0x8000+i] = arg[i]
    end
  end

  def run!
    @do_run = true
    @trace  = false
    go!
  end

  def trace!
    @do_run = true
    @trace  = true
    go!
  end

  def disasm!
    @do_run = false
    @trace  = true
    go!
  end

  private

  # N-й аргумент текущего оператора, по дефолту 0-й аргумент
  def arg id=0
    (@prg[@pos+1+id*2]<<8) + @prg[@pos+id*2]
  end

  def stop!
    @stop = true
  end

  def mem
    @prg
  end

  def push word
    @prg.store_word(@sp, word)
    @sp -= 2
  end

  def pop
    @sp += 2
    @prg.get_word(@sp)
  end

  def dump_stack
    printf "== SP: %04x:\t",@sp if @trace
    pos = @sp
    100.times do |i|
      break if pos >= 0x0fffe
      pos += 2
      printf "%04x ", mem.get_word(pos) if @trace
      print "\n\t\t" if (i+1)%8==0
    end
    puts
  end

  def dump_mem ptr
    printf "%04x: ", ptr if @trace
    8.times do
      printf "%04x ",mem.get_word(ptr) if @trace
      ptr += 2
    end
    puts
  end

  def go!
    @sp  = @bp = 0x0fffe
    @pos = 0

    begin

    while !@stop
      raise "no prg" if !@prg || @prg.size == 0

      if ARGV[1] == 'fact' && @pos == 0x85 && !do_run
        @pos = 0x87
      end

      if ARGV[1] == 'fact' && @pos == 0x8e && !do_run
        @pos = 0x90
      end

      b = @prg[@pos]
      #dump_stack
      printf "ip=%03x sp=%04x bp=%04x b=%02x\t",@pos,@sp,@bp,b if @trace
      case b
        when 0
          @pos += 1
          printf "mov [%04x], %04x (%4d)",arg,arg(1),arg(1) if @trace
          mem.store_word(arg,arg(1)) if do_run
          @pos += 4
        when 1
          @pos += 1
          printf "mov [%04x], [%04x]",arg,arg(1) if @trace
          printf "\t\t\t(%x)", mem.get_word(arg(1)) if @trace
          mem.store_word(arg, mem.get_word(arg(1))) if do_run
          @pos += 4
        when 2
          @pos += 1
          printf "add [%04x], [%04x]",arg,arg(1) if @trace
          printf "\t\t\t(%x, %x)", mem.get_word(arg), mem.get_word(arg(1)) if @trace
          #printf("\n\t\t\t%04x",mem.get_word(arg)) if @trace
          mem.store_word(arg, mem.get_word(arg) + mem.get_word(arg(1))) if do_run
          #printf("\n\t\t\t%04x",mem.get_word(arg)) if @trace
          @pos += 4
        when 3
          @pos += 1
          printf "[%04x] -= [%04x]", arg, arg(1) if @trace
          printf "\t\t\t(%x, %x)", mem.get_word(arg), mem.get_word(arg(1)) if @trace
          mem.store_word(arg, mem.get_word(arg) - mem.get_word(arg(1))) if do_run
          @pos += 4
        when 4
          @pos += 1
          printf "mul [%04x], [%04x]", arg, arg(1) if @trace
          printf "\t\t\t(%x, %x)", mem.get_word(arg), mem.get_word(arg(1)) if @trace
          mem.store_word(arg, mem.get_word(arg) * mem.get_word(arg(1))) if do_run
          @pos += 4
        when 5
          @pos += 1
          printf "goto %04x",arg if @trace
          if do_run
            @pos = arg
          else
            @pos += 2
          end
        when 6
          @pos += 1
          printf "goto %04x if [%04x] == [%04x]",arg,arg(1),arg(2) if @trace
          printf "\t\t(%x, %x) %s", mem.get_word(arg(1)), mem.get_word(arg(2)),
            mem.get_word(arg(1)) == mem.get_word(arg(2)) ? "JUMP" : "" if @trace

          if mem.get_word(arg(1)) == mem.get_word(arg(2)) && do_run
            @pos = arg
          else
            @pos += 6
          end
        when 7
          @pos += 1
          printf "goto %04x if [%04x] > [%04x]",arg,arg(1),arg(2) if @trace
          if mem.get_word(arg(1)) > mem.get_word(arg(2)) && do_run
            @pos = arg
          else
            @pos += 6
          end
        when 8
          @pos += 1
          printf "goto %04x if [%04x] < [%04x]\t\t(%x, %x)",arg,arg(1),arg(2),
            mem.get_word(arg(1)), mem.get_word(arg(2)) if @trace
          if mem.get_word(arg(1)) < mem.get_word(arg(2)) && do_run
            @pos = arg
          else
            @pos += 6
          end
        when 9
          @pos += 1
          printf "call %04x",arg if @trace
          if do_run
            puts if @trace
            push(@pos+2)
            @pos = arg
          else
            @pos += 2
          end
        when 0x0a
          @pos += 1
          printf "ret %04x\n",arg if @trace
          if do_run
            v = arg
            @pos = pop
            @sp += v
          end
        when 0x0b
          @pos += 1
          printf "[%04x] (%4d) /= [%04x] (%4d)", arg, mem.get_word(arg), arg(1), mem.get_word(arg(1)) if @trace
          printf "\n\t\t\t div %04x / %04x = %04x", mem.get_word(arg), mem.get_word(arg(1)),
            mem.get_word(arg) / mem.get_word(arg(1)) if do_run && @trace
          mem.store_word(arg, mem.get_word(arg) / mem.get_word(arg(1))) if do_run
          @pos += 4
        when 0x11
          @pos += 1
          @outpos ||= 0
          printf "putchar from [%04x] to outfile (pos=%d)",arg,@outpos if @trace
          @outpos += 1
          @pos += 2
        when 0x12
          @pos += 1
          printf "putchar from [%04x = %04x]: %s (%02x)",arg,
            mem.get_word(arg),
            prg[mem.get_word(arg)].chr.inspect,
            prg[mem.get_word(arg)] if @trace
          @output += sprintf("%c",prg[mem.get_word(arg)]) if do_run
          @pos += 2
        when 0x20
          @pos += 1
          printf "push [%04x]",arg if @trace
          t = mem.get_word(arg)
          printf "\t\t\t\t(%x)",t if @trace
          push t
          @pos += 2
        when 0x22
          @pos += 1
          # enter
          printf "t1=bp; t2=sp; bp=sp; sp -= %04x; push t2,t1",arg if @trace
          v = arg
          t1 = @bp
          t2 = @sp
          @bp = @sp
          @sp -= v
          push t2
          push t1
          @pos += 2
        when 0x23
          @pos += 1
          @bp = pop if do_run
          @sp = pop if do_run
          printf "pop bp,sp" if @trace
        when 0x24
          @pos += 1
          printf "[%04x] = bp",arg if @trace
          mem.store_word(arg,@bp)
          @pos += 2
        when 0x25
          @pos += 1
          printf "?ptr [%04x], [[%04x]]",arg,arg(1) if @trace
          t = mem.get_word(mem.get_word(arg(1)))
          printf "\t\t\t(%x)", t if @trace
          mem.store_word(arg, t) if do_run
          @pos += 4
        when 0x26
          @pos += 1
          printf "?movptr [[%04x]], [%04x]",arg,arg(1) if @trace
          t = mem.get_word(arg(1))
          printf "\t\t(%x, %x)", mem.get_word(arg),t if @trace
          mem.store_word(mem.get_word(arg), t) if do_run
          @pos += 4
        when 0x30
          @pos += 1
          puts "[*] EXIT" if @trace
          stop! if do_run
        when 0x42
          @pos += 1
          printf "printf(\"%%hu\", [%04x]): \"%d\"", arg, mem.get_word(arg) if @trace
          @output += mem.get_word(arg).to_s
          @pos += 2
        when 0x43
          @pos += 1
          printf "[%04x] = atoi([%04x])", arg, arg(1) if @trace
          mem.store_word(arg, mem[mem.get_word(arg(1)),10].to_i) if do_run
          printf "\t\t\t%04x (%d)", mem.get_word(arg), mem.get_word(arg) if @trace
          @pos += 4
        else
          printf "[!] unknown bytecode %02x at pos %04x\n", b, @pos
          stop!
      end
      puts if @trace
    end

    ensure

    if @trace || @do_memdump
      puts
      puts
      (@pos & 0xfffe).step(0x10000-2,2) do |addr|
        w = mem.get_word(addr)
        printf "mem[%04x] = %04x (%5d)\n", addr, w, w unless w == 0
      end
      #p mem[0x4b3,0x100]
      puts "OUTPUT:\n#{@output.inspect}"
    else
      puts @output
    end
    end
  end
end

if ARGV.size < 2 || !%w'r d t'.include?(ARGV.first[0,1])
  puts <<-EOF
Usage: #{$0} <cmd> <filename> [arg]
  cmd can be 'run', 'trace' or 'disasm'
  EOF
  exit
end

fname = ARGV[1]
emu = Emulator.new
emu.program = File.read(fname)
emu.arg = ARGV[2] if ARGV[2]

case ARGV.first[0,1]
when 'r'
  emu.do_memdump = true if ARGV.first['m']
  emu.run!
when 'd'
  emu.disasm!
when 't'
  emu.trace!
else
  raise "invalid cmd #{ARGV.first.inspect}"
end


