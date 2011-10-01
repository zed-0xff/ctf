require 'gserver'
require 'rpn.rb'
require 'infix.rb'
require 'notes.rb'

def esc()
    "\033\["
end

def gfx(cmd,text)
    esc()+cmd+'m'+text+"\033"+'[0m'
end

def cp(row,col)
    esc+row.to_s+';'+col.to_s+"H"
end


def clr
    esc+"2J"
end

Dir.mkdir("notes")  unless File.exist? "notes"


$options={
/\x03/=> "suppressGoAhead ",
/\x05/  => "status ",
/\x01/  => "echo ",
/\x01/  => "timingMark ",
/\x18/ => "terminalType ",
/\x1f/ => "windowSize " ,
/\x20/ => "terminalSpeed ",
/\x21/ => "remoteFlowControl ",
/\x22/ => "linemode ",
/\x24/ => "environmentVariables ",
/\000/=>" NULL ",
/\377/=>"\nIAC ",
/\373/=>"WILL ",
/\374/=>"WONT ",
/\375/=>"DO ",
/\376/=>"DoNT ",
/\xf0/=>"SE ",
/\xfa/=>"SB "
}

class Telnet
    attr_accessor :io, :buffer, :thread, :invalid

    def initialize(io)
        @io=io
        @buffer=""
        @thread=nil
        #charmode
        Thread.new do
            loop do
              begin
                r=io.readpartial(1000)
                @buffer+=r
              rescue
                @invalid=true
                break
              end
            end
        end
    end

    def filter(line)
        line.gsub(/\xff/,"\xff\xff")
    end

    def filterin(line)
        line.gsub!(/([^\377])\377\xfa[^\xf0]*\xf0/,"\\1")
        line.gsub!(/\377[^\377]./,"")
        line
    end

#def puts(line)
#        @io.puts(filter(line))
#    end

    def print(line)
        @io.print(filter(line))
    end

    def setc(row,col)
        @io.print("\033\[#{row.to_s};#{col.to_s}H")
    end

    def cls()
        @io.print("\033\[2J")
        setc(1,1)
    end

    def gfx(cmd,text)
        "\033\[#{cmd}m#{text}\033\[0m"
    end

    def charmode()
            @io.puts "\377\375\042\377\373\001"  #WTF???
            #IAC WONT LINEMODE IAC WILL ECHO
    end

    def inspect(text)
        print text
        "" if not text
        $options.each{|val,name| text.gsub!(val,name)}
       text
    end
end

class BasicServer < GServer

    def serve(io)

    puts "client connected"

    begin
        tio=Telnet.new(io)
    state=:main
    tio.io.puts "Welcome to the Stardust Office App"
    tio.io.puts "you may choose to use the 'rpn' or the 'infix' calculater"
    tio.io.puts "if you want to quit, just enter 'exit'"
    tio.io.print "#{state}>"
    loop do
      return if tio.invalid
      telnet(tio.buffer,tio.io)
      line=tio.buffer
      if line[-1..-1]=="\n" #always read a single whole line
        tio.buffer=""
        begin
        state=handle(line,state,tio)
        tio.io.print "#{state}>"
        rescue
        puts $!,$@
        puts "client crashed"
        return
        end
      end
      return if state==:exit
      sleep(0.1);
    end
    rescue
    end
    end

  def handle(line,state,tio)
    case state
    when :main
      case line
        when /^rpn/i
          tio.io.puts "you have chosen the rpn calculator"
          return :rpn
        when /^infix/i
          tio.io.puts "you have chosen the infix calculator"
          return :infix
        when /^exit/i
          tio.io.puts "have a nice day"
          return :exit
        when /^note: (.*)/
          tio.io.puts Notes.store($1.strip)
          return :main
        when /^read: (.*)/
          tio.io.puts Notes.read($1.strip)
          return :main
        when /^list/
          tio.io.puts Notes.list
          return :main
        else
          tio.io.puts "unknown command, try 'rpn', 'infix', 'note: sometext', 'read: someid', 'list' or 'exit'"
          return :main
      end
    when :rpn
      return :main if line=~/exit/
      eve=RPN::Evaluator.new
      tio.io.puts eve.run(line)
      return :rpn
    when :infix
      return :main if line=~/exit/
      eve=INFIX::Evaluator.new
      tio.io.puts eve.run(line)
      return :infix
    end
    return :exit
  end

  def telnet( line, io ) # minimal Telnet
    line.gsub!(/([^\015])\012/, "\\1") # ignore bare LFs
    line.gsub!(/\015\0/, "") # ignore bare CRs
    line.gsub!(/\0/, "") # ignore bare NULs

    while line.index("\377") # parse Telnet codes
      if line.sub!(/(^|[^\377])\377[\375\376](.)/, "\\1")
      #answer DOs and DON'Ts with WON'Ts
        io.print "\377\374#{$2}"
      elsif line.sub!(/(^|[^\377])\377[\373\374](.)/, "\\1")
        # answer WILLs and WON'Ts with DON'Ts
        io.print "\377\376#{$2}"
      elsif line.sub!(/(^|[^\377])\377\366/, "\\1")
        # answer "Are You There" codes
        io.puts "Still here, yes."
      elsif line.sub!(/(^|[^\377])\377\364/, "\\1")
        # do nothing - ignore IP Telnet codes
      elsif line.sub!(/(^|[^\377])\377[^\377]/, "\\1")
        # do nothing - ignore other Telnet codes
      elsif line.sub!(/\377\377/, "\377")
      # do nothing - handle escapes
      end
    end
   line

   end
end
#8 = backspace
#9 = tab
#10 = newline
#13 =carriag return?
#19 = wtf

Thread.abort_on_exception=true
BasicSocket.do_not_reverse_lookup = true
listenaddr= ARGV[0]=="global" ? "0.0.0.0" : "127.0.0.1"
server = BasicServer.new(1234,listenaddr,100)

#server.audit = true
server.start
sleep 60*60
server.shutdown
