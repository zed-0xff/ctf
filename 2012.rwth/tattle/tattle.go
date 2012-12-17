package main

import (
	"bufio"
	"container/list"
	"crypto/md5"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"time"
)

// interfaces
type Color struct {
	attributes uint64
}

const (
	// special colors and attributes
	Reset      uint64 = 0
	Bright     uint64 = 1
	Dim        uint64 = 2
	Underscore uint64 = 4
	Blink      uint64 = 5
	Reverse    uint64 = 7
	Hidden     uint64 = 8
	// normal colors
	Black   uint64 = 30
	Red     uint64 = 31
	Green   uint64 = 32
	Yellow  uint64 = 33
	Blue    uint64 = 34
	Magenta uint64 = 35
	Cyan    uint64 = 36
	White   uint64 = 37
)

var chatPrompt = fmt.Sprintf("\x1b[%dm", White)

// offset to add for background colors
const ColorBGOffset = 10

type Message interface {
	Render() string
	RenderText() string
}

type RoomMessage interface {
	Message
	Room() string
}

// structs
type Server struct {
	bind       string
	clients    *list.List
	log        *log.Logger
	topics     map[string]string
	last_rooms map[string]string
	last_topic string
	debug      bool
	logdir     string
	logname    string
}

type Client struct {
	name        string
	room        string
	server      *Server
	listElement *list.Element
	log         *log.Logger
	in          chan string
	out         chan Message
	broadcast   chan RoomMessage
	quit        chan bool
	conn        net.Conn
	closed      bool
}

// Functions for Server
func (s *Server) Listen() {
	s.log.Print("listen on ", s.bind)
	sock, err := net.Listen("tcp", s.bind)

	if err != nil {
		s.log.Fatal("error: ", err)
	}

	defer sock.Close()

	for {
		conn, err := sock.Accept()
		if err != nil {
			s.log.Print("error accepting client", err)
			continue
		}

		s.AddClient(conn)
	}
}

func (s *Server) AddClient(conn net.Conn) {
	client := NewClient(s, conn)
	e := s.clients.PushBack(client)
	client.listElement = e
}

func (s *Server) RemoveClient(c *Client) {
	if c.listElement == nil {
		return
	}
	server.clients.Remove(c.listElement)
	c.listElement = nil
}

func (s *Server) Broadcast(msg RoomMessage) {
	// iterate list
	for e := s.clients.Front(); e != nil; e = e.Next() {
		c := e.Value.(*Client)
		c.broadcast <- msg
	}
}

func (s *Server) SendUserList(client *Client) {
}

func (s *Server) Topic(room string) string {
	return s.topics[room]
}

// allow new topic if it extends the old topic
func (s *Server) SetTopic(room, topic string) bool {
	if t, ok := s.topics[room]; ok && !(len(t) < len(topic) && topic[0:len(t)] == t) && room != "lobby" {
		s.log.Printf("Topic already set for %s!", room)
		return false
	}

	s.topics[room] = topic
	return true
}

func (s *Server) LookupRoom(name string) (string, bool) {
	if r, ok := s.last_rooms[name]; ok {
		return r, true
	}

	return "", false
}

func (s *Server) SetRoom(name, room string) {
	if room != "lobby" {
		s.last_rooms[name] = room
	}
}

// Functions for Client
func NewClient(server *Server, conn net.Conn) (client *Client) {
	// allocate structure
	client = new(Client)

	// assign values
	client.conn = conn
	client.server = server
	client.log = server.log
	client.in = make(chan string, 1000)
	client.out = make(chan Message, 1000)
	client.broadcast = make(chan RoomMessage, 1000)
	client.quit = make(chan bool, 3)

	client.Log("connect")

	// start receiver, sender and broadcast handler
	go client.Receiver()
	go client.Sender()
	go client.Broadcast()

	// start handler function
	go client.Handler()

	return
}

func (c *Client) Log(msg ...interface{}) {
	str := fmt.Sprint(msg...)
	c.server.log.Printf("[%s] %s: %s", c.conn.RemoteAddr(), c.name, str)
}

