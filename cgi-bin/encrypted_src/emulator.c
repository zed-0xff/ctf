#include <stdio.h>

enum opcodes{SET=0x0,MOV=0x1,ADD=0x2,SUB=0x3,MUL=0x4,
	     JMP=0x5,JE=0x6,JA=0x7,JB=0x8,CALL=0x9,RET=0xa,DIV=0xb,READ=0x10,WRITE=0x11,
	     PRINT=0x12,EXEC=0x13,PUSH=0x20,POP=0x21,ENTER=0x22,LEAVE=0x23,GETBP=0x24,PTR=0x25,MOVPTR=0x26,
	     END=0x30,DUMP=0x40,CONTTYPE=0x41,SHOWSHORT=0x42,GETSHORT=0x43};

void startemulation(char *memory,FILE *infd,FILE *outfd)
{
  struct registers{unsigned short ip;unsigned short sp;unsigned short bp;} reg;
  reg.ip=0;
  reg.sp=0xfffe;
  reg.bp=0xfffe;
  
  unsigned int counter=0;
  
  while(counter++<100000000) {
    switch(memory[reg.ip]) {
      case END:
	return;
	break;
      case DUMP:
	printf("ip=%hx, sp=%hx, bp=%hx\n",reg.ip,reg.sp,reg.bp);
	int i;
	for(i=0xfffe;i>0xff00;i=i-2)
	  printf("%hx=%hx \n",i,*(unsigned short *)(memory+i));
	reg.ip++;
	break;
      case CONTTYPE:
	printf("%s%c%c\n","Content-Type:text/html;charset=iso-8859-1",13,10);
	reg.ip++;
	break;
      case SET:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))=*(unsigned short *)(memory+reg.ip+2);
	reg.ip+=4;
	break;
      case MOV:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))=*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2)));
	reg.ip+=4;
	break;
      case PTR:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))=*(unsigned short *)(memory+*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2))));
	reg.ip+=4;
	break;
      case MOVPTR:
	reg.ip++;
	*(unsigned short *)(memory+*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip))))=*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2)));
	reg.ip+=4;
	break;

      case ADD:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))+=*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2)));
	reg.ip+=4;
	break;
      case SUB:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))-=*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2)));
	reg.ip+=4;
	break;
      case MUL:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))*=*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2)));
	reg.ip+=4;
	break;
      case DIV:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))/=*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2)));
	reg.ip+=4;
	break;

      case SHOWSHORT:
	reg.ip++;
	printf("%hu\n",*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip))));
	reg.ip+=2;
	break;
      case GETSHORT:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))=(unsigned short)atoi((unsigned short *)(memory+*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2)))));
	reg.ip+=4;
	break;

      case GETBP:
	reg.ip++;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))=reg.bp;
	reg.ip+=2;
	break;
	
      case PUSH:
	reg.ip++;
	*(unsigned short *)(memory+reg.sp)=*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)));
	reg.sp-=2;
	reg.ip+=2;
	break;
      case POP:
	reg.ip++;
	reg.sp+=2;
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))=*(unsigned short *)(memory+reg.sp);
	reg.ip+=2;
	break;
      case ENTER:
	reg.ip++;

	char oldregbp=reg.bp;
	char oldregsp=reg.sp;
	
	reg.bp=reg.sp;

	reg.sp-=*(unsigned short *)(memory+reg.ip);

	*(unsigned short *)(memory+reg.sp)=oldregsp;
	reg.sp-=2;
	
	*(unsigned short *)(memory+reg.sp)=oldregbp;
	reg.sp-=2;
	
	reg.ip+=2;
	break;
      case LEAVE:
	reg.ip++;

	reg.sp+=2;
	reg.bp=*(unsigned short *)(memory+reg.sp);

	reg.sp+=2;
	reg.sp=*(unsigned short *)(memory+reg.sp);
	
	break;

      case CALL:
	reg.ip++;
	//reg.ip+=2;
	*(unsigned short *)(memory+reg.sp)=reg.ip+2;
	reg.sp-=2;
	
	reg.ip=*(unsigned short *)(memory+reg.ip);
	break;

      case JMP:
	reg.ip++;
	//reg.ip+=2;
	reg.ip=*(unsigned short *)(memory+reg.ip);
	break;
	
      case JE:
	reg.ip++;
	//reg.ip+=2;
	if(*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2))) == *(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+4)))) {
	  reg.ip=*(unsigned short *)(memory+reg.ip);
	} else
	  reg.ip+=6;
	break;

      case JB:
	reg.ip++;
	//reg.ip+=2;
	if(*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2))) < *(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+4)))) {
	  reg.ip=*(unsigned short *)(memory+reg.ip);
	} else
	  reg.ip+=6;
	break;

      case JA:
	reg.ip++;
	//reg.ip+=2;
	if(*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+2))) > *(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip+4)))) {
	  reg.ip=*(unsigned short *)(memory+reg.ip);
	} else
	  reg.ip+=6;
	break;

	
      case RET:
	reg.ip++;
	reg.sp+=2;

	//printf("reg.sp before=%hx",reg.sp);
	//printf("reg.ip=%hx",reg.ip);
	
	unsigned short oldip=reg.ip; // 
	reg.ip=*(unsigned short *)(memory+reg.sp);
	reg.sp+=*(unsigned short *)(memory+oldip);
	
	//printf("reg.sp after=%hx",reg.sp);
	//dprintf("reg.ip=%hx",reg.ip);
	break;
      case PRINT:
	reg.ip++;
	printf("%c",*(unsigned char *)(memory+(*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip))))));
	reg.ip+=2;
	break;
      case WRITE:
	reg.ip++;
	//unsigned char *c=(unsigned char *)(memory+(*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))));
	if(outfd!=0)
	  fprintf(outfd,"%c",*(unsigned char *)(memory+(*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip))))));
	//write(outfd,c,1);
	reg.ip+=2;
	break;
      case READ:
	reg.ip++;
	char c=0;
	if(infd!=0)
	  fscanf(infd,"%c",&c);
	
	*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip)))=(unsigned short)c;
	reg.ip+=2;
	break;
      case EXEC:
	reg.ip++;
	
	system((char *)(memory+(*(unsigned short *)(memory+(*(unsigned short *)(memory+reg.ip))))));

	reg.ip+=2;
	break;
	
      default:
	reg.ip++;
	printf("Debug: Unknown instruction at %x\n",reg.ip);
	break;
    }
  };
  
  printf("%s%c%c\n","Content-Type:text/html;charset=iso-8859-1",13,10);
  printf("Error: possible looping or long program. Killed!");
}

