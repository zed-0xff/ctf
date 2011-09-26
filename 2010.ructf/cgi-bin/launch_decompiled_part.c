#include <defs.h>


//-------------------------------------------------------------------------
// Data declarations

extern _UNKNOWN start; // weak
extern char s2[]; // idb
extern char aIn[]; // idb
extern char aOut[]; // idb
extern char aArg[]; // idb
extern char name[]; // idb
extern char aRequest_method[]; // idb
extern char aGet[]; // idb
extern char format[]; // idb
extern char aContentTypeTex[42]; // weak
extern char s[]; // idb
extern char aErrorInHandlin[]; // idb
extern char path[]; // idb
extern char aFailedToChange[]; // idb
extern char aBadAction[]; // idb
extern char a__Data[]; // idb
extern char aBadInputFileNa[]; // idb
extern char aBadOutputFileN[]; // idb
extern char modes[]; // idb
extern char aW[]; // idb
extern char aBadInputFile[]; // idb
extern char aBadOutputFileE[]; // idb
extern char aInternalErrorF[]; // idb
extern char aInternalMemory[]; // idb
extern char aInternalReadEr[]; // idb
extern char aIpHxSpHxBpHx[]; // idb
extern char aHxHx[]; // idb
extern char aSCC_0[]; // idb
extern char aContentTypeT_0[42]; // weak
extern char aHu[]; // idb
extern char aC[3]; // weak
extern char aDebugUnknownIn[]; // idb
extern char aErrorPossibleL[]; // idb
extern int _init_array_end; // weak
extern int dword_804BF14[]; // weak
extern _UNKNOWN _DTOR_END__; // weak
extern int dword_804BF1C; // weak
extern char byte_804C080; // weak
extern int dword_804C084; // weak
extern char action[]; // idb
extern char infile[]; // idb
extern char outfile[]; // idb
extern char arg[]; // idb
// extern _UNKNOWN _gmon_start__; weak

//-------------------------------------------------------------------------
// Function declarations

void (*__cdecl init_proc())(void);
int *__errno_location(void);
int open(const char *file, int oflag, ...);
int __isoc99_fscanf(_DWORD, const char *, ...); // weak
int __gmon_start__(void); // weak
char *strchr(const char *s, int c);
char *getenv(const char *name);
int system(const char *command);
char *strncpy(char *dest, const char *src, size_t n);
int putchar(int c);
ssize_t read(int fd, void *buf, size_t nbytes);
__int32 strtol(const char *nptr, char **endptr, int base);
int fclose(FILE *stream);
void *memcpy(void *dest, const void *src, size_t n);
size_t strlen(const char *s);
FILE *fopen(const char *filename, const char *modes);
char *strcpy(char *dest, const char *src);
int printf(const char *format, ...);
int chdir(const char *path);
__uid_t getuid(void);
int atoi(const char *nptr);
int close(int fd);
void *malloc(size_t size);
int fputc(int c, FILE *stream);
int puts(const char *s);
void bzero(void *s, size_t n);
int __fxstat(int ver, int fildes, struct stat *stat_buf);
int strcmp(const char *s1, const char *s2);
void exit(int status);
int __cdecl sub_8048904();
void __cdecl sub_804892C();
int __cdecl sub_804897B();
char *__cdecl set(const char *s1, const char *src);
int __cdecl handleparams();
int __cdecl main();
int __cdecl startemulation(int, int, FILE *stream); // idb
void __cdecl _libc_csu_fini();
int *__cdecl _libc_csu_init();
void __cdecl _i686_get_pc_thunk_bx();
int __cdecl fstat(int fildes, struct stat *a2);
void (*__cdecl sub_8049D64())(void);
void __cdecl term_proc();


//----- (080486E4) --------------------------------------------------------
void (*__cdecl init_proc())(void)
{
  sub_8048904();
  sub_804897B();
  return sub_8049D64();
}

//----- (080488E0) --------------------------------------------------------
#error "80488E3: positive sp value has been found (funcsize=2)"

//----- (08048904) --------------------------------------------------------
int __cdecl sub_8048904()
{
  int v1; // ST04_4@3

  if ( &_gmon_start__ )
    __gmon_start__();
  return v1;
}
// 804873C: using guessed type int __gmon_start__(void);

//----- (0804892C) --------------------------------------------------------
void __cdecl sub_804892C()
{
  int v0; // eax@2
  int i; // ebx@2

  if ( !byte_804C080 )
  {
    v0 = dword_804C084;
    for ( i = ((signed int)(&_DTOR_END__ - (_UNKNOWN *)dword_804BF14) >> 2) - 1;
          dword_804C084 < (unsigned int)i;
          v0 = dword_804C084 )
    {
      dword_804C084 = v0 + 1;
      ((void (*)(void))dword_804BF14[dword_804C084])();
    }
    byte_804C080 = 1;
  }
}
// 804BF14: using guessed type int dword_804BF14[];
// 804C080: using guessed type char byte_804C080;
// 804C084: using guessed type int dword_804C084;

