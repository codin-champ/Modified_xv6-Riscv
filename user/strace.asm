
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

int main(int argc, char *argv[]) {
   0:	cc010113          	addi	sp,sp,-832
   4:	32113c23          	sd	ra,824(sp)
   8:	32813823          	sd	s0,816(sp)
   c:	32913423          	sd	s1,808(sp)
  10:	33213023          	sd	s2,800(sp)
  14:	0680                	addi	s0,sp,832
  16:	892e                	mv	s2,a1
    int i;
    char *nargv[100];

    if(argc < 3 || (argv[1][0] < '0' || argv[1][0] > '9')){
  18:	4789                	li	a5,2
  1a:	00a7dd63          	bge	a5,a0,34 <main+0x34>
  1e:	84aa                	mv	s1,a0
  20:	6588                	ld	a0,8(a1)
  22:	00054783          	lbu	a5,0(a0)
  26:	fd07879b          	addiw	a5,a5,-48
  2a:	0ff7f793          	andi	a5,a5,255
  2e:	4725                	li	a4,9
  30:	02f77263          	bgeu	a4,a5,54 <main+0x54>
        fprintf(2, "Usage: %s mask command\n", argv[0]);
  34:	00093603          	ld	a2,0(s2)
  38:	00001597          	auipc	a1,0x1
  3c:	83858593          	addi	a1,a1,-1992 # 870 <malloc+0xe6>
  40:	4509                	li	a0,2
  42:	00000097          	auipc	ra,0x0
  46:	65c080e7          	jalr	1628(ra) # 69e <fprintf>
        exit(1);
  4a:	4505                	li	a0,1
  4c:	00000097          	auipc	ra,0x0
  50:	2f0080e7          	jalr	752(ra) # 33c <exit>
    }
    if(trace(atoi(argv[1]))<0)
  54:	00000097          	auipc	ra,0x0
  58:	1e8080e7          	jalr	488(ra) # 23c <atoi>
  5c:	00000097          	auipc	ra,0x0
  60:	380080e7          	jalr	896(ra) # 3dc <trace>
  64:	04054363          	bltz	a0,aa <main+0xaa>
  68:	01090793          	addi	a5,s2,16
  6c:	cc040713          	addi	a4,s0,-832
  70:	ffd4869b          	addiw	a3,s1,-3
  74:	1682                	slli	a3,a3,0x20
  76:	9281                	srli	a3,a3,0x20
  78:	068e                	slli	a3,a3,0x3
  7a:	96be                	add	a3,a3,a5
  7c:	32090913          	addi	s2,s2,800
    {
        fprintf(2, "trace failed\n");
        exit(1);
    }
    for(i = 2; i < argc && i < 100; i++){
    	nargv[i-2] = argv[i];
  80:	6390                	ld	a2,0(a5)
  82:	e310                	sd	a2,0(a4)
    for(i = 2; i < argc && i < 100; i++){
  84:	00d78663          	beq	a5,a3,90 <main+0x90>
  88:	07a1                	addi	a5,a5,8
  8a:	0721                	addi	a4,a4,8
  8c:	ff279ae3          	bne	a5,s2,80 <main+0x80>
    }
    exec(nargv[0], nargv);
  90:	cc040593          	addi	a1,s0,-832
  94:	cc043503          	ld	a0,-832(s0)
  98:	00000097          	auipc	ra,0x0
  9c:	2dc080e7          	jalr	732(ra) # 374 <exec>
    exit(0);
  a0:	4501                	li	a0,0
  a2:	00000097          	auipc	ra,0x0
  a6:	29a080e7          	jalr	666(ra) # 33c <exit>
        fprintf(2, "trace failed\n");
  aa:	00000597          	auipc	a1,0x0
  ae:	7de58593          	addi	a1,a1,2014 # 888 <malloc+0xfe>
  b2:	4509                	li	a0,2
  b4:	00000097          	auipc	ra,0x0
  b8:	5ea080e7          	jalr	1514(ra) # 69e <fprintf>
        exit(1);
  bc:	4505                	li	a0,1
  be:	00000097          	auipc	ra,0x0
  c2:	27e080e7          	jalr	638(ra) # 33c <exit>

00000000000000c6 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  c6:	1141                	addi	sp,sp,-16
  c8:	e422                	sd	s0,8(sp)
  ca:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  cc:	87aa                	mv	a5,a0
  ce:	0585                	addi	a1,a1,1
  d0:	0785                	addi	a5,a5,1
  d2:	fff5c703          	lbu	a4,-1(a1)
  d6:	fee78fa3          	sb	a4,-1(a5)
  da:	fb75                	bnez	a4,ce <strcpy+0x8>
    ;
  return os;
}
  dc:	6422                	ld	s0,8(sp)
  de:	0141                	addi	sp,sp,16
  e0:	8082                	ret

00000000000000e2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  e2:	1141                	addi	sp,sp,-16
  e4:	e422                	sd	s0,8(sp)
  e6:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  e8:	00054783          	lbu	a5,0(a0)
  ec:	cb91                	beqz	a5,100 <strcmp+0x1e>
  ee:	0005c703          	lbu	a4,0(a1)
  f2:	00f71763          	bne	a4,a5,100 <strcmp+0x1e>
    p++, q++;
  f6:	0505                	addi	a0,a0,1
  f8:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  fa:	00054783          	lbu	a5,0(a0)
  fe:	fbe5                	bnez	a5,ee <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 100:	0005c503          	lbu	a0,0(a1)
}
 104:	40a7853b          	subw	a0,a5,a0
 108:	6422                	ld	s0,8(sp)
 10a:	0141                	addi	sp,sp,16
 10c:	8082                	ret

