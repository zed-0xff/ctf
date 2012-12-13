package main
import (
		"rwthctfvm/cpu"
		"rwthctfvm/data"
		"time"
		"net"
		"log"
		"os"
		"runtime"
//		"os/exec"
		"fmt"
//		"strconv"
	)

func simulate(io *net.Conn, id int){
	core := cpu.NewCPU(id, 8092, *io, *io, os.Stderr)
	core.InitialSize = len(data.Memory)
	core.Log("startet VM with codesize",core.InitialSize)

	for addr, _ := range data.Memory { //initialize core memory
		core.Memory[addr] = int(data.Memory[addr])
	}  
	core.Labels = data.Labels //load lables from the assembler for debuggin using sys STEP,1

    defer func() { //close file handles and prevent a single core from crashing the server
        if r := recover(); r != nil { //no panic for you - bad core
					core.Log("execution crashed - recovering for the greater good", r)
        }
				(*io).Close() //close all filehandles
				for k,fd := range core.FileHandles {

					if ( (k>2) && (fd != nil) ) { // do not close stdin / stdout etc
						fmt.Println(fd)
						fd.Close()
					}
				}
    }()

	tickcount := 0

	go func(){
		time.Sleep(10*time.Second)
		core.Timeouted = true
		(*io).Close()
	}()

	for { //simulate core (nearly) endlessly
		tickcount += 1
		err := core.Tick()

		if err != nil { // something went wrong while ticking the core
			core.Log(err)
			return
		}

		if tickcount & 64 == 0 { //yield every few ticks so other cores can run
			runtime.Gosched()
		}

		if core.Timeouted {
				core.Log("terminated by timeout")
				return
		}

		if core.Terminated { //this core exited with sys EXIT
				core.Log("terminated by sys EXIT")
				return
		}

		if tickcount > 100000 { // to many instructions -> infinite loop?
				core.Log("more than 200.000 instructions executed -> terminating")
				return
		}
	}
}


func test(err error, mesg string) {
    if err!=nil {
        log.Panic("SERVER: ERROR: ", mesg);
         os.Exit(-1);
    } else {
        log.Print("Ok: ", mesg);
		}
}

func main () {

    //netlisten, err := net.Listen("tcp", "127.0.0.1:1393");
    netlisten, err := net.Listen("tcp", "0.0.0.0:1393");
    test(err, "main Listen");
    defer netlisten.Close();
		cpucounter := 0

		go func(){ //flag garbage collection
			for { 
				//fmt.Println("collecting old flags")
				//exec.Command("find", "./storage","-type","f", "-amin", "+15", "-delete").Run()
				//fmt.Println("done collecting old flags")
				time.Sleep(1*time.Minute)
			}
		}()

    for {
        // wait for clients
        log.Print("main(): wait for client ...");
        conn, err := netlisten.Accept();
        test(err, "main: Accept for client");
				cpucounter+=1
				go simulate(&conn,cpucounter)
    }
}
