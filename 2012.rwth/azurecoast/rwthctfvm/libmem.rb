class MemCode
  def code(asm)
    asm.asm do

        def _size; 0; end
        def _last; 1; end
        def _free; 2; end
        def _null; 3; end

        def free_value; 0x23; end
        def used_value; 0x42; end

      function :free do
        def linkptr;t1; end #argument0
        def lastptr;t2; end
        def linksize;t3; end
        def lastsize;t0; end
        def nextpr; t3; end
        push(t0,t1,t2,t3)
        sub linkptr,4 #linkptr now points to meta info
        get_offset(t2, linkptr,_free)
        if_then(t2,:!=, used_value) do
          prints("invalid free")
          sys EXIT,1
        end
        get_offset(lastptr, linkptr,_last) #set last.size+=link.size
        get_offset(linksize, linkptr,_size)
        get_offset(lastsize, lastptr,_size)
        add lastsize, linksize
        set_offset(lastptr,_size,lastsize)

        add linksize, linkptr # linksize is now nextptr
        set_offset(linksize,_last,lastptr) #next.last = link.last
        mov [linkptr],0
        inc linkptr
        mov [linkptr],0
        inc linkptr
        mov [linkptr],0

        pop(t0,t1,t2,t3)
      end

      function :malloc do
        def linkptr; t0; end
        def m_size; t1; end #argument0
        def new_ptr; t2; end
        def old_size; t3; end
        def new_size; t4; end
        def old_next; t4; end


        push(t0,t2,t3,t4)
        add m_size,4 #compensate for the 4 words of heap meta info
        push m_size
        add m_size,10 #make sure there will be at least room for some other chunk in this segment
        get("::init_mem::heap_begin",linkptr)
        label :loop_begin

        if_then([linkptr], :==, 0) do
          prints("end of memory while malloc")
          sys EXIT,1
        end

        mov old_size, [linkptr]
        if_then(old_size, :>=, m_size) do
          get_offset(t2, linkptr,_free)
          if_then(t2, :==, free_value) do #free block
            pop(m_size) #get unmodified size
            mov old_next, linkptr
            add old_next, [linkptr]
            mov new_ptr, linkptr
            add new_ptr, m_size
            set_offset(old_next,_last,new_ptr) #snd.last = &new

            set_offset(linkptr,_size,m_size) #fst.size = m_sizej
            set_offset(linkptr,_free,used_value) #fst.free = 0
            mov new_size, old_size
            sub new_size, m_size

            sub new_size, 4

            set_offset(new_ptr,_size, new_size) #new.size = m_size-4
            set_offset(new_ptr,_last, linkptr) #new.lastptr = fst.ptr
            set_offset(new_ptr,_free,free_value) #new.free = true
            set_offset(new_ptr,_null,0) #new.free = true
            mov t1, linkptr
            add t1, 4 #point to the begin of the allocated block, not to the meta data
            pop(t0,t2,t3,t4)
            ret
          end
        end
        add linkptr, [linkptr]
        jmp_to(:loop_begin)
        pop(t0,t2,t3,t4)
      end

      namespace :init_mem do
        label ":init_mem"
        def core_size; t0; end
        def code_size; t1; end
        def ret_addr; t4; end
        mov ret_addr, t0
        sys CORE,0
        mov t2, core_size
        sub t2, code_size
        if_then(t2,:<=,100) do
          prints("Warning, small core")
          sys BREAK,0
        end
        div t2,3
        mov t7, core_size
        sub t7,t2
        set(:stack_bottom,t7)
        mov t2,t7
        dec t2
        set(:heap_end,t2)
        mov t3, t1
        inc t3
        set(:heap_begin,t3)
        set_offset(t2,_last,t3) #linkedlist.last.last = heap_begin
        set_offset(t2,_free,used_value)
        set_offset(t2,_size,0)
        sub t2, t3  #heap_end -= heap_begin

        set_offset(t3,_size, t2) #linkedlist.first.size = heap_size
        set_offset(t3,_free,free_value)
        set_offset(t3,_last,0)
        jmp ret_addr

        const(:stack_bottom, 0)
        const(:heap_begin,   0)
        const(:heap_end,     0)
      end

    end
  end
end
