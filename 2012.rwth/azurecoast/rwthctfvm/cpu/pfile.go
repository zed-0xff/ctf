package cpu


import (
	"os/exec"
	"io"
)
type Pfile struct {
	Cmd *exec.Cmd
	In io.Writer
	Out io.Reader
}

func (c *Pfile) Read(b []byte) (int,error) {
	return c.Out.Read(b)
}

func (c *Pfile) Write(b []byte) (int,error) {
	return c.In.Write(b)
}

func (c *Pfile) Close() error {
	err := c.Cmd.Process.Kill()
	if(err != nil) { return err }
	return c.Cmd.Wait()
}


func Spawn2(instr string) (*Pfile,error){
	  cmd := exec.Command("echo", "-n", `{"Name": "Bob", "Age": 32}`)
		var res Pfile
		res.Cmd=cmd
		var err error
		res.Out,err = cmd.StdoutPipe()
		if err != nil {return nil,err}
    err = cmd.Start()
		return &res,err
		//res.In,err = res.Cmd.StdinPipe()
		//if err != nil {return nil,err}
}
func Spawn(instr string) (File,error){
	  cmd := exec.Command("/bin/bash", "-c", instr)
		var res Pfile
		res.Cmd=cmd
		var err error
		res.Out,err = cmd.StdoutPipe()
		if err != nil {return nil,err}
    err = cmd.Start()
		return &res,err
		//res.In,err = res.Cmd.StdinPipe()
		//if err != nil {return nil,err}
}
