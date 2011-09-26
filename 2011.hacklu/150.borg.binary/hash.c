#include <mhash.h>
#include "hexdump.h"

int main(int argc, char*argv[]){
    char buf[0x200];
    char result[0x200];
    char v3[0x10];
    MHASH thread; // v5
    int v2;

    if(argc <= 1){
        puts("no args!");
        return;
    }

    if(strlen(argv[1])<100){
        printf("[?] maybe i need %d chars more\n", 100-strlen(argv[1]));
    }

    bzero(buf,sizeof(buf));
    bzero(result,sizeof(result));
    bzero(v3,sizeof(v3));

    memcpy(buf,argv[1],100);
    memset(v3,0,5);
    strncpy(v3,argv[1],4);

    printf("[.] v3 = %s\n",v3);

    thread = mhash_init(1);
    if(!thread) exit(1);
    v2 = strlen(v3);
    printf("[.] updating hash with %d bytes of data\n",v2);
    mhash(thread, v3, v2);
    mhash_deinit(thread, result);

    hexdump(result,16);

    // call result

    return 0;
}