000000000000010e <strlen>:

uint
strlen(const char *s)
{
 10e:	1141                	addi	sp,sp,-16
 110:	e422                	sd	s0,8(sp)
 112:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 114:	00054783          	lbu	a5,0(a0)
 118:	cf91                	beqz	a5,134 <strlen+0x26>
 11a:	0505                	addi	a0,a0,1
 11c:	87aa                	mv	a5,a0
 11e:	4685                	li	a3,1
 120:	9e89                	subw	a3,a3,a0
 122:	00f6853b          	addw	a0,a3,a5
 126:	0785                	addi	a5,a5,1
 128:	fff7c703          	lbu	a4,-1(a5)
 12c:	fb7d                	bnez	a4,122 <strlen+0x14>
    ;
  return n;
}
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	addi	sp,sp,16
 132:	8082                	ret
  for(n = 0; s[n]; n++)
 134:	4501                	li	a0,0
 136:	bfe5                	j	12e <strlen+0x20>

0000000000000138 <memset>:

void*
memset(void *dst, int c, uint n)
{
 138:	1141                	addi	sp,sp,-16
 13a:	e422                	sd	s0,8(sp)
 13c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 13e:	ce09                	beqz	a2,158 <memset+0x20>
 140:	87aa                	mv	a5,a0
 142:	fff6071b          	addiw	a4,a2,-1
 146:	1702                	slli	a4,a4,0x20
 148:	9301                	srli	a4,a4,0x20
 14a:	0705                	addi	a4,a4,1
 14c:	972a                	add	a4,a4,a0
    cdst[i] = c;
 14e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 152:	0785                	addi	a5,a5,1
 154:	fee79de3          	bne	a5,a4,14e <memset+0x16>
  }
  return dst;
}
 158:	6422                	ld	s0,8(sp)
 15a:	0141                	addi	sp,sp,16
 15c:	8082                	ret

000000000000015e <strchr>:

char*
strchr(const char *s, char c)
{
 15e:	1141                	addi	sp,sp,-16
 160:	e422                	sd	s0,8(sp)
 162:	0800                	addi	s0,sp,16
  for(; *s; s++)
 164:	00054783          	lbu	a5,0(a0)
 168:	cb99                	beqz	a5,17e <strchr+0x20>
    if(*s == c)
 16a:	00f58763          	beq	a1,a5,178 <strchr+0x1a>
  for(; *s; s++)
 16e:	0505                	addi	a0,a0,1
 170:	00054783          	lbu	a5,0(a0)
 174:	fbfd                	bnez	a5,16a <strchr+0xc>
      return (char*)s;
  return 0;
 176:	4501                	li	a0,0
}
 178:	6422                	ld	s0,8(sp)
 17a:	0141                	addi	sp,sp,16
 17c:	8082                	ret
  return 0;
 17e:	4501                	li	a0,0
 180:	bfe5                	j	178 <strchr+0x1a>

0000000000000182 <gets>:

