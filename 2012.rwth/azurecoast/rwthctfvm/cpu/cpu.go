package cpu

import (
	"errors"
	"strconv"
	"fmt"
	"os"
	"io"
	"bufio"
	"encoding/binary"
	"bytes"
	"log"
	"time"
)

type CPU struct {
	Registers map[Register]int
	Memory    []int
	Step bool
	FileHandles map[int]File
	InitialSize int
	InstrCache map[int]*Instruction
	MaxHandle int
	ID int
	Labels map[string]int
	Terminated bool
	Timeouted bool
}

type Syscall int
const (
		EXIT Syscall= iota
		READB
		WRITEB
		READW
		WRITEW
		EXEC
		BREAK
		STEP
		OPEN
		CORE
		CLOSE
		CLOCK
		)

const (
		STDOUT int = iota
		STDIN
		)

type File interface {
	Read([]byte) (int,error)
	Write([]byte) (int,error)
	Close() error
}

func NewCPU(id, memsize int, stdin, stdout, stderr File) (cpu *CPU) {
	cpu = new(CPU)
	cpu.ID = id
	cpu.Step = false
	cpu.Registers = make(map[Register]int)
	cpu.FileHandles = make(map[int]File)
	cpu.InstrCache =make(map[int]*Instruction)
	cpu.FileHandles[0] = stdin //os.Stdout
	cpu.FileHandles[1] = stdout //os.Stdin
	cpu.FileHandles[2] = stderr //os.Stderr
	cpu.Registers[eq] = 0
	cpu.Registers[smaller] = 0
	cpu.Registers[bigger] = 0
	cpu.Registers[t0] = 0
	cpu.Registers[t1] = 0
	cpu.Registers[t2] = 0
	cpu.Registers[t3] = 0
	cpu.Registers[t4] = 0
	cpu.Registers[t5] = 0
	cpu.Registers[t6] = 0
	cpu.Registers[t7] = 0
	cpu.Registers[ip] = 0
	cpu.Memory = make([]int, memsize)
	cpu.MaxHandle = 2
	cpu.Terminated = false
	return
}

func dec(val int) string {
	return strconv.FormatInt(int64(val), 10)
}

func hex(val int) string {
	return "0x"+strconv.FormatUint(uint64(val), 16)
}

func (c *CPU) GetLastLabel(addr int) (str string,ok bool){
	last_key := ""
	last_addr := -1
	for key,val := range c.Labels {
		if val > last_addr && val <= addr {
			last_key = key
			last_addr = val
		}
	}
	if last_addr > -1 {
		return last_key+"+"+dec(addr-last_addr), true
	}
	return "",false
}

func (c *CPU) InspectIP() (res string) {
	ipv := c.Registers[ip]
	label,ok := c.GetLastLabel(ipv)
	if ok {
		res = "("+hex(ipv)+") "+label
	} else {
		res = "("+hex(ipv)+") "
	}
	return res
}

func (c *CPU) Inspect() (res string) {
	res =""
	res += "ip: "+c.InspectIP()+"  , "
	res += "e: "+hex(c.Registers[eq])+", "
	res += "s: "+hex(c.Registers[smaller])+", "
	res += "b: "+hex(c.Registers[bigger])+", "
	res += "t0: "+hex(c.Registers[t0])+", "
	res += "t1: "+hex(c.Registers[t1])+", "
	res += "t2: "+hex(c.Registers[t2])+", "
	res += "t3: "+hex(c.Registers[t3])+", "
	res += "t4: "+hex(c.Registers[t4])+", "
	res += "t5: "+hex(c.Registers[t5])+", "
	res += "t6: "+hex(c.Registers[t6])+", "
	res += "t7: "+hex(c.Registers[t7])+"\n"
	return res
}

func (c *CPU) Decompile(val int) (*Instruction,error) {
	instr,err := Dissect(val,c)
	if err != nil {
		return nil, errors.New("Undable to Decode Instruction: "+strconv.FormatInt(int64(val),16)+" reason: "+err.Error())
	}
	return instr,nil
}

func (c *CPU) GetInstr(instrval int) (*Instruction,error) {
	if val,ok := c.InstrCache[instrval]; ok {
		return val,nil
	}
	instr, err := c.Decompile(instrval)
	if err!=nil {return nil,err}
	c.InstrCache[instrval]=instr
	return instr,nil
}

func (c *CPU) Log(v ...interface{}) {
	log.Print("CPU [",c.ID,"] ",v)
}

func (c *CPU) Tick() error{
	if c.Step { getKey() }
	ipval,err := c.GetRegister(ip)
	//fmt.Println("fetching "+hex(ipval))
	fmt.Print(hex(ipval) + ": ")
	if err != nil {return errors.New("unable to get ip") }
	instrval, err := c.GetMemory(ipval)
	if err != nil {return errors.New("unable to get cmd") }
	instr, err := c.GetInstr(instrval)
	if err != nil {return errors.New("unable to decode instr") }
	fmt.Println(instr.Inspect())
	if c.Step {
		fmt.Print("IP: "+c.InspectIP())
		fmt.Println(instr.Inspect())
		fmt.Println(c.Inspect())
		last := 0
		for i,val := range c.Memory {
			if val != 0 && i > c.InitialSize {
			if i != last+1 {fmt.Print(" ... ")}
			last = i
			fmt.Print(" "+hex(i)+":"+hex(val))
			}
		}
		fmt.Println("")
	}
	return instr.Exec()
}

