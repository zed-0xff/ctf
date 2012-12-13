require './string.rb'
require './libmem.rb'
require './libcrypt.rb'
require './service.rb'

EXIT = 0
READB = 1
WRITEB = 2
READW = 3
WRITEW = 4
EXEC = 5
BREAK = 6
STEP = 7
OPEN = 8
CORE = 9
CLOSE = 10
CLOCK = 11


class CodeGen
  Instructions = [:add, :sub, :mul, :div, :mod, :rol, :band, :bor, :not, :xor, :cmp, :mov, :ldw, :jmp, :jnz, :jz, :sys]
  Registers = [:eq, :smaller, :bigger, :ip, :t0, :t1, :t2, :t3, :t4, :t5, :t6, :t7]
  Int_opt= 2
  Ptr_opt= 1
  Reg_opt= 0

  def initialize
    @instr = []
    @labels = {}
    @namespaces = [""]
    @id=0
  end

  def get_uid()
    @id+=1
    return @id
  end

  def asm(&blck)
    self.instance_eval(&blck)
  end

  def eq; [:reg, :eq]; end
  def bigger; [:reg, :bigger]; end
  def smaller; [:reg, :smaller]; end
  def ip; [:reg, :ip]; end
  def t0; [:reg, :t0]; end
  def t1; [:reg, :t1]; end
  def t2; [:reg, :t2]; end
  def t3; [:reg, :t3]; end
  def t4; [:reg, :t4]; end
  def t5; [:reg, :t5]; end
  def t6; [:reg, :t6]; end
  def t7; [:reg, :t7]; end

  def compile_opcode(op)
    Instructions.index op
  end

  def compile_reg(reg)
    Registers.index reg
  end

  def compile_arg(arg)
    case arg
      when Fixnum, Bignum then
        raise "warning oversize argument #{arg}" if arg > 255
        return [Int_opt,arg]
      when Array then
      if arg.length == 1
        return [Ptr_opt,compile_reg(arg[0][1])]
      else
        return [Reg_opt,compile_reg(arg[1])]
      end
    end
  end

  def compile(instr)
    puts instr.inspect
    return instr[1] if instr.first == :data

    opcode,src,dst = instr
    opts,srcb = compile_arg(src)
    optd,dstb = compile_arg(dst)
    opc = compile_opcode(opcode)
    bytes = [opc, opts | optd*4,srcb,dstb].reverse
    return bytes.map(&:chr).join("").unpack("L<").first
  end


  def gather_labels()
    stripped = []
    @instr.each do |x|
      if x.first == :label
        @labels[x.last]=stripped.length
      else
        stripped<<x
      end
    end
    @instr = stripped
  end

  def replace_labels(instr)
    return lookup(instr.last) if instr.is_a? Array and instr.first == :ref
    return instr.map{|x| replace_labels(x)} if instr.is_a? Array
    return instr
  end

  def lookup(name)
    return @labels[name] if @labels.include? name
    path = name.split("::") # produces a empty string in front of the path ["", "main", ..] etc
    prefix = path[0..-3]
    symbol = path.last
    while prefix.length > 0
      newname = (prefix+[symbol]).join("::")
      puts newname
      return @labels[newname] if @labels.include? newname
      prefix = prefix[0..-2]
    end
    raise "unable to locate symbol #{name}"
  end

  def generate()
    return @instr if @generated
    @generated = true
    puts @instr.map.with_index{|x,i| i.to_s+" "+x.inspect}
    puts ""
    gather_labels()
    puts "gathering labels"
#   puts @instr.map.with_index{|x,i| i.to_s+" "+x.inspect}
    puts ""
    @instr.map! {|x| replace_labels(x)}
    puts "repalced labels"
#   puts @instr.map.with_index{|x,i| i.to_s+" "+x.inspect}
    puts ""
    @instr.map! {|instr| compile(instr)}
    puts "compiled instructions"
#   puts @instr.map(&:inspect)
    return @instr
  end

  def to_go
    "package data\n"+
    "var Memory = []uint{ 0x#{self.generate.map{|x| x.to_s(16).rjust(8,"0")}.join(", 0x")} }\n"+
    "var Labels = map[string]int{ #{@labels.each_pair.map{|(s,i)| s.inspect+":"+i.to_s}.join(", ")} }"
  end

  def instr(code,dst,src); @instr<<[code,dst,src]; end

  def op(code,l,r); instr(code,l,r) end
  def ldw(l,r); op(:ldw,l,0); data(r);  end
  def add(l,r); op(:add,l,r); end
  def sub(l,r); op(:sub,l,r); end
  def div(l,r); op(:div,l,r); end
  def mod(l,r); op(:mod,l,r); end
  def rol(l,r); op(:rol,l,r); end
  def mul(l,r); op(:mul,l,r); end
  def band(l,r); op(:band,l,r); end
  def bor (l,r); op(:bor,l,r); end
  def xor (l,r); op(:xor,l,r); end
  def not(l,r); op(:not,l,r); end
  def mov(l,r); op(:mov,l,r); end
  def cmp(l,r); op(:cmp,l,r); end
  def jmp(l);   instr(:jmp,l,0); end
  def jnz(target,cond); instr(:jnz,target,cond); end
  def jz(target,cond); instr(:jz,target,cond); end
  def sys(l,r); op(:sys,l,r); end
  def data(val); instr(:data,val,0); end


  def mk_label(name)
      if name =~ /^::/ then
        return name
      elsif name =~ /^:/
        return "#{@namespaces[0..-2].join("::")}::#{name[1..-1]}"
      else
        return "#{@namespaces.join("::")}::#{name}"
      end
  end

  def label(name); @instr << [:label, mk_label(name.to_s)] end
  def ref(name); [:ref,mk_label(name.to_s)]; end