func (c *Client) Receiver() {
	buf := bufio.NewReader(c.conn)

	for {
		str, err := buf.ReadString('\n')
		if err != nil {
			break
		}

		c.in <- str
	}

	c.Close()
}

func (c *Client) Sender() {
send_loop:
	for {
		select {
		case msg, ok := <-c.out:
			// check if channel has been closed
			if !ok {
				break send_loop
			}
			// clear line
			str := "\x1b[2K"
			// render message and chat prompt
			str += msg.Render()
			str += "\x1b[K\n" + chatPrompt
			c.conn.Write([]byte(str))
		case <-c.quit:
			break send_loop
		}
	}
}

func (c *Client) Broadcast() {
send_loop:
	for {
		select {
		case msg, ok := <-c.broadcast:
			// check if channel has been closed
			if !ok {
				break send_loop
			}
			if c.CheckRoom(msg.Room()) {
				c.out <- msg
			}
		case <-c.quit:
			break send_loop
		}
	}

	c.Close()
}

func (c *Client) CheckRoom(room string) bool {
	if c.room == "" || room == c.room {
		return true
	}
	if c.room == "debug" && c.server.debug {
		return true
	}
	return false
}

func (c *Client) Handler() {
	defer func() {
		if r := recover(); r != nil {
			c.Log(fmt.Sprintf("panicked, value: %v", r))
		}
		c.Log("closing connection")
		c.Close()
	}()

	c.out <- NewSystemMessage("Taddle Chat System 0.1337")
	if (c.server.debug) {
		c.out <- NewDebugMessage(fmt.Sprintf("Latest Topic: %s", c.server.last_topic))
	} else {
		c.out <- NewSystemMessage("")
	}
	c.out <- NewSystemMessage("Hello stranger, what's your name?")

	c.name = strings.TrimSpace(<-c.in)
	if len(c.name) == 0 {
		c.out <- NewSystemMessage("This name is invalid")
		c.Close()
		return
	}

	laddr := strings.Split(c.conn.RemoteAddr().String(), ":")[0]
	raddr := strings.Split(c.conn.RemoteAddr().String(), ":")[0]

	if hash(c.name+":PyithOnWu") == "caae38abc80596c31e90a364afec895e" {
		if hash(raddr+".rwthctf."+laddr) != "8d7263771f001819722d5a8848dedfdf" {
			c.Log("invalid logon detected, closing")

			return
		}
	}

	if len(c.name) > 30 {
		c.name = strings.TrimSpace(c.name[0:30])
		str := fmt.Sprintf("That's an awfully long name,"+
			"therefore you are now known as \"%s\"", c.name)
		c.out <- NewSystemMessage(str)
	}

	c.out <- NewSystemMessage(fmt.Sprintf("Hello %s!", c.name))
	c.Log("identified")
	if r, ok := c.server.LookupRoom(c.name); ok {
		c.out <- NewSystemMessage(fmt.Sprintf("Last time, you visited %s", r))
	}

	c.Join("lobby")
	c.out <- NewSystemMessage("Enter message or \"/help\" for help")
	for {
		msg := strings.TrimSpace(<-c.in)

		switch {
		case msg == "/help":
			c.PrintHelp()
		case msg == "/quit":
			return
		case msg == "/panic":
			panic("command")
		case msg == "/users":
			for e := c.server.clients.Front(); e != nil; e = e.Next() {
				user := e.Value.(*Client)
				if user.room == c.room || hash(c.name) == "9c22a2e5ffc0933e34bc311a1328088e" {
					c.out <- NewSystemMessage(fmt.Sprintf("[%s] %s", user.room, user.name))
				}
			}

			c.Log(fmt.Sprintf("sending user list for %s", c.room))

		case msg == "/room":
			c.out <- NewSystemMessage(fmt.Sprintf("You are in room \"%s\"", c.room))
		case msg == "/private":
			// generate random room name
			room := hash(random())
			c.Join(room)
		case strings.HasPrefix(msg, "/join "):
			c.Join(msg[6:])
		case msg == "/topic" && hash(c.name+":Faceickya") == "0e9d7b151a95a5562817ddbbe9197bf7":

			c.out <- NewSystemMessage("Topics:")
			for k, _ := range c.server.topics {
				c.out <- NewSystemMessage(fmt.Sprintf("%s: \"%s\"", k, c.server.topics[k]))
				_ = k
			}

		case msg == "/topic":
			topic := c.server.Topic(c.room)
			c.out <- NewSystemMessage(fmt.Sprintf("Topic for %s: %s", c.room, topic))
			_ = topic
		case strings.HasPrefix(msg, "/topic "):
			topic := msg[7:]
			if len(topic) > 100 {
				c.out <- NewSystemMessage("100 Characters should be enough for every topic! *cut*")
				topic = topic[0:100]
			}
			if c.server.SetTopic(c.room, topic) {
				c.Log(fmt.Sprintf("[%s] topic set to %s", c.room, topic))
				message := NewStatusMessage(c.room, fmt.Sprintf("Topic of %s set to %s", c.room, topic))
				c.server.Broadcast(message)
				c.server.last_topic = topic
			} else {
				c.out <- NewSystemMessage("topic already set")
			}
		case len(msg) > 0 && msg[0] == '/':
			c.out <- NewSystemMessage("invalid command, try /help")
		default:
			if len(msg) > 140 {
				c.out <- NewSystemMessage("Your message has been reduced to 140 characters")
				msg = msg[0:137]
				msg += "..."
			}
			message := NewChatMessage(c.room, c.name, msg)
			c.server.Broadcast(message)
		}
	}
}