char*
gets(char *buf, int max)
{
 182:	711d                	addi	sp,sp,-96
 184:	ec86                	sd	ra,88(sp)
 186:	e8a2                	sd	s0,80(sp)
 188:	e4a6                	sd	s1,72(sp)
 18a:	e0ca                	sd	s2,64(sp)
 18c:	fc4e                	sd	s3,56(sp)
 18e:	f852                	sd	s4,48(sp)
 190:	f456                	sd	s5,40(sp)
 192:	f05a                	sd	s6,32(sp)
 194:	ec5e                	sd	s7,24(sp)
 196:	1080                	addi	s0,sp,96
 198:	8baa                	mv	s7,a0
 19a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 19c:	892a                	mv	s2,a0
 19e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1a0:	4aa9                	li	s5,10
 1a2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1a4:	89a6                	mv	s3,s1
 1a6:	2485                	addiw	s1,s1,1
 1a8:	0344d863          	bge	s1,s4,1d8 <gets+0x56>
    cc = read(0, &c, 1);
 1ac:	4605                	li	a2,1
 1ae:	faf40593          	addi	a1,s0,-81
 1b2:	4501                	li	a0,0
 1b4:	00000097          	auipc	ra,0x0
 1b8:	1a0080e7          	jalr	416(ra) # 354 <read>
    if(cc < 1)
 1bc:	00a05e63          	blez	a0,1d8 <gets+0x56>
    buf[i++] = c;
 1c0:	faf44783          	lbu	a5,-81(s0)
 1c4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1c8:	01578763          	beq	a5,s5,1d6 <gets+0x54>
 1cc:	0905                	addi	s2,s2,1
 1ce:	fd679be3          	bne	a5,s6,1a4 <gets+0x22>
  for(i=0; i+1 < max; ){
 1d2:	89a6                	mv	s3,s1
 1d4:	a011                	j	1d8 <gets+0x56>
 1d6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1d8:	99de                	add	s3,s3,s7
 1da:	00098023          	sb	zero,0(s3)
  return buf;
}
 1de:	855e                	mv	a0,s7
 1e0:	60e6                	ld	ra,88(sp)
 1e2:	6446                	ld	s0,80(sp)
 1e4:	64a6                	ld	s1,72(sp)
 1e6:	6906                	ld	s2,64(sp)
 1e8:	79e2                	ld	s3,56(sp)
 1ea:	7a42                	ld	s4,48(sp)
 1ec:	7aa2                	ld	s5,40(sp)
 1ee:	7b02                	ld	s6,32(sp)
 1f0:	6be2                	ld	s7,24(sp)
 1f2:	6125                	addi	sp,sp,96
 1f4:	8082                	ret

00000000000001f6 <stat>:

int
stat(const char *n, struct stat *st)
{
 1f6:	1101                	addi	sp,sp,-32
 1f8:	ec06                	sd	ra,24(sp)
 1fa:	e822                	sd	s0,16(sp)
 1fc:	e426                	sd	s1,8(sp)
 1fe:	e04a                	sd	s2,0(sp)
 200:	1000                	addi	s0,sp,32
 202:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 204:	4581                	li	a1,0
 206:	00000097          	auipc	ra,0x0
 20a:	176080e7          	jalr	374(ra) # 37c <open>
  if(fd < 0)
 20e:	02054563          	bltz	a0,238 <stat+0x42>
 212:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 214:	85ca                	mv	a1,s2
 216:	00000097          	auipc	ra,0x0
 21a:	17e080e7          	jalr	382(ra) # 394 <fstat>
 21e:	892a                	mv	s2,a0
  close(fd);
 220:	8526                	mv	a0,s1
 222:	00000097          	auipc	ra,0x0
 226:	142080e7          	jalr	322(ra) # 364 <close>
  return r;
}
 22a:	854a                	mv	a0,s2
 22c:	60e2                	ld	ra,24(sp)
 22e:	6442                	ld	s0,16(sp)
 230:	64a2                	ld	s1,8(sp)
 232:	6902                	ld	s2,0(sp)
 234:	6105                	addi	sp,sp,32
 236:	8082                	ret
    return -1;
 238:	597d                	li	s2,-1
 23a:	bfc5                	j	22a <stat+0x34>

000000000000023c <atoi>:

int
atoi(const char *s)
{
 23c:	1141                	addi	sp,sp,-16
 23e:	e422                	sd	s0,8(sp)
 240:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 242:	00054603          	lbu	a2,0(a0)
 246:	fd06079b          	addiw	a5,a2,-48
 24a:	0ff7f793          	andi	a5,a5,255
 24e:	4725                	li	a4,9
 250:	02f76963          	bltu	a4,a5,282 <atoi+0x46>
 254:	86aa                	mv	a3,a0
  n = 0;
 256:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 258:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 25a:	0685                	addi	a3,a3,1
 25c:	0025179b          	slliw	a5,a0,0x2
 260:	9fa9                	addw	a5,a5,a0
 262:	0017979b          	slliw	a5,a5,0x1
 266:	9fb1                	addw	a5,a5,a2
 268:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 26c:	0006c603          	lbu	a2,0(a3)
 270:	fd06071b          	addiw	a4,a2,-48
 274:	0ff77713          	andi	a4,a4,255
 278:	fee5f1e3          	bgeu	a1,a4,25a <atoi+0x1e>
  return n;
}
 27c:	6422                	ld	s0,8(sp)
 27e:	0141                	addi	sp,sp,16
 280:	8082                	ret
  n = 0;
 282:	4501                	li	a0,0
 284:	bfe5                	j	27c <atoi+0x40>

0000000000000286 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 286:	1141                	addi	sp,sp,-16
 288:	e422                	sd	s0,8(sp)
 28a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 28c:	02b57663          	bgeu	a0,a1,2b8 <memmove+0x32>
    while(n-- > 0)
 290:	02c05163          	blez	a2,2b2 <memmove+0x2c>
 294:	fff6079b          	addiw	a5,a2,-1
 298:	1782                	slli	a5,a5,0x20
 29a:	9381                	srli	a5,a5,0x20
 29c:	0785                	addi	a5,a5,1
 29e:	97aa                	add	a5,a5,a0
  dst = vdst;
 2a0:	872a                	mv	a4,a0
      *dst++ = *src++;
 2a2:	0585                	addi	a1,a1,1
 2a4:	0705                	addi	a4,a4,1
 2a6:	fff5c683          	lbu	a3,-1(a1)
 2aa:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2ae:	fee79ae3          	bne	a5,a4,2a2 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2b2:	6422                	ld	s0,8(sp)
 2b4:	0141                	addi	sp,sp,16
 2b6:	8082                	ret
    dst += n;
 2b8:	00c50733          	add	a4,a0,a2
    src += n;
 2bc:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2be:	fec05ae3          	blez	a2,2b2 <memmove+0x2c>
 2c2:	fff6079b          	addiw	a5,a2,-1
 2c6:	1782                	slli	a5,a5,0x20
 2c8:	9381                	srli	a5,a5,0x20
 2ca:	fff7c793          	not	a5,a5
 2ce:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2d0:	15fd                	addi	a1,a1,-1
 2d2:	177d                	addi	a4,a4,-1
 2d4:	0005c683          	lbu	a3,0(a1)
 2d8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2dc:	fee79ae3          	bne	a5,a4,2d0 <memmove+0x4a>
 2e0:	bfc9                	j	2b2 <memmove+0x2c>

00000000000002e2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2e2:	1141                	addi	sp,sp,-16
 2e4:	e422                	sd	s0,8(sp)
 2e6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2e8:	ca05                	beqz	a2,318 <memcmp+0x36>
 2ea:	fff6069b          	addiw	a3,a2,-1
 2ee:	1682                	slli	a3,a3,0x20
 2f0:	9281                	srli	a3,a3,0x20
 2f2:	0685                	addi	a3,a3,1
 2f4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2f6:	00054783          	lbu	a5,0(a0)
 2fa:	0005c703          	lbu	a4,0(a1)
 2fe:	00e79863          	bne	a5,a4,30e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 302:	0505                	addi	a0,a0,1
    p2++;
 304:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 306:	fed518e3          	bne	a0,a3,2f6 <memcmp+0x14>
  }
  return 0;
 30a:	4501                	li	a0,0
 30c:	a019                	j	312 <memcmp+0x30>
      return *p1 - *p2;
 30e:	40e7853b          	subw	a0,a5,a4
}
 312:	6422                	ld	s0,8(sp)
 314:	0141                	addi	sp,sp,16
 316:	8082                	ret
  return 0;
 318:	4501                	li	a0,0
 31a:	bfe5                	j	312 <memcmp+0x30>

