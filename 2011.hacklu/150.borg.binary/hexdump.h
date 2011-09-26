/*
 * This program will print the argvs addresses and the
 * stack from argv[0].
 *
 * Compilation:
 *  + gcc -o stack stack.c
 *
 * THIS PROGRAM IS FOR EDUCATIONAL PURPOSES *ONLY*
 * IT IS PROVIDED "AS IS" AND WITHOUT ANY WARRANTY
 *
 * (c) 2004 Copyright by Inode <inode@wayreth.eu.org>
 *
 */ 


#include <stdio.h>
#include <string.h>
#include <stdlib.h>

//void hexdump (char *desc, unsigned char *data, unsigned int amount);

void
hexdump (/*char *desc,*/ unsigned char *data, unsigned int amount)
{
	unsigned int	dp, p;	/* data pointer */
	const char	trans[] =
		"................................ !\"#$%&'()*+,-./0123456789"
		":;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklm"
		"nopqrstuvwxyz{|}~...................................."
		"....................................................."
		"........................................";


///	printf ("/* %s, %u bytes */\n", desc, amount);

	fprintf (stderr, "0x%p  ", &data[0]);

	for (dp = 1; dp <= amount; dp++) {
		fprintf (stderr, "%02x ", data[dp-1]);
		if ((dp % 4)== 0)
			fprintf (stderr, " ");
		if ((dp % 16) == 0) {
			fprintf (stderr, "| ");
			p = dp;
			for (dp -= 16; dp < p; dp++)
				fprintf (stderr, "%c", trans[data[dp]]);
			fflush (stderr);
			fprintf (stderr, "\n");
			fprintf (stderr, "0x%p  ", &data[dp]);
		}
		fflush (stderr);
	}

	if ((amount % 16) != 0) {
		p = dp = 16 - (amount % 16);
		for (dp = p; dp > 0; dp--) {
			fprintf (stderr, "   ");
			if (((dp % 8) == 0) && (p != 8))
				fprintf (stderr, " ");
			fflush (stderr);
		}
		fprintf (stderr, "  | ");
		for (dp = (amount - (16 - p)); dp < amount; dp++)
			fprintf (stderr, "%c", trans[data[dp]]);
		fflush (stderr);
	}
	fprintf (stderr, "\n");

	return;
}
 

