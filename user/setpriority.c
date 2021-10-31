#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
int main(int argc, char *argv[]) 
{
  if (argc != 3) 
  {
    fprintf(2, "Usage: setpriority newpriority pid");
    exit(1);
  }
  //printf("calling set_priority(%d,%d)\n", atoi(argv[1]), atoi(argv[2]));
  set_priority(atoi(argv[1]), atoi(argv[2]));
  exit(0);
}