000000000000031c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 31c:	1141                	addi	sp,sp,-16
 31e:	e406                	sd	ra,8(sp)
 320:	e022                	sd	s0,0(sp)
 322:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 324:	00000097          	auipc	ra,0x0
 328:	f62080e7          	jalr	-158(ra) # 286 <memmove>
}
 32c:	60a2                	ld	ra,8(sp)
 32e:	6402                	ld	s0,0(sp)
 330:	0141                	addi	sp,sp,16
 332:	8082                	ret

0000000000000334 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 334:	4885                	li	a7,1
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <exit>:
.global exit
exit:
 li a7, SYS_exit
 33c:	4889                	li	a7,2
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <wait>:
.global wait
wait:
 li a7, SYS_wait
 344:	488d                	li	a7,3
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 34c:	4891                	li	a7,4
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <read>:
.global read
read:
 li a7, SYS_read
 354:	4895                	li	a7,5
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <write>:
.global write
write:
 li a7, SYS_write
 35c:	48c1                	li	a7,16
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <close>:
.global close
close:
 li a7, SYS_close
 364:	48d5                	li	a7,21
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <kill>:
.global kill
kill:
 li a7, SYS_kill
 36c:	4899                	li	a7,6
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <exec>:
.global exec
exec:
 li a7, SYS_exec
 374:	489d                	li	a7,7
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <open>:
.global open
open:
 li a7, SYS_open
 37c:	48bd                	li	a7,15
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 384:	48c5                	li	a7,17
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 38c:	48c9                	li	a7,18
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 394:	48a1                	li	a7,8
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <link>:
.global link
link:
 li a7, SYS_link
 39c:	48cd                	li	a7,19
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3a4:	48d1                	li	a7,20
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3ac:	48a5                	li	a7,9
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3b4:	48a9                	li	a7,10
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3bc:	48ad                	li	a7,11
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3c4:	48b1                	li	a7,12
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3cc:	48b5                	li	a7,13
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3d4:	48b9                	li	a7,14
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <trace>:
.global trace
trace:
 li a7, SYS_trace
 3dc:	48d9                	li	a7,22
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 3e4:	48dd                	li	a7,23
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3ec:	48e1                	li	a7,24
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3f4:	1101                	addi	sp,sp,-32
 3f6:	ec06                	sd	ra,24(sp)
 3f8:	e822                	sd	s0,16(sp)
 3fa:	1000                	addi	s0,sp,32
 3fc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 400:	4605                	li	a2,1
 402:	fef40593          	addi	a1,s0,-17
 406:	00000097          	auipc	ra,0x0
 40a:	f56080e7          	jalr	-170(ra) # 35c <write>
}
 40e:	60e2                	ld	ra,24(sp)
 410:	6442                	ld	s0,16(sp)
 412:	6105                	addi	sp,sp,32
 414:	8082                	ret

