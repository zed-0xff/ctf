//----- (0804926C) --------------------------------------------------------
int __cdecl startemulation(int mem, int a2, FILE *stream)
{
  int result; // eax@2
  char v4; // al@44
  char v5; // [sp+1Dh] [bp-1Bh]@39
  unsigned __int16 IP; // [sp+1Eh] [bp-1Ah]@1
  unsigned __int16 SP; // [sp+20h] [bp-18h]@1
  unsigned __int16 BP; // [sp+22h] [bp-16h]@1
  int v9; // [sp+24h] [bp-14h]@1
  int i; // [sp+28h] [bp-10h]@3
  char v11; // [sp+2Ch] [bp-Ch]@21
  char v12; // [sp+2Dh] [bp-Bh]@21
  unsigned __int16 v13; // [sp+2Eh] [bp-Ah]@34

  IP = 0;
  SP = -2;
  BP = -2;
  v9 = 0;
  while ( 2 )
  {
    v4 = (unsigned int)v9++ <= 0x5F5E0FF;
    if ( v4 )
    {
      result = *(_BYTE *)(mem + IP);
      switch ( (_BYTE)result )
      {
        case 0x40:
          printf("ip=%hx, sp=%hx, bp=%hx\n", IP, SP, BP);
          for ( i = 65534; i > 65280; i -= 2 )
            printf("%hx=%hx \n", i, *(mem + i));
          ++IP;
          continue;
        case 0x41:
          printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
          ++IP;
          continue;
        case 0:
          ++IP;
          *(arg + mem) = arg(1);
          IP += 4;
          continue;
        case 1:
          ++IP;
          *(arg + mem) = *(mem + arg(1));
          IP += 4;
          continue;
        case 0x25:				// PTR
          ++IP;
          *(arg + mem) = *(mem + *(mem + arg(1)));
          IP += 4;
          continue;
        case 0x26:				// MOVPTR
          ++IP;
          *(*(mem + arg) + mem) = *(mem + arg(1));
          IP += 4;
          continue;
        case 2:
          ++IP;
          *(arg + mem) = *(mem + arg) + *(mem + arg(1));
          IP += 4;
          continue;
        case 3:
          ++IP;
          *(arg + mem) = *(mem + arg) - *(mem + arg(1));
          IP += 4;
          continue;
        case 4:
          ++IP;
          *(arg + mem) = *(mem + arg) * *(mem + arg(1));
          IP += 4;
          continue;
        case 0xB:
          ++IP;
          *(mem + arg) /= *(mem + arg(1));
          IP += 4;
          continue;
        case 0x42:
          ++IP;
          printf("%hu\n", *(mem + arg));
          IP += 2;
          continue;
        case 0x43:
          ++IP;
          *(mem + arg) = atoi((const char *)(mem + *(mem + arg(1))));
          IP += 4;
          continue;
        case 0x24: // push BP
          ++IP;
          *(arg + mem) = BP;
          IP += 2;
          continue;
        case 0x20:
          ++IP;
          *(SP + mem) = *(mem + arg);
          SP -= 2;
          IP += 2;
          continue;
        case 0x21:
          ++IP;
          SP += 2;
          *(arg + mem) = *(mem + SP);
          IP += 2;
          continue;
        case 0x22:
          ++IP;
          v11 = BP;
          v12 = SP;
          BP = SP;
          SP -= arg;
          *(SP + mem) = v12;
          SP -= 2;
          *(SP + mem) = v11;
          SP -= 2;
          IP += 2;
          continue;
        case 0x23: // pop BP,SP
          ++IP;
          SP += 2;
          BP = *(mem + SP);
          SP += 2;
          SP = *(mem + SP);
          continue;
        case 9: 					// CALL
          ++IP;
          *(mem + SP) = IP + 2;
          SP -= 2;
          IP = arg;
          continue;
        case 5:						// JMP
          ++IP;
          IP = arg;
          continue;
        case 6:						// GOTO arg IF arg(1) == arg(2)
          ++IP;
          if ( *(mem + arg(1)) == *(mem + arg(2)) )
            IP = arg;
          else
            IP += 6;
          continue;
        case 8:
          ++IP;
          if ( *(mem + arg(1)) >= *(mem + arg(2)) )
            IP += 6;
          else
            IP = arg;
          continue;
        case 7:
          ++IP;
          if ( *(mem + arg(1)) <= *(mem + arg(2)) )
            IP += 6;
          else
            IP = arg;
          continue;
        case 0xA: // ret
          ++IP;
          SP += 2;
          v13 = IP;
          IP = *(mem + SP);
          SP += *(mem + v13);
          continue;
        case 0x12:
          ++IP;
          putchar(*(_BYTE *)(mem + *(mem + arg)));
          IP += 2;
          continue;
        case 0x11:
          ++IP;
          if ( stream )
            fputc(*(_BYTE *)(mem + *(mem + arg)), stream);
          IP += 2;
          continue;
        case 0x10:
          ++IP;
          v5 = 0;
          if ( a2 )
            __isoc99_fscanf(a2, "%c", &v5);
          *(arg + mem) = v5;
          IP += 2;
          continue;
        case 0x13:
          ++IP;
          system((const char *)(mem + *(mem + arg)));
          IP += 2;
          continue;
        default:
          ++IP;
          printf("Debug: Unknown instruction at %x\n", IP);
          continue;
        case 0x30:
          return result;
      }
    }
    else
    {
      printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
      result = printf("Error: possible looping or long program. Killed!");
    }
    break;
  }
  return result;
}
// 804872C: using guessed type int __isoc99_fscanf(_DWORD, const char *, ...);

