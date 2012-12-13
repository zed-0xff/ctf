package cpu
import (
		"errors"
		"fmt"
		)

type Arg interface {
	SetVal(value int) error
	GetVal() (int, error)
	Inspect() string
}

type ImmediateArg struct {
	Val int
}

func NewImmArg(val int) (arg *ImmediateArg){
	arg = new(ImmediateArg)
	arg.Val = val
	return
}


func (s *ImmediateArg) Inspect() (res string) {
	res = hex(s.Val)
	return
}

func (arg *ImmediateArg) SetVal(value int) (err error) {
	err = errors.New("Tried to set immediate argument")
	return
}

func (arg *ImmediateArg) GetVal() (val int, err error) {
	val, err = arg.Val, nil
	return
}

type RegisterArg struct {
	Reg Register
	Cpu *CPU
}
func Report(err error){
	if err != nil {
		fmt.Println(err.Error())
	}
}

func (s *RegisterArg) Inspect() (res string) {
	regval,err := s.Cpu.GetRegister(s.Reg)
	Report(err)
	res = regnames[int(s.Reg)]+"("+hex(regval)+ ")"
	return
}

func NewRegArg(val int, c *CPU) (arg *RegisterArg){
	arg = new(RegisterArg)
	arg.Reg = Register(val)
	arg.Cpu = c
	return
}

func (arg *RegisterArg) SetVal(value int) error {
	return arg.Cpu.SetRegister(arg.Reg, value)
}

func (arg *RegisterArg) GetVal() (int, error) {
	return arg.Cpu.GetRegister(arg.Reg)
}

type PtrArg struct {
	Reg Register
	Cpu  *CPU
}

func (s *PtrArg) Inspect() (res string) {
	regval,err := s.Cpu.GetRegister(s.Reg)
	Report(err)
	memval,err := s.Cpu.GetMemory(regval)
	Report(err)
	res = "["+regnames[int(s.Reg)]+"("+hex(int(regval))+")]("+hex(memval)+")"
	return
}

func NewPtrArg(val int, c *CPU) (arg *PtrArg){
	arg = new(PtrArg)
	arg.Reg = Register(val)
	arg.Cpu = c
	return 
}

func (arg *PtrArg) SetVal(value int) error {
	addr, err := arg.Cpu.GetRegister(arg.Reg)
	if err != nil { return err }
	return arg.Cpu.SetMemory(addr, value)
}

func (arg *PtrArg) GetVal() (int, error) {
	addr, err := arg.Cpu.GetRegister(arg.Reg)
	if err != nil { return 0,err }
	return arg.Cpu.GetMemory(addr)
}

type Register int

var regnames []string = []string{"eq", "smaller", "bigger", "ip", "t0","t1","t2","t3","t4","t5","t6","t7" }
const (
	eq Register = iota
	smaller
	bigger
	ip
	t0
	t1
	t2
	t3
	t4
	t5
	t6
	t7
)

type Opcode int

var opnames []string = []string{"add","sub","mul","div","mod","rol", "and","or","not","xor", "cmp", "mov", "ldw", "jmp", "jnz","jz", "sys"}
const (
	add Opcode = iota
	sub
	mul
	div
	mod
	rol
	and
	or
	not
	xor
	cmp
	mov
	ldw
	jmp
	jnz
	jz
	sys
)

func urol(val,offset uint32) uint32{
	offset = offset % 32
	var divisor uint32 = 1<<(32-offset)
	if divisor == 0 {
		return val
	}
	return (val << offset) | (val / divisor)
}

var arith = map[Opcode](func(int, int) int){
	add:  func(l, r int) int {  fmt.Println("[.] R="+hex(l+r)+"\n"); return l + r },
	sub: func(l, r int) int {   fmt.Println("[.] R="+hex(l-r)+"\n"); return l - r },
	mul:  func(l, r int) int  { fmt.Println("[.] R="+hex(l*r)+"\n"); return l * r },
	div:   func(l, r int) int { if r != 0 {return l / r}; return 0 },
	mod:   func(l, r int) int { if r != 0 {return l % r}; return 0},
	rol:   func(l, r int) int { return int(urol(uint32(l),uint32(r)))},
	xor:   func(l, r int) int { fmt.Println("[.] R="+hex(l^r)+"\n"); return l ^ r },
	and:   func(l, r int) int { return l & r },
	or:    func(l, r int) int { return l | r },
	not:   func(l, r int) int { return ^r },
	mov:   func(l, r int) int { return r },
}

type Instruction struct {
	Instr Opcode
	Cpu   *CPU
	Src   Arg
	Dst   Arg
}


func (s *Instruction) Inspect() (res string) {
	res = "<"
	res += opnames[int(s.Instr)] + " "+ s.Dst.Inspect() +" "+ s.Src.Inspect() +" >"
	return
}

func (self *Instruction) Exec() error {
	ipval, err := self.Cpu.GetRegister(ip)
	if err != nil {
		return err
	}
	l, err := self.Dst.GetVal()
	if err != nil {
		return err
	}
	r, err := self.Src.GetVal()
	if err != nil {
		return err
	}

	if f, is_arith := arith[self.Instr]; is_arith {
		res, eqval, biggerval, smallerval := f(l, r), 0, 0, 0
		if res == 0 { eqval = 1 }
		if res < 0 { smallerval = 1 }
		if res > 0 { biggerval = 1 }
		err = self.Cpu.SetRegister(eq, eqval)
		err = self.Cpu.SetRegister(bigger, biggerval)
		err = self.Cpu.SetRegister(smaller, smallerval)
		if err != nil {
			return err
		}

		err = self.Dst.SetVal(res)
		if err != nil {
			return err
		}
		self.Cpu.SetRegister(ip, ipval+1)
		return nil
	}

	switch self.Instr {
	case cmp:
		eqval, biggerval, smallerval :=  0, 0, 0
		if l == r { eqval = 1 }
		if l < r  { smallerval = 1 }
		if l > r { biggerval = 1 }
		err = self.Cpu.SetRegister(eq, eqval)
		err = self.Cpu.SetRegister(bigger, biggerval)
		err = self.Cpu.SetRegister(smaller, smallerval)
		if err != nil {
			return err
		}
		return self.Cpu.SetRegister(ip, ipval+1)
	case ldw:
		mem,err := self.Cpu.GetMemory(ipval+1)
		if err != nil { return err }
		err = self.Dst.SetVal(mem)
		if err != nil { return err }
		return self.Cpu.SetRegister(ip, ipval+2)
	case jmp:
		return self.Cpu.SetRegister(ip, l)
	case jnz:
		if r == 0 {
			return self.Cpu.SetRegister(ip, ipval+1)
		} else {
			return self.Cpu.SetRegister(ip,l)
		}
	case jz:
		if r == 0 {
			return self.Cpu.SetRegister(ip, l)
		} else {
			return self.Cpu.SetRegister(ip, ipval+1)
		}
	case sys:
		err := self.Cpu.Sys(Syscall(l),r)
		if err != nil { return err }
		return self.Cpu.SetRegister(ip, ipval+1)
	default:
			return errors.New("Invalid Opcode")
	}
	return nil
}
