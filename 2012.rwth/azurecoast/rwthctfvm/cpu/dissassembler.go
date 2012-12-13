package cpu
import (
		"encoding/binary"
		"bytes"
		"errors"
		"fmt"
		)


func splitBytes(mem int) []byte{
	buf := new(bytes.Buffer)
	err := binary.Write(buf, binary.BigEndian, uint32(mem))
	if err != nil {
		panic ("unable to decode integer: "+hex(mem)+" cause: "+err.Error() )
	}
	return buf.Bytes()
}

func DissectArgs(c *CPU,opt byte, l byte, r byte) (al Arg, ar Arg, err error) {
	switch opt&3  {
	case 0 : al = NewRegArg(int(l),c)
	case 1 : al = NewPtrArg(int(l),c)
	case 2 : al = NewImmArg(int(l))
	default:
		err = errors.New("invalid op for arg1")
		return
	}
	switch (opt>>2)&3  {
	case 0 : ar = NewRegArg(int(r),c)
	case 1 : ar = NewPtrArg(int(r),c)
	case 2 : ar = NewImmArg(int(r))
	default:
		err = errors.New("invalid op for arg2")
		return
	}
	return
}


func Dissect(mem int, cpu *CPU) (*Instruction,error) {
	bytes := splitBytes(mem)
	fmt.Print("")
	//fmt.Print(hex(mem)+ " -> ")
	//fmt.Println(bytes)
	instr := new(Instruction)
	instr.Cpu = cpu
	dst,src, err := DissectArgs(cpu, bytes[1],bytes[2],bytes[3])
	instr.Dst,instr.Src = dst, src
	instr.Instr = Opcode(bytes[0])
	if err != nil {return nil,err}
	return instr,nil
}