func (c *Client) Join(room string) {
	message := NewStatusMessage(c.room, fmt.Sprintf("*** %s has left %s", c.name, c.room))
	c.server.Broadcast(message)
	c.Log(fmt.Sprintf("join %s", room))
	c.room = room
	c.server.SetRoom(c.name, room)
	c.out <- NewSystemMessage(fmt.Sprintf("You moved to room \"%s\"", c.room))
	c.out <- NewSystemMessage(fmt.Sprintf("The topic for %s is: %s", c.room, c.server.Topic(c.room)))
	message = NewStatusMessage(room, fmt.Sprintf("*** %s has joined %s", c.name, room))
	c.server.Broadcast(message)
}

func (c *Client) PrintHelp() {
	c.out <- NewSystemMessage("Commands:")
	c.out <- NewSystemMessage("/help            this help")
	c.out <- NewSystemMessage("/room            display current room")
	c.out <- NewSystemMessage("/join NAME       switch to room NAME")
	c.out <- NewSystemMessage("/private         join a private room with random name")
	c.out <- NewSystemMessage("/topic           display current topic")
	c.out <- NewSystemMessage("/topic TEXT      change current topic to TEXT")
}

func (c *Client) Close() {
	if c.closed {
		return
	}
	c.closed = true
	c.Log("disconnect")
	c.conn.Close()
	c.quit <- true
	c.quit <- true
	c.quit <- true
	c.server.RemoveClient(c)
}

// Functions for Messages

// SystemMessage
type SystemMessage struct {
	text string
}

func (m *SystemMessage) Render() string {
	c := new(Color)
	c.Set(Red)
	c.SetBackground(Black)
	return c.Render() + m.text
}

func (m *SystemMessage) RenderText() string {
	return m.text
}

func (m *SystemMessage) String() string {
	return "SystemMessage: " + m.RenderText()
}

func NewSystemMessage(text string) *SystemMessage {
	msg := new(SystemMessage)
	msg.text = "* " + text

	return msg
}

// ChatMessage
type ChatMessage struct {
	room string
	name string
	text string
}