0000000000000416 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 416:	7139                	addi	sp,sp,-64
 418:	fc06                	sd	ra,56(sp)
 41a:	f822                	sd	s0,48(sp)
 41c:	f426                	sd	s1,40(sp)
 41e:	f04a                	sd	s2,32(sp)
 420:	ec4e                	sd	s3,24(sp)
 422:	0080                	addi	s0,sp,64
 424:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 426:	c299                	beqz	a3,42c <printint+0x16>
 428:	0805c863          	bltz	a1,4b8 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 42c:	2581                	sext.w	a1,a1
  neg = 0;
 42e:	4881                	li	a7,0
 430:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 434:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 436:	2601                	sext.w	a2,a2
 438:	00000517          	auipc	a0,0x0
 43c:	46850513          	addi	a0,a0,1128 # 8a0 <digits>
 440:	883a                	mv	a6,a4
 442:	2705                	addiw	a4,a4,1
 444:	02c5f7bb          	remuw	a5,a1,a2
 448:	1782                	slli	a5,a5,0x20
 44a:	9381                	srli	a5,a5,0x20
 44c:	97aa                	add	a5,a5,a0
 44e:	0007c783          	lbu	a5,0(a5)
 452:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 456:	0005879b          	sext.w	a5,a1
 45a:	02c5d5bb          	divuw	a1,a1,a2
 45e:	0685                	addi	a3,a3,1
 460:	fec7f0e3          	bgeu	a5,a2,440 <printint+0x2a>
  if(neg)
 464:	00088b63          	beqz	a7,47a <printint+0x64>
    buf[i++] = '-';
 468:	fd040793          	addi	a5,s0,-48
 46c:	973e                	add	a4,a4,a5
 46e:	02d00793          	li	a5,45
 472:	fef70823          	sb	a5,-16(a4)
 476:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 47a:	02e05863          	blez	a4,4aa <printint+0x94>
 47e:	fc040793          	addi	a5,s0,-64
 482:	00e78933          	add	s2,a5,a4
 486:	fff78993          	addi	s3,a5,-1
 48a:	99ba                	add	s3,s3,a4
 48c:	377d                	addiw	a4,a4,-1
 48e:	1702                	slli	a4,a4,0x20
 490:	9301                	srli	a4,a4,0x20
 492:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 496:	fff94583          	lbu	a1,-1(s2)
 49a:	8526                	mv	a0,s1
 49c:	00000097          	auipc	ra,0x0
 4a0:	f58080e7          	jalr	-168(ra) # 3f4 <putc>
  while(--i >= 0)
 4a4:	197d                	addi	s2,s2,-1
 4a6:	ff3918e3          	bne	s2,s3,496 <printint+0x80>
}
 4aa:	70e2                	ld	ra,56(sp)
 4ac:	7442                	ld	s0,48(sp)
 4ae:	74a2                	ld	s1,40(sp)
 4b0:	7902                	ld	s2,32(sp)
 4b2:	69e2                	ld	s3,24(sp)
 4b4:	6121                	addi	sp,sp,64
 4b6:	8082                	ret
    x = -xx;
 4b8:	40b005bb          	negw	a1,a1
    neg = 1;
 4bc:	4885                	li	a7,1
    x = -xx;
 4be:	bf8d                	j	430 <printint+0x1a>

