#!/usr/bin/ruby

STDOUT.sync = true

fname = ARGV.first

@prg = File.read(fname)
@pos = 0

def prg
  @prg
end

def arg id=0
  (@prg[@pos+1+id*2]<<8) + @prg[@pos+id*2]
end

def do_run
  ARGV[1] == 'run'
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

@prg << 0 while @prg.size < 0x0f000

@sp = @bp = 0x0e000

def @prg.store_word(ptr, word)
  self[ptr]   = word & 0xff
  self[ptr+1] = word >> 8
  word
end

def @prg.get_word(ptr)
  self[ptr] + (self[ptr+1] << 8)
end

output = ""
@stop = false

def dump_stack
  printf "== SP: "
  pos = @sp
  4.times do
    break if pos >= 0x0e000
    pos += 2
    printf "%04x ", mem.get_word(pos)
  end
  puts
end

begin

while !@stop
  raise "no prg" if !@prg || @prg.size == 0

  b = @prg[@pos]
  #dump_stack
  printf "pos=%04x sp=%05x b=%02x\t",@pos,@sp,b
  case b
    when 0:
      @pos += 1
      printf "mov [%04x], %04x (%4d)",arg,arg(1),arg(1)
      mem.store_word(arg,arg(1))
      @pos += 4
    when 1:
      @pos += 1
      printf "mov [%04x], [%04x]",arg,arg(1)
      mem.store_word(arg, mem.get_word(arg(1)))
      #mem[arg] = mem[arg(1)]
      @pos += 4
    when 2:
      @pos += 1
      printf "add [%04x], [%04x]",arg,arg(1)
      mem.store_word(arg, mem.get_word(arg) + mem.get_word(arg(1)))
      @pos += 4
    when 3:
      @pos += 1
      printf "[%04x] -= [%04x]", arg, arg(1)
      mem.store_word(arg, mem.get_word(arg) - mem.get_word(arg(1)))
      @pos += 4
    when 4:
      @pos += 1
      printf "[%04x] *= [%04x]", arg, arg(1)
      mem.store_word(arg, mem.get_word(arg) * mem.get_word(arg(1)))
      @pos += 4
    when 5:
      @pos += 1
      printf "goto %04x",arg
      if do_run
        @pos = arg
      else
        @pos += 2
      end
    when 6:
      @pos += 1
      printf "goto %04x if [%04x] == [%04x]",arg,arg(1),arg(2)
      if mem.get_word(arg(1)) == mem.get_word(arg(2)) && do_run
        @pos = arg 
      else
        @pos += 6
      end
    when 7:
      @pos += 1
      printf "goto %04x if [%04x] > [%04x]",arg,arg(1),arg(2)
      if mem.get_word(arg(1)) > mem.get_word(arg(2)) && do_run
        @pos = arg 
      else
        @pos += 6
      end
    when 9:
      @pos += 1
      printf "call %04x",arg
      if do_run
        push(@pos+2)
        @pos = arg
      else
        @pos += 2
      end
    when 0x0a
      @pos += 1
      printf "ret"
      if do_run
        @pos = pop
      end
    when 0x0b:
      @pos += 1
      printf "[%04x] (%4d) /= [%04x] (%4d)", arg, mem.get_word(arg), arg(1), mem.get_word(arg(1))
      #mem[arg] /= mem[arg(1)]
      mem.store_word(arg, mem.get_word(arg) / mem.get_word(arg(1)))
      @pos += 4
    when 0x11:
      @pos += 1
      printf "putchar from [%04x] to outfile",arg
      @pos += 2
    when 0x12:
      @pos += 1
      printf "putchar from [%04x]: '%c' (%02x)",arg,prg[mem[arg]],prg[mem[arg]]
      output += sprintf("%c",prg[mem[arg]])
      @pos += 2
    when 0x20:
      @pos += 1
      printf "push %04x",arg
      push arg
      @pos += 2
    when 0x22:
      @pos += 1
      printf "t1=bp; t2=sp; bp=sp; sp -= %04x; push t2,t1",arg
      v = arg
      t1 = @bp
      t2 = @sp
      @bp = @sp
      @sp -= v
      push t2
      push t1
      @pos += 2
    when 0x23:
      @pos += 1
      @bp = pop
      @sp = pop
      printf "pop bp,sp"
    when 0x24:
      @pos += 1
      printf "[%04x] = bp",arg
      @pos += 2
    when 0x25:
      @pos += 1
      printf "?mov [%04x], [[%04x]] (%5d)",arg,arg(1), prg[arg(1)]
      mem.store_word(arg, mem.get_word(arg(1)))
      @pos += 4
    when 0x30:
      puts "[*] EXIT"
      stop!
    when 0x42:
      @pos += 1
      printf "printf([%04x]): \"%d\"", arg, prg[arg]
      output += prg[arg].to_s
      @pos += 2
    else
      puts "[!] unknown bytecode #{b.to_s(16)} at pos #{@pos.to_s(16)}"
      stop!
  end
  puts
end

ensure

puts
puts
(0x9000...0x10000).each do |addr|
  printf("mem[%04x] = %04x (%4d)\n", addr,mem[addr],mem[addr]) if mem[addr].to_i != 0
end
print "out = #{output.inspect}"
end