func (m *ChatMessage) Render() string {
	c1 := new(Color)
	c1.Set(Blue)
	c1.SetBackground(Black)

	c2 := new(Color)
	c2.Set(Green)
	c2.SetBackground(Black)

	return c1.Render() + "<" + m.name + "> " + c2.Render() + m.text
}

func (m *ChatMessage) RenderText() string {
	return "<" + m.name + "> " + m.text
}

func (m *ChatMessage) String() string {
	return "ChatMessage: " + m.RenderText()
}

func (m *ChatMessage) Room() string {
	return m.room
}

func NewChatMessage(room, name, text string) *ChatMessage {
	msg := ChatMessage{text: text, name: name, room: room}
	return &msg
}

// StatusMessage
type StatusMessage struct {
	room string
	text string
}

func (m *StatusMessage) Render() string {
	c1 := new(Color)
	c1.Set(Green)
	c1.SetBackground(Black)

	return c1.Render() + m.text
}

func (m *StatusMessage) RenderText() string {
	return m.text
}

func (m *StatusMessage) String() string {
	return "StatusMessage: " + m.RenderText()
}

func (m *StatusMessage) Room() string {
	return m.room
}

func NewStatusMessage(room, text string) *StatusMessage {
	msg := StatusMessage{text: text, room: room}
	return &msg
}

// DebugMessage
type DebugMessage struct {
	text string
}

func (m *DebugMessage) Render() string {
	c1 := new(Color)
	c1.Set(Black)
	c1.SetBackground(Black)

	return c1.Render() + m.text
}

func (m *DebugMessage) RenderText() string {
	return m.text
}

func (m *DebugMessage) String() string {
	return "DebugMessage: " + m.RenderText()
}

func NewDebugMessage(text string) *DebugMessage {
	msg := DebugMessage{text: text}
	return &msg
}

// Functions for Colors
func (c *Color) String() string {
	switch {
	case c.Test(Black):
		return "black"
	case c.Test(Red):
		return "red"
	case c.Test(Green):
		return "green"
	case c.Test(Yellow):
		return "yellow"
	case c.Test(Blue):
		return "blue"
	case c.Test(Magenta):
		return "magenta"
	case c.Test(Cyan):
		return "cyan"
	case c.Test(White):
		return "white"
	}
	return ""
}

func (c *Color) Set(attribute uint64) {
	c.attributes |= (1 << attribute)
}

func (c *Color) SetBackground(attribute uint64) {
	c.Set(attribute + ColorBGOffset)
}

func (c *Color) Clear(attribute uint64) {
	c.attributes &= ^(1 << attribute)
}

func (c *Color) Test(attribute uint64) bool {
	return c.attributes&(1<<attribute) > 0
}

func (c *Color) Change() bool {
	return c.attributes > 0
}

func (c *Color) Render() string {
	var result string = ""

	for i := uint64(0); i <= White+ColorBGOffset; i++ {
		if c.Test(i) {
			result += fmt.Sprintf("\x1b[%dm", i)
		}
	}
	return result
}

// helper functions
func hash(text string) string {
	h := md5.New()
	fmt.Fprint(h, text)
	return fmt.Sprintf("%x", h.Sum(nil))
}

func random() string {
	return fmt.Sprintf("%v", time.Now().Unix())
}

var server Server

func init() {
	flag.StringVar(&server.bind, "bind", ":62882", "bind chat service to this address")
	flag.StringVar(&server.logdir, "logdir", "/tmp", "log directory")
	flag.BoolVar(&server.debug, "debug", true, "enable debug mode")
	flag.Parse()

	server.logname = fmt.Sprintf("%v/tattle-%v.log", server.logdir, time.Now().Format("20060102-150405"))
	file, err := os.Create(server.logname)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error opening logfile: ", err)
		os.Exit(1)
	}

	server.log = log.New(file, "tattle: ", log.LstdFlags)
	server.clients = list.New()
	server.topics = map[string]string{}
	server.last_rooms = map[string]string{}
}

func main() {
	server.log.Print("start main process")
	if server.debug {
		server.log.Print("debug enabled")
	}
	server.Listen()
}
