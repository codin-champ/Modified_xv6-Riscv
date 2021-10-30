#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

int main(int argc, char *argv[]) {
    int i;
    char *nargv[100];

    if(argc < 3 || (argv[1][0] < '0' || argv[1][0] > '9')){
        fprintf(2, "Usage: %s mask command\n", argv[0]);
        exit(1);
    }
    if(trace(atoi(argv[1]))<0)
    {
        fprintf(2, "trace failed\n");
        exit(1);
    }
    for(i = 2; i < argc && i < 100; i++){
    	nargv[i-2] = argv[i];
    }
    exec(nargv[0], nargv);
    exit(0);
}