00000000000004c0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4c0:	7119                	addi	sp,sp,-128
 4c2:	fc86                	sd	ra,120(sp)
 4c4:	f8a2                	sd	s0,112(sp)
 4c6:	f4a6                	sd	s1,104(sp)
 4c8:	f0ca                	sd	s2,96(sp)
 4ca:	ecce                	sd	s3,88(sp)
 4cc:	e8d2                	sd	s4,80(sp)
 4ce:	e4d6                	sd	s5,72(sp)
 4d0:	e0da                	sd	s6,64(sp)
 4d2:	fc5e                	sd	s7,56(sp)
 4d4:	f862                	sd	s8,48(sp)
 4d6:	f466                	sd	s9,40(sp)
 4d8:	f06a                	sd	s10,32(sp)
 4da:	ec6e                	sd	s11,24(sp)
 4dc:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4de:	0005c903          	lbu	s2,0(a1)
 4e2:	18090f63          	beqz	s2,680 <vprintf+0x1c0>
 4e6:	8aaa                	mv	s5,a0
 4e8:	8b32                	mv	s6,a2
 4ea:	00158493          	addi	s1,a1,1
  state = 0;
 4ee:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4f0:	02500a13          	li	s4,37
      if(c == 'd'){
 4f4:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4f8:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4fc:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 500:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 504:	00000b97          	auipc	s7,0x0
 508:	39cb8b93          	addi	s7,s7,924 # 8a0 <digits>
 50c:	a839                	j	52a <vprintf+0x6a>
        putc(fd, c);
 50e:	85ca                	mv	a1,s2
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	ee2080e7          	jalr	-286(ra) # 3f4 <putc>
 51a:	a019                	j	520 <vprintf+0x60>
    } else if(state == '%'){
 51c:	01498f63          	beq	s3,s4,53a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 520:	0485                	addi	s1,s1,1
 522:	fff4c903          	lbu	s2,-1(s1)
 526:	14090d63          	beqz	s2,680 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 52a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 52e:	fe0997e3          	bnez	s3,51c <vprintf+0x5c>
      if(c == '%'){
 532:	fd479ee3          	bne	a5,s4,50e <vprintf+0x4e>
        state = '%';
 536:	89be                	mv	s3,a5
 538:	b7e5                	j	520 <vprintf+0x60>
      if(c == 'd'){
 53a:	05878063          	beq	a5,s8,57a <vprintf+0xba>
      } else if(c == 'l') {
 53e:	05978c63          	beq	a5,s9,596 <vprintf+0xd6>
      } else if(c == 'x') {
 542:	07a78863          	beq	a5,s10,5b2 <vprintf+0xf2>
      } else if(c == 'p') {
 546:	09b78463          	beq	a5,s11,5ce <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 54a:	07300713          	li	a4,115
 54e:	0ce78663          	beq	a5,a4,61a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 552:	06300713          	li	a4,99
 556:	0ee78e63          	beq	a5,a4,652 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 55a:	11478863          	beq	a5,s4,66a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 55e:	85d2                	mv	a1,s4
 560:	8556                	mv	a0,s5
 562:	00000097          	auipc	ra,0x0
 566:	e92080e7          	jalr	-366(ra) # 3f4 <putc>
        putc(fd, c);
 56a:	85ca                	mv	a1,s2
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	e86080e7          	jalr	-378(ra) # 3f4 <putc>
      }
      state = 0;
 576:	4981                	li	s3,0
 578:	b765                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 57a:	008b0913          	addi	s2,s6,8
 57e:	4685                	li	a3,1
 580:	4629                	li	a2,10
 582:	000b2583          	lw	a1,0(s6)
 586:	8556                	mv	a0,s5
 588:	00000097          	auipc	ra,0x0
 58c:	e8e080e7          	jalr	-370(ra) # 416 <printint>
 590:	8b4a                	mv	s6,s2
      state = 0;
 592:	4981                	li	s3,0
 594:	b771                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 596:	008b0913          	addi	s2,s6,8
 59a:	4681                	li	a3,0
 59c:	4629                	li	a2,10
 59e:	000b2583          	lw	a1,0(s6)
 5a2:	8556                	mv	a0,s5
 5a4:	00000097          	auipc	ra,0x0
 5a8:	e72080e7          	jalr	-398(ra) # 416 <printint>
 5ac:	8b4a                	mv	s6,s2
      state = 0;
 5ae:	4981                	li	s3,0
 5b0:	bf85                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5b2:	008b0913          	addi	s2,s6,8
 5b6:	4681                	li	a3,0
 5b8:	4641                	li	a2,16
 5ba:	000b2583          	lw	a1,0(s6)
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	e56080e7          	jalr	-426(ra) # 416 <printint>
 5c8:	8b4a                	mv	s6,s2
      state = 0;
 5ca:	4981                	li	s3,0
 5cc:	bf91                	j	520 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5ce:	008b0793          	addi	a5,s6,8
 5d2:	f8f43423          	sd	a5,-120(s0)
 5d6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5da:	03000593          	li	a1,48
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	e14080e7          	jalr	-492(ra) # 3f4 <putc>
  putc(fd, 'x');
 5e8:	85ea                	mv	a1,s10
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e08080e7          	jalr	-504(ra) # 3f4 <putc>
 5f4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f6:	03c9d793          	srli	a5,s3,0x3c
 5fa:	97de                	add	a5,a5,s7
 5fc:	0007c583          	lbu	a1,0(a5)
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	df2080e7          	jalr	-526(ra) # 3f4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 60a:	0992                	slli	s3,s3,0x4
 60c:	397d                	addiw	s2,s2,-1
 60e:	fe0914e3          	bnez	s2,5f6 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 612:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 616:	4981                	li	s3,0
 618:	b721                	j	520 <vprintf+0x60>
        s = va_arg(ap, char*);
 61a:	008b0993          	addi	s3,s6,8
 61e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 622:	02090163          	beqz	s2,644 <vprintf+0x184>
        while(*s != 0){
 626:	00094583          	lbu	a1,0(s2)
 62a:	c9a1                	beqz	a1,67a <vprintf+0x1ba>
          putc(fd, *s);
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	dc6080e7          	jalr	-570(ra) # 3f4 <putc>
          s++;
 636:	0905                	addi	s2,s2,1
        while(*s != 0){
 638:	00094583          	lbu	a1,0(s2)
 63c:	f9e5                	bnez	a1,62c <vprintf+0x16c>
        s = va_arg(ap, char*);
 63e:	8b4e                	mv	s6,s3
      state = 0;
 640:	4981                	li	s3,0
 642:	bdf9                	j	520 <vprintf+0x60>
          s = "(null)";
 644:	00000917          	auipc	s2,0x0
 648:	25490913          	addi	s2,s2,596 # 898 <malloc+0x10e>
        while(*s != 0){
 64c:	02800593          	li	a1,40
 650:	bff1                	j	62c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 652:	008b0913          	addi	s2,s6,8
 656:	000b4583          	lbu	a1,0(s6)
 65a:	8556                	mv	a0,s5
 65c:	00000097          	auipc	ra,0x0
 660:	d98080e7          	jalr	-616(ra) # 3f4 <putc>
 664:	8b4a                	mv	s6,s2
      state = 0;
 666:	4981                	li	s3,0
 668:	bd65                	j	520 <vprintf+0x60>
        putc(fd, c);
 66a:	85d2                	mv	a1,s4
 66c:	8556                	mv	a0,s5
 66e:	00000097          	auipc	ra,0x0
 672:	d86080e7          	jalr	-634(ra) # 3f4 <putc>
      state = 0;
 676:	4981                	li	s3,0
 678:	b565                	j	520 <vprintf+0x60>
        s = va_arg(ap, char*);
 67a:	8b4e                	mv	s6,s3
      state = 0;
 67c:	4981                	li	s3,0
 67e:	b54d                	j	520 <vprintf+0x60>
    }
  }
}
 680:	70e6                	ld	ra,120(sp)
 682:	7446                	ld	s0,112(sp)
 684:	74a6                	ld	s1,104(sp)
 686:	7906                	ld	s2,96(sp)
 688:	69e6                	ld	s3,88(sp)
 68a:	6a46                	ld	s4,80(sp)
 68c:	6aa6                	ld	s5,72(sp)
 68e:	6b06                	ld	s6,64(sp)
 690:	7be2                	ld	s7,56(sp)
 692:	7c42                	ld	s8,48(sp)
 694:	7ca2                	ld	s9,40(sp)
 696:	7d02                	ld	s10,32(sp)
 698:	6de2                	ld	s11,24(sp)
 69a:	6109                	addi	sp,sp,128
 69c:	8082                	ret

000000000000069e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 69e:	715d                	addi	sp,sp,-80
 6a0:	ec06                	sd	ra,24(sp)
 6a2:	e822                	sd	s0,16(sp)
 6a4:	1000                	addi	s0,sp,32
 6a6:	e010                	sd	a2,0(s0)
 6a8:	e414                	sd	a3,8(s0)
 6aa:	e818                	sd	a4,16(s0)
 6ac:	ec1c                	sd	a5,24(s0)
 6ae:	03043023          	sd	a6,32(s0)
 6b2:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6b6:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6ba:	8622                	mv	a2,s0
 6bc:	00000097          	auipc	ra,0x0
 6c0:	e04080e7          	jalr	-508(ra) # 4c0 <vprintf>
}
 6c4:	60e2                	ld	ra,24(sp)
 6c6:	6442                	ld	s0,16(sp)
 6c8:	6161                	addi	sp,sp,80
 6ca:	8082                	ret

00000000000006cc <printf>:

void
printf(const char *fmt, ...)
{
 6cc:	711d                	addi	sp,sp,-96
 6ce:	ec06                	sd	ra,24(sp)
 6d0:	e822                	sd	s0,16(sp)
 6d2:	1000                	addi	s0,sp,32
 6d4:	e40c                	sd	a1,8(s0)
 6d6:	e810                	sd	a2,16(s0)
 6d8:	ec14                	sd	a3,24(s0)
 6da:	f018                	sd	a4,32(s0)
 6dc:	f41c                	sd	a5,40(s0)
 6de:	03043823          	sd	a6,48(s0)
 6e2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6e6:	00840613          	addi	a2,s0,8
 6ea:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ee:	85aa                	mv	a1,a0
 6f0:	4505                	li	a0,1
 6f2:	00000097          	auipc	ra,0x0
 6f6:	dce080e7          	jalr	-562(ra) # 4c0 <vprintf>
}
 6fa:	60e2                	ld	ra,24(sp)
 6fc:	6442                	ld	s0,16(sp)
 6fe:	6125                	addi	sp,sp,96
 700:	8082                	ret

0000000000000702 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 702:	1141                	addi	sp,sp,-16
 704:	e422                	sd	s0,8(sp)
 706:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 708:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70c:	00000797          	auipc	a5,0x0
 710:	1ac7b783          	ld	a5,428(a5) # 8b8 <freep>
 714:	a805                	j	744 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 716:	4618                	lw	a4,8(a2)
 718:	9db9                	addw	a1,a1,a4
 71a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 71e:	6398                	ld	a4,0(a5)
 720:	6318                	ld	a4,0(a4)
 722:	fee53823          	sd	a4,-16(a0)
 726:	a091                	j	76a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 728:	ff852703          	lw	a4,-8(a0)
 72c:	9e39                	addw	a2,a2,a4
 72e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 730:	ff053703          	ld	a4,-16(a0)
 734:	e398                	sd	a4,0(a5)
 736:	a099                	j	77c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 738:	6398                	ld	a4,0(a5)
 73a:	00e7e463          	bltu	a5,a4,742 <free+0x40>
 73e:	00e6ea63          	bltu	a3,a4,752 <free+0x50>
{
 742:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 744:	fed7fae3          	bgeu	a5,a3,738 <free+0x36>
 748:	6398                	ld	a4,0(a5)
 74a:	00e6e463          	bltu	a3,a4,752 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 74e:	fee7eae3          	bltu	a5,a4,742 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 752:	ff852583          	lw	a1,-8(a0)
 756:	6390                	ld	a2,0(a5)
 758:	02059713          	slli	a4,a1,0x20
 75c:	9301                	srli	a4,a4,0x20
 75e:	0712                	slli	a4,a4,0x4
 760:	9736                	add	a4,a4,a3
 762:	fae60ae3          	beq	a2,a4,716 <free+0x14>
    bp->s.ptr = p->s.ptr;
 766:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 76a:	4790                	lw	a2,8(a5)
 76c:	02061713          	slli	a4,a2,0x20
 770:	9301                	srli	a4,a4,0x20
 772:	0712                	slli	a4,a4,0x4
 774:	973e                	add	a4,a4,a5
 776:	fae689e3          	beq	a3,a4,728 <free+0x26>
  } else
    p->s.ptr = bp;
 77a:	e394                	sd	a3,0(a5)
  freep = p;
 77c:	00000717          	auipc	a4,0x0
 780:	12f73e23          	sd	a5,316(a4) # 8b8 <freep>
}
 784:	6422                	ld	s0,8(sp)
 786:	0141                	addi	sp,sp,16
 788:	8082                	ret