func (c *CPU) GetRegister(reg Register) (int, error) {
	if val, ok := c.Registers[reg]; ok {
		return val, nil
	}
	return 0, errors.New("Invalid Register access (read): "+ hex(int(reg)))
}

func (c *CPU) SetRegister(reg Register, val int) error {
	if _, ok := c.Registers[reg]; ok {
		c.Registers[reg] = val
		return nil
	}
	return errors.New("Invalid Register access (write)"+ hex(int(reg)))
}

func (c *CPU) GetMemory(addr int) (int, error) {
	if addr >= len(c.Memory) || addr < 0 {
		return 0, errors.New("Invalid Memory access (read)")
	}
	return c.Memory[addr], nil
}

func (c *CPU) SetMemory(addr int, value int) error {
	if addr > len(c.Memory) || addr < 0 {
		return errors.New("Invalid Memory access (write)")
	}
	c.Memory[addr] = value
	return nil
}

func getKey() {
			reader := bufio.NewReader(os.Stdin)
			_ , _ = reader.ReadString('\n')
}

func (c *CPU) GetString(offset int) string {
		str := ""
	for i:=offset; i<len(c.Memory) && c.Memory[i]!=0; i+=1 {
		str+=string(c.Memory[i])
	}
	c.Log("extracted string from memory", str, "with length", len(str), "from addr", offset)
	return str
}

func (c *CPU) Sys(num Syscall, arg1 int) error {
	arg2, err := c.GetRegister(t0)
	if err != nil {return err}
	switch num {
		case EXIT : c.Terminated = true
		case BREAK : fmt.Print("BREAK");getKey()
		case STEP : fmt.Print("STEP"); if arg1 == 0 {c.Step=false} else {c.Step = true}
		case CLOCK : c.SetRegister(t0,time.Now().Nanosecond())
		case CORE :
				c.SetRegister(t0,len(c.Memory))
				c.SetRegister(t1,c.InitialSize)
		case EXEC : 
				c.MaxHandle+=1
				newhandle := c.MaxHandle
				cmdline := c.GetString(arg1)
				c.Log("exec",cmdline)
				fd,err := Spawn(cmdline)
				if err != nil {
					c.Log("unable to execute ",err)
					c.SetRegister(t0,0)
				} else {
					c.Log("spawned",cmdline,"with handle",newhandle)
					c.SetRegister(t0,newhandle)
					c.FileHandles[newhandle] = fd
				}
		case OPEN:
				c.MaxHandle+=1
				newhandle := c.MaxHandle
				filename := c.GetString(arg1)
				c.Log("open file ",filename)
				fd,err := os.OpenFile("./storage/"+filename,os.O_CREATE|os.O_RDWR,0666)
				if err != nil {
					c.Log("unable to open file: ",filename)
					c.SetRegister(t0,0)
				} else {
					c.FileHandles[newhandle]=fd
					c.Log("opened file ",filename, "with handle", newhandle)
					c.SetRegister(t0,newhandle)
				}
		case CLOSE :
				if f,ok := c.FileHandles[arg1]; ok {
					delete(c.FileHandles, arg1)
					f.Close()
					c.Log("closed file ", arg1)
				} else {
					c.Log("trying to close unknown filehandle", arg1)
				}
		case WRITEB :
			if file,ok := c.FileHandles[arg1]; ok {
				file.Write([]byte(string(arg2)))
			}else {
				return errors.New( "invalid file handle "+ hex(arg1))
			}
		case READB :
			if file,ok := c.FileHandles[arg1]; ok {
				bytes := make([]byte,1)
				num,err := file.Read(bytes)
				if(err != nil) { c.Log("failed reading from",arg1,"due to:",err) }
				i := int(bytes[0])

				if i!=0x0a { //don't print newlines
				c.Log("readb from",arg1,"read", hex(int(i)), string(i), "ok:", num)
				} else {
				c.Log("readb from",arg1,"read", hex(int(i)), "ok:", num)
				}
				c.SetRegister(t1,num)
				c.SetRegister(t0,i)
			}else {
				return errors.New( "invalid file handle "+ hex(arg1))
			}
		case READW :
			if file,ok := c.FileHandles[arg1]; ok {
				var i int32 = 0
				bts := make([]byte,4)
				num,err := io.ReadFull(file,bts)
				if(err != nil) { c.Log("failed reading from",arg1,"due to:",err) }

				if num == 4 {
					num = 1
					binary.Read(bytes.NewBuffer(bts), binary.LittleEndian, &i)
				} else {
					num = 0
				}
				if i!=0x0a { //don't print newlines
				c.Log("read from",arg1,"read", hex(int(i)), string(i), "ok:", num)
				} else {
				c.Log("read from",arg1,"read", hex(int(i)), "ok:", num)
				}

				fmt.Println("read num:",num,", v=",hex(int(i)))
				c.SetRegister(t1,num)
				c.SetRegister(t0,int(i))
			}else {
				return errors.New( "invalid file handle "+ hex(arg1))
			}
		case WRITEW :
			fmt.Println("writingw: ",arg2)
			if file,ok := c.FileHandles[arg1]; ok {
				buff := new(bytes.Buffer)

				var i int32 = int32(arg2)
				_ = binary.Write(buff, binary.LittleEndian, i)
				file.Write(buff.Bytes())
			}else {
				return errors.New( "invalid file handle "+ hex(arg1))
			}

		default:
			return errors.New("invalid syscall "+hex(int(num)))
	}
	return nil
}