//----- (0804897B) --------------------------------------------------------
int __cdecl sub_804897B()
{
  int result; // eax@1

  result = dword_804BF1C;
  if ( dword_804BF1C )
    result = 0;
  return result;
}
// 804BF1C: using guessed type int dword_804BF1C;

//----- (080489A0) --------------------------------------------------------
char *__cdecl set(const char *s1, const char *src)
{
  char *result; // eax@2

  if ( strcmp(s1, "action") )
  {
    if ( strcmp(s1, "in") )
    {
      if ( strcmp(s1, "out") )
      {
        result = (char *)strcmp(s1, "arg");
        if ( !result )
          result = strcpy(arg, src);
      }
      else
      {
        result = strcpy(outfile, src);
      }
    }
    else
    {
      result = strcpy(infile, src);
    }
  }
  else
  {
    result = strcpy(action, src);
  }
  return result;
}

//----- (08048A59) --------------------------------------------------------
int __cdecl handleparams()
{
  signed int v1; // eax@9
  char nptr; // [sp+13h] [bp-825h]@22
  char src[1024]; // [sp+18h] [bp-820h]@8
  char s1[1024]; // [sp+418h] [bp-420h]@7
  char *s; // [sp+818h] [bp-20h]@1
  int v6; // [sp+81Ch] [bp-1Ch]@5
  int v7; // [sp+820h] [bp-18h]@5
  __int32 v8; // [sp+824h] [bp-14h]@5
  int v9; // [sp+828h] [bp-10h]@5
  size_t i; // [sp+82Ch] [bp-Ch]@5

  s = getenv("QUERY_STRING");
  if ( !s )
    return -1;
  if ( !*s )
    return -1;
  v6 = 0;
  v7 = 0;
  v8 = 0;
  v9 = 1;
  for ( i = 0; i < strlen(s); ++i )
  {
    if ( v9 == 1 )
    {
      s1[v7] = 0;
      s1[v7 + 1] = 0;
    }
    else
    {
      src[v7] = 0;
      src[v7 + 1] = 0;
    }
    v1 = s[i];
    if ( v1 == 38 )
    {
      if ( v9 )
      {
        src[0] = 0;
        s1[v7] = 0;
      }
      else
      {
        src[v7] = 0;
      }
      set(s1, src);
      s1[0] = 0;
      src[0] = 0;
      ++v6;
      v9 = 1;
      v7 = 0;
    }
    else
    {
      if ( v1 > 38 )
      {
        if ( v1 == 43 )
        {
          if ( v9 )
            s1[v7] = 32;
          else
            src[v7] = 32;
          ++v7;
        }
        else
        {
          if ( v1 != 61 )
          {
LABEL_30:
            if ( v9 )
              s1[v7] = s[i];
            else
              src[v7] = s[i];
            ++v7;
            continue;
          }
          if ( v9 )
          {
            s1[v7] = 0;
            v7 = 0;
            v9 = 0;
          }
          else
          {
            src[v7++] = s[i];
          }
        }
      }
      else
      {
        if ( v1 != 37 )
          goto LABEL_30;
        strncpy(&nptr, &s[i + 1], 2u);
        v8 = strtol(&nptr, 0, 16);
        if ( v9 )
          s1[v7] = v8;
        else
          src[v7] = v8;
        ++v7;
        i += 2;
      }
    }
  }
  if ( s1[0] )
  {
    set(s1, src);
    ++v6;
  }
  return v6;
}
// 8048A59: using guessed type char s1[1024];
// 8048A59: using guessed type char src[1024];

