#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"

// Fetch the uint64 at addr from the current process.
int
fetchaddr(uint64 addr, uint64 *ip)
{
  struct proc *p = myproc();
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    return -1;
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    return -1;
  return 0;
}

// Fetch the nul-terminated string at addr from the current process.
// Returns length of string, not including nul, or -1 for error.
int
fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  int err = copyinstr(p->pagetable, buf, addr, max);
  if(err < 0)
    return err;
  return strlen(buf);
}

static uint64
argraw(int n)
{
  struct proc *p = myproc();
  switch (n) {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  *ip = argraw(n);
  return 0;
}

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);
  return 0;
}

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
}

extern uint64 sys_chdir(void);
extern uint64 sys_close(void);
extern uint64 sys_dup(void);
extern uint64 sys_exec(void);
extern uint64 sys_exit(void);
extern uint64 sys_fork(void);
extern uint64 sys_fstat(void);
extern uint64 sys_getpid(void);
extern uint64 sys_kill(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_mknod(void);
extern uint64 sys_open(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_sleep(void);
extern uint64 sys_unlink(void);
extern uint64 sys_wait(void);
extern uint64 sys_write(void);
extern uint64 sys_uptime(void);
extern uint64 sys_trace(void);
extern uint64 sys_waitx(void);
extern uint64 sys_set_priority(void);

static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
[SYS_trace]   sys_trace,
[SYS_waitx]   sys_waitx,
[SYS_set_priority] sys_set_priority,
};

void SyscallNamesArray(char *names[NELEM(syscalls)])
{
  names[1] = "fork";
  names[2] = "exit";
  names[3] = "wait";
  names[4] = "pipe";
  names[5] = "read";
  names[6] = "kill";
  names[7] = "exec";
  names[8] = "fstat";
  names[9] = "chdir";
  names[10] = "dup";
  names[11] = "getpid";
  names[12] = "sbrk";
  names[13] = "sleep";
  names[14] = "uptime";
  names[15] = "open";
  names[16] = "write";
  names[17] = "mknod";
  names[18] = "unlink";
  names[19] = "link";
  names[20] = "mkdir";
  names[21] = "close";
  names[22] = "trace";
  names[23] = "set_priority";
}

void ArgumentCount(int *count)
{
  count[1] = 0;
  count[2] = 1;
  count[3] = 1;
  count[4] = 0;
  count[5] = 3;
  count[6] = 2;
  count[7] = 2;
  count[8] = 1;
  count[9] = 1;
  count[10] = 1;
  count[11] = 0;
  count[12] = 1;
  count[13] = 1;
  count[14] = 0;
  count[15] = 2;
  count[16] = 3;
  count[17] = 3;
  count[18] = 1;
  count[19] = 2;
  count[20] = 1;
  count[21] = 1;
  count[22] = 1;
}

void
syscall(void)
{
  char *names[25];
  SyscallNamesArray(names);
  int count[25];
  ArgumentCount(count);
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) 
  {
    int arg1 = p->trapframe->a0;
    int arg2 = p->trapframe->a1;
    int arg3 = p->trapframe->a2;
    p->trapframe->a0 = syscalls[num]();
    int mask = p->mask;
    if((mask >> num) &0x1 )
    {
      //printf("%d: sycscall %s (%d, %d, %d) ->%d\n",p->pid,names[num],p->trapframe->a2,p->trapframe->a1,p->trapframe->a3,p->trapframe->a0);
      printf("%d: syscall %s (",p->pid,names[num]);
      if(count[num] == 1)
      {
       printf("%d", arg1); 
      }
      if(count[num] == 2)
      {
        printf("%d %d", arg1, arg2);
      }
      if(count[num] == 3)
      {
        printf("%d %d %d", arg1, arg2, arg3);
      }
      printf(") ->%d\n",p->trapframe->a0);
    }
  } 
  else 
  {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