000000000000078a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 78a:	7139                	addi	sp,sp,-64
 78c:	fc06                	sd	ra,56(sp)
 78e:	f822                	sd	s0,48(sp)
 790:	f426                	sd	s1,40(sp)
 792:	f04a                	sd	s2,32(sp)
 794:	ec4e                	sd	s3,24(sp)
 796:	e852                	sd	s4,16(sp)
 798:	e456                	sd	s5,8(sp)
 79a:	e05a                	sd	s6,0(sp)
 79c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 79e:	02051493          	slli	s1,a0,0x20
 7a2:	9081                	srli	s1,s1,0x20
 7a4:	04bd                	addi	s1,s1,15
 7a6:	8091                	srli	s1,s1,0x4
 7a8:	0014899b          	addiw	s3,s1,1
 7ac:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7ae:	00000517          	auipc	a0,0x0
 7b2:	10a53503          	ld	a0,266(a0) # 8b8 <freep>
 7b6:	c515                	beqz	a0,7e2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7ba:	4798                	lw	a4,8(a5)
 7bc:	02977f63          	bgeu	a4,s1,7fa <malloc+0x70>
 7c0:	8a4e                	mv	s4,s3
 7c2:	0009871b          	sext.w	a4,s3
 7c6:	6685                	lui	a3,0x1
 7c8:	00d77363          	bgeu	a4,a3,7ce <malloc+0x44>
 7cc:	6a05                	lui	s4,0x1
 7ce:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7d2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7d6:	00000917          	auipc	s2,0x0
 7da:	0e290913          	addi	s2,s2,226 # 8b8 <freep>
  if(p == (char*)-1)
 7de:	5afd                	li	s5,-1
 7e0:	a88d                	j	852 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7e2:	00000797          	auipc	a5,0x0
 7e6:	0de78793          	addi	a5,a5,222 # 8c0 <base>
 7ea:	00000717          	auipc	a4,0x0
 7ee:	0cf73723          	sd	a5,206(a4) # 8b8 <freep>
 7f2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7f4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7f8:	b7e1                	j	7c0 <malloc+0x36>
      if(p->s.size == nunits)
 7fa:	02e48b63          	beq	s1,a4,830 <malloc+0xa6>
        p->s.size -= nunits;
 7fe:	4137073b          	subw	a4,a4,s3
 802:	c798                	sw	a4,8(a5)
        p += p->s.size;
 804:	1702                	slli	a4,a4,0x20
 806:	9301                	srli	a4,a4,0x20
 808:	0712                	slli	a4,a4,0x4
 80a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 80c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 810:	00000717          	auipc	a4,0x0
 814:	0aa73423          	sd	a0,168(a4) # 8b8 <freep>
      return (void*)(p + 1);
 818:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 81c:	70e2                	ld	ra,56(sp)
 81e:	7442                	ld	s0,48(sp)
 820:	74a2                	ld	s1,40(sp)
 822:	7902                	ld	s2,32(sp)
 824:	69e2                	ld	s3,24(sp)
 826:	6a42                	ld	s4,16(sp)
 828:	6aa2                	ld	s5,8(sp)
 82a:	6b02                	ld	s6,0(sp)
 82c:	6121                	addi	sp,sp,64
 82e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 830:	6398                	ld	a4,0(a5)
 832:	e118                	sd	a4,0(a0)
 834:	bff1                	j	810 <malloc+0x86>
  hp->s.size = nu;
 836:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 83a:	0541                	addi	a0,a0,16
 83c:	00000097          	auipc	ra,0x0
 840:	ec6080e7          	jalr	-314(ra) # 702 <free>
  return freep;
 844:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 848:	d971                	beqz	a0,81c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 84a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 84c:	4798                	lw	a4,8(a5)
 84e:	fa9776e3          	bgeu	a4,s1,7fa <malloc+0x70>
    if(p == freep)
 852:	00093703          	ld	a4,0(s2)
 856:	853e                	mv	a0,a5
 858:	fef719e3          	bne	a4,a5,84a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 85c:	8552                	mv	a0,s4
 85e:	00000097          	auipc	ra,0x0
 862:	b66080e7          	jalr	-1178(ra) # 3c4 <sbrk>
  if(p == (char*)-1)
 866:	fd5518e3          	bne	a0,s5,836 <malloc+0xac>
        return 0;
 86a:	4501                	li	a0,0
 86c:	bf45                	j	81c <malloc+0x92>
