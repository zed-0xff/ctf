#include <stdio.h>
#include <string.h>
#include <stdlib.h>


void hexdump(unsigned char *data, unsigned int amount);
void hexdump2(unsigned char *data, unsigned int amount, char* title);

void hexdump2(unsigned char *data, unsigned int amount, char* title){
        fprintf(stdout, "/* %s, %u bytes */\n", title, amount);
        hexdump(data,amount);
}

void hexdump(unsigned char *data, unsigned int amount) {
	unsigned int	dp, p;	/* data pointer */
	const char	trans[] =
		"................................ !\"#$%&'()*+,-./0123456789"
		":;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklm"
		"nopqrstuvwxyz{|}~...................................."
		"....................................................."
		"........................................";


	fprintf (stdout, "0x%p  ", &data[0]);

	for (dp = 1; dp <= amount; dp++) {
		fprintf (stdout, "%02x ", data[dp-1]);
		if ((dp % 4)== 0)
			fprintf (stdout, " ");
		if ((dp % 16) == 0) {
			fprintf (stdout, "| ");
			p = dp;
			for (dp -= 16; dp < p; dp++)
				fprintf (stdout, "%c", trans[data[dp]]);
			fflush (stdout);
			fprintf (stdout, "\n");
			fprintf (stdout, "0x%p  ", &data[dp]);
		}
		fflush (stdout);
	}

	if ((amount % 16) != 0) {
		p = dp = 16 - (amount % 16);
		for (dp = p; dp > 0; dp--) {
			fprintf (stdout, "   ");
			if (((dp % 8) == 0) && (p != 8))
				fprintf (stdout, " ");
			fflush (stdout);
		}
		fprintf (stdout, "  | ");
		for (dp = (amount - (16 - p)); dp < amount; dp++)
			fprintf (stdout, "%c", trans[data[dp]]);
		fflush (stdout);
	}
	fprintf (stdout, "\n");

	return;
}
 