#macros
  def inc(t);         add t,1; end
  def dec(t);         sub t,1; end
  def push_one(l);    add t7, 1; mov [t7],l; end
  def pop_one(l);     mov l, [t7]; mov [t7],0; sub t7,1; end
  def call(l);        mov t6,ip; add t6,5; push t6; jmp l; end
  def ret;            pop t6; jmp t6; end

  def push(*args)
    args.each do |arg|
      push_one(arg)
    end
  end

  def pop(*args)
    args.reverse.each do |arg|
      pop_one(arg)
    end
  end

  def set(name, val)
    ldw t6, ref(name)
    mov [t6], val
  end

  def get(name, val)
    ldw t6, ref(name)
    mov  val, [t6]
  end

  def get_offset(target, ptr,offset)
    mov t6, ptr
    add t6,offset
    mov target, [t6]
  end

  def set_offset(ptr, offset,val)
    mov t6,ptr
    add t6,offset
    mov [t6], val
  end

  def mk_target(x)
    case x
      when String,Symbol
        return ref(x)
      else return x
    end
  end

  def jmp_to(target); ldw t6, mk_target(target); jmp t6; end
  def jnz_to(target,cond); ldw t6, mk_target(target); jnz t6, cond; end
  def jz_to(target,cond);  ldw t6, mk_target(target); jz t6, cond; end
  def call_to(target, reg = t5);     ldw reg, mk_target(target); mov t6,ip; add t6,5; push t6; jmp reg; end

  def char(str)
    str.each_codepoint.first
  end

  def const(name, val)
    case val
      when String
        label(name); val.each_codepoint{|x| data(x)};data(0)
      when Fixnum,Bignum
        label(name); data(val)
      else
        raise "unable to use that as constant #{val}"
    end
  end

  def namespace(name, &block)
    @namespaces<<name
    block.call
    @namespaces.pop
  end

  def function(name, &block)
    namespace name do
      label(":#{name}")
      block.call
      label "#{name}_exit"
      ret
    end
  end

  def jmp_unless(val1,op,val2, if_label)
    cmp val1, val2
    case op
      when :== then
        jz_to ref(if_label), eq
      when :"!=" then
        jnz_to ref(if_label), eq
      when :< then
        jz_to ref(if_label), smaller
      when :> then
        jz_to ref(if_label), bigger
      when :>= then
        jnz_to ref(if_label), smaller
      when :<= then
        jnz_to ref(if_label), bigger
      else
        raise "invalid op for if #{op}"
    end
  end

  def jmp_if(val1,op,val2, if_label)
    cmp val1, val2
    case op
      when :== then
        jnz_to ref(if_label), eq
      when :"!=" then
        jz_to ref(if_label), eq
      when :< then
        jnz_to ref(if_label), smaller
      when :> then
        jnz_to ref(if_label), bigger
      when :>= then
        jz_to ref(if_label), smaller
      when :<= then
        jz_to ref(if_label), bigger
      else
        raise "invalid op for if #{op}"
    end
  end

  def until_loop(*cmps,&block)
    loop_end = "loop_#{get_uid}_end"
    jmp_if(*cmps,loop_end)
    block.call
    label loop_end
  end

  def loop_while(*cmps,&block)
    loop_begin = "loop_#{get_uid}_begin"
    label loop_begin
    block.call
    jmp_if(*cmps,loop_begin)
  end

  def generate_if(val1,op,val2, if_label, else_label, &block)
    jmp_unless(val1,op,val2, if_label)
    block.call()
    jmp_to else_label if else_label!=if_label
    label if_label
  end

  def if_then(a1, op, a2, &blk)
    id = get_uid()
    generate_if(a1,op,a2, "if_#{id}_#{[a1,op,a2].inspect}","if_#{id}_#{[a1,op,a2].inspect}",&blk)
    return nil
  end

  class Else
    def initialize(codegen,label); @codegen,@label=codegen,label; end
    def else(&blk)
      @codegen.instance_eval(&blk)
      @codegen.label(@label)
    end
  end

  def if_else(a1,op,a2, &blk)
    id = get_uid()
    generate_if(a1,op,a2, "if_#{id}_#{[a1,op,a2].inspect}", "else_#{id}_#{[a1,op,a2].inspect}", &blk)
    return Else.new(self,"else_#{id}_#{[a1,op,a2].inspect}")
  end

  def import (x)
    x.code(self)
  end

  def prints(str)
    push t1
    jmp_to "print "+str
    const str,str
    label("print "+str)
    ldw t1, ref(str)
    call_to :printstrln
    pop t1
  end

  def printi(int)
    push t1,t2
    mov t1, int
    ldw t2, ref(:numbuffer)
    call_to :itou
    ldw t1, ref(:numbuffer)
    call_to :printstrln
    pop t1,t2
  end
end

asm = CodeGen.new
asm.asm do
  ldw t0, ref(:entermain)
  jmp_to :init_mem
  label :entermain
  call_to :main
  sys EXIT,0

  function :main do
    def buffer; t1; end
    def length; t2; end
    ldw buffer, ref(:hashbuffer)
    ldw length, 4
#call_to :hash
#call_to :printi
    call_to :server
    ret

    label :hashbuffer
    data 1
    data 2
    data 3
    data 4
  end

  import(StringCode.new)
  import(MemCode.new)
  import(CryptCode.new)
  import(ServiceCode.new)
end

File.open("data/img.go","w") do |f|
  f.puts asm.to_go
end

puts asm.to_go