//----- (08048CE5) --------------------------------------------------------
int __cdecl main()
{
  __uid_t v0; // ebx@34
  int *v1; // eax@34
  ssize_t v2; // eax@42
  int result; // eax@45
  char v4; // [sp+10h] [bp-80h]@36
  signed int v5; // [sp+3Ch] [bp-54h]@36
  char *v6; // [sp+68h] [bp-28h]@1
  int v7; // [sp+6Ch] [bp-24h]@14
  FILE *v8; // [sp+70h] [bp-20h]@28
  FILE *v9; // [sp+74h] [bp-1Ch]@28
  size_t v10; // [sp+78h] [bp-18h]@36
  int v11; // [sp+7Ch] [bp-14h]@39

  v6 = getenv("REQUEST_METHOD");
  if ( strcmp(v6, "GET") )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Only GET method is supported");
    exit(1);
  }
  if ( handleparams() == -1 )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Error in handling params or no params");
    exit(1);
  }
  if ( chdir("actions") == -1 )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Failed to change directory");
    exit(1);
  }
  if ( strchr(action, 46) || strchr(action, 47) )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Bad action");
    exit(1);
  }
  v7 = open(action, 0);
  if ( v7 == -1 )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Bad action");
    exit(1);
  }
  if ( chdir("../data") == -1 )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Failed to change directory");
    exit(1);
  }
  if ( strchr(infile, 46) || strchr(infile, 47) )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Bad input file name");
    exit(1);
  }
  if ( strchr(outfile, 46) || strchr(outfile, 47) )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Bad output file name");
    exit(1);
  }
  v8 = fopen(infile, "r");
  v9 = fopen(outfile, "w");
  if ( infile[0] )
  {
    if ( !v8 )
    {
      printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
      puts("Bad input file");
      exit(1);
    }
  }
  if ( outfile[0] )
  {
    if ( !v9 )
    {
      printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
      v0 = getuid();
      v1 = __errno_location();
      printf("Bad output file, errno=%d getuid=%d\n", *v1, v0);
      exit(1);
    }
  }
  fstat(v7, (struct stat *)&v4);
  v10 = v5;
  if ( v5 > 32768 )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Internal error: file is too big");
    exit(1);
  }
  v11 = (int)malloc(0x10000u);
  bzero((void *)v11, 0x10000u);
  if ( !v11 )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Internal memory error");
    exit(1);
  }
  v2 = read(v7, (void *)v11, v10);
  if ( v2 != v10 )
  {
    printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
    puts("Internal read error");
    exit(1);
  }
  memcpy((void *)(v11 + 32768), arg, 0x400u);
  startemulation(v11, (int)v8, v9);
  result = close(v7);
  if ( v8 )
    result = fclose(v8);
  if ( v9 )
    result = fclose(v9);
  return result;
}

