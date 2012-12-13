class StringCode
  def code(asm)
    asm.asm do
      function :printstrln do
        push(t0)
        call_to :printstr
        mov t0, char("\n")
        sys WRITEW, 0
        pop(t0)
      end

      function :printstr do #ptr int t1
        def ptr; t1 ;end
        push(t0)
        label :loop
          mov t0, [ptr]
          jz_to :done, t0
          sys WRITEW, 0
          add ptr, 1
        jmp_to :loop
        label :done
        pop(t0)
      end

      function :printi do
        def int; t1; end #arg0
        def strbuffer; t2; end
        def neg; t3; end

        push t0,t1,neg,strbuffer
        mov neg,0
        ldw strbuffer, ref(:numbuffer)
        if_then(int,:<,0) do
          mov neg,1
          push t3     #int = -int
            mov t3,0
            sub t3,int
            mov int,t3
          pop t3
          inc strbuffer
        end
        call_to(:itou)
        ldw t1, ref(:numbuffer)
        if_then(neg,:==,1) { mov [t1],char("-");}
        call_to(:printstrln)
        pop t0, t1, neg, strbuffer
        ret
        const :numbuffer, "-4294967296"
      end


      function :log10length do #t1 -> t1
        def int; t1; end
        def log; t2; end
        push log
        mov log,0
        if_then(int,:<,0) do
          push t3     #int = -int
          mov t3,0
          sub t3,int
          mov int,t3
          pop t3
          mul int,10 #add one digit for the "-"
        end

        label :loop
          div int, 10
          add log,1
          jz_to :exit, int
        jmp_to :loop

        label :exit
        mov int, log
        pop log
      end

      function :itou do
        def int; t1; end #argument 0
        def strlen; t1; end
        def ptr; t2; end #argument 1
        def rem; t3; end

        push t0,t1,t2,t3

        push t1
          call_to :log10length #returns strlen in t1
          add ptr, strlen
          mov [ptr],0
          sub ptr, 1
        pop t1

        label :loop
          mov rem, int
          mod rem, 10
          add rem, 0x30
          mov [ptr], rem
          sub ptr,1
          div int, 10
          jz_to :exit, int
        jmp_to :loop

        label :exit
        pop t0,t1,t2,t3
      end

      function :strlen do #ptr in t1, returns len in t1
        def ptr; t1; end
        def len; t2; end
        push len
        mov len,0
        label :loop
          mov t0, [ptr]
          jz_to :exit, t0
          add len, 1
          add ptr, 1
        jmp_to :loop

        label :exit
        mov t1,len
        pop len
      end

      function :readline do #buffer, bufferlen, sock
        def buffer; t1; end
        def bufferlen; t2; end
        def bufferend; t2; end
        def sock; t3; end
        push t0, t1, t2, t3
        add bufferlen, buffer # bufferlen becomes bufferend
        label :loop
        if_else(buffer,:>=,bufferend){
          mov [bufferend],0
          pop(t0,t1,t2,t3)
          ret
        }.else{
          push buffer
          sys READW,sock #t1 = num, #t0 = read val
          if_then(t0, :==, 0) do #encountered eof?
            pop buffer
            mov [buffer],0
            pop(t0,t1,t2,t3)
            ret
          end
          pop buffer
          mov [buffer],t0

          if_then(t0,:==, char("\n")) do #encountered newline
            mov [buffer],0
            pop(t0,t1,t2,t3)
            ret
          end

          inc buffer
        }
        jmp_to :loop
      end

      function :split do
        def str_ptr; t1; end #arg1
        def tab_ptr; t2; end #arg2
        def split; t3; end #arg3
        push t1,t2,t3
        mov [tab_ptr], str_ptr
        inc tab_ptr
        label :loop
        if_then([str_ptr], :==, 0) do
          mov [tab_ptr], 0
          pop t1,t2,t3
          ret
        end
        if_else([str_ptr],:==,split) do
          mov [str_ptr],0
          inc str_ptr
          mov [tab_ptr],str_ptr
          inc tab_ptr
        end.else do
          inc str_ptr
        end
        jmp_to :loop
      end

      function :count_char do
        def ptr; t1; end
        def char; t2; end

        push t0,t2
        mov t0,0
        label :loop
        if_then([t1], :==, t2) do
          inc t0
        end
        if_then([t1], :==, 0) do
          mov t1,t0
          pop t0,t2
          ret
        end
        inc t1
        jmp_to :loop

      end

    end
  end
end

def strings; StringCode.new; end
