#include "user.h"
//#include "kernel/stat.h"
#include "kernel/types.h"

int
main(int argc, char *argv[]) {
  if (argc != 3) {
    printf("Usage: setPriority new_priority pid");
    exit(1);
  }

  set_priority(atoi(argv[1]), atoi(argv[2]));
  exit(1);
}