//----- (0804926C) --------------------------------------------------------
int __cdecl startemulation(int a1, int a2, FILE *stream)
{
  int result; // eax@2
  char v4; // al@44
  char v5; // [sp+1Dh] [bp-1Bh]@39
  unsigned __int16 v6; // [sp+1Eh] [bp-1Ah]@1
  unsigned __int16 v7; // [sp+20h] [bp-18h]@1
  unsigned __int16 v8; // [sp+22h] [bp-16h]@1
  int v9; // [sp+24h] [bp-14h]@1
  int i; // [sp+28h] [bp-10h]@3
  char v11; // [sp+2Ch] [bp-Ch]@21
  char v12; // [sp+2Dh] [bp-Bh]@21
  unsigned __int16 v13; // [sp+2Eh] [bp-Ah]@34

  v6 = 0;
  v7 = -2;
  v8 = -2;
  v9 = 0;
  while ( 2 )
  {
    v4 = (unsigned int)v9++ <= 0x5F5E0FF;
    if ( v4 )
    {
      result = *(_BYTE *)(a1 + v6);
      switch ( (_BYTE)result )
      {
        case 0x40:
          printf("ip=%hx, sp=%hx, bp=%hx\n", v6, v7, v8);
          for ( i = 65534; i > 65280; i -= 2 )
            printf("%hx=%hx \n", i, *(_WORD *)(a1 + i));
          ++v6;
          continue;
        case 0x41:
          printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1", 13, 10);
          ++v6;
          continue;
        case 0:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = *(_WORD *)(a1 + v6 + 2);
          v6 += 4;
          continue;
        case 1:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2));
          v6 += 4;
          continue;
        case 0x25:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = *(_WORD *)(a1 + *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2)));
          v6 += 4;
          continue;
        case 0x26:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + *(_WORD *)(a1 + v6)) + a1) = *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2));
          v6 += 4;
          continue;
        case 2:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = *(_WORD *)(a1 + *(_WORD *)(a1 + v6))
                                               + *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2));
          v6 += 4;
          continue;
        case 3:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = *(_WORD *)(a1 + *(_WORD *)(a1 + v6))
                                               - *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2));
          v6 += 4;
          continue;
        case 4:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = *(_WORD *)(a1 + *(_WORD *)(a1 + v6))
                                               * *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2));
          v6 += 4;
          continue;
        case 0xB:
          ++v6;
          *(_WORD *)(a1 + *(_WORD *)(a1 + v6)) /= *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2));
          v6 += 4;
          continue;
        case 0x42:
          ++v6;
          printf("%hu\n", *(_WORD *)(a1 + *(_WORD *)(a1 + v6)));
          v6 += 2;
          continue;
        case 0x43:
          ++v6;
          *(_WORD *)(a1 + *(_WORD *)(a1 + v6)) = atoi((const char *)(a1 + *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2))));
          v6 += 4;
          continue;
        case 0x24:
          ++v6;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = v8;
          v6 += 2;
          continue;
        case 0x20:
          ++v6;
          *(_WORD *)(v7 + a1) = *(_WORD *)(a1 + *(_WORD *)(a1 + v6));
          v7 -= 2;
          v6 += 2;
          continue;
        case 0x21:
          ++v6;
          v7 += 2;
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = *(_WORD *)(a1 + v7);
          v6 += 2;
          continue;
        case 0x22:
          ++v6;
          v11 = v8;
          v12 = v7;
          v8 = v7;
          v7 -= *(_WORD *)(a1 + v6);
          *(_WORD *)(v7 + a1) = v12;
          v7 -= 2;
          *(_WORD *)(v7 + a1) = v11;
          v7 -= 2;
          v6 += 2;
          continue;
        case 0x23:
          ++v6;
          v7 += 2;
          v8 = *(_WORD *)(a1 + v7);
          v7 += 2;
          v7 = *(_WORD *)(a1 + v7);
          continue;
        case 9:
          ++v6;
          *(_WORD *)(a1 + v7) = v6 + 2;
          v7 -= 2;
          v6 = *(_WORD *)(a1 + v6);
          continue;
        case 5:
          ++v6;
          v6 = *(_WORD *)(a1 + v6);
          continue;
        case 6:
          ++v6;
          if ( *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2)) == *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 4)) )
            v6 = *(_WORD *)(a1 + v6);
          else
            v6 += 6;
          continue;
        case 8:
          ++v6;
          if ( *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2)) >= *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 4)) )
            v6 += 6;
          else
            v6 = *(_WORD *)(a1 + v6);
          continue;
        case 7:
          ++v6;
          if ( *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 2)) <= *(_WORD *)(a1 + *(_WORD *)(a1 + v6 + 4)) )
            v6 += 6;
          else
            v6 = *(_WORD *)(a1 + v6);
          continue;
        case 0xA:
          ++v6;
          v7 += 2;
          v13 = v6;
          v6 = *(_WORD *)(a1 + v7);
          v7 += *(_WORD *)(a1 + v13);
          continue;
        case 0x12:
          ++v6;
          putchar(*(_BYTE *)(a1 + *(_WORD *)(a1 + *(_WORD *)(a1 + v6))));
          v6 += 2;
          continue;
        case 0x11:
          ++v6;
          if ( stream )
            fputc(*(_BYTE *)(a1 + *(_WORD *)(a1 + *(_WORD *)(a1 + v6))), stream);
          v6 += 2;
          continue;
        case 0x10:
          ++v6;
          v5 = 0;
          if ( a2 )
            __isoc99_fscanf(a2, "%c", &v5);
          *(_WORD *)(*(_WORD *)(a1 + v6) + a1) = v5;
          v6 += 2;
          continue;
        case 0x13:
          ++v6;
          system((const char *)(a1 + *(_WORD *)(a1 + *(_WORD *)(a1 + v6))));
          v6 += 2;
          continue;
        default:
          ++v6;
          printf("Debug: Unknown instruction at %x\n", v6);
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

//----- (08049CC0) --------------------------------------------------------
void __cdecl _libc_csu_fini()
{
  ;
}

//----- (08049CD0) --------------------------------------------------------
int *__cdecl _libc_csu_init()
{
  init_proc();
  return &_init_array_end;
}
// 804BF0C: using guessed type int _init_array_end;

//----- (08049D2A) --------------------------------------------------------
void __cdecl _i686_get_pc_thunk_bx()
{
  ;
}

//----- (08049D30) --------------------------------------------------------
int __cdecl fstat(int fildes, struct stat *a2)
{
  return __fxstat(3, fildes, a2);
}

//----- (08049D64) --------------------------------------------------------
void (*__cdecl sub_8049D64())(void)
{
  void (*result)(void); // eax@1
  int *v1; // ebx@2

  result = (void (*)(void))_init_array_end;
  if ( _init_array_end != -1 )
  {
    v1 = &_init_array_end;
    do
    {
      result();
      --v1;
      result = (void (*)(void))*v1;
    }
    while ( *v1 != -1 );
  }
  return result;
}
// 804BF0C: using guessed type int _init_array_end;

//----- (08049D8C) --------------------------------------------------------
void __cdecl term_proc()
{
  sub_804892C();
}

#error "There were 1 decompilation failure(s) on 15 function(s)"
