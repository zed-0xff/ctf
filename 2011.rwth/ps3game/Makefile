ps3gamedbg: ps3game.c
	gcc -g -O2 -m32 -std=gnu99 -o $@ $<

exploit: exploit.c import.c
	gcc -m32 -std=gnu99 -o $@ $< import.c

clean:
	rm -f ps3game
