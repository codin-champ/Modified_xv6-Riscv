
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	99013103          	ld	sp,-1648(sp) # 80008990 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	29c78793          	addi	a5,a5,668 # 80006300 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	2d0080e7          	jalr	720(ra) # 800023fc <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e22080e7          	jalr	-478(ra) # 80001ff6 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	196080e7          	jalr	406(ra) # 800023a6 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	376080e7          	jalr	886(ra) # 80002668 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d3c080e7          	jalr	-708(ra) # 80002182 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	b1878793          	addi	a5,a5,-1256 # 80022f90 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	8e2080e7          	jalr	-1822(ra) # 80002182 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	6ca080e7          	jalr	1738(ra) # 80001ff6 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00026797          	auipc	a5,0x26
    80000a10:	5f478793          	addi	a5,a5,1524 # 80027000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00026517          	auipc	a0,0x26
    80000ae0:	52450513          	addi	a0,a0,1316 # 80027000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	a82080e7          	jalr	-1406(ra) # 80002956 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	464080e7          	jalr	1124(ra) # 80006340 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	630080e7          	jalr	1584(ra) # 80002514 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	9e2080e7          	jalr	-1566(ra) # 8000292e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a02080e7          	jalr	-1534(ra) # 80002956 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	3ce080e7          	jalr	974(ra) # 8000632a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	3dc080e7          	jalr	988(ra) # 80006340 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	5b4080e7          	jalr	1460(ra) # 80003520 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	c44080e7          	jalr	-956(ra) # 80003bb8 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	bee080e7          	jalr	-1042(ra) # 80004b6a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	4de080e7          	jalr	1246(ra) # 80006462 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d1e080e7          	jalr	-738(ra) # 80001caa <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00011497          	auipc	s1,0x11
    80001858:	8f448493          	addi	s1,s1,-1804 # 80012148 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000186e:	00017a17          	auipc	s4,0x17
    80001872:	4daa0a13          	addi	s4,s4,1242 # 80018d48 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if (pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a8:	1b048493          	addi	s1,s1,432
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001918:	00011497          	auipc	s1,0x11
    8000191c:	83048493          	addi	s1,s1,-2000 # 80012148 <proc>
  {
    initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000193a:	00017997          	auipc	s3,0x17
    8000193e:	40e98993          	addi	s3,s3,1038 # 80018d48 <tickslock>
    initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001968:	1b048493          	addi	s1,s1,432
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first)
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	f407a783          	lw	a5,-192(a5) # 80008940 <first.2429>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	f64080e7          	jalr	-156(ra) # 8000296e <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	f207a323          	sw	zero,-218(a5) # 80008940 <first.2429>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	114080e7          	jalr	276(ra) # 80003b38 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
{
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	ef878793          	addi	a5,a5,-264 # 80008944 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	58248493          	addi	s1,s1,1410 # 80012148 <proc>
    80001bce:	00017917          	auipc	s2,0x17
    80001bd2:	17a90913          	addi	s2,s2,378 # 80018d48 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bee:	1b048493          	addi	s1,s1,432
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a895                	j	80001c6c <allocproc+0xb2>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  p->ctime = ticks;
    80001c08:	00007797          	auipc	a5,0x7
    80001c0c:	4307a783          	lw	a5,1072(a5) # 80009038 <ticks>
    80001c10:	16f4a623          	sw	a5,364(s1)
  p->rtime = 0;
    80001c14:	1604aa23          	sw	zero,372(s1)
  p->niceness = 5;
    80001c18:	4795                	li	a5,5
    80001c1a:	16f4ae23          	sw	a5,380(s1)
  p->static_priority = 60;
    80001c1e:	03c00793          	li	a5,60
    80001c22:	18f4a023          	sw	a5,384(s1)
  p->dynamic_priority = 60;
    80001c26:	18f4a223          	sw	a5,388(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	eca080e7          	jalr	-310(ra) # 80000af4 <kalloc>
    80001c32:	892a                	mv	s2,a0
    80001c34:	eca8                	sd	a0,88(s1)
    80001c36:	c131                	beqz	a0,80001c7a <allocproc+0xc0>
  p->pagetable = proc_pagetable(p);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	e3a080e7          	jalr	-454(ra) # 80001a74 <proc_pagetable>
    80001c42:	892a                	mv	s2,a0
    80001c44:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c46:	c531                	beqz	a0,80001c92 <allocproc+0xd8>
  memset(&p->context, 0, sizeof(p->context));
    80001c48:	07000613          	li	a2,112
    80001c4c:	4581                	li	a1,0
    80001c4e:	06048513          	addi	a0,s1,96
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	08e080e7          	jalr	142(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c5a:	00000797          	auipc	a5,0x0
    80001c5e:	d8e78793          	addi	a5,a5,-626 # 800019e8 <forkret>
    80001c62:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c64:	60bc                	ld	a5,64(s1)
    80001c66:	6705                	lui	a4,0x1
    80001c68:	97ba                	add	a5,a5,a4
    80001c6a:	f4bc                	sd	a5,104(s1)
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
    freeproc(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	ee6080e7          	jalr	-282(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	012080e7          	jalr	18(ra) # 80000c98 <release>
    return 0;
    80001c8e:	84ca                	mv	s1,s2
    80001c90:	bff1                	j	80001c6c <allocproc+0xb2>
    freeproc(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	ece080e7          	jalr	-306(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	ffa080e7          	jalr	-6(ra) # 80000c98 <release>
    return 0;
    80001ca6:	84ca                	mv	s1,s2
    80001ca8:	b7d1                	j	80001c6c <allocproc+0xb2>

0000000080001caa <userinit>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	f06080e7          	jalr	-250(ra) # 80001bba <allocproc>
    80001cbc:	84aa                	mv	s1,a0
  initproc = p;
    80001cbe:	00007797          	auipc	a5,0x7
    80001cc2:	36a7b923          	sd	a0,882(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc6:	03400613          	li	a2,52
    80001cca:	00007597          	auipc	a1,0x7
    80001cce:	c8658593          	addi	a1,a1,-890 # 80008950 <initcode>
    80001cd2:	6928                	ld	a0,80(a0)
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	694080e7          	jalr	1684(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cdc:	6785                	lui	a5,0x1
    80001cde:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cea:	4641                	li	a2,16
    80001cec:	00006597          	auipc	a1,0x6
    80001cf0:	51458593          	addi	a1,a1,1300 # 80008200 <digits+0x1c0>
    80001cf4:	15848513          	addi	a0,s1,344
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	13a080e7          	jalr	314(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d00:	00006517          	auipc	a0,0x6
    80001d04:	51050513          	addi	a0,a0,1296 # 80008210 <digits+0x1d0>
    80001d08:	00003097          	auipc	ra,0x3
    80001d0c:	85e080e7          	jalr	-1954(ra) # 80004566 <namei>
    80001d10:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d14:	478d                	li	a5,3
    80001d16:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	f7e080e7          	jalr	-130(ra) # 80000c98 <release>
}
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret

0000000080001d2c <growproc>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	e04a                	sd	s2,0(sp)
    80001d36:	1000                	addi	s0,sp,32
    80001d38:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	c76080e7          	jalr	-906(ra) # 800019b0 <myproc>
    80001d42:	892a                	mv	s2,a0
  sz = p->sz;
    80001d44:	652c                	ld	a1,72(a0)
    80001d46:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d4a:	00904f63          	bgtz	s1,80001d68 <growproc+0x3c>
  else if (n < 0)
    80001d4e:	0204cc63          	bltz	s1,80001d86 <growproc+0x5a>
  p->sz = sz;
    80001d52:	1602                	slli	a2,a2,0x20
    80001d54:	9201                	srli	a2,a2,0x20
    80001d56:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d5a:	4501                	li	a0,0
}
    80001d5c:	60e2                	ld	ra,24(sp)
    80001d5e:	6442                	ld	s0,16(sp)
    80001d60:	64a2                	ld	s1,8(sp)
    80001d62:	6902                	ld	s2,0(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d68:	9e25                	addw	a2,a2,s1
    80001d6a:	1602                	slli	a2,a2,0x20
    80001d6c:	9201                	srli	a2,a2,0x20
    80001d6e:	1582                	slli	a1,a1,0x20
    80001d70:	9181                	srli	a1,a1,0x20
    80001d72:	6928                	ld	a0,80(a0)
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	6ae080e7          	jalr	1710(ra) # 80001422 <uvmalloc>
    80001d7c:	0005061b          	sext.w	a2,a0
    80001d80:	fa69                	bnez	a2,80001d52 <growproc+0x26>
      return -1;
    80001d82:	557d                	li	a0,-1
    80001d84:	bfe1                	j	80001d5c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d86:	9e25                	addw	a2,a2,s1
    80001d88:	1602                	slli	a2,a2,0x20
    80001d8a:	9201                	srli	a2,a2,0x20
    80001d8c:	1582                	slli	a1,a1,0x20
    80001d8e:	9181                	srli	a1,a1,0x20
    80001d90:	6928                	ld	a0,80(a0)
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	648080e7          	jalr	1608(ra) # 800013da <uvmdealloc>
    80001d9a:	0005061b          	sext.w	a2,a0
    80001d9e:	bf55                	j	80001d52 <growproc+0x26>

0000000080001da0 <fork>:
{
    80001da0:	7179                	addi	sp,sp,-48
    80001da2:	f406                	sd	ra,40(sp)
    80001da4:	f022                	sd	s0,32(sp)
    80001da6:	ec26                	sd	s1,24(sp)
    80001da8:	e84a                	sd	s2,16(sp)
    80001daa:	e44e                	sd	s3,8(sp)
    80001dac:	e052                	sd	s4,0(sp)
    80001dae:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	c00080e7          	jalr	-1024(ra) # 800019b0 <myproc>
    80001db8:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	e00080e7          	jalr	-512(ra) # 80001bba <allocproc>
    80001dc2:	10050f63          	beqz	a0,80001ee0 <fork+0x140>
    80001dc6:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dc8:	04893603          	ld	a2,72(s2)
    80001dcc:	692c                	ld	a1,80(a0)
    80001dce:	05093503          	ld	a0,80(s2)
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	79c080e7          	jalr	1948(ra) # 8000156e <uvmcopy>
    80001dda:	04054a63          	bltz	a0,80001e2e <fork+0x8e>
  np->sz = p->sz;
    80001dde:	04893783          	ld	a5,72(s2)
    80001de2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001de6:	05893683          	ld	a3,88(s2)
    80001dea:	87b6                	mv	a5,a3
    80001dec:	0589b703          	ld	a4,88(s3)
    80001df0:	12068693          	addi	a3,a3,288
    80001df4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df8:	6788                	ld	a0,8(a5)
    80001dfa:	6b8c                	ld	a1,16(a5)
    80001dfc:	6f90                	ld	a2,24(a5)
    80001dfe:	01073023          	sd	a6,0(a4)
    80001e02:	e708                	sd	a0,8(a4)
    80001e04:	eb0c                	sd	a1,16(a4)
    80001e06:	ef10                	sd	a2,24(a4)
    80001e08:	02078793          	addi	a5,a5,32
    80001e0c:	02070713          	addi	a4,a4,32
    80001e10:	fed792e3          	bne	a5,a3,80001df4 <fork+0x54>
  (np->mask) = (p->mask);
    80001e14:	16892783          	lw	a5,360(s2)
    80001e18:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001e1c:	0589b783          	ld	a5,88(s3)
    80001e20:	0607b823          	sd	zero,112(a5)
    80001e24:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e28:	15000a13          	li	s4,336
    80001e2c:	a03d                	j	80001e5a <fork+0xba>
    freeproc(np);
    80001e2e:	854e                	mv	a0,s3
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d32080e7          	jalr	-718(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e38:	854e                	mv	a0,s3
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e5e080e7          	jalr	-418(ra) # 80000c98 <release>
    return -1;
    80001e42:	5a7d                	li	s4,-1
    80001e44:	a069                	j	80001ece <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e46:	00003097          	auipc	ra,0x3
    80001e4a:	db6080e7          	jalr	-586(ra) # 80004bfc <filedup>
    80001e4e:	009987b3          	add	a5,s3,s1
    80001e52:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e54:	04a1                	addi	s1,s1,8
    80001e56:	01448763          	beq	s1,s4,80001e64 <fork+0xc4>
    if (p->ofile[i])
    80001e5a:	009907b3          	add	a5,s2,s1
    80001e5e:	6388                	ld	a0,0(a5)
    80001e60:	f17d                	bnez	a0,80001e46 <fork+0xa6>
    80001e62:	bfcd                	j	80001e54 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e64:	15093503          	ld	a0,336(s2)
    80001e68:	00002097          	auipc	ra,0x2
    80001e6c:	f0a080e7          	jalr	-246(ra) # 80003d72 <idup>
    80001e70:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e74:	4641                	li	a2,16
    80001e76:	15890593          	addi	a1,s2,344
    80001e7a:	15898513          	addi	a0,s3,344
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	fb4080e7          	jalr	-76(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e86:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	e0c080e7          	jalr	-500(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e94:	0000f497          	auipc	s1,0xf
    80001e98:	42448493          	addi	s1,s1,1060 # 800112b8 <wait_lock>
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	d46080e7          	jalr	-698(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ea6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	dec080e7          	jalr	-532(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eb4:	854e                	mv	a0,s3
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	d2e080e7          	jalr	-722(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ebe:	478d                	li	a5,3
    80001ec0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec4:	854e                	mv	a0,s3
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	dd2080e7          	jalr	-558(ra) # 80000c98 <release>
}
    80001ece:	8552                	mv	a0,s4
    80001ed0:	70a2                	ld	ra,40(sp)
    80001ed2:	7402                	ld	s0,32(sp)
    80001ed4:	64e2                	ld	s1,24(sp)
    80001ed6:	6942                	ld	s2,16(sp)
    80001ed8:	69a2                	ld	s3,8(sp)
    80001eda:	6a02                	ld	s4,0(sp)
    80001edc:	6145                	addi	sp,sp,48
    80001ede:	8082                	ret
    return -1;
    80001ee0:	5a7d                	li	s4,-1
    80001ee2:	b7f5                	j	80001ece <fork+0x12e>

0000000080001ee4 <sched>:
{
    80001ee4:	7179                	addi	sp,sp,-48
    80001ee6:	f406                	sd	ra,40(sp)
    80001ee8:	f022                	sd	s0,32(sp)
    80001eea:	ec26                	sd	s1,24(sp)
    80001eec:	e84a                	sd	s2,16(sp)
    80001eee:	e44e                	sd	s3,8(sp)
    80001ef0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ef2:	00000097          	auipc	ra,0x0
    80001ef6:	abe080e7          	jalr	-1346(ra) # 800019b0 <myproc>
    80001efa:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	c6e080e7          	jalr	-914(ra) # 80000b6a <holding>
    80001f04:	c93d                	beqz	a0,80001f7a <sched+0x96>
    80001f06:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f08:	2781                	sext.w	a5,a5
    80001f0a:	079e                	slli	a5,a5,0x7
    80001f0c:	0000f717          	auipc	a4,0xf
    80001f10:	39470713          	addi	a4,a4,916 # 800112a0 <pid_lock>
    80001f14:	97ba                	add	a5,a5,a4
    80001f16:	0a87a703          	lw	a4,168(a5)
    80001f1a:	4785                	li	a5,1
    80001f1c:	06f71763          	bne	a4,a5,80001f8a <sched+0xa6>
  if (p->state == RUNNING)
    80001f20:	4c98                	lw	a4,24(s1)
    80001f22:	4791                	li	a5,4
    80001f24:	06f70b63          	beq	a4,a5,80001f9a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f28:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f2c:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f2e:	efb5                	bnez	a5,80001faa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f30:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f32:	0000f917          	auipc	s2,0xf
    80001f36:	36e90913          	addi	s2,s2,878 # 800112a0 <pid_lock>
    80001f3a:	2781                	sext.w	a5,a5
    80001f3c:	079e                	slli	a5,a5,0x7
    80001f3e:	97ca                	add	a5,a5,s2
    80001f40:	0ac7a983          	lw	s3,172(a5)
    80001f44:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f46:	2781                	sext.w	a5,a5
    80001f48:	079e                	slli	a5,a5,0x7
    80001f4a:	0000f597          	auipc	a1,0xf
    80001f4e:	38e58593          	addi	a1,a1,910 # 800112d8 <cpus+0x8>
    80001f52:	95be                	add	a1,a1,a5
    80001f54:	06048513          	addi	a0,s1,96
    80001f58:	00001097          	auipc	ra,0x1
    80001f5c:	96c080e7          	jalr	-1684(ra) # 800028c4 <swtch>
    80001f60:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f62:	2781                	sext.w	a5,a5
    80001f64:	079e                	slli	a5,a5,0x7
    80001f66:	97ca                	add	a5,a5,s2
    80001f68:	0b37a623          	sw	s3,172(a5)
}
    80001f6c:	70a2                	ld	ra,40(sp)
    80001f6e:	7402                	ld	s0,32(sp)
    80001f70:	64e2                	ld	s1,24(sp)
    80001f72:	6942                	ld	s2,16(sp)
    80001f74:	69a2                	ld	s3,8(sp)
    80001f76:	6145                	addi	sp,sp,48
    80001f78:	8082                	ret
    panic("sched p->lock");
    80001f7a:	00006517          	auipc	a0,0x6
    80001f7e:	29e50513          	addi	a0,a0,670 # 80008218 <digits+0x1d8>
    80001f82:	ffffe097          	auipc	ra,0xffffe
    80001f86:	5bc080e7          	jalr	1468(ra) # 8000053e <panic>
    panic("sched locks");
    80001f8a:	00006517          	auipc	a0,0x6
    80001f8e:	29e50513          	addi	a0,a0,670 # 80008228 <digits+0x1e8>
    80001f92:	ffffe097          	auipc	ra,0xffffe
    80001f96:	5ac080e7          	jalr	1452(ra) # 8000053e <panic>
    panic("sched running");
    80001f9a:	00006517          	auipc	a0,0x6
    80001f9e:	29e50513          	addi	a0,a0,670 # 80008238 <digits+0x1f8>
    80001fa2:	ffffe097          	auipc	ra,0xffffe
    80001fa6:	59c080e7          	jalr	1436(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001faa:	00006517          	auipc	a0,0x6
    80001fae:	29e50513          	addi	a0,a0,670 # 80008248 <digits+0x208>
    80001fb2:	ffffe097          	auipc	ra,0xffffe
    80001fb6:	58c080e7          	jalr	1420(ra) # 8000053e <panic>

0000000080001fba <yield>:
{
    80001fba:	1101                	addi	sp,sp,-32
    80001fbc:	ec06                	sd	ra,24(sp)
    80001fbe:	e822                	sd	s0,16(sp)
    80001fc0:	e426                	sd	s1,8(sp)
    80001fc2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	9ec080e7          	jalr	-1556(ra) # 800019b0 <myproc>
    80001fcc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	c16080e7          	jalr	-1002(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80001fd6:	478d                	li	a5,3
    80001fd8:	cc9c                	sw	a5,24(s1)
  sched();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	f0a080e7          	jalr	-246(ra) # 80001ee4 <sched>
  release(&p->lock);
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	cb4080e7          	jalr	-844(ra) # 80000c98 <release>
}
    80001fec:	60e2                	ld	ra,24(sp)
    80001fee:	6442                	ld	s0,16(sp)
    80001ff0:	64a2                	ld	s1,8(sp)
    80001ff2:	6105                	addi	sp,sp,32
    80001ff4:	8082                	ret

0000000080001ff6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80001ff6:	7179                	addi	sp,sp,-48
    80001ff8:	f406                	sd	ra,40(sp)
    80001ffa:	f022                	sd	s0,32(sp)
    80001ffc:	ec26                	sd	s1,24(sp)
    80001ffe:	e84a                	sd	s2,16(sp)
    80002000:	e44e                	sd	s3,8(sp)
    80002002:	1800                	addi	s0,sp,48
    80002004:	89aa                	mv	s3,a0
    80002006:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	9a8080e7          	jalr	-1624(ra) # 800019b0 <myproc>
    80002010:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	bd2080e7          	jalr	-1070(ra) # 80000be4 <acquire>
  release(lk);
    8000201a:	854a                	mv	a0,s2
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	c7c080e7          	jalr	-900(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002024:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002028:	4789                	li	a5,2
    8000202a:	cc9c                	sw	a5,24(s1)

  sched();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	eb8080e7          	jalr	-328(ra) # 80001ee4 <sched>

  // Tidy up.
  p->chan = 0;
    80002034:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c5e080e7          	jalr	-930(ra) # 80000c98 <release>
  acquire(lk);
    80002042:	854a                	mv	a0,s2
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	ba0080e7          	jalr	-1120(ra) # 80000be4 <acquire>
}
    8000204c:	70a2                	ld	ra,40(sp)
    8000204e:	7402                	ld	s0,32(sp)
    80002050:	64e2                	ld	s1,24(sp)
    80002052:	6942                	ld	s2,16(sp)
    80002054:	69a2                	ld	s3,8(sp)
    80002056:	6145                	addi	sp,sp,48
    80002058:	8082                	ret

000000008000205a <wait>:
{
    8000205a:	715d                	addi	sp,sp,-80
    8000205c:	e486                	sd	ra,72(sp)
    8000205e:	e0a2                	sd	s0,64(sp)
    80002060:	fc26                	sd	s1,56(sp)
    80002062:	f84a                	sd	s2,48(sp)
    80002064:	f44e                	sd	s3,40(sp)
    80002066:	f052                	sd	s4,32(sp)
    80002068:	ec56                	sd	s5,24(sp)
    8000206a:	e85a                	sd	s6,16(sp)
    8000206c:	e45e                	sd	s7,8(sp)
    8000206e:	e062                	sd	s8,0(sp)
    80002070:	0880                	addi	s0,sp,80
    80002072:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	93c080e7          	jalr	-1732(ra) # 800019b0 <myproc>
    8000207c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000207e:	0000f517          	auipc	a0,0xf
    80002082:	23a50513          	addi	a0,a0,570 # 800112b8 <wait_lock>
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b5e080e7          	jalr	-1186(ra) # 80000be4 <acquire>
    havekids = 0;
    8000208e:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002090:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002092:	00017997          	auipc	s3,0x17
    80002096:	cb698993          	addi	s3,s3,-842 # 80018d48 <tickslock>
        havekids = 1;
    8000209a:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000209c:	0000fc17          	auipc	s8,0xf
    800020a0:	21cc0c13          	addi	s8,s8,540 # 800112b8 <wait_lock>
    havekids = 0;
    800020a4:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800020a6:	00010497          	auipc	s1,0x10
    800020aa:	0a248493          	addi	s1,s1,162 # 80012148 <proc>
    800020ae:	a0bd                	j	8000211c <wait+0xc2>
          pid = np->pid;
    800020b0:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020b4:	000b0e63          	beqz	s6,800020d0 <wait+0x76>
    800020b8:	4691                	li	a3,4
    800020ba:	02c48613          	addi	a2,s1,44
    800020be:	85da                	mv	a1,s6
    800020c0:	05093503          	ld	a0,80(s2)
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	5ae080e7          	jalr	1454(ra) # 80001672 <copyout>
    800020cc:	02054563          	bltz	a0,800020f6 <wait+0x9c>
          freeproc(np);
    800020d0:	8526                	mv	a0,s1
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	a90080e7          	jalr	-1392(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	bbc080e7          	jalr	-1092(ra) # 80000c98 <release>
          release(&wait_lock);
    800020e4:	0000f517          	auipc	a0,0xf
    800020e8:	1d450513          	addi	a0,a0,468 # 800112b8 <wait_lock>
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	bac080e7          	jalr	-1108(ra) # 80000c98 <release>
          return pid;
    800020f4:	a09d                	j	8000215a <wait+0x100>
            release(&np->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
            release(&wait_lock);
    80002100:	0000f517          	auipc	a0,0xf
    80002104:	1b850513          	addi	a0,a0,440 # 800112b8 <wait_lock>
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b90080e7          	jalr	-1136(ra) # 80000c98 <release>
            return -1;
    80002110:	59fd                	li	s3,-1
    80002112:	a0a1                	j	8000215a <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002114:	1b048493          	addi	s1,s1,432
    80002118:	03348463          	beq	s1,s3,80002140 <wait+0xe6>
      if (np->parent == p)
    8000211c:	7c9c                	ld	a5,56(s1)
    8000211e:	ff279be3          	bne	a5,s2,80002114 <wait+0xba>
        acquire(&np->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	ac0080e7          	jalr	-1344(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    8000212c:	4c9c                	lw	a5,24(s1)
    8000212e:	f94781e3          	beq	a5,s4,800020b0 <wait+0x56>
        release(&np->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	b64080e7          	jalr	-1180(ra) # 80000c98 <release>
        havekids = 1;
    8000213c:	8756                	mv	a4,s5
    8000213e:	bfd9                	j	80002114 <wait+0xba>
    if (!havekids || p->killed)
    80002140:	c701                	beqz	a4,80002148 <wait+0xee>
    80002142:	02892783          	lw	a5,40(s2)
    80002146:	c79d                	beqz	a5,80002174 <wait+0x11a>
      release(&wait_lock);
    80002148:	0000f517          	auipc	a0,0xf
    8000214c:	17050513          	addi	a0,a0,368 # 800112b8 <wait_lock>
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b48080e7          	jalr	-1208(ra) # 80000c98 <release>
      return -1;
    80002158:	59fd                	li	s3,-1
}
    8000215a:	854e                	mv	a0,s3
    8000215c:	60a6                	ld	ra,72(sp)
    8000215e:	6406                	ld	s0,64(sp)
    80002160:	74e2                	ld	s1,56(sp)
    80002162:	7942                	ld	s2,48(sp)
    80002164:	79a2                	ld	s3,40(sp)
    80002166:	7a02                	ld	s4,32(sp)
    80002168:	6ae2                	ld	s5,24(sp)
    8000216a:	6b42                	ld	s6,16(sp)
    8000216c:	6ba2                	ld	s7,8(sp)
    8000216e:	6c02                	ld	s8,0(sp)
    80002170:	6161                	addi	sp,sp,80
    80002172:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002174:	85e2                	mv	a1,s8
    80002176:	854a                	mv	a0,s2
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	e7e080e7          	jalr	-386(ra) # 80001ff6 <sleep>
    havekids = 0;
    80002180:	b715                	j	800020a4 <wait+0x4a>

0000000080002182 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002182:	7139                	addi	sp,sp,-64
    80002184:	fc06                	sd	ra,56(sp)
    80002186:	f822                	sd	s0,48(sp)
    80002188:	f426                	sd	s1,40(sp)
    8000218a:	f04a                	sd	s2,32(sp)
    8000218c:	ec4e                	sd	s3,24(sp)
    8000218e:	e852                	sd	s4,16(sp)
    80002190:	e456                	sd	s5,8(sp)
    80002192:	0080                	addi	s0,sp,64
    80002194:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002196:	00010497          	auipc	s1,0x10
    8000219a:	fb248493          	addi	s1,s1,-78 # 80012148 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000219e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800021a0:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800021a2:	00017917          	auipc	s2,0x17
    800021a6:	ba690913          	addi	s2,s2,-1114 # 80018d48 <tickslock>
    800021aa:	a821                	j	800021c2 <wakeup+0x40>
        p->state = RUNNABLE;
    800021ac:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ae6080e7          	jalr	-1306(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800021ba:	1b048493          	addi	s1,s1,432
    800021be:	03248463          	beq	s1,s2,800021e6 <wakeup+0x64>
    if (p != myproc())
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	7ee080e7          	jalr	2030(ra) # 800019b0 <myproc>
    800021ca:	fea488e3          	beq	s1,a0,800021ba <wakeup+0x38>
      acquire(&p->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	a14080e7          	jalr	-1516(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800021d8:	4c9c                	lw	a5,24(s1)
    800021da:	fd379be3          	bne	a5,s3,800021b0 <wakeup+0x2e>
    800021de:	709c                	ld	a5,32(s1)
    800021e0:	fd4798e3          	bne	a5,s4,800021b0 <wakeup+0x2e>
    800021e4:	b7e1                	j	800021ac <wakeup+0x2a>
    }
  }
}
    800021e6:	70e2                	ld	ra,56(sp)
    800021e8:	7442                	ld	s0,48(sp)
    800021ea:	74a2                	ld	s1,40(sp)
    800021ec:	7902                	ld	s2,32(sp)
    800021ee:	69e2                	ld	s3,24(sp)
    800021f0:	6a42                	ld	s4,16(sp)
    800021f2:	6aa2                	ld	s5,8(sp)
    800021f4:	6121                	addi	sp,sp,64
    800021f6:	8082                	ret

00000000800021f8 <reparent>:
{
    800021f8:	7179                	addi	sp,sp,-48
    800021fa:	f406                	sd	ra,40(sp)
    800021fc:	f022                	sd	s0,32(sp)
    800021fe:	ec26                	sd	s1,24(sp)
    80002200:	e84a                	sd	s2,16(sp)
    80002202:	e44e                	sd	s3,8(sp)
    80002204:	e052                	sd	s4,0(sp)
    80002206:	1800                	addi	s0,sp,48
    80002208:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000220a:	00010497          	auipc	s1,0x10
    8000220e:	f3e48493          	addi	s1,s1,-194 # 80012148 <proc>
      pp->parent = initproc;
    80002212:	00007a17          	auipc	s4,0x7
    80002216:	e1ea0a13          	addi	s4,s4,-482 # 80009030 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000221a:	00017997          	auipc	s3,0x17
    8000221e:	b2e98993          	addi	s3,s3,-1234 # 80018d48 <tickslock>
    80002222:	a029                	j	8000222c <reparent+0x34>
    80002224:	1b048493          	addi	s1,s1,432
    80002228:	01348d63          	beq	s1,s3,80002242 <reparent+0x4a>
    if (pp->parent == p)
    8000222c:	7c9c                	ld	a5,56(s1)
    8000222e:	ff279be3          	bne	a5,s2,80002224 <reparent+0x2c>
      pp->parent = initproc;
    80002232:	000a3503          	ld	a0,0(s4)
    80002236:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	f4a080e7          	jalr	-182(ra) # 80002182 <wakeup>
    80002240:	b7d5                	j	80002224 <reparent+0x2c>
}
    80002242:	70a2                	ld	ra,40(sp)
    80002244:	7402                	ld	s0,32(sp)
    80002246:	64e2                	ld	s1,24(sp)
    80002248:	6942                	ld	s2,16(sp)
    8000224a:	69a2                	ld	s3,8(sp)
    8000224c:	6a02                	ld	s4,0(sp)
    8000224e:	6145                	addi	sp,sp,48
    80002250:	8082                	ret

0000000080002252 <exit>:
{
    80002252:	7179                	addi	sp,sp,-48
    80002254:	f406                	sd	ra,40(sp)
    80002256:	f022                	sd	s0,32(sp)
    80002258:	ec26                	sd	s1,24(sp)
    8000225a:	e84a                	sd	s2,16(sp)
    8000225c:	e44e                	sd	s3,8(sp)
    8000225e:	e052                	sd	s4,0(sp)
    80002260:	1800                	addi	s0,sp,48
    80002262:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	74c080e7          	jalr	1868(ra) # 800019b0 <myproc>
    8000226c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000226e:	00007797          	auipc	a5,0x7
    80002272:	dc27b783          	ld	a5,-574(a5) # 80009030 <initproc>
    80002276:	0d050493          	addi	s1,a0,208
    8000227a:	15050913          	addi	s2,a0,336
    8000227e:	02a79363          	bne	a5,a0,800022a4 <exit+0x52>
    panic("init exiting");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	fde50513          	addi	a0,a0,-34 # 80008260 <digits+0x220>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>
      fileclose(f);
    80002292:	00003097          	auipc	ra,0x3
    80002296:	9bc080e7          	jalr	-1604(ra) # 80004c4e <fileclose>
      p->ofile[fd] = 0;
    8000229a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000229e:	04a1                	addi	s1,s1,8
    800022a0:	01248563          	beq	s1,s2,800022aa <exit+0x58>
    if (p->ofile[fd])
    800022a4:	6088                	ld	a0,0(s1)
    800022a6:	f575                	bnez	a0,80002292 <exit+0x40>
    800022a8:	bfdd                	j	8000229e <exit+0x4c>
  begin_op();
    800022aa:	00002097          	auipc	ra,0x2
    800022ae:	4d8080e7          	jalr	1240(ra) # 80004782 <begin_op>
  iput(p->cwd);
    800022b2:	1509b503          	ld	a0,336(s3)
    800022b6:	00002097          	auipc	ra,0x2
    800022ba:	cb4080e7          	jalr	-844(ra) # 80003f6a <iput>
  end_op();
    800022be:	00002097          	auipc	ra,0x2
    800022c2:	544080e7          	jalr	1348(ra) # 80004802 <end_op>
  p->cwd = 0;
    800022c6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022ca:	0000f497          	auipc	s1,0xf
    800022ce:	fee48493          	addi	s1,s1,-18 # 800112b8 <wait_lock>
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>
  reparent(p);
    800022dc:	854e                	mv	a0,s3
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	f1a080e7          	jalr	-230(ra) # 800021f8 <reparent>
  wakeup(p->parent);
    800022e6:	0389b503          	ld	a0,56(s3)
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	e98080e7          	jalr	-360(ra) # 80002182 <wakeup>
  acquire(&p->lock);
    800022f2:	854e                	mv	a0,s3
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	8f0080e7          	jalr	-1808(ra) # 80000be4 <acquire>
  p->xstate = status;
    800022fc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002300:	4795                	li	a5,5
    80002302:	00f9ac23          	sw	a5,24(s3)
  p->etime  = ticks;
    80002306:	00007797          	auipc	a5,0x7
    8000230a:	d327a783          	lw	a5,-718(a5) # 80009038 <ticks>
    8000230e:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002312:	8526                	mv	a0,s1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
  sched();
    8000231c:	00000097          	auipc	ra,0x0
    80002320:	bc8080e7          	jalr	-1080(ra) # 80001ee4 <sched>
  panic("zombie exit");
    80002324:	00006517          	auipc	a0,0x6
    80002328:	f4c50513          	addi	a0,a0,-180 # 80008270 <digits+0x230>
    8000232c:	ffffe097          	auipc	ra,0xffffe
    80002330:	212080e7          	jalr	530(ra) # 8000053e <panic>

0000000080002334 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002334:	7179                	addi	sp,sp,-48
    80002336:	f406                	sd	ra,40(sp)
    80002338:	f022                	sd	s0,32(sp)
    8000233a:	ec26                	sd	s1,24(sp)
    8000233c:	e84a                	sd	s2,16(sp)
    8000233e:	e44e                	sd	s3,8(sp)
    80002340:	1800                	addi	s0,sp,48
    80002342:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002344:	00010497          	auipc	s1,0x10
    80002348:	e0448493          	addi	s1,s1,-508 # 80012148 <proc>
    8000234c:	00017997          	auipc	s3,0x17
    80002350:	9fc98993          	addi	s3,s3,-1540 # 80018d48 <tickslock>
  {
    acquire(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	88e080e7          	jalr	-1906(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000235e:	589c                	lw	a5,48(s1)
    80002360:	01278d63          	beq	a5,s2,8000237a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	932080e7          	jalr	-1742(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000236e:	1b048493          	addi	s1,s1,432
    80002372:	ff3491e3          	bne	s1,s3,80002354 <kill+0x20>
  }
  return -1;
    80002376:	557d                	li	a0,-1
    80002378:	a829                	j	80002392 <kill+0x5e>
      p->killed = 1;
    8000237a:	4785                	li	a5,1
    8000237c:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000237e:	4c98                	lw	a4,24(s1)
    80002380:	4789                	li	a5,2
    80002382:	00f70f63          	beq	a4,a5,800023a0 <kill+0x6c>
      release(&p->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
      return 0;
    80002390:	4501                	li	a0,0
}
    80002392:	70a2                	ld	ra,40(sp)
    80002394:	7402                	ld	s0,32(sp)
    80002396:	64e2                	ld	s1,24(sp)
    80002398:	6942                	ld	s2,16(sp)
    8000239a:	69a2                	ld	s3,8(sp)
    8000239c:	6145                	addi	sp,sp,48
    8000239e:	8082                	ret
        p->state = RUNNABLE;
    800023a0:	478d                	li	a5,3
    800023a2:	cc9c                	sw	a5,24(s1)
    800023a4:	b7cd                	j	80002386 <kill+0x52>

00000000800023a6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023a6:	7179                	addi	sp,sp,-48
    800023a8:	f406                	sd	ra,40(sp)
    800023aa:	f022                	sd	s0,32(sp)
    800023ac:	ec26                	sd	s1,24(sp)
    800023ae:	e84a                	sd	s2,16(sp)
    800023b0:	e44e                	sd	s3,8(sp)
    800023b2:	e052                	sd	s4,0(sp)
    800023b4:	1800                	addi	s0,sp,48
    800023b6:	84aa                	mv	s1,a0
    800023b8:	892e                	mv	s2,a1
    800023ba:	89b2                	mv	s3,a2
    800023bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	5f2080e7          	jalr	1522(ra) # 800019b0 <myproc>
  if (user_dst)
    800023c6:	c08d                	beqz	s1,800023e8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800023c8:	86d2                	mv	a3,s4
    800023ca:	864e                	mv	a2,s3
    800023cc:	85ca                	mv	a1,s2
    800023ce:	6928                	ld	a0,80(a0)
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	2a2080e7          	jalr	674(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800023d8:	70a2                	ld	ra,40(sp)
    800023da:	7402                	ld	s0,32(sp)
    800023dc:	64e2                	ld	s1,24(sp)
    800023de:	6942                	ld	s2,16(sp)
    800023e0:	69a2                	ld	s3,8(sp)
    800023e2:	6a02                	ld	s4,0(sp)
    800023e4:	6145                	addi	sp,sp,48
    800023e6:	8082                	ret
    memmove((char *)dst, src, len);
    800023e8:	000a061b          	sext.w	a2,s4
    800023ec:	85ce                	mv	a1,s3
    800023ee:	854a                	mv	a0,s2
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	950080e7          	jalr	-1712(ra) # 80000d40 <memmove>
    return 0;
    800023f8:	8526                	mv	a0,s1
    800023fa:	bff9                	j	800023d8 <either_copyout+0x32>

00000000800023fc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	e052                	sd	s4,0(sp)
    8000240a:	1800                	addi	s0,sp,48
    8000240c:	892a                	mv	s2,a0
    8000240e:	84ae                	mv	s1,a1
    80002410:	89b2                	mv	s3,a2
    80002412:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	59c080e7          	jalr	1436(ra) # 800019b0 <myproc>
  if (user_src)
    8000241c:	c08d                	beqz	s1,8000243e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000241e:	86d2                	mv	a3,s4
    80002420:	864e                	mv	a2,s3
    80002422:	85ca                	mv	a1,s2
    80002424:	6928                	ld	a0,80(a0)
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	2d8080e7          	jalr	728(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000242e:	70a2                	ld	ra,40(sp)
    80002430:	7402                	ld	s0,32(sp)
    80002432:	64e2                	ld	s1,24(sp)
    80002434:	6942                	ld	s2,16(sp)
    80002436:	69a2                	ld	s3,8(sp)
    80002438:	6a02                	ld	s4,0(sp)
    8000243a:	6145                	addi	sp,sp,48
    8000243c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000243e:	000a061b          	sext.w	a2,s4
    80002442:	85ce                	mv	a1,s3
    80002444:	854a                	mv	a0,s2
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	8fa080e7          	jalr	-1798(ra) # 80000d40 <memmove>
    return 0;
    8000244e:	8526                	mv	a0,s1
    80002450:	bff9                	j	8000242e <either_copyin+0x32>

0000000080002452 <ageing>:

void ageing(void)
{
    80002452:	715d                	addi	sp,sp,-80
    80002454:	e486                	sd	ra,72(sp)
    80002456:	e0a2                	sd	s0,64(sp)
    80002458:	fc26                	sd	s1,56(sp)
    8000245a:	f84a                	sd	s2,48(sp)
    8000245c:	f44e                	sd	s3,40(sp)
    8000245e:	f052                	sd	s4,32(sp)
    80002460:	ec56                	sd	s5,24(sp)
    80002462:	e85a                	sd	s6,16(sp)
    80002464:	e45e                	sd	s7,8(sp)
    80002466:	e062                	sd	s8,0(sp)
    80002468:	0880                	addi	s0,sp,80
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000246a:	00010497          	auipc	s1,0x10
    8000246e:	cde48493          	addi	s1,s1,-802 # 80012148 <proc>
  {
    if (p->state == RUNNABLE && ticks - p->q_enter >= AGETICK)
    80002472:	498d                	li	s3,3
    80002474:	00007a17          	auipc	s4,0x7
    80002478:	bc4a0a13          	addi	s4,s4,-1084 # 80009038 <ticks>
    8000247c:	07f00a93          	li	s5,127
    {
      printf("Ageing: %d\n", p->pid);
    80002480:	00006b17          	auipc	s6,0x6
    80002484:	e00b0b13          	addi	s6,s6,-512 # 80008280 <digits+0x240>
      if (p->in_queue)
      {
        qerase(&mlfq[p->level], p->pid);
    80002488:	21800c13          	li	s8,536
    8000248c:	0000fb97          	auipc	s7,0xf
    80002490:	244b8b93          	addi	s7,s7,580 # 800116d0 <mlfq>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002494:	00017917          	auipc	s2,0x17
    80002498:	8b490913          	addi	s2,s2,-1868 # 80018d48 <tickslock>
    8000249c:	a035                	j	800024c8 <ageing+0x76>
        qerase(&mlfq[p->level], p->pid);
    8000249e:	1884a503          	lw	a0,392(s1)
    800024a2:	03850533          	mul	a0,a0,s8
    800024a6:	588c                	lw	a1,48(s1)
    800024a8:	955e                	add	a0,a0,s7
    800024aa:	00004097          	auipc	ra,0x4
    800024ae:	544080e7          	jalr	1348(ra) # 800069ee <qerase>
        p->in_queue = 0;
    800024b2:	1804a623          	sw	zero,396(s1)
    800024b6:	a825                	j	800024ee <ageing+0x9c>
      }
      if (p->level != 0)
      {
        p->level--;
      }
      p->q_enter = ticks;
    800024b8:	000a2783          	lw	a5,0(s4)
    800024bc:	18f4ac23          	sw	a5,408(s1)
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800024c0:	1b048493          	addi	s1,s1,432
    800024c4:	03248c63          	beq	s1,s2,800024fc <ageing+0xaa>
    if (p->state == RUNNABLE && ticks - p->q_enter >= AGETICK)
    800024c8:	4c9c                	lw	a5,24(s1)
    800024ca:	ff379be3          	bne	a5,s3,800024c0 <ageing+0x6e>
    800024ce:	000a2783          	lw	a5,0(s4)
    800024d2:	1984a703          	lw	a4,408(s1)
    800024d6:	9f99                	subw	a5,a5,a4
    800024d8:	fefaf4e3          	bgeu	s5,a5,800024c0 <ageing+0x6e>
      printf("Ageing: %d\n", p->pid);
    800024dc:	588c                	lw	a1,48(s1)
    800024de:	855a                	mv	a0,s6
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	0a8080e7          	jalr	168(ra) # 80000588 <printf>
      if (p->in_queue)
    800024e8:	18c4a783          	lw	a5,396(s1)
    800024ec:	fbcd                	bnez	a5,8000249e <ageing+0x4c>
      if (p->level != 0)
    800024ee:	1884a783          	lw	a5,392(s1)
    800024f2:	d3f9                	beqz	a5,800024b8 <ageing+0x66>
        p->level--;
    800024f4:	37fd                	addiw	a5,a5,-1
    800024f6:	18f4a423          	sw	a5,392(s1)
    800024fa:	bf7d                	j	800024b8 <ageing+0x66>
    }
  }
}
    800024fc:	60a6                	ld	ra,72(sp)
    800024fe:	6406                	ld	s0,64(sp)
    80002500:	74e2                	ld	s1,56(sp)
    80002502:	7942                	ld	s2,48(sp)
    80002504:	79a2                	ld	s3,40(sp)
    80002506:	7a02                	ld	s4,32(sp)
    80002508:	6ae2                	ld	s5,24(sp)
    8000250a:	6b42                	ld	s6,16(sp)
    8000250c:	6ba2                	ld	s7,8(sp)
    8000250e:	6c02                	ld	s8,0(sp)
    80002510:	6161                	addi	sp,sp,80
    80002512:	8082                	ret

0000000080002514 <scheduler>:
{
    80002514:	711d                	addi	sp,sp,-96
    80002516:	ec86                	sd	ra,88(sp)
    80002518:	e8a2                	sd	s0,80(sp)
    8000251a:	e4a6                	sd	s1,72(sp)
    8000251c:	e0ca                	sd	s2,64(sp)
    8000251e:	fc4e                	sd	s3,56(sp)
    80002520:	f852                	sd	s4,48(sp)
    80002522:	f456                	sd	s5,40(sp)
    80002524:	f05a                	sd	s6,32(sp)
    80002526:	ec5e                	sd	s7,24(sp)
    80002528:	e862                	sd	s8,16(sp)
    8000252a:	e466                	sd	s9,8(sp)
    8000252c:	e06a                	sd	s10,0(sp)
    8000252e:	1080                	addi	s0,sp,96
    80002530:	8792                	mv	a5,tp
  int id = r_tp();
    80002532:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002534:	00779d13          	slli	s10,a5,0x7
    80002538:	0000f717          	auipc	a4,0xf
    8000253c:	d6870713          	addi	a4,a4,-664 # 800112a0 <pid_lock>
    80002540:	976a                	add	a4,a4,s10
    80002542:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002546:	0000f717          	auipc	a4,0xf
    8000254a:	d9270713          	addi	a4,a4,-622 # 800112d8 <cpus+0x8>
    8000254e:	9d3a                	add	s10,s10,a4
    if (p->state == RUNNABLE && p->in_queue == 0)
    80002550:	4a0d                	li	s4,3
      push(&mlfq[p->level], p);
    80002552:	0000fb97          	auipc	s7,0xf
    80002556:	17eb8b93          	addi	s7,s7,382 # 800116d0 <mlfq>
  for (p = proc; p < &proc[NPROC]; p++)
    8000255a:	00016b17          	auipc	s6,0x16
    8000255e:	7eeb0b13          	addi	s6,s6,2030 # 80018d48 <tickslock>
        c->proc = p;
    80002562:	079e                	slli	a5,a5,0x7
    80002564:	0000fc97          	auipc	s9,0xf
    80002568:	d3cc8c93          	addi	s9,s9,-708 # 800112a0 <pid_lock>
    8000256c:	9cbe                	add	s9,s9,a5
    8000256e:	a0d1                	j	80002632 <scheduler+0x11e>
      push(&mlfq[p->level], p);
    80002570:	1884a503          	lw	a0,392(s1)
    80002574:	03550533          	mul	a0,a0,s5
    80002578:	85a6                	mv	a1,s1
    8000257a:	955e                	add	a0,a0,s7
    8000257c:	00004097          	auipc	ra,0x4
    80002580:	3ca080e7          	jalr	970(ra) # 80006946 <push>
      p->in_queue = 1;
    80002584:	1924a623          	sw	s2,396(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80002588:	1b048493          	addi	s1,s1,432
    8000258c:	01648963          	beq	s1,s6,8000259e <scheduler+0x8a>
    if (p->state == RUNNABLE && p->in_queue == 0)
    80002590:	4c9c                	lw	a5,24(s1)
    80002592:	ff479be3          	bne	a5,s4,80002588 <scheduler+0x74>
    80002596:	18c4a783          	lw	a5,396(s1)
    8000259a:	f7fd                	bnez	a5,80002588 <scheduler+0x74>
    8000259c:	bfd1                	j	80002570 <scheduler+0x5c>
    8000259e:	0000f917          	auipc	s2,0xf
    800025a2:	13290913          	addi	s2,s2,306 # 800116d0 <mlfq>
      struct proc *p = front(&mlfq[level]);
    800025a6:	89ca                	mv	s3,s2
    while (mlfq[level].size)
    800025a8:	2109a783          	lw	a5,528(s3)
    800025ac:	cbd1                	beqz	a5,80002640 <scheduler+0x12c>
      struct proc *p = front(&mlfq[level]);
    800025ae:	854e                	mv	a0,s3
    800025b0:	00004097          	auipc	ra,0x4
    800025b4:	420080e7          	jalr	1056(ra) # 800069d0 <front>
    800025b8:	84aa                	mv	s1,a0
      pop(&mlfq[level]);
    800025ba:	854e                	mv	a0,s3
    800025bc:	00004097          	auipc	ra,0x4
    800025c0:	3d6080e7          	jalr	982(ra) # 80006992 <pop>
      p->in_queue = 0;
    800025c4:	1804a623          	sw	zero,396(s1)
      if (p->state == RUNNABLE)
    800025c8:	4c9c                	lw	a5,24(s1)
    800025ca:	fd479fe3          	bne	a5,s4,800025a8 <scheduler+0x94>
        p->q_enter = ticks;
    800025ce:	00007797          	auipc	a5,0x7
    800025d2:	a6a7a783          	lw	a5,-1430(a5) # 80009038 <ticks>
    800025d6:	18f4ac23          	sw	a5,408(s1)
      acquire(&p->lock);
    800025da:	8526                	mv	a0,s1
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	608080e7          	jalr	1544(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    800025e4:	4c9c                	lw	a5,24(s1)
    800025e6:	05479163          	bne	a5,s4,80002628 <scheduler+0x114>
        p->change_queue = 1 << p->level;
    800025ea:	1884a703          	lw	a4,392(s1)
    800025ee:	4785                	li	a5,1
    800025f0:	00e797bb          	sllw	a5,a5,a4
    800025f4:	18f4a823          	sw	a5,400(s1)
        p->state = RUNNING;
    800025f8:	4791                	li	a5,4
    800025fa:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    800025fc:	029cb823          	sd	s1,48(s9)
        p->q_enter = ticks;
    80002600:	00007797          	auipc	a5,0x7
    80002604:	a387a783          	lw	a5,-1480(a5) # 80009038 <ticks>
    80002608:	18f4ac23          	sw	a5,408(s1)
        p->n_run++;
    8000260c:	1944a783          	lw	a5,404(s1)
    80002610:	2785                	addiw	a5,a5,1
    80002612:	18f4aa23          	sw	a5,404(s1)
        swtch(&c->context, &p->context);
    80002616:	06048593          	addi	a1,s1,96
    8000261a:	856a                	mv	a0,s10
    8000261c:	00000097          	auipc	ra,0x0
    80002620:	2a8080e7          	jalr	680(ra) # 800028c4 <swtch>
        c->proc = 0;
    80002624:	020cb823          	sd	zero,48(s9)
      release(&p->lock);
    80002628:	8526                	mv	a0,s1
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	66e080e7          	jalr	1646(ra) # 80000c98 <release>
      push(&mlfq[p->level], p);
    80002632:	21800a93          	li	s5,536
    80002636:	00010c17          	auipc	s8,0x10
    8000263a:	b12c0c13          	addi	s8,s8,-1262 # 80012148 <proc>
    8000263e:	a029                	j	80002648 <scheduler+0x134>
  for (int level = 0; level < NMLFQ; level++)
    80002640:	21890913          	addi	s2,s2,536
    80002644:	f78911e3          	bne	s2,s8,800025a6 <scheduler+0x92>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002648:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000264c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002650:	10079073          	csrw	sstatus,a5
  ageing();
    80002654:	00000097          	auipc	ra,0x0
    80002658:	dfe080e7          	jalr	-514(ra) # 80002452 <ageing>
  for (p = proc; p < &proc[NPROC]; p++)
    8000265c:	00010497          	auipc	s1,0x10
    80002660:	aec48493          	addi	s1,s1,-1300 # 80012148 <proc>
      p->in_queue = 1;
    80002664:	4905                	li	s2,1
    80002666:	b72d                	j	80002590 <scheduler+0x7c>

0000000080002668 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002668:	715d                	addi	sp,sp,-80
    8000266a:	e486                	sd	ra,72(sp)
    8000266c:	e0a2                	sd	s0,64(sp)
    8000266e:	fc26                	sd	s1,56(sp)
    80002670:	f84a                	sd	s2,48(sp)
    80002672:	f44e                	sd	s3,40(sp)
    80002674:	f052                	sd	s4,32(sp)
    80002676:	ec56                	sd	s5,24(sp)
    80002678:	e85a                	sd	s6,16(sp)
    8000267a:	e45e                	sd	s7,8(sp)
    8000267c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000267e:	00006517          	auipc	a0,0x6
    80002682:	a4a50513          	addi	a0,a0,-1462 # 800080c8 <digits+0x88>
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	f02080e7          	jalr	-254(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000268e:	00010497          	auipc	s1,0x10
    80002692:	c1248493          	addi	s1,s1,-1006 # 800122a0 <proc+0x158>
    80002696:	00017917          	auipc	s2,0x17
    8000269a:	80a90913          	addi	s2,s2,-2038 # 80018ea0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000269e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026a0:	00006997          	auipc	s3,0x6
    800026a4:	bf098993          	addi	s3,s3,-1040 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800026a8:	00006a97          	auipc	s5,0x6
    800026ac:	bf0a8a93          	addi	s5,s5,-1040 # 80008298 <digits+0x258>
    printf("\n");
    800026b0:	00006a17          	auipc	s4,0x6
    800026b4:	a18a0a13          	addi	s4,s4,-1512 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b8:	00006b97          	auipc	s7,0x6
    800026bc:	c18b8b93          	addi	s7,s7,-1000 # 800082d0 <states.2473>
    800026c0:	a00d                	j	800026e2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026c2:	ed86a583          	lw	a1,-296(a3)
    800026c6:	8556                	mv	a0,s5
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	ec0080e7          	jalr	-320(ra) # 80000588 <printf>
    printf("\n");
    800026d0:	8552                	mv	a0,s4
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	eb6080e7          	jalr	-330(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026da:	1b048493          	addi	s1,s1,432
    800026de:	03248163          	beq	s1,s2,80002700 <procdump+0x98>
    if (p->state == UNUSED)
    800026e2:	86a6                	mv	a3,s1
    800026e4:	ec04a783          	lw	a5,-320(s1)
    800026e8:	dbed                	beqz	a5,800026da <procdump+0x72>
      state = "???";
    800026ea:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026ec:	fcfb6be3          	bltu	s6,a5,800026c2 <procdump+0x5a>
    800026f0:	1782                	slli	a5,a5,0x20
    800026f2:	9381                	srli	a5,a5,0x20
    800026f4:	078e                	slli	a5,a5,0x3
    800026f6:	97de                	add	a5,a5,s7
    800026f8:	6390                	ld	a2,0(a5)
    800026fa:	f661                	bnez	a2,800026c2 <procdump+0x5a>
      state = "???";
    800026fc:	864e                	mv	a2,s3
    800026fe:	b7d1                	j	800026c2 <procdump+0x5a>
  }
}
    80002700:	60a6                	ld	ra,72(sp)
    80002702:	6406                	ld	s0,64(sp)
    80002704:	74e2                	ld	s1,56(sp)
    80002706:	7942                	ld	s2,48(sp)
    80002708:	79a2                	ld	s3,40(sp)
    8000270a:	7a02                	ld	s4,32(sp)
    8000270c:	6ae2                	ld	s5,24(sp)
    8000270e:	6b42                	ld	s6,16(sp)
    80002710:	6ba2                	ld	s7,8(sp)
    80002712:	6161                	addi	sp,sp,80
    80002714:	8082                	ret

0000000080002716 <waitx>:


int
waitx(uint64 addr, uint* rtime, uint* wtime)
{
    80002716:	711d                	addi	sp,sp,-96
    80002718:	ec86                	sd	ra,88(sp)
    8000271a:	e8a2                	sd	s0,80(sp)
    8000271c:	e4a6                	sd	s1,72(sp)
    8000271e:	e0ca                	sd	s2,64(sp)
    80002720:	fc4e                	sd	s3,56(sp)
    80002722:	f852                	sd	s4,48(sp)
    80002724:	f456                	sd	s5,40(sp)
    80002726:	f05a                	sd	s6,32(sp)
    80002728:	ec5e                	sd	s7,24(sp)
    8000272a:	e862                	sd	s8,16(sp)
    8000272c:	e466                	sd	s9,8(sp)
    8000272e:	e06a                	sd	s10,0(sp)
    80002730:	1080                	addi	s0,sp,96
    80002732:	8b2a                	mv	s6,a0
    80002734:	8c2e                	mv	s8,a1
    80002736:	8bb2                	mv	s7,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	278080e7          	jalr	632(ra) # 800019b0 <myproc>
    80002740:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002742:	0000f517          	auipc	a0,0xf
    80002746:	b7650513          	addi	a0,a0,-1162 # 800112b8 <wait_lock>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	49a080e7          	jalr	1178(ra) # 80000be4 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002752:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002754:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002756:	00016997          	auipc	s3,0x16
    8000275a:	5f298993          	addi	s3,s3,1522 # 80018d48 <tickslock>
        havekids = 1;
    8000275e:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002760:	0000fd17          	auipc	s10,0xf
    80002764:	b58d0d13          	addi	s10,s10,-1192 # 800112b8 <wait_lock>
    havekids = 0;
    80002768:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    8000276a:	00010497          	auipc	s1,0x10
    8000276e:	9de48493          	addi	s1,s1,-1570 # 80012148 <proc>
    80002772:	a069                	j	800027fc <waitx+0xe6>
          pid = np->pid;
    80002774:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002778:	1744a783          	lw	a5,372(s1)
    8000277c:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002780:	1704a783          	lw	a5,368(s1)
    80002784:	16c4a703          	lw	a4,364(s1)
    80002788:	9f99                	subw	a5,a5,a4
    8000278a:	1744a703          	lw	a4,372(s1)
    8000278e:	9f99                	subw	a5,a5,a4
    80002790:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002794:	000b0e63          	beqz	s6,800027b0 <waitx+0x9a>
    80002798:	4691                	li	a3,4
    8000279a:	02c48613          	addi	a2,s1,44
    8000279e:	85da                	mv	a1,s6
    800027a0:	05093503          	ld	a0,80(s2)
    800027a4:	fffff097          	auipc	ra,0xfffff
    800027a8:	ece080e7          	jalr	-306(ra) # 80001672 <copyout>
    800027ac:	02054563          	bltz	a0,800027d6 <waitx+0xc0>
          freeproc(np);
    800027b0:	8526                	mv	a0,s1
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	3b0080e7          	jalr	944(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800027ba:	8526                	mv	a0,s1
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	4dc080e7          	jalr	1244(ra) # 80000c98 <release>
          release(&wait_lock);
    800027c4:	0000f517          	auipc	a0,0xf
    800027c8:	af450513          	addi	a0,a0,-1292 # 800112b8 <wait_lock>
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	4cc080e7          	jalr	1228(ra) # 80000c98 <release>
          return pid;
    800027d4:	a09d                	j	8000283a <waitx+0x124>
            release(&np->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4c0080e7          	jalr	1216(ra) # 80000c98 <release>
            release(&wait_lock);
    800027e0:	0000f517          	auipc	a0,0xf
    800027e4:	ad850513          	addi	a0,a0,-1320 # 800112b8 <wait_lock>
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	4b0080e7          	jalr	1200(ra) # 80000c98 <release>
            return -1;
    800027f0:	59fd                	li	s3,-1
    800027f2:	a0a1                	j	8000283a <waitx+0x124>
    for(np = proc; np < &proc[NPROC]; np++){
    800027f4:	1b048493          	addi	s1,s1,432
    800027f8:	03348463          	beq	s1,s3,80002820 <waitx+0x10a>
      if(np->parent == p){
    800027fc:	7c9c                	ld	a5,56(s1)
    800027fe:	ff279be3          	bne	a5,s2,800027f4 <waitx+0xde>
        acquire(&np->lock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	3e0080e7          	jalr	992(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000280c:	4c9c                	lw	a5,24(s1)
    8000280e:	f74783e3          	beq	a5,s4,80002774 <waitx+0x5e>
        release(&np->lock);
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	484080e7          	jalr	1156(ra) # 80000c98 <release>
        havekids = 1;
    8000281c:	8756                	mv	a4,s5
    8000281e:	bfd9                	j	800027f4 <waitx+0xde>
    if(!havekids || p->killed){
    80002820:	c701                	beqz	a4,80002828 <waitx+0x112>
    80002822:	02892783          	lw	a5,40(s2)
    80002826:	cb8d                	beqz	a5,80002858 <waitx+0x142>
      release(&wait_lock);
    80002828:	0000f517          	auipc	a0,0xf
    8000282c:	a9050513          	addi	a0,a0,-1392 # 800112b8 <wait_lock>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	468080e7          	jalr	1128(ra) # 80000c98 <release>
      return -1;
    80002838:	59fd                	li	s3,-1
  }
}
    8000283a:	854e                	mv	a0,s3
    8000283c:	60e6                	ld	ra,88(sp)
    8000283e:	6446                	ld	s0,80(sp)
    80002840:	64a6                	ld	s1,72(sp)
    80002842:	6906                	ld	s2,64(sp)
    80002844:	79e2                	ld	s3,56(sp)
    80002846:	7a42                	ld	s4,48(sp)
    80002848:	7aa2                	ld	s5,40(sp)
    8000284a:	7b02                	ld	s6,32(sp)
    8000284c:	6be2                	ld	s7,24(sp)
    8000284e:	6c42                	ld	s8,16(sp)
    80002850:	6ca2                	ld	s9,8(sp)
    80002852:	6d02                	ld	s10,0(sp)
    80002854:	6125                	addi	sp,sp,96
    80002856:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002858:	85ea                	mv	a1,s10
    8000285a:	854a                	mv	a0,s2
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	79a080e7          	jalr	1946(ra) # 80001ff6 <sleep>
    havekids = 0;
    80002864:	b711                	j	80002768 <waitx+0x52>

0000000080002866 <update_time>:

void
update_time()
{
    80002866:	7179                	addi	sp,sp,-48
    80002868:	f406                	sd	ra,40(sp)
    8000286a:	f022                	sd	s0,32(sp)
    8000286c:	ec26                	sd	s1,24(sp)
    8000286e:	e84a                	sd	s2,16(sp)
    80002870:	e44e                	sd	s3,8(sp)
    80002872:	1800                	addi	s0,sp,48
  struct proc* p;
  for (p = proc; p < &proc[NPROC]; p++) {
    80002874:	00010497          	auipc	s1,0x10
    80002878:	8d448493          	addi	s1,s1,-1836 # 80012148 <proc>
    acquire(&p->lock);
    if (p->state == RUNNING) {
    8000287c:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {
    8000287e:	00016917          	auipc	s2,0x16
    80002882:	4ca90913          	addi	s2,s2,1226 # 80018d48 <tickslock>
    80002886:	a811                	j	8000289a <update_time+0x34>
      p->rtime++;
    }
    release(&p->lock); 
    80002888:	8526                	mv	a0,s1
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	40e080e7          	jalr	1038(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002892:	1b048493          	addi	s1,s1,432
    80002896:	03248063          	beq	s1,s2,800028b6 <update_time+0x50>
    acquire(&p->lock);
    8000289a:	8526                	mv	a0,s1
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	348080e7          	jalr	840(ra) # 80000be4 <acquire>
    if (p->state == RUNNING) {
    800028a4:	4c9c                	lw	a5,24(s1)
    800028a6:	ff3791e3          	bne	a5,s3,80002888 <update_time+0x22>
      p->rtime++;
    800028aa:	1744a783          	lw	a5,372(s1)
    800028ae:	2785                	addiw	a5,a5,1
    800028b0:	16f4aa23          	sw	a5,372(s1)
    800028b4:	bfd1                	j	80002888 <update_time+0x22>
  }
}
    800028b6:	70a2                	ld	ra,40(sp)
    800028b8:	7402                	ld	s0,32(sp)
    800028ba:	64e2                	ld	s1,24(sp)
    800028bc:	6942                	ld	s2,16(sp)
    800028be:	69a2                	ld	s3,8(sp)
    800028c0:	6145                	addi	sp,sp,48
    800028c2:	8082                	ret

00000000800028c4 <swtch>:
    800028c4:	00153023          	sd	ra,0(a0)
    800028c8:	00253423          	sd	sp,8(a0)
    800028cc:	e900                	sd	s0,16(a0)
    800028ce:	ed04                	sd	s1,24(a0)
    800028d0:	03253023          	sd	s2,32(a0)
    800028d4:	03353423          	sd	s3,40(a0)
    800028d8:	03453823          	sd	s4,48(a0)
    800028dc:	03553c23          	sd	s5,56(a0)
    800028e0:	05653023          	sd	s6,64(a0)
    800028e4:	05753423          	sd	s7,72(a0)
    800028e8:	05853823          	sd	s8,80(a0)
    800028ec:	05953c23          	sd	s9,88(a0)
    800028f0:	07a53023          	sd	s10,96(a0)
    800028f4:	07b53423          	sd	s11,104(a0)
    800028f8:	0005b083          	ld	ra,0(a1)
    800028fc:	0085b103          	ld	sp,8(a1)
    80002900:	6980                	ld	s0,16(a1)
    80002902:	6d84                	ld	s1,24(a1)
    80002904:	0205b903          	ld	s2,32(a1)
    80002908:	0285b983          	ld	s3,40(a1)
    8000290c:	0305ba03          	ld	s4,48(a1)
    80002910:	0385ba83          	ld	s5,56(a1)
    80002914:	0405bb03          	ld	s6,64(a1)
    80002918:	0485bb83          	ld	s7,72(a1)
    8000291c:	0505bc03          	ld	s8,80(a1)
    80002920:	0585bc83          	ld	s9,88(a1)
    80002924:	0605bd03          	ld	s10,96(a1)
    80002928:	0685bd83          	ld	s11,104(a1)
    8000292c:	8082                	ret

000000008000292e <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    8000292e:	1141                	addi	sp,sp,-16
    80002930:	e406                	sd	ra,8(sp)
    80002932:	e022                	sd	s0,0(sp)
    80002934:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002936:	00006597          	auipc	a1,0x6
    8000293a:	9ca58593          	addi	a1,a1,-1590 # 80008300 <states.2473+0x30>
    8000293e:	00016517          	auipc	a0,0x16
    80002942:	40a50513          	addi	a0,a0,1034 # 80018d48 <tickslock>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
}
    8000294e:	60a2                	ld	ra,8(sp)
    80002950:	6402                	ld	s0,0(sp)
    80002952:	0141                	addi	sp,sp,16
    80002954:	8082                	ret

0000000080002956 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002956:	1141                	addi	sp,sp,-16
    80002958:	e422                	sd	s0,8(sp)
    8000295a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000295c:	00004797          	auipc	a5,0x4
    80002960:	91478793          	addi	a5,a5,-1772 # 80006270 <kernelvec>
    80002964:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002968:	6422                	ld	s0,8(sp)
    8000296a:	0141                	addi	sp,sp,16
    8000296c:	8082                	ret

000000008000296e <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000296e:	1141                	addi	sp,sp,-16
    80002970:	e406                	sd	ra,8(sp)
    80002972:	e022                	sd	s0,0(sp)
    80002974:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	03a080e7          	jalr	58(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002982:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002984:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002988:	00004617          	auipc	a2,0x4
    8000298c:	67860613          	addi	a2,a2,1656 # 80007000 <_trampoline>
    80002990:	00004697          	auipc	a3,0x4
    80002994:	67068693          	addi	a3,a3,1648 # 80007000 <_trampoline>
    80002998:	8e91                	sub	a3,a3,a2
    8000299a:	040007b7          	lui	a5,0x4000
    8000299e:	17fd                	addi	a5,a5,-1
    800029a0:	07b2                	slli	a5,a5,0xc
    800029a2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029aa:	180026f3          	csrr	a3,satp
    800029ae:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029b0:	6d38                	ld	a4,88(a0)
    800029b2:	6134                	ld	a3,64(a0)
    800029b4:	6585                	lui	a1,0x1
    800029b6:	96ae                	add	a3,a3,a1
    800029b8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ba:	6d38                	ld	a4,88(a0)
    800029bc:	00000697          	auipc	a3,0x0
    800029c0:	27068693          	addi	a3,a3,624 # 80002c2c <usertrap>
    800029c4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800029c6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029c8:	8692                	mv	a3,tp
    800029ca:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029cc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029d0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029d4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029de:	6f18                	ld	a4,24(a4)
    800029e0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029e4:	692c                	ld	a1,80(a0)
    800029e6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029e8:	00004717          	auipc	a4,0x4
    800029ec:	6a870713          	addi	a4,a4,1704 # 80007090 <userret>
    800029f0:	8f11                	sub	a4,a4,a2
    800029f2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    800029f4:	577d                	li	a4,-1
    800029f6:	177e                	slli	a4,a4,0x3f
    800029f8:	8dd9                	or	a1,a1,a4
    800029fa:	02000537          	lui	a0,0x2000
    800029fe:	157d                	addi	a0,a0,-1
    80002a00:	0536                	slli	a0,a0,0xd
    80002a02:	9782                	jalr	a5
}
    80002a04:	60a2                	ld	ra,8(sp)
    80002a06:	6402                	ld	s0,0(sp)
    80002a08:	0141                	addi	sp,sp,16
    80002a0a:	8082                	ret

0000000080002a0c <min>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

int min(int a, int b)
{
    80002a0c:	1141                	addi	sp,sp,-16
    80002a0e:	e422                	sd	s0,8(sp)
    80002a10:	0800                	addi	s0,sp,16
  if(a>b)
    80002a12:	87aa                	mv	a5,a0
    80002a14:	00a5d363          	bge	a1,a0,80002a1a <min+0xe>
    80002a18:	87ae                	mv	a5,a1
  {
    return b;
  }
  return a;
}
    80002a1a:	0007851b          	sext.w	a0,a5
    80002a1e:	6422                	ld	s0,8(sp)
    80002a20:	0141                	addi	sp,sp,16
    80002a22:	8082                	ret

0000000080002a24 <max>:

int max(int a, int b)
{
    80002a24:	1141                	addi	sp,sp,-16
    80002a26:	e422                	sd	s0,8(sp)
    80002a28:	0800                	addi	s0,sp,16
  if(a>b)
    80002a2a:	87aa                	mv	a5,a0
    80002a2c:	00b55363          	bge	a0,a1,80002a32 <max+0xe>
    80002a30:	87ae                	mv	a5,a1
  {
    return a;
  }
  return b;
}
    80002a32:	0007851b          	sext.w	a0,a5
    80002a36:	6422                	ld	s0,8(sp)
    80002a38:	0141                	addi	sp,sp,16
    80002a3a:	8082                	ret

0000000080002a3c <clockintr>:


void clockintr()
{
    80002a3c:	7139                	addi	sp,sp,-64
    80002a3e:	fc06                	sd	ra,56(sp)
    80002a40:	f822                	sd	s0,48(sp)
    80002a42:	f426                	sd	s1,40(sp)
    80002a44:	f04a                	sd	s2,32(sp)
    80002a46:	ec4e                	sd	s3,24(sp)
    80002a48:	e852                	sd	s4,16(sp)
    80002a4a:	e456                	sd	s5,8(sp)
    80002a4c:	e05a                	sd	s6,0(sp)
    80002a4e:	0080                	addi	s0,sp,64
  acquire(&tickslock);
    80002a50:	00016917          	auipc	s2,0x16
    80002a54:	2f890913          	addi	s2,s2,760 # 80018d48 <tickslock>
    80002a58:	854a                	mv	a0,s2
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	18a080e7          	jalr	394(ra) # 80000be4 <acquire>
  ticks++;
    80002a62:	00006497          	auipc	s1,0x6
    80002a66:	5d648493          	addi	s1,s1,1494 # 80009038 <ticks>
    80002a6a:	409c                	lw	a5,0(s1)
    80002a6c:	2785                	addiw	a5,a5,1
    80002a6e:	c09c                	sw	a5,0(s1)
  update_time();
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	df6080e7          	jalr	-522(ra) # 80002866 <update_time>
  wakeup(&ticks);
    80002a78:	8526                	mv	a0,s1
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	708080e7          	jalr	1800(ra) # 80002182 <wakeup>
  release(&tickslock);
    80002a82:	854a                	mv	a0,s2
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	214080e7          	jalr	532(ra) # 80000c98 <release>

  if (myproc())
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	f24080e7          	jalr	-220(ra) # 800019b0 <myproc>
    80002a94:	c529                	beqz	a0,80002ade <clockintr+0xa2>
  {
    myproc()->rtime++;
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	f1a080e7          	jalr	-230(ra) # 800019b0 <myproc>
    80002a9e:	17452783          	lw	a5,372(a0) # 2000174 <_entry-0x7dfffe8c>
    80002aa2:	2785                	addiw	a5,a5,1
    80002aa4:	16f52a23          	sw	a5,372(a0)
    myproc()->q[myproc()->level]++;
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	f08080e7          	jalr	-248(ra) # 800019b0 <myproc>
    80002ab0:	84aa                	mv	s1,a0
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	efe080e7          	jalr	-258(ra) # 800019b0 <myproc>
    80002aba:	18852783          	lw	a5,392(a0)
    80002abe:	078a                	slli	a5,a5,0x2
    80002ac0:	97a6                	add	a5,a5,s1
    80002ac2:	19c7a703          	lw	a4,412(a5) # 400019c <_entry-0x7bfffe64>
    80002ac6:	2705                	addiw	a4,a4,1
    80002ac8:	18e7ae23          	sw	a4,412(a5)
    myproc()->change_queue--;
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	ee4080e7          	jalr	-284(ra) # 800019b0 <myproc>
    80002ad4:	19052783          	lw	a5,400(a0)
    80002ad8:	37fd                	addiw	a5,a5,-1
    80002ada:	18f52823          	sw	a5,400(a0)
{
    80002ade:	0000f497          	auipc	s1,0xf
    80002ae2:	66a48493          	addi	s1,s1,1642 # 80012148 <proc>
  struct proc *p;

  for(p = proc; p<&proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if(p->state == SLEEPING)
    80002ae6:	4a09                	li	s4,2
    {
     p->sleep_time++;
    }
    if(p->state == RUNNING)
    80002ae8:	4a91                	li	s5,4
    {
      p->rtime++;
    }

    p->niceness = (p->sleep_time/(p->sleep_time + p->rtime))*10;
    p->dynamic_priority = max(0, min(p->static_priority - p->niceness + 5, 100));
    80002aea:	06400993          	li	s3,100
    80002aee:	06400b13          	li	s6,100
  for(p = proc; p<&proc[NPROC]; p++)
    80002af2:	00016917          	auipc	s2,0x16
    80002af6:	25690913          	addi	s2,s2,598 # 80018d48 <tickslock>
    80002afa:	a8b1                	j	80002b56 <clockintr+0x11a>
     p->sleep_time++;
    80002afc:	1784a783          	lw	a5,376(s1)
    80002b00:	2785                	addiw	a5,a5,1
    80002b02:	16f4ac23          	sw	a5,376(s1)
    p->niceness = (p->sleep_time/(p->sleep_time + p->rtime))*10;
    80002b06:	1784a703          	lw	a4,376(s1)
    80002b0a:	1744a783          	lw	a5,372(s1)
    80002b0e:	9fb9                	addw	a5,a5,a4
    80002b10:	02f7473b          	divw	a4,a4,a5
    80002b14:	0027179b          	slliw	a5,a4,0x2
    80002b18:	9fb9                	addw	a5,a5,a4
    80002b1a:	0017971b          	slliw	a4,a5,0x1
    80002b1e:	16e4ae23          	sw	a4,380(s1)
    p->dynamic_priority = max(0, min(p->static_priority - p->niceness + 5, 100));
    80002b22:	1804a783          	lw	a5,384(s1)
    80002b26:	9f99                	subw	a5,a5,a4
    80002b28:	2795                	addiw	a5,a5,5
    80002b2a:	0007871b          	sext.w	a4,a5
    80002b2e:	00e9d363          	bge	s3,a4,80002b34 <clockintr+0xf8>
    80002b32:	87da                	mv	a5,s6
    80002b34:	0007871b          	sext.w	a4,a5
    80002b38:	fff74713          	not	a4,a4
    80002b3c:	977d                	srai	a4,a4,0x3f
    80002b3e:	8ff9                	and	a5,a5,a4
    80002b40:	18f4a223          	sw	a5,388(s1)
    release(&p->lock);
    80002b44:	8526                	mv	a0,s1
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	152080e7          	jalr	338(ra) # 80000c98 <release>
  for(p = proc; p<&proc[NPROC]; p++)
    80002b4e:	1b048493          	addi	s1,s1,432
    80002b52:	03248263          	beq	s1,s2,80002b76 <clockintr+0x13a>
    acquire(&p->lock);
    80002b56:	8526                	mv	a0,s1
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	08c080e7          	jalr	140(ra) # 80000be4 <acquire>
    if(p->state == SLEEPING)
    80002b60:	4c9c                	lw	a5,24(s1)
    80002b62:	f9478de3          	beq	a5,s4,80002afc <clockintr+0xc0>
    if(p->state == RUNNING)
    80002b66:	fb5790e3          	bne	a5,s5,80002b06 <clockintr+0xca>
      p->rtime++;
    80002b6a:	1744a783          	lw	a5,372(s1)
    80002b6e:	2785                	addiw	a5,a5,1
    80002b70:	16f4aa23          	sw	a5,372(s1)
    80002b74:	bf49                	j	80002b06 <clockintr+0xca>
    
  }
}
    80002b76:	70e2                	ld	ra,56(sp)
    80002b78:	7442                	ld	s0,48(sp)
    80002b7a:	74a2                	ld	s1,40(sp)
    80002b7c:	7902                	ld	s2,32(sp)
    80002b7e:	69e2                	ld	s3,24(sp)
    80002b80:	6a42                	ld	s4,16(sp)
    80002b82:	6aa2                	ld	s5,8(sp)
    80002b84:	6b02                	ld	s6,0(sp)
    80002b86:	6121                	addi	sp,sp,64
    80002b88:	8082                	ret

0000000080002b8a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b8a:	1101                	addi	sp,sp,-32
    80002b8c:	ec06                	sd	ra,24(sp)
    80002b8e:	e822                	sd	s0,16(sp)
    80002b90:	e426                	sd	s1,8(sp)
    80002b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b94:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002b98:	00074d63          	bltz	a4,80002bb2 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002b9c:	57fd                	li	a5,-1
    80002b9e:	17fe                	slli	a5,a5,0x3f
    80002ba0:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002ba2:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002ba4:	06f70363          	beq	a4,a5,80002c0a <devintr+0x80>
  }
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret
      (scause & 0xff) == 9)
    80002bb2:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002bb6:	46a5                	li	a3,9
    80002bb8:	fed792e3          	bne	a5,a3,80002b9c <devintr+0x12>
    int irq = plic_claim();
    80002bbc:	00003097          	auipc	ra,0x3
    80002bc0:	7bc080e7          	jalr	1980(ra) # 80006378 <plic_claim>
    80002bc4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002bc6:	47a9                	li	a5,10
    80002bc8:	02f50763          	beq	a0,a5,80002bf6 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002bcc:	4785                	li	a5,1
    80002bce:	02f50963          	beq	a0,a5,80002c00 <devintr+0x76>
    return 1;
    80002bd2:	4505                	li	a0,1
    else if (irq)
    80002bd4:	d8f1                	beqz	s1,80002ba8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bd6:	85a6                	mv	a1,s1
    80002bd8:	00005517          	auipc	a0,0x5
    80002bdc:	73050513          	addi	a0,a0,1840 # 80008308 <states.2473+0x38>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	9a8080e7          	jalr	-1624(ra) # 80000588 <printf>
      plic_complete(irq);
    80002be8:	8526                	mv	a0,s1
    80002bea:	00003097          	auipc	ra,0x3
    80002bee:	7b2080e7          	jalr	1970(ra) # 8000639c <plic_complete>
    return 1;
    80002bf2:	4505                	li	a0,1
    80002bf4:	bf55                	j	80002ba8 <devintr+0x1e>
      uartintr();
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	db2080e7          	jalr	-590(ra) # 800009a8 <uartintr>
    80002bfe:	b7ed                	j	80002be8 <devintr+0x5e>
      virtio_disk_intr();
    80002c00:	00004097          	auipc	ra,0x4
    80002c04:	c7c080e7          	jalr	-900(ra) # 8000687c <virtio_disk_intr>
    80002c08:	b7c5                	j	80002be8 <devintr+0x5e>
    if (cpuid() == 0)
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	d7a080e7          	jalr	-646(ra) # 80001984 <cpuid>
    80002c12:	c901                	beqz	a0,80002c22 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c14:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c18:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c1a:	14479073          	csrw	sip,a5
    return 2;
    80002c1e:	4509                	li	a0,2
    80002c20:	b761                	j	80002ba8 <devintr+0x1e>
      clockintr();
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	e1a080e7          	jalr	-486(ra) # 80002a3c <clockintr>
    80002c2a:	b7ed                	j	80002c14 <devintr+0x8a>

0000000080002c2c <usertrap>:
{
    80002c2c:	1101                	addi	sp,sp,-32
    80002c2e:	ec06                	sd	ra,24(sp)
    80002c30:	e822                	sd	s0,16(sp)
    80002c32:	e426                	sd	s1,8(sp)
    80002c34:	e04a                	sd	s2,0(sp)
    80002c36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c38:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c3c:	1007f793          	andi	a5,a5,256
    80002c40:	e3ad                	bnez	a5,80002ca2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c42:	00003797          	auipc	a5,0x3
    80002c46:	62e78793          	addi	a5,a5,1582 # 80006270 <kernelvec>
    80002c4a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	d62080e7          	jalr	-670(ra) # 800019b0 <myproc>
    80002c56:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c58:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5a:	14102773          	csrr	a4,sepc
    80002c5e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c60:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c64:	47a1                	li	a5,8
    80002c66:	04f71c63          	bne	a4,a5,80002cbe <usertrap+0x92>
    if (p->killed)
    80002c6a:	551c                	lw	a5,40(a0)
    80002c6c:	e3b9                	bnez	a5,80002cb2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c6e:	6cb8                	ld	a4,88(s1)
    80002c70:	6f1c                	ld	a5,24(a4)
    80002c72:	0791                	addi	a5,a5,4
    80002c74:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c7e:	10079073          	csrw	sstatus,a5
    syscall();
    80002c82:	00000097          	auipc	ra,0x0
    80002c86:	44e080e7          	jalr	1102(ra) # 800030d0 <syscall>
  if (p->killed)
    80002c8a:	549c                	lw	a5,40(s1)
    80002c8c:	ebc5                	bnez	a5,80002d3c <usertrap+0x110>
  usertrapret();
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	ce0080e7          	jalr	-800(ra) # 8000296e <usertrapret>
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6902                	ld	s2,0(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret
    panic("usertrap: not from user mode");
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	68650513          	addi	a0,a0,1670 # 80008328 <states.2473+0x58>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	894080e7          	jalr	-1900(ra) # 8000053e <panic>
      exit(-1);
    80002cb2:	557d                	li	a0,-1
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	59e080e7          	jalr	1438(ra) # 80002252 <exit>
    80002cbc:	bf4d                	j	80002c6e <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	ecc080e7          	jalr	-308(ra) # 80002b8a <devintr>
    80002cc6:	892a                	mv	s2,a0
    80002cc8:	c501                	beqz	a0,80002cd0 <usertrap+0xa4>
  if (p->killed)
    80002cca:	549c                	lw	a5,40(s1)
    80002ccc:	c3a1                	beqz	a5,80002d0c <usertrap+0xe0>
    80002cce:	a815                	j	80002d02 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cd4:	5890                	lw	a2,48(s1)
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	67250513          	addi	a0,a0,1650 # 80008348 <states.2473+0x78>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8aa080e7          	jalr	-1878(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cea:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	68a50513          	addi	a0,a0,1674 # 80008378 <states.2473+0xa8>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	892080e7          	jalr	-1902(ra) # 80000588 <printf>
    p->killed = 1;
    80002cfe:	4785                	li	a5,1
    80002d00:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d02:	557d                	li	a0,-1
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	54e080e7          	jalr	1358(ra) # 80002252 <exit>
  if (which_dev == 2)
    80002d0c:	4789                	li	a5,2
    80002d0e:	f8f910e3          	bne	s2,a5,80002c8e <usertrap+0x62>
    struct proc *p = myproc();
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	c9e080e7          	jalr	-866(ra) # 800019b0 <myproc>
    if (p->change_queue <= 0)
    80002d1a:	19052783          	lw	a5,400(a0)
    80002d1e:	f6f048e3          	bgtz	a5,80002c8e <usertrap+0x62>
      if (p->level + 1 != NMLFQ)
    80002d22:	18852783          	lw	a5,392(a0)
    80002d26:	4711                	li	a4,4
    80002d28:	00e78563          	beq	a5,a4,80002d32 <usertrap+0x106>
        p->level++;
    80002d2c:	2785                	addiw	a5,a5,1
    80002d2e:	18f52423          	sw	a5,392(a0)
      yield();
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	288080e7          	jalr	648(ra) # 80001fba <yield>
    80002d3a:	bf91                	j	80002c8e <usertrap+0x62>
  int which_dev = 0;
    80002d3c:	4901                	li	s2,0
    80002d3e:	b7d1                	j	80002d02 <usertrap+0xd6>

0000000080002d40 <kerneltrap>:
{
    80002d40:	7179                	addi	sp,sp,-48
    80002d42:	f406                	sd	ra,40(sp)
    80002d44:	f022                	sd	s0,32(sp)
    80002d46:	ec26                	sd	s1,24(sp)
    80002d48:	e84a                	sd	s2,16(sp)
    80002d4a:	e44e                	sd	s3,8(sp)
    80002d4c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d4e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d52:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d56:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002d5a:	1004f793          	andi	a5,s1,256
    80002d5e:	cb85                	beqz	a5,80002d8e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d64:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002d66:	ef85                	bnez	a5,80002d9e <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	e22080e7          	jalr	-478(ra) # 80002b8a <devintr>
    80002d70:	cd1d                	beqz	a0,80002dae <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d72:	4789                	li	a5,2
    80002d74:	06f50a63          	beq	a0,a5,80002de8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d78:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d7c:	10049073          	csrw	sstatus,s1
}
    80002d80:	70a2                	ld	ra,40(sp)
    80002d82:	7402                	ld	s0,32(sp)
    80002d84:	64e2                	ld	s1,24(sp)
    80002d86:	6942                	ld	s2,16(sp)
    80002d88:	69a2                	ld	s3,8(sp)
    80002d8a:	6145                	addi	sp,sp,48
    80002d8c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d8e:	00005517          	auipc	a0,0x5
    80002d92:	60a50513          	addi	a0,a0,1546 # 80008398 <states.2473+0xc8>
    80002d96:	ffffd097          	auipc	ra,0xffffd
    80002d9a:	7a8080e7          	jalr	1960(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002d9e:	00005517          	auipc	a0,0x5
    80002da2:	62250513          	addi	a0,a0,1570 # 800083c0 <states.2473+0xf0>
    80002da6:	ffffd097          	auipc	ra,0xffffd
    80002daa:	798080e7          	jalr	1944(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002dae:	85ce                	mv	a1,s3
    80002db0:	00005517          	auipc	a0,0x5
    80002db4:	63050513          	addi	a0,a0,1584 # 800083e0 <states.2473+0x110>
    80002db8:	ffffd097          	auipc	ra,0xffffd
    80002dbc:	7d0080e7          	jalr	2000(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dc0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dc4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dc8:	00005517          	auipc	a0,0x5
    80002dcc:	62850513          	addi	a0,a0,1576 # 800083f0 <states.2473+0x120>
    80002dd0:	ffffd097          	auipc	ra,0xffffd
    80002dd4:	7b8080e7          	jalr	1976(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002dd8:	00005517          	auipc	a0,0x5
    80002ddc:	63050513          	addi	a0,a0,1584 # 80008408 <states.2473+0x138>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	75e080e7          	jalr	1886(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	bc8080e7          	jalr	-1080(ra) # 800019b0 <myproc>
    80002df0:	d541                	beqz	a0,80002d78 <kerneltrap+0x38>
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	bbe080e7          	jalr	-1090(ra) # 800019b0 <myproc>
    80002dfa:	4d18                	lw	a4,24(a0)
    80002dfc:	4791                	li	a5,4
    80002dfe:	f6f71de3          	bne	a4,a5,80002d78 <kerneltrap+0x38>
    struct proc *p = myproc();
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	bae080e7          	jalr	-1106(ra) # 800019b0 <myproc>
    if (p->change_queue <= 0)
    80002e0a:	19052783          	lw	a5,400(a0)
    80002e0e:	f6f045e3          	bgtz	a5,80002d78 <kerneltrap+0x38>
      if (p->level + 1 != NMLFQ)
    80002e12:	18852783          	lw	a5,392(a0)
    80002e16:	4711                	li	a4,4
    80002e18:	00e78563          	beq	a5,a4,80002e22 <kerneltrap+0xe2>
        p->level++;
    80002e1c:	2785                	addiw	a5,a5,1
    80002e1e:	18f52423          	sw	a5,392(a0)
      yield();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	198080e7          	jalr	408(ra) # 80001fba <yield>
    80002e2a:	b7b9                	j	80002d78 <kerneltrap+0x38>

0000000080002e2c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e2c:	1101                	addi	sp,sp,-32
    80002e2e:	ec06                	sd	ra,24(sp)
    80002e30:	e822                	sd	s0,16(sp)
    80002e32:	e426                	sd	s1,8(sp)
    80002e34:	1000                	addi	s0,sp,32
    80002e36:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	b78080e7          	jalr	-1160(ra) # 800019b0 <myproc>
  switch (n) {
    80002e40:	4795                	li	a5,5
    80002e42:	0497e163          	bltu	a5,s1,80002e84 <argraw+0x58>
    80002e46:	048a                	slli	s1,s1,0x2
    80002e48:	00005717          	auipc	a4,0x5
    80002e4c:	6e070713          	addi	a4,a4,1760 # 80008528 <states.2473+0x258>
    80002e50:	94ba                	add	s1,s1,a4
    80002e52:	409c                	lw	a5,0(s1)
    80002e54:	97ba                	add	a5,a5,a4
    80002e56:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e58:	6d3c                	ld	a5,88(a0)
    80002e5a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e5c:	60e2                	ld	ra,24(sp)
    80002e5e:	6442                	ld	s0,16(sp)
    80002e60:	64a2                	ld	s1,8(sp)
    80002e62:	6105                	addi	sp,sp,32
    80002e64:	8082                	ret
    return p->trapframe->a1;
    80002e66:	6d3c                	ld	a5,88(a0)
    80002e68:	7fa8                	ld	a0,120(a5)
    80002e6a:	bfcd                	j	80002e5c <argraw+0x30>
    return p->trapframe->a2;
    80002e6c:	6d3c                	ld	a5,88(a0)
    80002e6e:	63c8                	ld	a0,128(a5)
    80002e70:	b7f5                	j	80002e5c <argraw+0x30>
    return p->trapframe->a3;
    80002e72:	6d3c                	ld	a5,88(a0)
    80002e74:	67c8                	ld	a0,136(a5)
    80002e76:	b7dd                	j	80002e5c <argraw+0x30>
    return p->trapframe->a4;
    80002e78:	6d3c                	ld	a5,88(a0)
    80002e7a:	6bc8                	ld	a0,144(a5)
    80002e7c:	b7c5                	j	80002e5c <argraw+0x30>
    return p->trapframe->a5;
    80002e7e:	6d3c                	ld	a5,88(a0)
    80002e80:	6fc8                	ld	a0,152(a5)
    80002e82:	bfe9                	j	80002e5c <argraw+0x30>
  panic("argraw");
    80002e84:	00005517          	auipc	a0,0x5
    80002e88:	59450513          	addi	a0,a0,1428 # 80008418 <states.2473+0x148>
    80002e8c:	ffffd097          	auipc	ra,0xffffd
    80002e90:	6b2080e7          	jalr	1714(ra) # 8000053e <panic>

0000000080002e94 <fetchaddr>:
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	e04a                	sd	s2,0(sp)
    80002e9e:	1000                	addi	s0,sp,32
    80002ea0:	84aa                	mv	s1,a0
    80002ea2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	b0c080e7          	jalr	-1268(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002eac:	653c                	ld	a5,72(a0)
    80002eae:	02f4f863          	bgeu	s1,a5,80002ede <fetchaddr+0x4a>
    80002eb2:	00848713          	addi	a4,s1,8
    80002eb6:	02e7e663          	bltu	a5,a4,80002ee2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002eba:	46a1                	li	a3,8
    80002ebc:	8626                	mv	a2,s1
    80002ebe:	85ca                	mv	a1,s2
    80002ec0:	6928                	ld	a0,80(a0)
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	83c080e7          	jalr	-1988(ra) # 800016fe <copyin>
    80002eca:	00a03533          	snez	a0,a0
    80002ece:	40a00533          	neg	a0,a0
}
    80002ed2:	60e2                	ld	ra,24(sp)
    80002ed4:	6442                	ld	s0,16(sp)
    80002ed6:	64a2                	ld	s1,8(sp)
    80002ed8:	6902                	ld	s2,0(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret
    return -1;
    80002ede:	557d                	li	a0,-1
    80002ee0:	bfcd                	j	80002ed2 <fetchaddr+0x3e>
    80002ee2:	557d                	li	a0,-1
    80002ee4:	b7fd                	j	80002ed2 <fetchaddr+0x3e>

0000000080002ee6 <fetchstr>:
{
    80002ee6:	7179                	addi	sp,sp,-48
    80002ee8:	f406                	sd	ra,40(sp)
    80002eea:	f022                	sd	s0,32(sp)
    80002eec:	ec26                	sd	s1,24(sp)
    80002eee:	e84a                	sd	s2,16(sp)
    80002ef0:	e44e                	sd	s3,8(sp)
    80002ef2:	1800                	addi	s0,sp,48
    80002ef4:	892a                	mv	s2,a0
    80002ef6:	84ae                	mv	s1,a1
    80002ef8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	ab6080e7          	jalr	-1354(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f02:	86ce                	mv	a3,s3
    80002f04:	864a                	mv	a2,s2
    80002f06:	85a6                	mv	a1,s1
    80002f08:	6928                	ld	a0,80(a0)
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	880080e7          	jalr	-1920(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002f12:	00054763          	bltz	a0,80002f20 <fetchstr+0x3a>
  return strlen(buf);
    80002f16:	8526                	mv	a0,s1
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	f4c080e7          	jalr	-180(ra) # 80000e64 <strlen>
}
    80002f20:	70a2                	ld	ra,40(sp)
    80002f22:	7402                	ld	s0,32(sp)
    80002f24:	64e2                	ld	s1,24(sp)
    80002f26:	6942                	ld	s2,16(sp)
    80002f28:	69a2                	ld	s3,8(sp)
    80002f2a:	6145                	addi	sp,sp,48
    80002f2c:	8082                	ret

0000000080002f2e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f2e:	1101                	addi	sp,sp,-32
    80002f30:	ec06                	sd	ra,24(sp)
    80002f32:	e822                	sd	s0,16(sp)
    80002f34:	e426                	sd	s1,8(sp)
    80002f36:	1000                	addi	s0,sp,32
    80002f38:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f3a:	00000097          	auipc	ra,0x0
    80002f3e:	ef2080e7          	jalr	-270(ra) # 80002e2c <argraw>
    80002f42:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f44:	4501                	li	a0,0
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	64a2                	ld	s1,8(sp)
    80002f4c:	6105                	addi	sp,sp,32
    80002f4e:	8082                	ret

0000000080002f50 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f50:	1101                	addi	sp,sp,-32
    80002f52:	ec06                	sd	ra,24(sp)
    80002f54:	e822                	sd	s0,16(sp)
    80002f56:	e426                	sd	s1,8(sp)
    80002f58:	1000                	addi	s0,sp,32
    80002f5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f5c:	00000097          	auipc	ra,0x0
    80002f60:	ed0080e7          	jalr	-304(ra) # 80002e2c <argraw>
    80002f64:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f66:	4501                	li	a0,0
    80002f68:	60e2                	ld	ra,24(sp)
    80002f6a:	6442                	ld	s0,16(sp)
    80002f6c:	64a2                	ld	s1,8(sp)
    80002f6e:	6105                	addi	sp,sp,32
    80002f70:	8082                	ret

0000000080002f72 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f72:	1101                	addi	sp,sp,-32
    80002f74:	ec06                	sd	ra,24(sp)
    80002f76:	e822                	sd	s0,16(sp)
    80002f78:	e426                	sd	s1,8(sp)
    80002f7a:	e04a                	sd	s2,0(sp)
    80002f7c:	1000                	addi	s0,sp,32
    80002f7e:	84ae                	mv	s1,a1
    80002f80:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	eaa080e7          	jalr	-342(ra) # 80002e2c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f8a:	864a                	mv	a2,s2
    80002f8c:	85a6                	mv	a1,s1
    80002f8e:	00000097          	auipc	ra,0x0
    80002f92:	f58080e7          	jalr	-168(ra) # 80002ee6 <fetchstr>
}
    80002f96:	60e2                	ld	ra,24(sp)
    80002f98:	6442                	ld	s0,16(sp)
    80002f9a:	64a2                	ld	s1,8(sp)
    80002f9c:	6902                	ld	s2,0(sp)
    80002f9e:	6105                	addi	sp,sp,32
    80002fa0:	8082                	ret

0000000080002fa2 <SyscallNamesArray>:
[SYS_trace]   sys_trace,
[SYS_waitx]   sys_waitx,
};

void SyscallNamesArray(char *names[NELEM(syscalls)])
{
    80002fa2:	1141                	addi	sp,sp,-16
    80002fa4:	e422                	sd	s0,8(sp)
    80002fa6:	0800                	addi	s0,sp,16
  names[1] = "fork";
    80002fa8:	00005797          	auipc	a5,0x5
    80002fac:	47878793          	addi	a5,a5,1144 # 80008420 <states.2473+0x150>
    80002fb0:	e51c                	sd	a5,8(a0)
  names[2] = "exit";
    80002fb2:	00005797          	auipc	a5,0x5
    80002fb6:	47678793          	addi	a5,a5,1142 # 80008428 <states.2473+0x158>
    80002fba:	e91c                	sd	a5,16(a0)
  names[3] = "wait";
    80002fbc:	00005797          	auipc	a5,0x5
    80002fc0:	47478793          	addi	a5,a5,1140 # 80008430 <states.2473+0x160>
    80002fc4:	ed1c                	sd	a5,24(a0)
  names[4] = "pipe";
    80002fc6:	00005797          	auipc	a5,0x5
    80002fca:	47278793          	addi	a5,a5,1138 # 80008438 <states.2473+0x168>
    80002fce:	f11c                	sd	a5,32(a0)
  names[5] = "read";
    80002fd0:	00005797          	auipc	a5,0x5
    80002fd4:	75078793          	addi	a5,a5,1872 # 80008720 <syscalls+0x1e0>
    80002fd8:	f51c                	sd	a5,40(a0)
  names[6] = "kill";
    80002fda:	00005797          	auipc	a5,0x5
    80002fde:	46678793          	addi	a5,a5,1126 # 80008440 <states.2473+0x170>
    80002fe2:	f91c                	sd	a5,48(a0)
  names[7] = "exec";
    80002fe4:	00005797          	auipc	a5,0x5
    80002fe8:	46478793          	addi	a5,a5,1124 # 80008448 <states.2473+0x178>
    80002fec:	fd1c                	sd	a5,56(a0)
  names[8] = "fstat";
    80002fee:	00005797          	auipc	a5,0x5
    80002ff2:	46278793          	addi	a5,a5,1122 # 80008450 <states.2473+0x180>
    80002ff6:	e13c                	sd	a5,64(a0)
  names[9] = "chdir";
    80002ff8:	00005797          	auipc	a5,0x5
    80002ffc:	46078793          	addi	a5,a5,1120 # 80008458 <states.2473+0x188>
    80003000:	e53c                	sd	a5,72(a0)
  names[10] = "dup";
    80003002:	00005797          	auipc	a5,0x5
    80003006:	45e78793          	addi	a5,a5,1118 # 80008460 <states.2473+0x190>
    8000300a:	e93c                	sd	a5,80(a0)
  names[11] = "getpid";
    8000300c:	00005797          	auipc	a5,0x5
    80003010:	45c78793          	addi	a5,a5,1116 # 80008468 <states.2473+0x198>
    80003014:	ed3c                	sd	a5,88(a0)
  names[12] = "sbrk";
    80003016:	00005797          	auipc	a5,0x5
    8000301a:	45a78793          	addi	a5,a5,1114 # 80008470 <states.2473+0x1a0>
    8000301e:	f13c                	sd	a5,96(a0)
  names[13] = "sleep";
    80003020:	00005797          	auipc	a5,0x5
    80003024:	45878793          	addi	a5,a5,1112 # 80008478 <states.2473+0x1a8>
    80003028:	f53c                	sd	a5,104(a0)
  names[14] = "uptime";
    8000302a:	00005797          	auipc	a5,0x5
    8000302e:	45678793          	addi	a5,a5,1110 # 80008480 <states.2473+0x1b0>
    80003032:	f93c                	sd	a5,112(a0)
  names[15] = "open";
    80003034:	00005797          	auipc	a5,0x5
    80003038:	45478793          	addi	a5,a5,1108 # 80008488 <states.2473+0x1b8>
    8000303c:	fd3c                	sd	a5,120(a0)
  names[16] = "write";
    8000303e:	00005797          	auipc	a5,0x5
    80003042:	45278793          	addi	a5,a5,1106 # 80008490 <states.2473+0x1c0>
    80003046:	e15c                	sd	a5,128(a0)
  names[17] = "mknod";
    80003048:	00005797          	auipc	a5,0x5
    8000304c:	45078793          	addi	a5,a5,1104 # 80008498 <states.2473+0x1c8>
    80003050:	e55c                	sd	a5,136(a0)
  names[18] = "unlink";
    80003052:	00005797          	auipc	a5,0x5
    80003056:	44e78793          	addi	a5,a5,1102 # 800084a0 <states.2473+0x1d0>
    8000305a:	e95c                	sd	a5,144(a0)
  names[19] = "link";
    8000305c:	00005797          	auipc	a5,0x5
    80003060:	44c78793          	addi	a5,a5,1100 # 800084a8 <states.2473+0x1d8>
    80003064:	ed5c                	sd	a5,152(a0)
  names[20] = "mkdir";
    80003066:	00005797          	auipc	a5,0x5
    8000306a:	44a78793          	addi	a5,a5,1098 # 800084b0 <states.2473+0x1e0>
    8000306e:	f15c                	sd	a5,160(a0)
  names[21] = "close";
    80003070:	00005797          	auipc	a5,0x5
    80003074:	44878793          	addi	a5,a5,1096 # 800084b8 <states.2473+0x1e8>
    80003078:	f55c                	sd	a5,168(a0)
  names[22] = "trace";
    8000307a:	00005797          	auipc	a5,0x5
    8000307e:	44678793          	addi	a5,a5,1094 # 800084c0 <states.2473+0x1f0>
    80003082:	f95c                	sd	a5,176(a0)
}
    80003084:	6422                	ld	s0,8(sp)
    80003086:	0141                	addi	sp,sp,16
    80003088:	8082                	ret

000000008000308a <ArgumentCount>:

void ArgumentCount(int *count)
{
    8000308a:	1141                	addi	sp,sp,-16
    8000308c:	e422                	sd	s0,8(sp)
    8000308e:	0800                	addi	s0,sp,16
  count[1] = 0;
    80003090:	00052223          	sw	zero,4(a0)
  count[2] = 1;
    80003094:	4785                	li	a5,1
    80003096:	c51c                	sw	a5,8(a0)
  count[3] = 1;
    80003098:	c55c                	sw	a5,12(a0)
  count[4] = 0;
    8000309a:	00052823          	sw	zero,16(a0)
  count[5] = 3;
    8000309e:	468d                	li	a3,3
    800030a0:	c954                	sw	a3,20(a0)
  count[6] = 2;
    800030a2:	4709                	li	a4,2
    800030a4:	cd18                	sw	a4,24(a0)
  count[7] = 2;
    800030a6:	cd58                	sw	a4,28(a0)
  count[8] = 1;
    800030a8:	d11c                	sw	a5,32(a0)
  count[9] = 1;
    800030aa:	d15c                	sw	a5,36(a0)
  count[10] = 1;
    800030ac:	d51c                	sw	a5,40(a0)
  count[11] = 0;
    800030ae:	02052623          	sw	zero,44(a0)
  count[12] = 1;
    800030b2:	d91c                	sw	a5,48(a0)
  count[13] = 1;
    800030b4:	d95c                	sw	a5,52(a0)
  count[14] = 0;
    800030b6:	02052c23          	sw	zero,56(a0)
  count[15] = 2;
    800030ba:	dd58                	sw	a4,60(a0)
  count[16] = 3;
    800030bc:	c134                	sw	a3,64(a0)
  count[17] = 3;
    800030be:	c174                	sw	a3,68(a0)
  count[18] = 1;
    800030c0:	c53c                	sw	a5,72(a0)
  count[19] = 2;
    800030c2:	c578                	sw	a4,76(a0)
  count[20] = 1;
    800030c4:	c93c                	sw	a5,80(a0)
  count[21] = 1;
    800030c6:	c97c                	sw	a5,84(a0)
  count[22] = 1;
    800030c8:	cd3c                	sw	a5,88(a0)
}
    800030ca:	6422                	ld	s0,8(sp)
    800030cc:	0141                	addi	sp,sp,16
    800030ce:	8082                	ret

00000000800030d0 <syscall>:

void
syscall(void)
{
    800030d0:	7149                	addi	sp,sp,-368
    800030d2:	f686                	sd	ra,360(sp)
    800030d4:	f2a2                	sd	s0,352(sp)
    800030d6:	eea6                	sd	s1,344(sp)
    800030d8:	eaca                	sd	s2,336(sp)
    800030da:	e6ce                	sd	s3,328(sp)
    800030dc:	e2d2                	sd	s4,320(sp)
    800030de:	fe56                	sd	s5,312(sp)
    800030e0:	fa5a                	sd	s6,304(sp)
    800030e2:	1a80                	addi	s0,sp,368
  char *names[25];
  SyscallNamesArray(names);
    800030e4:	ef840513          	addi	a0,s0,-264
    800030e8:	00000097          	auipc	ra,0x0
    800030ec:	eba080e7          	jalr	-326(ra) # 80002fa2 <SyscallNamesArray>
  int count[25];
  ArgumentCount(count);
    800030f0:	e9040513          	addi	a0,s0,-368
    800030f4:	00000097          	auipc	ra,0x0
    800030f8:	f96080e7          	jalr	-106(ra) # 8000308a <ArgumentCount>
  int num;
  struct proc *p = myproc();
    800030fc:	fffff097          	auipc	ra,0xfffff
    80003100:	8b4080e7          	jalr	-1868(ra) # 800019b0 <myproc>
    80003104:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003106:	05853903          	ld	s2,88(a0)
    8000310a:	0a893783          	ld	a5,168(s2)
    8000310e:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) 
    80003112:	37fd                	addiw	a5,a5,-1
    80003114:	4759                	li	a4,22
    80003116:	0ef76663          	bltu	a4,a5,80003202 <syscall+0x132>
    8000311a:	00399713          	slli	a4,s3,0x3
    8000311e:	00005797          	auipc	a5,0x5
    80003122:	42278793          	addi	a5,a5,1058 # 80008540 <syscalls>
    80003126:	97ba                	add	a5,a5,a4
    80003128:	639c                	ld	a5,0(a5)
    8000312a:	cfe1                	beqz	a5,80003202 <syscall+0x132>
  {
    int arg1 = p->trapframe->a0;
    8000312c:	07093a03          	ld	s4,112(s2)
    int arg2 = p->trapframe->a1;
    80003130:	07893a83          	ld	s5,120(s2)
    int arg3 = p->trapframe->a2;
    80003134:	08093b03          	ld	s6,128(s2)
    p->trapframe->a0 = syscalls[num]();
    80003138:	9782                	jalr	a5
    8000313a:	06a93823          	sd	a0,112(s2)
    int mask = p->mask;
    if((mask >> num) &0x1 )
    8000313e:	1684a783          	lw	a5,360(s1)
    80003142:	4137d7bb          	sraw	a5,a5,s3
    80003146:	8b85                	andi	a5,a5,1
    80003148:	cfe1                	beqz	a5,80003220 <syscall+0x150>
    int arg1 = p->trapframe->a0;
    8000314a:	2a01                	sext.w	s4,s4
    {
      //printf("%d: sycscall %s (%d, %d, %d) ->%d\n",p->pid,names[num],p->trapframe->a2,p->trapframe->a1,p->trapframe->a3,p->trapframe->a0);
      printf("%d: syscall %s (",p->pid,names[num]);
    8000314c:	00399793          	slli	a5,s3,0x3
    80003150:	fc040713          	addi	a4,s0,-64
    80003154:	97ba                	add	a5,a5,a4
    80003156:	f387b603          	ld	a2,-200(a5)
    8000315a:	588c                	lw	a1,48(s1)
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	36c50513          	addi	a0,a0,876 # 800084c8 <states.2473+0x1f8>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	424080e7          	jalr	1060(ra) # 80000588 <printf>
      if(count[num] == 1)
    8000316c:	00299793          	slli	a5,s3,0x2
    80003170:	fc040713          	addi	a4,s0,-64
    80003174:	97ba                	add	a5,a5,a4
    80003176:	ed07a703          	lw	a4,-304(a5)
    8000317a:	4785                	li	a5,1
    8000317c:	04f70163          	beq	a4,a5,800031be <syscall+0xee>
    int arg2 = p->trapframe->a1;
    80003180:	2a81                	sext.w	s5,s5
      {
       printf("%d", arg1); 
      }
      if(count[num] == 2)
    80003182:	00299793          	slli	a5,s3,0x2
    80003186:	fc040713          	addi	a4,s0,-64
    8000318a:	97ba                	add	a5,a5,a4
    8000318c:	ed07a703          	lw	a4,-304(a5)
    80003190:	4789                	li	a5,2
    80003192:	04f70063          	beq	a4,a5,800031d2 <syscall+0x102>
      {
        printf("%d %d", arg1, arg2);
      }
      if(count[num] == 3)
    80003196:	098a                	slli	s3,s3,0x2
    80003198:	fc040793          	addi	a5,s0,-64
    8000319c:	99be                	add	s3,s3,a5
    8000319e:	ed09a703          	lw	a4,-304(s3)
    800031a2:	478d                	li	a5,3
    800031a4:	04f70263          	beq	a4,a5,800031e8 <syscall+0x118>
      {
        printf("%d %d %d", arg1, arg2, arg3);
      }
      printf(") ->%d\n",p->trapframe->a0);
    800031a8:	6cbc                	ld	a5,88(s1)
    800031aa:	7bac                	ld	a1,112(a5)
    800031ac:	00005517          	auipc	a0,0x5
    800031b0:	35450513          	addi	a0,a0,852 # 80008500 <states.2473+0x230>
    800031b4:	ffffd097          	auipc	ra,0xffffd
    800031b8:	3d4080e7          	jalr	980(ra) # 80000588 <printf>
    800031bc:	a095                	j	80003220 <syscall+0x150>
       printf("%d", arg1); 
    800031be:	85d2                	mv	a1,s4
    800031c0:	00005517          	auipc	a0,0x5
    800031c4:	32050513          	addi	a0,a0,800 # 800084e0 <states.2473+0x210>
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	3c0080e7          	jalr	960(ra) # 80000588 <printf>
    800031d0:	bf45                	j	80003180 <syscall+0xb0>
        printf("%d %d", arg1, arg2);
    800031d2:	8656                	mv	a2,s5
    800031d4:	85d2                	mv	a1,s4
    800031d6:	00005517          	auipc	a0,0x5
    800031da:	31250513          	addi	a0,a0,786 # 800084e8 <states.2473+0x218>
    800031de:	ffffd097          	auipc	ra,0xffffd
    800031e2:	3aa080e7          	jalr	938(ra) # 80000588 <printf>
    800031e6:	bf45                	j	80003196 <syscall+0xc6>
        printf("%d %d %d", arg1, arg2, arg3);
    800031e8:	000b069b          	sext.w	a3,s6
    800031ec:	8656                	mv	a2,s5
    800031ee:	85d2                	mv	a1,s4
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	30050513          	addi	a0,a0,768 # 800084f0 <states.2473+0x220>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	390080e7          	jalr	912(ra) # 80000588 <printf>
    80003200:	b765                	j	800031a8 <syscall+0xd8>
    }
  } 
  else 
  {
    printf("%d %s: unknown sys call %d\n",
    80003202:	86ce                	mv	a3,s3
    80003204:	15848613          	addi	a2,s1,344
    80003208:	588c                	lw	a1,48(s1)
    8000320a:	00005517          	auipc	a0,0x5
    8000320e:	2fe50513          	addi	a0,a0,766 # 80008508 <states.2473+0x238>
    80003212:	ffffd097          	auipc	ra,0xffffd
    80003216:	376080e7          	jalr	886(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000321a:	6cbc                	ld	a5,88(s1)
    8000321c:	577d                	li	a4,-1
    8000321e:	fbb8                	sd	a4,112(a5)
  }
}
    80003220:	70b6                	ld	ra,360(sp)
    80003222:	7416                	ld	s0,352(sp)
    80003224:	64f6                	ld	s1,344(sp)
    80003226:	6956                	ld	s2,336(sp)
    80003228:	69b6                	ld	s3,328(sp)
    8000322a:	6a16                	ld	s4,320(sp)
    8000322c:	7af2                	ld	s5,312(sp)
    8000322e:	7b52                	ld	s6,304(sp)
    80003230:	6175                	addi	sp,sp,368
    80003232:	8082                	ret

0000000080003234 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003234:	1101                	addi	sp,sp,-32
    80003236:	ec06                	sd	ra,24(sp)
    80003238:	e822                	sd	s0,16(sp)
    8000323a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000323c:	fec40593          	addi	a1,s0,-20
    80003240:	4501                	li	a0,0
    80003242:	00000097          	auipc	ra,0x0
    80003246:	cec080e7          	jalr	-788(ra) # 80002f2e <argint>
    return -1;
    8000324a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000324c:	00054963          	bltz	a0,8000325e <sys_exit+0x2a>
  exit(n);
    80003250:	fec42503          	lw	a0,-20(s0)
    80003254:	fffff097          	auipc	ra,0xfffff
    80003258:	ffe080e7          	jalr	-2(ra) # 80002252 <exit>
  return 0;  // not reached
    8000325c:	4781                	li	a5,0
}
    8000325e:	853e                	mv	a0,a5
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	6105                	addi	sp,sp,32
    80003266:	8082                	ret

0000000080003268 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003268:	1141                	addi	sp,sp,-16
    8000326a:	e406                	sd	ra,8(sp)
    8000326c:	e022                	sd	s0,0(sp)
    8000326e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	740080e7          	jalr	1856(ra) # 800019b0 <myproc>
}
    80003278:	5908                	lw	a0,48(a0)
    8000327a:	60a2                	ld	ra,8(sp)
    8000327c:	6402                	ld	s0,0(sp)
    8000327e:	0141                	addi	sp,sp,16
    80003280:	8082                	ret

0000000080003282 <sys_fork>:

uint64
sys_fork(void)
{
    80003282:	1141                	addi	sp,sp,-16
    80003284:	e406                	sd	ra,8(sp)
    80003286:	e022                	sd	s0,0(sp)
    80003288:	0800                	addi	s0,sp,16
  return fork();
    8000328a:	fffff097          	auipc	ra,0xfffff
    8000328e:	b16080e7          	jalr	-1258(ra) # 80001da0 <fork>
}
    80003292:	60a2                	ld	ra,8(sp)
    80003294:	6402                	ld	s0,0(sp)
    80003296:	0141                	addi	sp,sp,16
    80003298:	8082                	ret

000000008000329a <sys_wait>:

uint64
sys_wait(void)
{
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800032a2:	fe840593          	addi	a1,s0,-24
    800032a6:	4501                	li	a0,0
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	ca8080e7          	jalr	-856(ra) # 80002f50 <argaddr>
    800032b0:	87aa                	mv	a5,a0
    return -1;
    800032b2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032b4:	0007c863          	bltz	a5,800032c4 <sys_wait+0x2a>
  return wait(p);
    800032b8:	fe843503          	ld	a0,-24(s0)
    800032bc:	fffff097          	auipc	ra,0xfffff
    800032c0:	d9e080e7          	jalr	-610(ra) # 8000205a <wait>
}
    800032c4:	60e2                	ld	ra,24(sp)
    800032c6:	6442                	ld	s0,16(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret

00000000800032cc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032cc:	7179                	addi	sp,sp,-48
    800032ce:	f406                	sd	ra,40(sp)
    800032d0:	f022                	sd	s0,32(sp)
    800032d2:	ec26                	sd	s1,24(sp)
    800032d4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032d6:	fdc40593          	addi	a1,s0,-36
    800032da:	4501                	li	a0,0
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	c52080e7          	jalr	-942(ra) # 80002f2e <argint>
    800032e4:	87aa                	mv	a5,a0
    return -1;
    800032e6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032e8:	0207c063          	bltz	a5,80003308 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	6c4080e7          	jalr	1732(ra) # 800019b0 <myproc>
    800032f4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800032f6:	fdc42503          	lw	a0,-36(s0)
    800032fa:	fffff097          	auipc	ra,0xfffff
    800032fe:	a32080e7          	jalr	-1486(ra) # 80001d2c <growproc>
    80003302:	00054863          	bltz	a0,80003312 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003306:	8526                	mv	a0,s1
}
    80003308:	70a2                	ld	ra,40(sp)
    8000330a:	7402                	ld	s0,32(sp)
    8000330c:	64e2                	ld	s1,24(sp)
    8000330e:	6145                	addi	sp,sp,48
    80003310:	8082                	ret
    return -1;
    80003312:	557d                	li	a0,-1
    80003314:	bfd5                	j	80003308 <sys_sbrk+0x3c>

0000000080003316 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003316:	7139                	addi	sp,sp,-64
    80003318:	fc06                	sd	ra,56(sp)
    8000331a:	f822                	sd	s0,48(sp)
    8000331c:	f426                	sd	s1,40(sp)
    8000331e:	f04a                	sd	s2,32(sp)
    80003320:	ec4e                	sd	s3,24(sp)
    80003322:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003324:	fcc40593          	addi	a1,s0,-52
    80003328:	4501                	li	a0,0
    8000332a:	00000097          	auipc	ra,0x0
    8000332e:	c04080e7          	jalr	-1020(ra) # 80002f2e <argint>
    return -1;
    80003332:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003334:	06054563          	bltz	a0,8000339e <sys_sleep+0x88>
  acquire(&tickslock);
    80003338:	00016517          	auipc	a0,0x16
    8000333c:	a1050513          	addi	a0,a0,-1520 # 80018d48 <tickslock>
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	8a4080e7          	jalr	-1884(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003348:	00006917          	auipc	s2,0x6
    8000334c:	cf092903          	lw	s2,-784(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80003350:	fcc42783          	lw	a5,-52(s0)
    80003354:	cf85                	beqz	a5,8000338c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003356:	00016997          	auipc	s3,0x16
    8000335a:	9f298993          	addi	s3,s3,-1550 # 80018d48 <tickslock>
    8000335e:	00006497          	auipc	s1,0x6
    80003362:	cda48493          	addi	s1,s1,-806 # 80009038 <ticks>
    if(myproc()->killed){
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	64a080e7          	jalr	1610(ra) # 800019b0 <myproc>
    8000336e:	551c                	lw	a5,40(a0)
    80003370:	ef9d                	bnez	a5,800033ae <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003372:	85ce                	mv	a1,s3
    80003374:	8526                	mv	a0,s1
    80003376:	fffff097          	auipc	ra,0xfffff
    8000337a:	c80080e7          	jalr	-896(ra) # 80001ff6 <sleep>
  while(ticks - ticks0 < n){
    8000337e:	409c                	lw	a5,0(s1)
    80003380:	412787bb          	subw	a5,a5,s2
    80003384:	fcc42703          	lw	a4,-52(s0)
    80003388:	fce7efe3          	bltu	a5,a4,80003366 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000338c:	00016517          	auipc	a0,0x16
    80003390:	9bc50513          	addi	a0,a0,-1604 # 80018d48 <tickslock>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	904080e7          	jalr	-1788(ra) # 80000c98 <release>
  return 0;
    8000339c:	4781                	li	a5,0
}
    8000339e:	853e                	mv	a0,a5
    800033a0:	70e2                	ld	ra,56(sp)
    800033a2:	7442                	ld	s0,48(sp)
    800033a4:	74a2                	ld	s1,40(sp)
    800033a6:	7902                	ld	s2,32(sp)
    800033a8:	69e2                	ld	s3,24(sp)
    800033aa:	6121                	addi	sp,sp,64
    800033ac:	8082                	ret
      release(&tickslock);
    800033ae:	00016517          	auipc	a0,0x16
    800033b2:	99a50513          	addi	a0,a0,-1638 # 80018d48 <tickslock>
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
      return -1;
    800033be:	57fd                	li	a5,-1
    800033c0:	bff9                	j	8000339e <sys_sleep+0x88>

00000000800033c2 <sys_kill>:

uint64
sys_kill(void)
{
    800033c2:	1101                	addi	sp,sp,-32
    800033c4:	ec06                	sd	ra,24(sp)
    800033c6:	e822                	sd	s0,16(sp)
    800033c8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800033ca:	fec40593          	addi	a1,s0,-20
    800033ce:	4501                	li	a0,0
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	b5e080e7          	jalr	-1186(ra) # 80002f2e <argint>
    800033d8:	87aa                	mv	a5,a0
    return -1;
    800033da:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033dc:	0007c863          	bltz	a5,800033ec <sys_kill+0x2a>
  return kill(pid);
    800033e0:	fec42503          	lw	a0,-20(s0)
    800033e4:	fffff097          	auipc	ra,0xfffff
    800033e8:	f50080e7          	jalr	-176(ra) # 80002334 <kill>
}
    800033ec:	60e2                	ld	ra,24(sp)
    800033ee:	6442                	ld	s0,16(sp)
    800033f0:	6105                	addi	sp,sp,32
    800033f2:	8082                	ret

00000000800033f4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033f4:	1101                	addi	sp,sp,-32
    800033f6:	ec06                	sd	ra,24(sp)
    800033f8:	e822                	sd	s0,16(sp)
    800033fa:	e426                	sd	s1,8(sp)
    800033fc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033fe:	00016517          	auipc	a0,0x16
    80003402:	94a50513          	addi	a0,a0,-1718 # 80018d48 <tickslock>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	7de080e7          	jalr	2014(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000340e:	00006497          	auipc	s1,0x6
    80003412:	c2a4a483          	lw	s1,-982(s1) # 80009038 <ticks>
  release(&tickslock);
    80003416:	00016517          	auipc	a0,0x16
    8000341a:	93250513          	addi	a0,a0,-1742 # 80018d48 <tickslock>
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
  return xticks;
}
    80003426:	02049513          	slli	a0,s1,0x20
    8000342a:	9101                	srli	a0,a0,0x20
    8000342c:	60e2                	ld	ra,24(sp)
    8000342e:	6442                	ld	s0,16(sp)
    80003430:	64a2                	ld	s1,8(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret

0000000080003436 <sys_trace>:

uint64
sys_trace(void)
{
    80003436:	1101                	addi	sp,sp,-32
    80003438:	ec06                	sd	ra,24(sp)
    8000343a:	e822                	sd	s0,16(sp)
    8000343c:	1000                	addi	s0,sp,32
  int mask=0;
    8000343e:	fe042623          	sw	zero,-20(s0)
  if(argint(0,&mask)<0)
    80003442:	fec40593          	addi	a1,s0,-20
    80003446:	4501                	li	a0,0
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	ae6080e7          	jalr	-1306(ra) # 80002f2e <argint>
  {
    return -1;
    80003450:	57fd                	li	a5,-1
  if(argint(0,&mask)<0)
    80003452:	00054b63          	bltz	a0,80003468 <sys_trace+0x32>
  }
  myproc()->mask = mask;
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	55a080e7          	jalr	1370(ra) # 800019b0 <myproc>
    8000345e:	fec42783          	lw	a5,-20(s0)
    80003462:	16f52423          	sw	a5,360(a0)
  return 0;
    80003466:	4781                	li	a5,0
}
    80003468:	853e                	mv	a0,a5
    8000346a:	60e2                	ld	ra,24(sp)
    8000346c:	6442                	ld	s0,16(sp)
    8000346e:	6105                	addi	sp,sp,32
    80003470:	8082                	ret

0000000080003472 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003472:	7139                	addi	sp,sp,-64
    80003474:	fc06                	sd	ra,56(sp)
    80003476:	f822                	sd	s0,48(sp)
    80003478:	f426                	sd	s1,40(sp)
    8000347a:	f04a                	sd	s2,32(sp)
    8000347c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    8000347e:	fd840593          	addi	a1,s0,-40
    80003482:	4501                	li	a0,0
    80003484:	00000097          	auipc	ra,0x0
    80003488:	acc080e7          	jalr	-1332(ra) # 80002f50 <argaddr>
    return -1;
    8000348c:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    8000348e:	08054063          	bltz	a0,8000350e <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003492:	fd040593          	addi	a1,s0,-48
    80003496:	4505                	li	a0,1
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	ab8080e7          	jalr	-1352(ra) # 80002f50 <argaddr>
    return -1;
    800034a0:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800034a2:	06054663          	bltz	a0,8000350e <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    800034a6:	fc840593          	addi	a1,s0,-56
    800034aa:	4509                	li	a0,2
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	aa4080e7          	jalr	-1372(ra) # 80002f50 <argaddr>
    return -1;
    800034b4:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    800034b6:	04054c63          	bltz	a0,8000350e <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800034ba:	fc040613          	addi	a2,s0,-64
    800034be:	fc440593          	addi	a1,s0,-60
    800034c2:	fd843503          	ld	a0,-40(s0)
    800034c6:	fffff097          	auipc	ra,0xfffff
    800034ca:	250080e7          	jalr	592(ra) # 80002716 <waitx>
    800034ce:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800034d0:	ffffe097          	auipc	ra,0xffffe
    800034d4:	4e0080e7          	jalr	1248(ra) # 800019b0 <myproc>
    800034d8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800034da:	4691                	li	a3,4
    800034dc:	fc440613          	addi	a2,s0,-60
    800034e0:	fd043583          	ld	a1,-48(s0)
    800034e4:	6928                	ld	a0,80(a0)
    800034e6:	ffffe097          	auipc	ra,0xffffe
    800034ea:	18c080e7          	jalr	396(ra) # 80001672 <copyout>
    return -1;
    800034ee:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800034f0:	00054f63          	bltz	a0,8000350e <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800034f4:	4691                	li	a3,4
    800034f6:	fc040613          	addi	a2,s0,-64
    800034fa:	fc843583          	ld	a1,-56(s0)
    800034fe:	68a8                	ld	a0,80(s1)
    80003500:	ffffe097          	auipc	ra,0xffffe
    80003504:	172080e7          	jalr	370(ra) # 80001672 <copyout>
    80003508:	00054a63          	bltz	a0,8000351c <sys_waitx+0xaa>
    return -1;
  return ret;
    8000350c:	87ca                	mv	a5,s2
}
    8000350e:	853e                	mv	a0,a5
    80003510:	70e2                	ld	ra,56(sp)
    80003512:	7442                	ld	s0,48(sp)
    80003514:	74a2                	ld	s1,40(sp)
    80003516:	7902                	ld	s2,32(sp)
    80003518:	6121                	addi	sp,sp,64
    8000351a:	8082                	ret
    return -1;
    8000351c:	57fd                	li	a5,-1
    8000351e:	bfc5                	j	8000350e <sys_waitx+0x9c>

0000000080003520 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003520:	7179                	addi	sp,sp,-48
    80003522:	f406                	sd	ra,40(sp)
    80003524:	f022                	sd	s0,32(sp)
    80003526:	ec26                	sd	s1,24(sp)
    80003528:	e84a                	sd	s2,16(sp)
    8000352a:	e44e                	sd	s3,8(sp)
    8000352c:	e052                	sd	s4,0(sp)
    8000352e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003530:	00005597          	auipc	a1,0x5
    80003534:	0d058593          	addi	a1,a1,208 # 80008600 <syscalls+0xc0>
    80003538:	00016517          	auipc	a0,0x16
    8000353c:	82850513          	addi	a0,a0,-2008 # 80018d60 <bcache>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	614080e7          	jalr	1556(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003548:	0001e797          	auipc	a5,0x1e
    8000354c:	81878793          	addi	a5,a5,-2024 # 80020d60 <bcache+0x8000>
    80003550:	0001e717          	auipc	a4,0x1e
    80003554:	a7870713          	addi	a4,a4,-1416 # 80020fc8 <bcache+0x8268>
    80003558:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000355c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003560:	00016497          	auipc	s1,0x16
    80003564:	81848493          	addi	s1,s1,-2024 # 80018d78 <bcache+0x18>
    b->next = bcache.head.next;
    80003568:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000356a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000356c:	00005a17          	auipc	s4,0x5
    80003570:	09ca0a13          	addi	s4,s4,156 # 80008608 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003574:	2b893783          	ld	a5,696(s2)
    80003578:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000357a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000357e:	85d2                	mv	a1,s4
    80003580:	01048513          	addi	a0,s1,16
    80003584:	00001097          	auipc	ra,0x1
    80003588:	4bc080e7          	jalr	1212(ra) # 80004a40 <initsleeplock>
    bcache.head.next->prev = b;
    8000358c:	2b893783          	ld	a5,696(s2)
    80003590:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003592:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003596:	45848493          	addi	s1,s1,1112
    8000359a:	fd349de3          	bne	s1,s3,80003574 <binit+0x54>
  }
}
    8000359e:	70a2                	ld	ra,40(sp)
    800035a0:	7402                	ld	s0,32(sp)
    800035a2:	64e2                	ld	s1,24(sp)
    800035a4:	6942                	ld	s2,16(sp)
    800035a6:	69a2                	ld	s3,8(sp)
    800035a8:	6a02                	ld	s4,0(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret

00000000800035ae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035ae:	7179                	addi	sp,sp,-48
    800035b0:	f406                	sd	ra,40(sp)
    800035b2:	f022                	sd	s0,32(sp)
    800035b4:	ec26                	sd	s1,24(sp)
    800035b6:	e84a                	sd	s2,16(sp)
    800035b8:	e44e                	sd	s3,8(sp)
    800035ba:	1800                	addi	s0,sp,48
    800035bc:	89aa                	mv	s3,a0
    800035be:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035c0:	00015517          	auipc	a0,0x15
    800035c4:	7a050513          	addi	a0,a0,1952 # 80018d60 <bcache>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	61c080e7          	jalr	1564(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035d0:	0001e497          	auipc	s1,0x1e
    800035d4:	a484b483          	ld	s1,-1464(s1) # 80021018 <bcache+0x82b8>
    800035d8:	0001e797          	auipc	a5,0x1e
    800035dc:	9f078793          	addi	a5,a5,-1552 # 80020fc8 <bcache+0x8268>
    800035e0:	02f48f63          	beq	s1,a5,8000361e <bread+0x70>
    800035e4:	873e                	mv	a4,a5
    800035e6:	a021                	j	800035ee <bread+0x40>
    800035e8:	68a4                	ld	s1,80(s1)
    800035ea:	02e48a63          	beq	s1,a4,8000361e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035ee:	449c                	lw	a5,8(s1)
    800035f0:	ff379ce3          	bne	a5,s3,800035e8 <bread+0x3a>
    800035f4:	44dc                	lw	a5,12(s1)
    800035f6:	ff2799e3          	bne	a5,s2,800035e8 <bread+0x3a>
      b->refcnt++;
    800035fa:	40bc                	lw	a5,64(s1)
    800035fc:	2785                	addiw	a5,a5,1
    800035fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003600:	00015517          	auipc	a0,0x15
    80003604:	76050513          	addi	a0,a0,1888 # 80018d60 <bcache>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	690080e7          	jalr	1680(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003610:	01048513          	addi	a0,s1,16
    80003614:	00001097          	auipc	ra,0x1
    80003618:	466080e7          	jalr	1126(ra) # 80004a7a <acquiresleep>
      return b;
    8000361c:	a8b9                	j	8000367a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000361e:	0001e497          	auipc	s1,0x1e
    80003622:	9f24b483          	ld	s1,-1550(s1) # 80021010 <bcache+0x82b0>
    80003626:	0001e797          	auipc	a5,0x1e
    8000362a:	9a278793          	addi	a5,a5,-1630 # 80020fc8 <bcache+0x8268>
    8000362e:	00f48863          	beq	s1,a5,8000363e <bread+0x90>
    80003632:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003634:	40bc                	lw	a5,64(s1)
    80003636:	cf81                	beqz	a5,8000364e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003638:	64a4                	ld	s1,72(s1)
    8000363a:	fee49de3          	bne	s1,a4,80003634 <bread+0x86>
  panic("bget: no buffers");
    8000363e:	00005517          	auipc	a0,0x5
    80003642:	fd250513          	addi	a0,a0,-46 # 80008610 <syscalls+0xd0>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	ef8080e7          	jalr	-264(ra) # 8000053e <panic>
      b->dev = dev;
    8000364e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003652:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003656:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000365a:	4785                	li	a5,1
    8000365c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000365e:	00015517          	auipc	a0,0x15
    80003662:	70250513          	addi	a0,a0,1794 # 80018d60 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	632080e7          	jalr	1586(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000366e:	01048513          	addi	a0,s1,16
    80003672:	00001097          	auipc	ra,0x1
    80003676:	408080e7          	jalr	1032(ra) # 80004a7a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000367a:	409c                	lw	a5,0(s1)
    8000367c:	cb89                	beqz	a5,8000368e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000367e:	8526                	mv	a0,s1
    80003680:	70a2                	ld	ra,40(sp)
    80003682:	7402                	ld	s0,32(sp)
    80003684:	64e2                	ld	s1,24(sp)
    80003686:	6942                	ld	s2,16(sp)
    80003688:	69a2                	ld	s3,8(sp)
    8000368a:	6145                	addi	sp,sp,48
    8000368c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000368e:	4581                	li	a1,0
    80003690:	8526                	mv	a0,s1
    80003692:	00003097          	auipc	ra,0x3
    80003696:	f14080e7          	jalr	-236(ra) # 800065a6 <virtio_disk_rw>
    b->valid = 1;
    8000369a:	4785                	li	a5,1
    8000369c:	c09c                	sw	a5,0(s1)
  return b;
    8000369e:	b7c5                	j	8000367e <bread+0xd0>

00000000800036a0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036a0:	1101                	addi	sp,sp,-32
    800036a2:	ec06                	sd	ra,24(sp)
    800036a4:	e822                	sd	s0,16(sp)
    800036a6:	e426                	sd	s1,8(sp)
    800036a8:	1000                	addi	s0,sp,32
    800036aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036ac:	0541                	addi	a0,a0,16
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	466080e7          	jalr	1126(ra) # 80004b14 <holdingsleep>
    800036b6:	cd01                	beqz	a0,800036ce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036b8:	4585                	li	a1,1
    800036ba:	8526                	mv	a0,s1
    800036bc:	00003097          	auipc	ra,0x3
    800036c0:	eea080e7          	jalr	-278(ra) # 800065a6 <virtio_disk_rw>
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6105                	addi	sp,sp,32
    800036cc:	8082                	ret
    panic("bwrite");
    800036ce:	00005517          	auipc	a0,0x5
    800036d2:	f5a50513          	addi	a0,a0,-166 # 80008628 <syscalls+0xe8>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	e68080e7          	jalr	-408(ra) # 8000053e <panic>

00000000800036de <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036de:	1101                	addi	sp,sp,-32
    800036e0:	ec06                	sd	ra,24(sp)
    800036e2:	e822                	sd	s0,16(sp)
    800036e4:	e426                	sd	s1,8(sp)
    800036e6:	e04a                	sd	s2,0(sp)
    800036e8:	1000                	addi	s0,sp,32
    800036ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036ec:	01050913          	addi	s2,a0,16
    800036f0:	854a                	mv	a0,s2
    800036f2:	00001097          	auipc	ra,0x1
    800036f6:	422080e7          	jalr	1058(ra) # 80004b14 <holdingsleep>
    800036fa:	c92d                	beqz	a0,8000376c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800036fc:	854a                	mv	a0,s2
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	3d2080e7          	jalr	978(ra) # 80004ad0 <releasesleep>

  acquire(&bcache.lock);
    80003706:	00015517          	auipc	a0,0x15
    8000370a:	65a50513          	addi	a0,a0,1626 # 80018d60 <bcache>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	4d6080e7          	jalr	1238(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003716:	40bc                	lw	a5,64(s1)
    80003718:	37fd                	addiw	a5,a5,-1
    8000371a:	0007871b          	sext.w	a4,a5
    8000371e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003720:	eb05                	bnez	a4,80003750 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003722:	68bc                	ld	a5,80(s1)
    80003724:	64b8                	ld	a4,72(s1)
    80003726:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003728:	64bc                	ld	a5,72(s1)
    8000372a:	68b8                	ld	a4,80(s1)
    8000372c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000372e:	0001d797          	auipc	a5,0x1d
    80003732:	63278793          	addi	a5,a5,1586 # 80020d60 <bcache+0x8000>
    80003736:	2b87b703          	ld	a4,696(a5)
    8000373a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000373c:	0001e717          	auipc	a4,0x1e
    80003740:	88c70713          	addi	a4,a4,-1908 # 80020fc8 <bcache+0x8268>
    80003744:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003746:	2b87b703          	ld	a4,696(a5)
    8000374a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000374c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003750:	00015517          	auipc	a0,0x15
    80003754:	61050513          	addi	a0,a0,1552 # 80018d60 <bcache>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	540080e7          	jalr	1344(ra) # 80000c98 <release>
}
    80003760:	60e2                	ld	ra,24(sp)
    80003762:	6442                	ld	s0,16(sp)
    80003764:	64a2                	ld	s1,8(sp)
    80003766:	6902                	ld	s2,0(sp)
    80003768:	6105                	addi	sp,sp,32
    8000376a:	8082                	ret
    panic("brelse");
    8000376c:	00005517          	auipc	a0,0x5
    80003770:	ec450513          	addi	a0,a0,-316 # 80008630 <syscalls+0xf0>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	dca080e7          	jalr	-566(ra) # 8000053e <panic>

000000008000377c <bpin>:

void
bpin(struct buf *b) {
    8000377c:	1101                	addi	sp,sp,-32
    8000377e:	ec06                	sd	ra,24(sp)
    80003780:	e822                	sd	s0,16(sp)
    80003782:	e426                	sd	s1,8(sp)
    80003784:	1000                	addi	s0,sp,32
    80003786:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003788:	00015517          	auipc	a0,0x15
    8000378c:	5d850513          	addi	a0,a0,1496 # 80018d60 <bcache>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	454080e7          	jalr	1108(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003798:	40bc                	lw	a5,64(s1)
    8000379a:	2785                	addiw	a5,a5,1
    8000379c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000379e:	00015517          	auipc	a0,0x15
    800037a2:	5c250513          	addi	a0,a0,1474 # 80018d60 <bcache>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	4f2080e7          	jalr	1266(ra) # 80000c98 <release>
}
    800037ae:	60e2                	ld	ra,24(sp)
    800037b0:	6442                	ld	s0,16(sp)
    800037b2:	64a2                	ld	s1,8(sp)
    800037b4:	6105                	addi	sp,sp,32
    800037b6:	8082                	ret

00000000800037b8 <bunpin>:

void
bunpin(struct buf *b) {
    800037b8:	1101                	addi	sp,sp,-32
    800037ba:	ec06                	sd	ra,24(sp)
    800037bc:	e822                	sd	s0,16(sp)
    800037be:	e426                	sd	s1,8(sp)
    800037c0:	1000                	addi	s0,sp,32
    800037c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037c4:	00015517          	auipc	a0,0x15
    800037c8:	59c50513          	addi	a0,a0,1436 # 80018d60 <bcache>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	418080e7          	jalr	1048(ra) # 80000be4 <acquire>
  b->refcnt--;
    800037d4:	40bc                	lw	a5,64(s1)
    800037d6:	37fd                	addiw	a5,a5,-1
    800037d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037da:	00015517          	auipc	a0,0x15
    800037de:	58650513          	addi	a0,a0,1414 # 80018d60 <bcache>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	4b6080e7          	jalr	1206(ra) # 80000c98 <release>
}
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	64a2                	ld	s1,8(sp)
    800037f0:	6105                	addi	sp,sp,32
    800037f2:	8082                	ret

00000000800037f4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037f4:	1101                	addi	sp,sp,-32
    800037f6:	ec06                	sd	ra,24(sp)
    800037f8:	e822                	sd	s0,16(sp)
    800037fa:	e426                	sd	s1,8(sp)
    800037fc:	e04a                	sd	s2,0(sp)
    800037fe:	1000                	addi	s0,sp,32
    80003800:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003802:	00d5d59b          	srliw	a1,a1,0xd
    80003806:	0001e797          	auipc	a5,0x1e
    8000380a:	c367a783          	lw	a5,-970(a5) # 8002143c <sb+0x1c>
    8000380e:	9dbd                	addw	a1,a1,a5
    80003810:	00000097          	auipc	ra,0x0
    80003814:	d9e080e7          	jalr	-610(ra) # 800035ae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003818:	0074f713          	andi	a4,s1,7
    8000381c:	4785                	li	a5,1
    8000381e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003822:	14ce                	slli	s1,s1,0x33
    80003824:	90d9                	srli	s1,s1,0x36
    80003826:	00950733          	add	a4,a0,s1
    8000382a:	05874703          	lbu	a4,88(a4)
    8000382e:	00e7f6b3          	and	a3,a5,a4
    80003832:	c69d                	beqz	a3,80003860 <bfree+0x6c>
    80003834:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003836:	94aa                	add	s1,s1,a0
    80003838:	fff7c793          	not	a5,a5
    8000383c:	8ff9                	and	a5,a5,a4
    8000383e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003842:	00001097          	auipc	ra,0x1
    80003846:	118080e7          	jalr	280(ra) # 8000495a <log_write>
  brelse(bp);
    8000384a:	854a                	mv	a0,s2
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	e92080e7          	jalr	-366(ra) # 800036de <brelse>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	64a2                	ld	s1,8(sp)
    8000385a:	6902                	ld	s2,0(sp)
    8000385c:	6105                	addi	sp,sp,32
    8000385e:	8082                	ret
    panic("freeing free block");
    80003860:	00005517          	auipc	a0,0x5
    80003864:	dd850513          	addi	a0,a0,-552 # 80008638 <syscalls+0xf8>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	cd6080e7          	jalr	-810(ra) # 8000053e <panic>

0000000080003870 <balloc>:
{
    80003870:	711d                	addi	sp,sp,-96
    80003872:	ec86                	sd	ra,88(sp)
    80003874:	e8a2                	sd	s0,80(sp)
    80003876:	e4a6                	sd	s1,72(sp)
    80003878:	e0ca                	sd	s2,64(sp)
    8000387a:	fc4e                	sd	s3,56(sp)
    8000387c:	f852                	sd	s4,48(sp)
    8000387e:	f456                	sd	s5,40(sp)
    80003880:	f05a                	sd	s6,32(sp)
    80003882:	ec5e                	sd	s7,24(sp)
    80003884:	e862                	sd	s8,16(sp)
    80003886:	e466                	sd	s9,8(sp)
    80003888:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000388a:	0001e797          	auipc	a5,0x1e
    8000388e:	b9a7a783          	lw	a5,-1126(a5) # 80021424 <sb+0x4>
    80003892:	cbd1                	beqz	a5,80003926 <balloc+0xb6>
    80003894:	8baa                	mv	s7,a0
    80003896:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003898:	0001eb17          	auipc	s6,0x1e
    8000389c:	b88b0b13          	addi	s6,s6,-1144 # 80021420 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038a0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038a2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038a4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038a6:	6c89                	lui	s9,0x2
    800038a8:	a831                	j	800038c4 <balloc+0x54>
    brelse(bp);
    800038aa:	854a                	mv	a0,s2
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	e32080e7          	jalr	-462(ra) # 800036de <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038b4:	015c87bb          	addw	a5,s9,s5
    800038b8:	00078a9b          	sext.w	s5,a5
    800038bc:	004b2703          	lw	a4,4(s6)
    800038c0:	06eaf363          	bgeu	s5,a4,80003926 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038c4:	41fad79b          	sraiw	a5,s5,0x1f
    800038c8:	0137d79b          	srliw	a5,a5,0x13
    800038cc:	015787bb          	addw	a5,a5,s5
    800038d0:	40d7d79b          	sraiw	a5,a5,0xd
    800038d4:	01cb2583          	lw	a1,28(s6)
    800038d8:	9dbd                	addw	a1,a1,a5
    800038da:	855e                	mv	a0,s7
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	cd2080e7          	jalr	-814(ra) # 800035ae <bread>
    800038e4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038e6:	004b2503          	lw	a0,4(s6)
    800038ea:	000a849b          	sext.w	s1,s5
    800038ee:	8662                	mv	a2,s8
    800038f0:	faa4fde3          	bgeu	s1,a0,800038aa <balloc+0x3a>
      m = 1 << (bi % 8);
    800038f4:	41f6579b          	sraiw	a5,a2,0x1f
    800038f8:	01d7d69b          	srliw	a3,a5,0x1d
    800038fc:	00c6873b          	addw	a4,a3,a2
    80003900:	00777793          	andi	a5,a4,7
    80003904:	9f95                	subw	a5,a5,a3
    80003906:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000390a:	4037571b          	sraiw	a4,a4,0x3
    8000390e:	00e906b3          	add	a3,s2,a4
    80003912:	0586c683          	lbu	a3,88(a3)
    80003916:	00d7f5b3          	and	a1,a5,a3
    8000391a:	cd91                	beqz	a1,80003936 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000391c:	2605                	addiw	a2,a2,1
    8000391e:	2485                	addiw	s1,s1,1
    80003920:	fd4618e3          	bne	a2,s4,800038f0 <balloc+0x80>
    80003924:	b759                	j	800038aa <balloc+0x3a>
  panic("balloc: out of blocks");
    80003926:	00005517          	auipc	a0,0x5
    8000392a:	d2a50513          	addi	a0,a0,-726 # 80008650 <syscalls+0x110>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	c10080e7          	jalr	-1008(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003936:	974a                	add	a4,a4,s2
    80003938:	8fd5                	or	a5,a5,a3
    8000393a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000393e:	854a                	mv	a0,s2
    80003940:	00001097          	auipc	ra,0x1
    80003944:	01a080e7          	jalr	26(ra) # 8000495a <log_write>
        brelse(bp);
    80003948:	854a                	mv	a0,s2
    8000394a:	00000097          	auipc	ra,0x0
    8000394e:	d94080e7          	jalr	-620(ra) # 800036de <brelse>
  bp = bread(dev, bno);
    80003952:	85a6                	mv	a1,s1
    80003954:	855e                	mv	a0,s7
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	c58080e7          	jalr	-936(ra) # 800035ae <bread>
    8000395e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003960:	40000613          	li	a2,1024
    80003964:	4581                	li	a1,0
    80003966:	05850513          	addi	a0,a0,88
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	376080e7          	jalr	886(ra) # 80000ce0 <memset>
  log_write(bp);
    80003972:	854a                	mv	a0,s2
    80003974:	00001097          	auipc	ra,0x1
    80003978:	fe6080e7          	jalr	-26(ra) # 8000495a <log_write>
  brelse(bp);
    8000397c:	854a                	mv	a0,s2
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	d60080e7          	jalr	-672(ra) # 800036de <brelse>
}
    80003986:	8526                	mv	a0,s1
    80003988:	60e6                	ld	ra,88(sp)
    8000398a:	6446                	ld	s0,80(sp)
    8000398c:	64a6                	ld	s1,72(sp)
    8000398e:	6906                	ld	s2,64(sp)
    80003990:	79e2                	ld	s3,56(sp)
    80003992:	7a42                	ld	s4,48(sp)
    80003994:	7aa2                	ld	s5,40(sp)
    80003996:	7b02                	ld	s6,32(sp)
    80003998:	6be2                	ld	s7,24(sp)
    8000399a:	6c42                	ld	s8,16(sp)
    8000399c:	6ca2                	ld	s9,8(sp)
    8000399e:	6125                	addi	sp,sp,96
    800039a0:	8082                	ret

00000000800039a2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039a2:	7179                	addi	sp,sp,-48
    800039a4:	f406                	sd	ra,40(sp)
    800039a6:	f022                	sd	s0,32(sp)
    800039a8:	ec26                	sd	s1,24(sp)
    800039aa:	e84a                	sd	s2,16(sp)
    800039ac:	e44e                	sd	s3,8(sp)
    800039ae:	e052                	sd	s4,0(sp)
    800039b0:	1800                	addi	s0,sp,48
    800039b2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039b4:	47ad                	li	a5,11
    800039b6:	04b7fe63          	bgeu	a5,a1,80003a12 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039ba:	ff45849b          	addiw	s1,a1,-12
    800039be:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039c2:	0ff00793          	li	a5,255
    800039c6:	0ae7e363          	bltu	a5,a4,80003a6c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800039ca:	08052583          	lw	a1,128(a0)
    800039ce:	c5ad                	beqz	a1,80003a38 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800039d0:	00092503          	lw	a0,0(s2)
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	bda080e7          	jalr	-1062(ra) # 800035ae <bread>
    800039dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039de:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039e2:	02049593          	slli	a1,s1,0x20
    800039e6:	9181                	srli	a1,a1,0x20
    800039e8:	058a                	slli	a1,a1,0x2
    800039ea:	00b784b3          	add	s1,a5,a1
    800039ee:	0004a983          	lw	s3,0(s1)
    800039f2:	04098d63          	beqz	s3,80003a4c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800039f6:	8552                	mv	a0,s4
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	ce6080e7          	jalr	-794(ra) # 800036de <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a00:	854e                	mv	a0,s3
    80003a02:	70a2                	ld	ra,40(sp)
    80003a04:	7402                	ld	s0,32(sp)
    80003a06:	64e2                	ld	s1,24(sp)
    80003a08:	6942                	ld	s2,16(sp)
    80003a0a:	69a2                	ld	s3,8(sp)
    80003a0c:	6a02                	ld	s4,0(sp)
    80003a0e:	6145                	addi	sp,sp,48
    80003a10:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a12:	02059493          	slli	s1,a1,0x20
    80003a16:	9081                	srli	s1,s1,0x20
    80003a18:	048a                	slli	s1,s1,0x2
    80003a1a:	94aa                	add	s1,s1,a0
    80003a1c:	0504a983          	lw	s3,80(s1)
    80003a20:	fe0990e3          	bnez	s3,80003a00 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a24:	4108                	lw	a0,0(a0)
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	e4a080e7          	jalr	-438(ra) # 80003870 <balloc>
    80003a2e:	0005099b          	sext.w	s3,a0
    80003a32:	0534a823          	sw	s3,80(s1)
    80003a36:	b7e9                	j	80003a00 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a38:	4108                	lw	a0,0(a0)
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	e36080e7          	jalr	-458(ra) # 80003870 <balloc>
    80003a42:	0005059b          	sext.w	a1,a0
    80003a46:	08b92023          	sw	a1,128(s2)
    80003a4a:	b759                	j	800039d0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a4c:	00092503          	lw	a0,0(s2)
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	e20080e7          	jalr	-480(ra) # 80003870 <balloc>
    80003a58:	0005099b          	sext.w	s3,a0
    80003a5c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a60:	8552                	mv	a0,s4
    80003a62:	00001097          	auipc	ra,0x1
    80003a66:	ef8080e7          	jalr	-264(ra) # 8000495a <log_write>
    80003a6a:	b771                	j	800039f6 <bmap+0x54>
  panic("bmap: out of range");
    80003a6c:	00005517          	auipc	a0,0x5
    80003a70:	bfc50513          	addi	a0,a0,-1028 # 80008668 <syscalls+0x128>
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	aca080e7          	jalr	-1334(ra) # 8000053e <panic>

0000000080003a7c <iget>:
{
    80003a7c:	7179                	addi	sp,sp,-48
    80003a7e:	f406                	sd	ra,40(sp)
    80003a80:	f022                	sd	s0,32(sp)
    80003a82:	ec26                	sd	s1,24(sp)
    80003a84:	e84a                	sd	s2,16(sp)
    80003a86:	e44e                	sd	s3,8(sp)
    80003a88:	e052                	sd	s4,0(sp)
    80003a8a:	1800                	addi	s0,sp,48
    80003a8c:	89aa                	mv	s3,a0
    80003a8e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a90:	0001e517          	auipc	a0,0x1e
    80003a94:	9b050513          	addi	a0,a0,-1616 # 80021440 <itable>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	14c080e7          	jalr	332(ra) # 80000be4 <acquire>
  empty = 0;
    80003aa0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aa2:	0001e497          	auipc	s1,0x1e
    80003aa6:	9b648493          	addi	s1,s1,-1610 # 80021458 <itable+0x18>
    80003aaa:	0001f697          	auipc	a3,0x1f
    80003aae:	43e68693          	addi	a3,a3,1086 # 80022ee8 <log>
    80003ab2:	a039                	j	80003ac0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ab4:	02090b63          	beqz	s2,80003aea <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ab8:	08848493          	addi	s1,s1,136
    80003abc:	02d48a63          	beq	s1,a3,80003af0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ac0:	449c                	lw	a5,8(s1)
    80003ac2:	fef059e3          	blez	a5,80003ab4 <iget+0x38>
    80003ac6:	4098                	lw	a4,0(s1)
    80003ac8:	ff3716e3          	bne	a4,s3,80003ab4 <iget+0x38>
    80003acc:	40d8                	lw	a4,4(s1)
    80003ace:	ff4713e3          	bne	a4,s4,80003ab4 <iget+0x38>
      ip->ref++;
    80003ad2:	2785                	addiw	a5,a5,1
    80003ad4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ad6:	0001e517          	auipc	a0,0x1e
    80003ada:	96a50513          	addi	a0,a0,-1686 # 80021440 <itable>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	1ba080e7          	jalr	442(ra) # 80000c98 <release>
      return ip;
    80003ae6:	8926                	mv	s2,s1
    80003ae8:	a03d                	j	80003b16 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aea:	f7f9                	bnez	a5,80003ab8 <iget+0x3c>
    80003aec:	8926                	mv	s2,s1
    80003aee:	b7e9                	j	80003ab8 <iget+0x3c>
  if(empty == 0)
    80003af0:	02090c63          	beqz	s2,80003b28 <iget+0xac>
  ip->dev = dev;
    80003af4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003af8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003afc:	4785                	li	a5,1
    80003afe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b02:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b06:	0001e517          	auipc	a0,0x1e
    80003b0a:	93a50513          	addi	a0,a0,-1734 # 80021440 <itable>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
}
    80003b16:	854a                	mv	a0,s2
    80003b18:	70a2                	ld	ra,40(sp)
    80003b1a:	7402                	ld	s0,32(sp)
    80003b1c:	64e2                	ld	s1,24(sp)
    80003b1e:	6942                	ld	s2,16(sp)
    80003b20:	69a2                	ld	s3,8(sp)
    80003b22:	6a02                	ld	s4,0(sp)
    80003b24:	6145                	addi	sp,sp,48
    80003b26:	8082                	ret
    panic("iget: no inodes");
    80003b28:	00005517          	auipc	a0,0x5
    80003b2c:	b5850513          	addi	a0,a0,-1192 # 80008680 <syscalls+0x140>
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	a0e080e7          	jalr	-1522(ra) # 8000053e <panic>

0000000080003b38 <fsinit>:
fsinit(int dev) {
    80003b38:	7179                	addi	sp,sp,-48
    80003b3a:	f406                	sd	ra,40(sp)
    80003b3c:	f022                	sd	s0,32(sp)
    80003b3e:	ec26                	sd	s1,24(sp)
    80003b40:	e84a                	sd	s2,16(sp)
    80003b42:	e44e                	sd	s3,8(sp)
    80003b44:	1800                	addi	s0,sp,48
    80003b46:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b48:	4585                	li	a1,1
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	a64080e7          	jalr	-1436(ra) # 800035ae <bread>
    80003b52:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b54:	0001e997          	auipc	s3,0x1e
    80003b58:	8cc98993          	addi	s3,s3,-1844 # 80021420 <sb>
    80003b5c:	02000613          	li	a2,32
    80003b60:	05850593          	addi	a1,a0,88
    80003b64:	854e                	mv	a0,s3
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	1da080e7          	jalr	474(ra) # 80000d40 <memmove>
  brelse(bp);
    80003b6e:	8526                	mv	a0,s1
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	b6e080e7          	jalr	-1170(ra) # 800036de <brelse>
  if(sb.magic != FSMAGIC)
    80003b78:	0009a703          	lw	a4,0(s3)
    80003b7c:	102037b7          	lui	a5,0x10203
    80003b80:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b84:	02f71263          	bne	a4,a5,80003ba8 <fsinit+0x70>
  initlog(dev, &sb);
    80003b88:	0001e597          	auipc	a1,0x1e
    80003b8c:	89858593          	addi	a1,a1,-1896 # 80021420 <sb>
    80003b90:	854a                	mv	a0,s2
    80003b92:	00001097          	auipc	ra,0x1
    80003b96:	b4c080e7          	jalr	-1204(ra) # 800046de <initlog>
}
    80003b9a:	70a2                	ld	ra,40(sp)
    80003b9c:	7402                	ld	s0,32(sp)
    80003b9e:	64e2                	ld	s1,24(sp)
    80003ba0:	6942                	ld	s2,16(sp)
    80003ba2:	69a2                	ld	s3,8(sp)
    80003ba4:	6145                	addi	sp,sp,48
    80003ba6:	8082                	ret
    panic("invalid file system");
    80003ba8:	00005517          	auipc	a0,0x5
    80003bac:	ae850513          	addi	a0,a0,-1304 # 80008690 <syscalls+0x150>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>

0000000080003bb8 <iinit>:
{
    80003bb8:	7179                	addi	sp,sp,-48
    80003bba:	f406                	sd	ra,40(sp)
    80003bbc:	f022                	sd	s0,32(sp)
    80003bbe:	ec26                	sd	s1,24(sp)
    80003bc0:	e84a                	sd	s2,16(sp)
    80003bc2:	e44e                	sd	s3,8(sp)
    80003bc4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bc6:	00005597          	auipc	a1,0x5
    80003bca:	ae258593          	addi	a1,a1,-1310 # 800086a8 <syscalls+0x168>
    80003bce:	0001e517          	auipc	a0,0x1e
    80003bd2:	87250513          	addi	a0,a0,-1934 # 80021440 <itable>
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	f7e080e7          	jalr	-130(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bde:	0001e497          	auipc	s1,0x1e
    80003be2:	88a48493          	addi	s1,s1,-1910 # 80021468 <itable+0x28>
    80003be6:	0001f997          	auipc	s3,0x1f
    80003bea:	31298993          	addi	s3,s3,786 # 80022ef8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bee:	00005917          	auipc	s2,0x5
    80003bf2:	ac290913          	addi	s2,s2,-1342 # 800086b0 <syscalls+0x170>
    80003bf6:	85ca                	mv	a1,s2
    80003bf8:	8526                	mv	a0,s1
    80003bfa:	00001097          	auipc	ra,0x1
    80003bfe:	e46080e7          	jalr	-442(ra) # 80004a40 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c02:	08848493          	addi	s1,s1,136
    80003c06:	ff3498e3          	bne	s1,s3,80003bf6 <iinit+0x3e>
}
    80003c0a:	70a2                	ld	ra,40(sp)
    80003c0c:	7402                	ld	s0,32(sp)
    80003c0e:	64e2                	ld	s1,24(sp)
    80003c10:	6942                	ld	s2,16(sp)
    80003c12:	69a2                	ld	s3,8(sp)
    80003c14:	6145                	addi	sp,sp,48
    80003c16:	8082                	ret

0000000080003c18 <ialloc>:
{
    80003c18:	715d                	addi	sp,sp,-80
    80003c1a:	e486                	sd	ra,72(sp)
    80003c1c:	e0a2                	sd	s0,64(sp)
    80003c1e:	fc26                	sd	s1,56(sp)
    80003c20:	f84a                	sd	s2,48(sp)
    80003c22:	f44e                	sd	s3,40(sp)
    80003c24:	f052                	sd	s4,32(sp)
    80003c26:	ec56                	sd	s5,24(sp)
    80003c28:	e85a                	sd	s6,16(sp)
    80003c2a:	e45e                	sd	s7,8(sp)
    80003c2c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c2e:	0001d717          	auipc	a4,0x1d
    80003c32:	7fe72703          	lw	a4,2046(a4) # 8002142c <sb+0xc>
    80003c36:	4785                	li	a5,1
    80003c38:	04e7fa63          	bgeu	a5,a4,80003c8c <ialloc+0x74>
    80003c3c:	8aaa                	mv	s5,a0
    80003c3e:	8bae                	mv	s7,a1
    80003c40:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c42:	0001da17          	auipc	s4,0x1d
    80003c46:	7dea0a13          	addi	s4,s4,2014 # 80021420 <sb>
    80003c4a:	00048b1b          	sext.w	s6,s1
    80003c4e:	0044d593          	srli	a1,s1,0x4
    80003c52:	018a2783          	lw	a5,24(s4)
    80003c56:	9dbd                	addw	a1,a1,a5
    80003c58:	8556                	mv	a0,s5
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	954080e7          	jalr	-1708(ra) # 800035ae <bread>
    80003c62:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c64:	05850993          	addi	s3,a0,88
    80003c68:	00f4f793          	andi	a5,s1,15
    80003c6c:	079a                	slli	a5,a5,0x6
    80003c6e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c70:	00099783          	lh	a5,0(s3)
    80003c74:	c785                	beqz	a5,80003c9c <ialloc+0x84>
    brelse(bp);
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	a68080e7          	jalr	-1432(ra) # 800036de <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c7e:	0485                	addi	s1,s1,1
    80003c80:	00ca2703          	lw	a4,12(s4)
    80003c84:	0004879b          	sext.w	a5,s1
    80003c88:	fce7e1e3          	bltu	a5,a4,80003c4a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c8c:	00005517          	auipc	a0,0x5
    80003c90:	a2c50513          	addi	a0,a0,-1492 # 800086b8 <syscalls+0x178>
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	8aa080e7          	jalr	-1878(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003c9c:	04000613          	li	a2,64
    80003ca0:	4581                	li	a1,0
    80003ca2:	854e                	mv	a0,s3
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	03c080e7          	jalr	60(ra) # 80000ce0 <memset>
      dip->type = type;
    80003cac:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	00001097          	auipc	ra,0x1
    80003cb6:	ca8080e7          	jalr	-856(ra) # 8000495a <log_write>
      brelse(bp);
    80003cba:	854a                	mv	a0,s2
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	a22080e7          	jalr	-1502(ra) # 800036de <brelse>
      return iget(dev, inum);
    80003cc4:	85da                	mv	a1,s6
    80003cc6:	8556                	mv	a0,s5
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	db4080e7          	jalr	-588(ra) # 80003a7c <iget>
}
    80003cd0:	60a6                	ld	ra,72(sp)
    80003cd2:	6406                	ld	s0,64(sp)
    80003cd4:	74e2                	ld	s1,56(sp)
    80003cd6:	7942                	ld	s2,48(sp)
    80003cd8:	79a2                	ld	s3,40(sp)
    80003cda:	7a02                	ld	s4,32(sp)
    80003cdc:	6ae2                	ld	s5,24(sp)
    80003cde:	6b42                	ld	s6,16(sp)
    80003ce0:	6ba2                	ld	s7,8(sp)
    80003ce2:	6161                	addi	sp,sp,80
    80003ce4:	8082                	ret

0000000080003ce6 <iupdate>:
{
    80003ce6:	1101                	addi	sp,sp,-32
    80003ce8:	ec06                	sd	ra,24(sp)
    80003cea:	e822                	sd	s0,16(sp)
    80003cec:	e426                	sd	s1,8(sp)
    80003cee:	e04a                	sd	s2,0(sp)
    80003cf0:	1000                	addi	s0,sp,32
    80003cf2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cf4:	415c                	lw	a5,4(a0)
    80003cf6:	0047d79b          	srliw	a5,a5,0x4
    80003cfa:	0001d597          	auipc	a1,0x1d
    80003cfe:	73e5a583          	lw	a1,1854(a1) # 80021438 <sb+0x18>
    80003d02:	9dbd                	addw	a1,a1,a5
    80003d04:	4108                	lw	a0,0(a0)
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	8a8080e7          	jalr	-1880(ra) # 800035ae <bread>
    80003d0e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d10:	05850793          	addi	a5,a0,88
    80003d14:	40c8                	lw	a0,4(s1)
    80003d16:	893d                	andi	a0,a0,15
    80003d18:	051a                	slli	a0,a0,0x6
    80003d1a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d1c:	04449703          	lh	a4,68(s1)
    80003d20:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d24:	04649703          	lh	a4,70(s1)
    80003d28:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d2c:	04849703          	lh	a4,72(s1)
    80003d30:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d34:	04a49703          	lh	a4,74(s1)
    80003d38:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d3c:	44f8                	lw	a4,76(s1)
    80003d3e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d40:	03400613          	li	a2,52
    80003d44:	05048593          	addi	a1,s1,80
    80003d48:	0531                	addi	a0,a0,12
    80003d4a:	ffffd097          	auipc	ra,0xffffd
    80003d4e:	ff6080e7          	jalr	-10(ra) # 80000d40 <memmove>
  log_write(bp);
    80003d52:	854a                	mv	a0,s2
    80003d54:	00001097          	auipc	ra,0x1
    80003d58:	c06080e7          	jalr	-1018(ra) # 8000495a <log_write>
  brelse(bp);
    80003d5c:	854a                	mv	a0,s2
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	980080e7          	jalr	-1664(ra) # 800036de <brelse>
}
    80003d66:	60e2                	ld	ra,24(sp)
    80003d68:	6442                	ld	s0,16(sp)
    80003d6a:	64a2                	ld	s1,8(sp)
    80003d6c:	6902                	ld	s2,0(sp)
    80003d6e:	6105                	addi	sp,sp,32
    80003d70:	8082                	ret

0000000080003d72 <idup>:
{
    80003d72:	1101                	addi	sp,sp,-32
    80003d74:	ec06                	sd	ra,24(sp)
    80003d76:	e822                	sd	s0,16(sp)
    80003d78:	e426                	sd	s1,8(sp)
    80003d7a:	1000                	addi	s0,sp,32
    80003d7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d7e:	0001d517          	auipc	a0,0x1d
    80003d82:	6c250513          	addi	a0,a0,1730 # 80021440 <itable>
    80003d86:	ffffd097          	auipc	ra,0xffffd
    80003d8a:	e5e080e7          	jalr	-418(ra) # 80000be4 <acquire>
  ip->ref++;
    80003d8e:	449c                	lw	a5,8(s1)
    80003d90:	2785                	addiw	a5,a5,1
    80003d92:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d94:	0001d517          	auipc	a0,0x1d
    80003d98:	6ac50513          	addi	a0,a0,1708 # 80021440 <itable>
    80003d9c:	ffffd097          	auipc	ra,0xffffd
    80003da0:	efc080e7          	jalr	-260(ra) # 80000c98 <release>
}
    80003da4:	8526                	mv	a0,s1
    80003da6:	60e2                	ld	ra,24(sp)
    80003da8:	6442                	ld	s0,16(sp)
    80003daa:	64a2                	ld	s1,8(sp)
    80003dac:	6105                	addi	sp,sp,32
    80003dae:	8082                	ret

0000000080003db0 <ilock>:
{
    80003db0:	1101                	addi	sp,sp,-32
    80003db2:	ec06                	sd	ra,24(sp)
    80003db4:	e822                	sd	s0,16(sp)
    80003db6:	e426                	sd	s1,8(sp)
    80003db8:	e04a                	sd	s2,0(sp)
    80003dba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dbc:	c115                	beqz	a0,80003de0 <ilock+0x30>
    80003dbe:	84aa                	mv	s1,a0
    80003dc0:	451c                	lw	a5,8(a0)
    80003dc2:	00f05f63          	blez	a5,80003de0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dc6:	0541                	addi	a0,a0,16
    80003dc8:	00001097          	auipc	ra,0x1
    80003dcc:	cb2080e7          	jalr	-846(ra) # 80004a7a <acquiresleep>
  if(ip->valid == 0){
    80003dd0:	40bc                	lw	a5,64(s1)
    80003dd2:	cf99                	beqz	a5,80003df0 <ilock+0x40>
}
    80003dd4:	60e2                	ld	ra,24(sp)
    80003dd6:	6442                	ld	s0,16(sp)
    80003dd8:	64a2                	ld	s1,8(sp)
    80003dda:	6902                	ld	s2,0(sp)
    80003ddc:	6105                	addi	sp,sp,32
    80003dde:	8082                	ret
    panic("ilock");
    80003de0:	00005517          	auipc	a0,0x5
    80003de4:	8f050513          	addi	a0,a0,-1808 # 800086d0 <syscalls+0x190>
    80003de8:	ffffc097          	auipc	ra,0xffffc
    80003dec:	756080e7          	jalr	1878(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003df0:	40dc                	lw	a5,4(s1)
    80003df2:	0047d79b          	srliw	a5,a5,0x4
    80003df6:	0001d597          	auipc	a1,0x1d
    80003dfa:	6425a583          	lw	a1,1602(a1) # 80021438 <sb+0x18>
    80003dfe:	9dbd                	addw	a1,a1,a5
    80003e00:	4088                	lw	a0,0(s1)
    80003e02:	fffff097          	auipc	ra,0xfffff
    80003e06:	7ac080e7          	jalr	1964(ra) # 800035ae <bread>
    80003e0a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e0c:	05850593          	addi	a1,a0,88
    80003e10:	40dc                	lw	a5,4(s1)
    80003e12:	8bbd                	andi	a5,a5,15
    80003e14:	079a                	slli	a5,a5,0x6
    80003e16:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e18:	00059783          	lh	a5,0(a1)
    80003e1c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e20:	00259783          	lh	a5,2(a1)
    80003e24:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e28:	00459783          	lh	a5,4(a1)
    80003e2c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e30:	00659783          	lh	a5,6(a1)
    80003e34:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e38:	459c                	lw	a5,8(a1)
    80003e3a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e3c:	03400613          	li	a2,52
    80003e40:	05b1                	addi	a1,a1,12
    80003e42:	05048513          	addi	a0,s1,80
    80003e46:	ffffd097          	auipc	ra,0xffffd
    80003e4a:	efa080e7          	jalr	-262(ra) # 80000d40 <memmove>
    brelse(bp);
    80003e4e:	854a                	mv	a0,s2
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	88e080e7          	jalr	-1906(ra) # 800036de <brelse>
    ip->valid = 1;
    80003e58:	4785                	li	a5,1
    80003e5a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e5c:	04449783          	lh	a5,68(s1)
    80003e60:	fbb5                	bnez	a5,80003dd4 <ilock+0x24>
      panic("ilock: no type");
    80003e62:	00005517          	auipc	a0,0x5
    80003e66:	87650513          	addi	a0,a0,-1930 # 800086d8 <syscalls+0x198>
    80003e6a:	ffffc097          	auipc	ra,0xffffc
    80003e6e:	6d4080e7          	jalr	1748(ra) # 8000053e <panic>

0000000080003e72 <iunlock>:
{
    80003e72:	1101                	addi	sp,sp,-32
    80003e74:	ec06                	sd	ra,24(sp)
    80003e76:	e822                	sd	s0,16(sp)
    80003e78:	e426                	sd	s1,8(sp)
    80003e7a:	e04a                	sd	s2,0(sp)
    80003e7c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e7e:	c905                	beqz	a0,80003eae <iunlock+0x3c>
    80003e80:	84aa                	mv	s1,a0
    80003e82:	01050913          	addi	s2,a0,16
    80003e86:	854a                	mv	a0,s2
    80003e88:	00001097          	auipc	ra,0x1
    80003e8c:	c8c080e7          	jalr	-884(ra) # 80004b14 <holdingsleep>
    80003e90:	cd19                	beqz	a0,80003eae <iunlock+0x3c>
    80003e92:	449c                	lw	a5,8(s1)
    80003e94:	00f05d63          	blez	a5,80003eae <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e98:	854a                	mv	a0,s2
    80003e9a:	00001097          	auipc	ra,0x1
    80003e9e:	c36080e7          	jalr	-970(ra) # 80004ad0 <releasesleep>
}
    80003ea2:	60e2                	ld	ra,24(sp)
    80003ea4:	6442                	ld	s0,16(sp)
    80003ea6:	64a2                	ld	s1,8(sp)
    80003ea8:	6902                	ld	s2,0(sp)
    80003eaa:	6105                	addi	sp,sp,32
    80003eac:	8082                	ret
    panic("iunlock");
    80003eae:	00005517          	auipc	a0,0x5
    80003eb2:	83a50513          	addi	a0,a0,-1990 # 800086e8 <syscalls+0x1a8>
    80003eb6:	ffffc097          	auipc	ra,0xffffc
    80003eba:	688080e7          	jalr	1672(ra) # 8000053e <panic>

0000000080003ebe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ebe:	7179                	addi	sp,sp,-48
    80003ec0:	f406                	sd	ra,40(sp)
    80003ec2:	f022                	sd	s0,32(sp)
    80003ec4:	ec26                	sd	s1,24(sp)
    80003ec6:	e84a                	sd	s2,16(sp)
    80003ec8:	e44e                	sd	s3,8(sp)
    80003eca:	e052                	sd	s4,0(sp)
    80003ecc:	1800                	addi	s0,sp,48
    80003ece:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ed0:	05050493          	addi	s1,a0,80
    80003ed4:	08050913          	addi	s2,a0,128
    80003ed8:	a021                	j	80003ee0 <itrunc+0x22>
    80003eda:	0491                	addi	s1,s1,4
    80003edc:	01248d63          	beq	s1,s2,80003ef6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ee0:	408c                	lw	a1,0(s1)
    80003ee2:	dde5                	beqz	a1,80003eda <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ee4:	0009a503          	lw	a0,0(s3)
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	90c080e7          	jalr	-1780(ra) # 800037f4 <bfree>
      ip->addrs[i] = 0;
    80003ef0:	0004a023          	sw	zero,0(s1)
    80003ef4:	b7dd                	j	80003eda <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ef6:	0809a583          	lw	a1,128(s3)
    80003efa:	e185                	bnez	a1,80003f1a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003efc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f00:	854e                	mv	a0,s3
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	de4080e7          	jalr	-540(ra) # 80003ce6 <iupdate>
}
    80003f0a:	70a2                	ld	ra,40(sp)
    80003f0c:	7402                	ld	s0,32(sp)
    80003f0e:	64e2                	ld	s1,24(sp)
    80003f10:	6942                	ld	s2,16(sp)
    80003f12:	69a2                	ld	s3,8(sp)
    80003f14:	6a02                	ld	s4,0(sp)
    80003f16:	6145                	addi	sp,sp,48
    80003f18:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f1a:	0009a503          	lw	a0,0(s3)
    80003f1e:	fffff097          	auipc	ra,0xfffff
    80003f22:	690080e7          	jalr	1680(ra) # 800035ae <bread>
    80003f26:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f28:	05850493          	addi	s1,a0,88
    80003f2c:	45850913          	addi	s2,a0,1112
    80003f30:	a811                	j	80003f44 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f32:	0009a503          	lw	a0,0(s3)
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	8be080e7          	jalr	-1858(ra) # 800037f4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f3e:	0491                	addi	s1,s1,4
    80003f40:	01248563          	beq	s1,s2,80003f4a <itrunc+0x8c>
      if(a[j])
    80003f44:	408c                	lw	a1,0(s1)
    80003f46:	dde5                	beqz	a1,80003f3e <itrunc+0x80>
    80003f48:	b7ed                	j	80003f32 <itrunc+0x74>
    brelse(bp);
    80003f4a:	8552                	mv	a0,s4
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	792080e7          	jalr	1938(ra) # 800036de <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f54:	0809a583          	lw	a1,128(s3)
    80003f58:	0009a503          	lw	a0,0(s3)
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	898080e7          	jalr	-1896(ra) # 800037f4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f64:	0809a023          	sw	zero,128(s3)
    80003f68:	bf51                	j	80003efc <itrunc+0x3e>

0000000080003f6a <iput>:
{
    80003f6a:	1101                	addi	sp,sp,-32
    80003f6c:	ec06                	sd	ra,24(sp)
    80003f6e:	e822                	sd	s0,16(sp)
    80003f70:	e426                	sd	s1,8(sp)
    80003f72:	e04a                	sd	s2,0(sp)
    80003f74:	1000                	addi	s0,sp,32
    80003f76:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f78:	0001d517          	auipc	a0,0x1d
    80003f7c:	4c850513          	addi	a0,a0,1224 # 80021440 <itable>
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	c64080e7          	jalr	-924(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f88:	4498                	lw	a4,8(s1)
    80003f8a:	4785                	li	a5,1
    80003f8c:	02f70363          	beq	a4,a5,80003fb2 <iput+0x48>
  ip->ref--;
    80003f90:	449c                	lw	a5,8(s1)
    80003f92:	37fd                	addiw	a5,a5,-1
    80003f94:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f96:	0001d517          	auipc	a0,0x1d
    80003f9a:	4aa50513          	addi	a0,a0,1194 # 80021440 <itable>
    80003f9e:	ffffd097          	auipc	ra,0xffffd
    80003fa2:	cfa080e7          	jalr	-774(ra) # 80000c98 <release>
}
    80003fa6:	60e2                	ld	ra,24(sp)
    80003fa8:	6442                	ld	s0,16(sp)
    80003faa:	64a2                	ld	s1,8(sp)
    80003fac:	6902                	ld	s2,0(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fb2:	40bc                	lw	a5,64(s1)
    80003fb4:	dff1                	beqz	a5,80003f90 <iput+0x26>
    80003fb6:	04a49783          	lh	a5,74(s1)
    80003fba:	fbf9                	bnez	a5,80003f90 <iput+0x26>
    acquiresleep(&ip->lock);
    80003fbc:	01048913          	addi	s2,s1,16
    80003fc0:	854a                	mv	a0,s2
    80003fc2:	00001097          	auipc	ra,0x1
    80003fc6:	ab8080e7          	jalr	-1352(ra) # 80004a7a <acquiresleep>
    release(&itable.lock);
    80003fca:	0001d517          	auipc	a0,0x1d
    80003fce:	47650513          	addi	a0,a0,1142 # 80021440 <itable>
    80003fd2:	ffffd097          	auipc	ra,0xffffd
    80003fd6:	cc6080e7          	jalr	-826(ra) # 80000c98 <release>
    itrunc(ip);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	00000097          	auipc	ra,0x0
    80003fe0:	ee2080e7          	jalr	-286(ra) # 80003ebe <itrunc>
    ip->type = 0;
    80003fe4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	cfc080e7          	jalr	-772(ra) # 80003ce6 <iupdate>
    ip->valid = 0;
    80003ff2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	00001097          	auipc	ra,0x1
    80003ffc:	ad8080e7          	jalr	-1320(ra) # 80004ad0 <releasesleep>
    acquire(&itable.lock);
    80004000:	0001d517          	auipc	a0,0x1d
    80004004:	44050513          	addi	a0,a0,1088 # 80021440 <itable>
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	bdc080e7          	jalr	-1060(ra) # 80000be4 <acquire>
    80004010:	b741                	j	80003f90 <iput+0x26>

0000000080004012 <iunlockput>:
{
    80004012:	1101                	addi	sp,sp,-32
    80004014:	ec06                	sd	ra,24(sp)
    80004016:	e822                	sd	s0,16(sp)
    80004018:	e426                	sd	s1,8(sp)
    8000401a:	1000                	addi	s0,sp,32
    8000401c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	e54080e7          	jalr	-428(ra) # 80003e72 <iunlock>
  iput(ip);
    80004026:	8526                	mv	a0,s1
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	f42080e7          	jalr	-190(ra) # 80003f6a <iput>
}
    80004030:	60e2                	ld	ra,24(sp)
    80004032:	6442                	ld	s0,16(sp)
    80004034:	64a2                	ld	s1,8(sp)
    80004036:	6105                	addi	sp,sp,32
    80004038:	8082                	ret

000000008000403a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000403a:	1141                	addi	sp,sp,-16
    8000403c:	e422                	sd	s0,8(sp)
    8000403e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004040:	411c                	lw	a5,0(a0)
    80004042:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004044:	415c                	lw	a5,4(a0)
    80004046:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004048:	04451783          	lh	a5,68(a0)
    8000404c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004050:	04a51783          	lh	a5,74(a0)
    80004054:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004058:	04c56783          	lwu	a5,76(a0)
    8000405c:	e99c                	sd	a5,16(a1)
}
    8000405e:	6422                	ld	s0,8(sp)
    80004060:	0141                	addi	sp,sp,16
    80004062:	8082                	ret

0000000080004064 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004064:	457c                	lw	a5,76(a0)
    80004066:	0ed7e963          	bltu	a5,a3,80004158 <readi+0xf4>
{
    8000406a:	7159                	addi	sp,sp,-112
    8000406c:	f486                	sd	ra,104(sp)
    8000406e:	f0a2                	sd	s0,96(sp)
    80004070:	eca6                	sd	s1,88(sp)
    80004072:	e8ca                	sd	s2,80(sp)
    80004074:	e4ce                	sd	s3,72(sp)
    80004076:	e0d2                	sd	s4,64(sp)
    80004078:	fc56                	sd	s5,56(sp)
    8000407a:	f85a                	sd	s6,48(sp)
    8000407c:	f45e                	sd	s7,40(sp)
    8000407e:	f062                	sd	s8,32(sp)
    80004080:	ec66                	sd	s9,24(sp)
    80004082:	e86a                	sd	s10,16(sp)
    80004084:	e46e                	sd	s11,8(sp)
    80004086:	1880                	addi	s0,sp,112
    80004088:	8baa                	mv	s7,a0
    8000408a:	8c2e                	mv	s8,a1
    8000408c:	8ab2                	mv	s5,a2
    8000408e:	84b6                	mv	s1,a3
    80004090:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004092:	9f35                	addw	a4,a4,a3
    return 0;
    80004094:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004096:	0ad76063          	bltu	a4,a3,80004136 <readi+0xd2>
  if(off + n > ip->size)
    8000409a:	00e7f463          	bgeu	a5,a4,800040a2 <readi+0x3e>
    n = ip->size - off;
    8000409e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040a2:	0a0b0963          	beqz	s6,80004154 <readi+0xf0>
    800040a6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040a8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040ac:	5cfd                	li	s9,-1
    800040ae:	a82d                	j	800040e8 <readi+0x84>
    800040b0:	020a1d93          	slli	s11,s4,0x20
    800040b4:	020ddd93          	srli	s11,s11,0x20
    800040b8:	05890613          	addi	a2,s2,88
    800040bc:	86ee                	mv	a3,s11
    800040be:	963a                	add	a2,a2,a4
    800040c0:	85d6                	mv	a1,s5
    800040c2:	8562                	mv	a0,s8
    800040c4:	ffffe097          	auipc	ra,0xffffe
    800040c8:	2e2080e7          	jalr	738(ra) # 800023a6 <either_copyout>
    800040cc:	05950d63          	beq	a0,s9,80004126 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040d0:	854a                	mv	a0,s2
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	60c080e7          	jalr	1548(ra) # 800036de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040da:	013a09bb          	addw	s3,s4,s3
    800040de:	009a04bb          	addw	s1,s4,s1
    800040e2:	9aee                	add	s5,s5,s11
    800040e4:	0569f763          	bgeu	s3,s6,80004132 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040e8:	000ba903          	lw	s2,0(s7)
    800040ec:	00a4d59b          	srliw	a1,s1,0xa
    800040f0:	855e                	mv	a0,s7
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	8b0080e7          	jalr	-1872(ra) # 800039a2 <bmap>
    800040fa:	0005059b          	sext.w	a1,a0
    800040fe:	854a                	mv	a0,s2
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	4ae080e7          	jalr	1198(ra) # 800035ae <bread>
    80004108:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000410a:	3ff4f713          	andi	a4,s1,1023
    8000410e:	40ed07bb          	subw	a5,s10,a4
    80004112:	413b06bb          	subw	a3,s6,s3
    80004116:	8a3e                	mv	s4,a5
    80004118:	2781                	sext.w	a5,a5
    8000411a:	0006861b          	sext.w	a2,a3
    8000411e:	f8f679e3          	bgeu	a2,a5,800040b0 <readi+0x4c>
    80004122:	8a36                	mv	s4,a3
    80004124:	b771                	j	800040b0 <readi+0x4c>
      brelse(bp);
    80004126:	854a                	mv	a0,s2
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	5b6080e7          	jalr	1462(ra) # 800036de <brelse>
      tot = -1;
    80004130:	59fd                	li	s3,-1
  }
  return tot;
    80004132:	0009851b          	sext.w	a0,s3
}
    80004136:	70a6                	ld	ra,104(sp)
    80004138:	7406                	ld	s0,96(sp)
    8000413a:	64e6                	ld	s1,88(sp)
    8000413c:	6946                	ld	s2,80(sp)
    8000413e:	69a6                	ld	s3,72(sp)
    80004140:	6a06                	ld	s4,64(sp)
    80004142:	7ae2                	ld	s5,56(sp)
    80004144:	7b42                	ld	s6,48(sp)
    80004146:	7ba2                	ld	s7,40(sp)
    80004148:	7c02                	ld	s8,32(sp)
    8000414a:	6ce2                	ld	s9,24(sp)
    8000414c:	6d42                	ld	s10,16(sp)
    8000414e:	6da2                	ld	s11,8(sp)
    80004150:	6165                	addi	sp,sp,112
    80004152:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004154:	89da                	mv	s3,s6
    80004156:	bff1                	j	80004132 <readi+0xce>
    return 0;
    80004158:	4501                	li	a0,0
}
    8000415a:	8082                	ret

000000008000415c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000415c:	457c                	lw	a5,76(a0)
    8000415e:	10d7e863          	bltu	a5,a3,8000426e <writei+0x112>
{
    80004162:	7159                	addi	sp,sp,-112
    80004164:	f486                	sd	ra,104(sp)
    80004166:	f0a2                	sd	s0,96(sp)
    80004168:	eca6                	sd	s1,88(sp)
    8000416a:	e8ca                	sd	s2,80(sp)
    8000416c:	e4ce                	sd	s3,72(sp)
    8000416e:	e0d2                	sd	s4,64(sp)
    80004170:	fc56                	sd	s5,56(sp)
    80004172:	f85a                	sd	s6,48(sp)
    80004174:	f45e                	sd	s7,40(sp)
    80004176:	f062                	sd	s8,32(sp)
    80004178:	ec66                	sd	s9,24(sp)
    8000417a:	e86a                	sd	s10,16(sp)
    8000417c:	e46e                	sd	s11,8(sp)
    8000417e:	1880                	addi	s0,sp,112
    80004180:	8b2a                	mv	s6,a0
    80004182:	8c2e                	mv	s8,a1
    80004184:	8ab2                	mv	s5,a2
    80004186:	8936                	mv	s2,a3
    80004188:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000418a:	00e687bb          	addw	a5,a3,a4
    8000418e:	0ed7e263          	bltu	a5,a3,80004272 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004192:	00043737          	lui	a4,0x43
    80004196:	0ef76063          	bltu	a4,a5,80004276 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000419a:	0c0b8863          	beqz	s7,8000426a <writei+0x10e>
    8000419e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041a4:	5cfd                	li	s9,-1
    800041a6:	a091                	j	800041ea <writei+0x8e>
    800041a8:	02099d93          	slli	s11,s3,0x20
    800041ac:	020ddd93          	srli	s11,s11,0x20
    800041b0:	05848513          	addi	a0,s1,88
    800041b4:	86ee                	mv	a3,s11
    800041b6:	8656                	mv	a2,s5
    800041b8:	85e2                	mv	a1,s8
    800041ba:	953a                	add	a0,a0,a4
    800041bc:	ffffe097          	auipc	ra,0xffffe
    800041c0:	240080e7          	jalr	576(ra) # 800023fc <either_copyin>
    800041c4:	07950263          	beq	a0,s9,80004228 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041c8:	8526                	mv	a0,s1
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	790080e7          	jalr	1936(ra) # 8000495a <log_write>
    brelse(bp);
    800041d2:	8526                	mv	a0,s1
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	50a080e7          	jalr	1290(ra) # 800036de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041dc:	01498a3b          	addw	s4,s3,s4
    800041e0:	0129893b          	addw	s2,s3,s2
    800041e4:	9aee                	add	s5,s5,s11
    800041e6:	057a7663          	bgeu	s4,s7,80004232 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041ea:	000b2483          	lw	s1,0(s6)
    800041ee:	00a9559b          	srliw	a1,s2,0xa
    800041f2:	855a                	mv	a0,s6
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	7ae080e7          	jalr	1966(ra) # 800039a2 <bmap>
    800041fc:	0005059b          	sext.w	a1,a0
    80004200:	8526                	mv	a0,s1
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	3ac080e7          	jalr	940(ra) # 800035ae <bread>
    8000420a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000420c:	3ff97713          	andi	a4,s2,1023
    80004210:	40ed07bb          	subw	a5,s10,a4
    80004214:	414b86bb          	subw	a3,s7,s4
    80004218:	89be                	mv	s3,a5
    8000421a:	2781                	sext.w	a5,a5
    8000421c:	0006861b          	sext.w	a2,a3
    80004220:	f8f674e3          	bgeu	a2,a5,800041a8 <writei+0x4c>
    80004224:	89b6                	mv	s3,a3
    80004226:	b749                	j	800041a8 <writei+0x4c>
      brelse(bp);
    80004228:	8526                	mv	a0,s1
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	4b4080e7          	jalr	1204(ra) # 800036de <brelse>
  }

  if(off > ip->size)
    80004232:	04cb2783          	lw	a5,76(s6)
    80004236:	0127f463          	bgeu	a5,s2,8000423e <writei+0xe2>
    ip->size = off;
    8000423a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000423e:	855a                	mv	a0,s6
    80004240:	00000097          	auipc	ra,0x0
    80004244:	aa6080e7          	jalr	-1370(ra) # 80003ce6 <iupdate>

  return tot;
    80004248:	000a051b          	sext.w	a0,s4
}
    8000424c:	70a6                	ld	ra,104(sp)
    8000424e:	7406                	ld	s0,96(sp)
    80004250:	64e6                	ld	s1,88(sp)
    80004252:	6946                	ld	s2,80(sp)
    80004254:	69a6                	ld	s3,72(sp)
    80004256:	6a06                	ld	s4,64(sp)
    80004258:	7ae2                	ld	s5,56(sp)
    8000425a:	7b42                	ld	s6,48(sp)
    8000425c:	7ba2                	ld	s7,40(sp)
    8000425e:	7c02                	ld	s8,32(sp)
    80004260:	6ce2                	ld	s9,24(sp)
    80004262:	6d42                	ld	s10,16(sp)
    80004264:	6da2                	ld	s11,8(sp)
    80004266:	6165                	addi	sp,sp,112
    80004268:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000426a:	8a5e                	mv	s4,s7
    8000426c:	bfc9                	j	8000423e <writei+0xe2>
    return -1;
    8000426e:	557d                	li	a0,-1
}
    80004270:	8082                	ret
    return -1;
    80004272:	557d                	li	a0,-1
    80004274:	bfe1                	j	8000424c <writei+0xf0>
    return -1;
    80004276:	557d                	li	a0,-1
    80004278:	bfd1                	j	8000424c <writei+0xf0>

000000008000427a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000427a:	1141                	addi	sp,sp,-16
    8000427c:	e406                	sd	ra,8(sp)
    8000427e:	e022                	sd	s0,0(sp)
    80004280:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004282:	4639                	li	a2,14
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	b34080e7          	jalr	-1228(ra) # 80000db8 <strncmp>
}
    8000428c:	60a2                	ld	ra,8(sp)
    8000428e:	6402                	ld	s0,0(sp)
    80004290:	0141                	addi	sp,sp,16
    80004292:	8082                	ret

0000000080004294 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004294:	7139                	addi	sp,sp,-64
    80004296:	fc06                	sd	ra,56(sp)
    80004298:	f822                	sd	s0,48(sp)
    8000429a:	f426                	sd	s1,40(sp)
    8000429c:	f04a                	sd	s2,32(sp)
    8000429e:	ec4e                	sd	s3,24(sp)
    800042a0:	e852                	sd	s4,16(sp)
    800042a2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042a4:	04451703          	lh	a4,68(a0)
    800042a8:	4785                	li	a5,1
    800042aa:	00f71a63          	bne	a4,a5,800042be <dirlookup+0x2a>
    800042ae:	892a                	mv	s2,a0
    800042b0:	89ae                	mv	s3,a1
    800042b2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b4:	457c                	lw	a5,76(a0)
    800042b6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042b8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ba:	e79d                	bnez	a5,800042e8 <dirlookup+0x54>
    800042bc:	a8a5                	j	80004334 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042be:	00004517          	auipc	a0,0x4
    800042c2:	43250513          	addi	a0,a0,1074 # 800086f0 <syscalls+0x1b0>
    800042c6:	ffffc097          	auipc	ra,0xffffc
    800042ca:	278080e7          	jalr	632(ra) # 8000053e <panic>
      panic("dirlookup read");
    800042ce:	00004517          	auipc	a0,0x4
    800042d2:	43a50513          	addi	a0,a0,1082 # 80008708 <syscalls+0x1c8>
    800042d6:	ffffc097          	auipc	ra,0xffffc
    800042da:	268080e7          	jalr	616(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042de:	24c1                	addiw	s1,s1,16
    800042e0:	04c92783          	lw	a5,76(s2)
    800042e4:	04f4f763          	bgeu	s1,a5,80004332 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042e8:	4741                	li	a4,16
    800042ea:	86a6                	mv	a3,s1
    800042ec:	fc040613          	addi	a2,s0,-64
    800042f0:	4581                	li	a1,0
    800042f2:	854a                	mv	a0,s2
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	d70080e7          	jalr	-656(ra) # 80004064 <readi>
    800042fc:	47c1                	li	a5,16
    800042fe:	fcf518e3          	bne	a0,a5,800042ce <dirlookup+0x3a>
    if(de.inum == 0)
    80004302:	fc045783          	lhu	a5,-64(s0)
    80004306:	dfe1                	beqz	a5,800042de <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004308:	fc240593          	addi	a1,s0,-62
    8000430c:	854e                	mv	a0,s3
    8000430e:	00000097          	auipc	ra,0x0
    80004312:	f6c080e7          	jalr	-148(ra) # 8000427a <namecmp>
    80004316:	f561                	bnez	a0,800042de <dirlookup+0x4a>
      if(poff)
    80004318:	000a0463          	beqz	s4,80004320 <dirlookup+0x8c>
        *poff = off;
    8000431c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004320:	fc045583          	lhu	a1,-64(s0)
    80004324:	00092503          	lw	a0,0(s2)
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	754080e7          	jalr	1876(ra) # 80003a7c <iget>
    80004330:	a011                	j	80004334 <dirlookup+0xa0>
  return 0;
    80004332:	4501                	li	a0,0
}
    80004334:	70e2                	ld	ra,56(sp)
    80004336:	7442                	ld	s0,48(sp)
    80004338:	74a2                	ld	s1,40(sp)
    8000433a:	7902                	ld	s2,32(sp)
    8000433c:	69e2                	ld	s3,24(sp)
    8000433e:	6a42                	ld	s4,16(sp)
    80004340:	6121                	addi	sp,sp,64
    80004342:	8082                	ret

0000000080004344 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004344:	711d                	addi	sp,sp,-96
    80004346:	ec86                	sd	ra,88(sp)
    80004348:	e8a2                	sd	s0,80(sp)
    8000434a:	e4a6                	sd	s1,72(sp)
    8000434c:	e0ca                	sd	s2,64(sp)
    8000434e:	fc4e                	sd	s3,56(sp)
    80004350:	f852                	sd	s4,48(sp)
    80004352:	f456                	sd	s5,40(sp)
    80004354:	f05a                	sd	s6,32(sp)
    80004356:	ec5e                	sd	s7,24(sp)
    80004358:	e862                	sd	s8,16(sp)
    8000435a:	e466                	sd	s9,8(sp)
    8000435c:	1080                	addi	s0,sp,96
    8000435e:	84aa                	mv	s1,a0
    80004360:	8b2e                	mv	s6,a1
    80004362:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004364:	00054703          	lbu	a4,0(a0)
    80004368:	02f00793          	li	a5,47
    8000436c:	02f70363          	beq	a4,a5,80004392 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	640080e7          	jalr	1600(ra) # 800019b0 <myproc>
    80004378:	15053503          	ld	a0,336(a0)
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	9f6080e7          	jalr	-1546(ra) # 80003d72 <idup>
    80004384:	89aa                	mv	s3,a0
  while(*path == '/')
    80004386:	02f00913          	li	s2,47
  len = path - s;
    8000438a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000438c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000438e:	4c05                	li	s8,1
    80004390:	a865                	j	80004448 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004392:	4585                	li	a1,1
    80004394:	4505                	li	a0,1
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	6e6080e7          	jalr	1766(ra) # 80003a7c <iget>
    8000439e:	89aa                	mv	s3,a0
    800043a0:	b7dd                	j	80004386 <namex+0x42>
      iunlockput(ip);
    800043a2:	854e                	mv	a0,s3
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	c6e080e7          	jalr	-914(ra) # 80004012 <iunlockput>
      return 0;
    800043ac:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043ae:	854e                	mv	a0,s3
    800043b0:	60e6                	ld	ra,88(sp)
    800043b2:	6446                	ld	s0,80(sp)
    800043b4:	64a6                	ld	s1,72(sp)
    800043b6:	6906                	ld	s2,64(sp)
    800043b8:	79e2                	ld	s3,56(sp)
    800043ba:	7a42                	ld	s4,48(sp)
    800043bc:	7aa2                	ld	s5,40(sp)
    800043be:	7b02                	ld	s6,32(sp)
    800043c0:	6be2                	ld	s7,24(sp)
    800043c2:	6c42                	ld	s8,16(sp)
    800043c4:	6ca2                	ld	s9,8(sp)
    800043c6:	6125                	addi	sp,sp,96
    800043c8:	8082                	ret
      iunlock(ip);
    800043ca:	854e                	mv	a0,s3
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	aa6080e7          	jalr	-1370(ra) # 80003e72 <iunlock>
      return ip;
    800043d4:	bfe9                	j	800043ae <namex+0x6a>
      iunlockput(ip);
    800043d6:	854e                	mv	a0,s3
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	c3a080e7          	jalr	-966(ra) # 80004012 <iunlockput>
      return 0;
    800043e0:	89d2                	mv	s3,s4
    800043e2:	b7f1                	j	800043ae <namex+0x6a>
  len = path - s;
    800043e4:	40b48633          	sub	a2,s1,a1
    800043e8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800043ec:	094cd463          	bge	s9,s4,80004474 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800043f0:	4639                	li	a2,14
    800043f2:	8556                	mv	a0,s5
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	94c080e7          	jalr	-1716(ra) # 80000d40 <memmove>
  while(*path == '/')
    800043fc:	0004c783          	lbu	a5,0(s1)
    80004400:	01279763          	bne	a5,s2,8000440e <namex+0xca>
    path++;
    80004404:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004406:	0004c783          	lbu	a5,0(s1)
    8000440a:	ff278de3          	beq	a5,s2,80004404 <namex+0xc0>
    ilock(ip);
    8000440e:	854e                	mv	a0,s3
    80004410:	00000097          	auipc	ra,0x0
    80004414:	9a0080e7          	jalr	-1632(ra) # 80003db0 <ilock>
    if(ip->type != T_DIR){
    80004418:	04499783          	lh	a5,68(s3)
    8000441c:	f98793e3          	bne	a5,s8,800043a2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004420:	000b0563          	beqz	s6,8000442a <namex+0xe6>
    80004424:	0004c783          	lbu	a5,0(s1)
    80004428:	d3cd                	beqz	a5,800043ca <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000442a:	865e                	mv	a2,s7
    8000442c:	85d6                	mv	a1,s5
    8000442e:	854e                	mv	a0,s3
    80004430:	00000097          	auipc	ra,0x0
    80004434:	e64080e7          	jalr	-412(ra) # 80004294 <dirlookup>
    80004438:	8a2a                	mv	s4,a0
    8000443a:	dd51                	beqz	a0,800043d6 <namex+0x92>
    iunlockput(ip);
    8000443c:	854e                	mv	a0,s3
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	bd4080e7          	jalr	-1068(ra) # 80004012 <iunlockput>
    ip = next;
    80004446:	89d2                	mv	s3,s4
  while(*path == '/')
    80004448:	0004c783          	lbu	a5,0(s1)
    8000444c:	05279763          	bne	a5,s2,8000449a <namex+0x156>
    path++;
    80004450:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004452:	0004c783          	lbu	a5,0(s1)
    80004456:	ff278de3          	beq	a5,s2,80004450 <namex+0x10c>
  if(*path == 0)
    8000445a:	c79d                	beqz	a5,80004488 <namex+0x144>
    path++;
    8000445c:	85a6                	mv	a1,s1
  len = path - s;
    8000445e:	8a5e                	mv	s4,s7
    80004460:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004462:	01278963          	beq	a5,s2,80004474 <namex+0x130>
    80004466:	dfbd                	beqz	a5,800043e4 <namex+0xa0>
    path++;
    80004468:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000446a:	0004c783          	lbu	a5,0(s1)
    8000446e:	ff279ce3          	bne	a5,s2,80004466 <namex+0x122>
    80004472:	bf8d                	j	800043e4 <namex+0xa0>
    memmove(name, s, len);
    80004474:	2601                	sext.w	a2,a2
    80004476:	8556                	mv	a0,s5
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	8c8080e7          	jalr	-1848(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004480:	9a56                	add	s4,s4,s5
    80004482:	000a0023          	sb	zero,0(s4)
    80004486:	bf9d                	j	800043fc <namex+0xb8>
  if(nameiparent){
    80004488:	f20b03e3          	beqz	s6,800043ae <namex+0x6a>
    iput(ip);
    8000448c:	854e                	mv	a0,s3
    8000448e:	00000097          	auipc	ra,0x0
    80004492:	adc080e7          	jalr	-1316(ra) # 80003f6a <iput>
    return 0;
    80004496:	4981                	li	s3,0
    80004498:	bf19                	j	800043ae <namex+0x6a>
  if(*path == 0)
    8000449a:	d7fd                	beqz	a5,80004488 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000449c:	0004c783          	lbu	a5,0(s1)
    800044a0:	85a6                	mv	a1,s1
    800044a2:	b7d1                	j	80004466 <namex+0x122>

00000000800044a4 <dirlink>:
{
    800044a4:	7139                	addi	sp,sp,-64
    800044a6:	fc06                	sd	ra,56(sp)
    800044a8:	f822                	sd	s0,48(sp)
    800044aa:	f426                	sd	s1,40(sp)
    800044ac:	f04a                	sd	s2,32(sp)
    800044ae:	ec4e                	sd	s3,24(sp)
    800044b0:	e852                	sd	s4,16(sp)
    800044b2:	0080                	addi	s0,sp,64
    800044b4:	892a                	mv	s2,a0
    800044b6:	8a2e                	mv	s4,a1
    800044b8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044ba:	4601                	li	a2,0
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	dd8080e7          	jalr	-552(ra) # 80004294 <dirlookup>
    800044c4:	e93d                	bnez	a0,8000453a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044c6:	04c92483          	lw	s1,76(s2)
    800044ca:	c49d                	beqz	s1,800044f8 <dirlink+0x54>
    800044cc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044ce:	4741                	li	a4,16
    800044d0:	86a6                	mv	a3,s1
    800044d2:	fc040613          	addi	a2,s0,-64
    800044d6:	4581                	li	a1,0
    800044d8:	854a                	mv	a0,s2
    800044da:	00000097          	auipc	ra,0x0
    800044de:	b8a080e7          	jalr	-1142(ra) # 80004064 <readi>
    800044e2:	47c1                	li	a5,16
    800044e4:	06f51163          	bne	a0,a5,80004546 <dirlink+0xa2>
    if(de.inum == 0)
    800044e8:	fc045783          	lhu	a5,-64(s0)
    800044ec:	c791                	beqz	a5,800044f8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ee:	24c1                	addiw	s1,s1,16
    800044f0:	04c92783          	lw	a5,76(s2)
    800044f4:	fcf4ede3          	bltu	s1,a5,800044ce <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044f8:	4639                	li	a2,14
    800044fa:	85d2                	mv	a1,s4
    800044fc:	fc240513          	addi	a0,s0,-62
    80004500:	ffffd097          	auipc	ra,0xffffd
    80004504:	8f4080e7          	jalr	-1804(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004508:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000450c:	4741                	li	a4,16
    8000450e:	86a6                	mv	a3,s1
    80004510:	fc040613          	addi	a2,s0,-64
    80004514:	4581                	li	a1,0
    80004516:	854a                	mv	a0,s2
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	c44080e7          	jalr	-956(ra) # 8000415c <writei>
    80004520:	872a                	mv	a4,a0
    80004522:	47c1                	li	a5,16
  return 0;
    80004524:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004526:	02f71863          	bne	a4,a5,80004556 <dirlink+0xb2>
}
    8000452a:	70e2                	ld	ra,56(sp)
    8000452c:	7442                	ld	s0,48(sp)
    8000452e:	74a2                	ld	s1,40(sp)
    80004530:	7902                	ld	s2,32(sp)
    80004532:	69e2                	ld	s3,24(sp)
    80004534:	6a42                	ld	s4,16(sp)
    80004536:	6121                	addi	sp,sp,64
    80004538:	8082                	ret
    iput(ip);
    8000453a:	00000097          	auipc	ra,0x0
    8000453e:	a30080e7          	jalr	-1488(ra) # 80003f6a <iput>
    return -1;
    80004542:	557d                	li	a0,-1
    80004544:	b7dd                	j	8000452a <dirlink+0x86>
      panic("dirlink read");
    80004546:	00004517          	auipc	a0,0x4
    8000454a:	1d250513          	addi	a0,a0,466 # 80008718 <syscalls+0x1d8>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	ff0080e7          	jalr	-16(ra) # 8000053e <panic>
    panic("dirlink");
    80004556:	00004517          	auipc	a0,0x4
    8000455a:	2ca50513          	addi	a0,a0,714 # 80008820 <syscalls+0x2e0>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	fe0080e7          	jalr	-32(ra) # 8000053e <panic>

0000000080004566 <namei>:

struct inode*
namei(char *path)
{
    80004566:	1101                	addi	sp,sp,-32
    80004568:	ec06                	sd	ra,24(sp)
    8000456a:	e822                	sd	s0,16(sp)
    8000456c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000456e:	fe040613          	addi	a2,s0,-32
    80004572:	4581                	li	a1,0
    80004574:	00000097          	auipc	ra,0x0
    80004578:	dd0080e7          	jalr	-560(ra) # 80004344 <namex>
}
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	6105                	addi	sp,sp,32
    80004582:	8082                	ret

0000000080004584 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004584:	1141                	addi	sp,sp,-16
    80004586:	e406                	sd	ra,8(sp)
    80004588:	e022                	sd	s0,0(sp)
    8000458a:	0800                	addi	s0,sp,16
    8000458c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000458e:	4585                	li	a1,1
    80004590:	00000097          	auipc	ra,0x0
    80004594:	db4080e7          	jalr	-588(ra) # 80004344 <namex>
}
    80004598:	60a2                	ld	ra,8(sp)
    8000459a:	6402                	ld	s0,0(sp)
    8000459c:	0141                	addi	sp,sp,16
    8000459e:	8082                	ret

00000000800045a0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	e426                	sd	s1,8(sp)
    800045a8:	e04a                	sd	s2,0(sp)
    800045aa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045ac:	0001f917          	auipc	s2,0x1f
    800045b0:	93c90913          	addi	s2,s2,-1732 # 80022ee8 <log>
    800045b4:	01892583          	lw	a1,24(s2)
    800045b8:	02892503          	lw	a0,40(s2)
    800045bc:	fffff097          	auipc	ra,0xfffff
    800045c0:	ff2080e7          	jalr	-14(ra) # 800035ae <bread>
    800045c4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045c6:	02c92683          	lw	a3,44(s2)
    800045ca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045cc:	02d05763          	blez	a3,800045fa <write_head+0x5a>
    800045d0:	0001f797          	auipc	a5,0x1f
    800045d4:	94878793          	addi	a5,a5,-1720 # 80022f18 <log+0x30>
    800045d8:	05c50713          	addi	a4,a0,92
    800045dc:	36fd                	addiw	a3,a3,-1
    800045de:	1682                	slli	a3,a3,0x20
    800045e0:	9281                	srli	a3,a3,0x20
    800045e2:	068a                	slli	a3,a3,0x2
    800045e4:	0001f617          	auipc	a2,0x1f
    800045e8:	93860613          	addi	a2,a2,-1736 # 80022f1c <log+0x34>
    800045ec:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800045ee:	4390                	lw	a2,0(a5)
    800045f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045f2:	0791                	addi	a5,a5,4
    800045f4:	0711                	addi	a4,a4,4
    800045f6:	fed79ce3          	bne	a5,a3,800045ee <write_head+0x4e>
  }
  bwrite(buf);
    800045fa:	8526                	mv	a0,s1
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	0a4080e7          	jalr	164(ra) # 800036a0 <bwrite>
  brelse(buf);
    80004604:	8526                	mv	a0,s1
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	0d8080e7          	jalr	216(ra) # 800036de <brelse>
}
    8000460e:	60e2                	ld	ra,24(sp)
    80004610:	6442                	ld	s0,16(sp)
    80004612:	64a2                	ld	s1,8(sp)
    80004614:	6902                	ld	s2,0(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret

000000008000461a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000461a:	0001f797          	auipc	a5,0x1f
    8000461e:	8fa7a783          	lw	a5,-1798(a5) # 80022f14 <log+0x2c>
    80004622:	0af05d63          	blez	a5,800046dc <install_trans+0xc2>
{
    80004626:	7139                	addi	sp,sp,-64
    80004628:	fc06                	sd	ra,56(sp)
    8000462a:	f822                	sd	s0,48(sp)
    8000462c:	f426                	sd	s1,40(sp)
    8000462e:	f04a                	sd	s2,32(sp)
    80004630:	ec4e                	sd	s3,24(sp)
    80004632:	e852                	sd	s4,16(sp)
    80004634:	e456                	sd	s5,8(sp)
    80004636:	e05a                	sd	s6,0(sp)
    80004638:	0080                	addi	s0,sp,64
    8000463a:	8b2a                	mv	s6,a0
    8000463c:	0001fa97          	auipc	s5,0x1f
    80004640:	8dca8a93          	addi	s5,s5,-1828 # 80022f18 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004644:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004646:	0001f997          	auipc	s3,0x1f
    8000464a:	8a298993          	addi	s3,s3,-1886 # 80022ee8 <log>
    8000464e:	a035                	j	8000467a <install_trans+0x60>
      bunpin(dbuf);
    80004650:	8526                	mv	a0,s1
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	166080e7          	jalr	358(ra) # 800037b8 <bunpin>
    brelse(lbuf);
    8000465a:	854a                	mv	a0,s2
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	082080e7          	jalr	130(ra) # 800036de <brelse>
    brelse(dbuf);
    80004664:	8526                	mv	a0,s1
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	078080e7          	jalr	120(ra) # 800036de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000466e:	2a05                	addiw	s4,s4,1
    80004670:	0a91                	addi	s5,s5,4
    80004672:	02c9a783          	lw	a5,44(s3)
    80004676:	04fa5963          	bge	s4,a5,800046c8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000467a:	0189a583          	lw	a1,24(s3)
    8000467e:	014585bb          	addw	a1,a1,s4
    80004682:	2585                	addiw	a1,a1,1
    80004684:	0289a503          	lw	a0,40(s3)
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	f26080e7          	jalr	-218(ra) # 800035ae <bread>
    80004690:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004692:	000aa583          	lw	a1,0(s5)
    80004696:	0289a503          	lw	a0,40(s3)
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	f14080e7          	jalr	-236(ra) # 800035ae <bread>
    800046a2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046a4:	40000613          	li	a2,1024
    800046a8:	05890593          	addi	a1,s2,88
    800046ac:	05850513          	addi	a0,a0,88
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	690080e7          	jalr	1680(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046b8:	8526                	mv	a0,s1
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	fe6080e7          	jalr	-26(ra) # 800036a0 <bwrite>
    if(recovering == 0)
    800046c2:	f80b1ce3          	bnez	s6,8000465a <install_trans+0x40>
    800046c6:	b769                	j	80004650 <install_trans+0x36>
}
    800046c8:	70e2                	ld	ra,56(sp)
    800046ca:	7442                	ld	s0,48(sp)
    800046cc:	74a2                	ld	s1,40(sp)
    800046ce:	7902                	ld	s2,32(sp)
    800046d0:	69e2                	ld	s3,24(sp)
    800046d2:	6a42                	ld	s4,16(sp)
    800046d4:	6aa2                	ld	s5,8(sp)
    800046d6:	6b02                	ld	s6,0(sp)
    800046d8:	6121                	addi	sp,sp,64
    800046da:	8082                	ret
    800046dc:	8082                	ret

00000000800046de <initlog>:
{
    800046de:	7179                	addi	sp,sp,-48
    800046e0:	f406                	sd	ra,40(sp)
    800046e2:	f022                	sd	s0,32(sp)
    800046e4:	ec26                	sd	s1,24(sp)
    800046e6:	e84a                	sd	s2,16(sp)
    800046e8:	e44e                	sd	s3,8(sp)
    800046ea:	1800                	addi	s0,sp,48
    800046ec:	892a                	mv	s2,a0
    800046ee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046f0:	0001e497          	auipc	s1,0x1e
    800046f4:	7f848493          	addi	s1,s1,2040 # 80022ee8 <log>
    800046f8:	00004597          	auipc	a1,0x4
    800046fc:	03058593          	addi	a1,a1,48 # 80008728 <syscalls+0x1e8>
    80004700:	8526                	mv	a0,s1
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	452080e7          	jalr	1106(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000470a:	0149a583          	lw	a1,20(s3)
    8000470e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004710:	0109a783          	lw	a5,16(s3)
    80004714:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004716:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000471a:	854a                	mv	a0,s2
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	e92080e7          	jalr	-366(ra) # 800035ae <bread>
  log.lh.n = lh->n;
    80004724:	4d3c                	lw	a5,88(a0)
    80004726:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004728:	02f05563          	blez	a5,80004752 <initlog+0x74>
    8000472c:	05c50713          	addi	a4,a0,92
    80004730:	0001e697          	auipc	a3,0x1e
    80004734:	7e868693          	addi	a3,a3,2024 # 80022f18 <log+0x30>
    80004738:	37fd                	addiw	a5,a5,-1
    8000473a:	1782                	slli	a5,a5,0x20
    8000473c:	9381                	srli	a5,a5,0x20
    8000473e:	078a                	slli	a5,a5,0x2
    80004740:	06050613          	addi	a2,a0,96
    80004744:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004746:	4310                	lw	a2,0(a4)
    80004748:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000474a:	0711                	addi	a4,a4,4
    8000474c:	0691                	addi	a3,a3,4
    8000474e:	fef71ce3          	bne	a4,a5,80004746 <initlog+0x68>
  brelse(buf);
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	f8c080e7          	jalr	-116(ra) # 800036de <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000475a:	4505                	li	a0,1
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	ebe080e7          	jalr	-322(ra) # 8000461a <install_trans>
  log.lh.n = 0;
    80004764:	0001e797          	auipc	a5,0x1e
    80004768:	7a07a823          	sw	zero,1968(a5) # 80022f14 <log+0x2c>
  write_head(); // clear the log
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	e34080e7          	jalr	-460(ra) # 800045a0 <write_head>
}
    80004774:	70a2                	ld	ra,40(sp)
    80004776:	7402                	ld	s0,32(sp)
    80004778:	64e2                	ld	s1,24(sp)
    8000477a:	6942                	ld	s2,16(sp)
    8000477c:	69a2                	ld	s3,8(sp)
    8000477e:	6145                	addi	sp,sp,48
    80004780:	8082                	ret

0000000080004782 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004782:	1101                	addi	sp,sp,-32
    80004784:	ec06                	sd	ra,24(sp)
    80004786:	e822                	sd	s0,16(sp)
    80004788:	e426                	sd	s1,8(sp)
    8000478a:	e04a                	sd	s2,0(sp)
    8000478c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000478e:	0001e517          	auipc	a0,0x1e
    80004792:	75a50513          	addi	a0,a0,1882 # 80022ee8 <log>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	44e080e7          	jalr	1102(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000479e:	0001e497          	auipc	s1,0x1e
    800047a2:	74a48493          	addi	s1,s1,1866 # 80022ee8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047a6:	4979                	li	s2,30
    800047a8:	a039                	j	800047b6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047aa:	85a6                	mv	a1,s1
    800047ac:	8526                	mv	a0,s1
    800047ae:	ffffe097          	auipc	ra,0xffffe
    800047b2:	848080e7          	jalr	-1976(ra) # 80001ff6 <sleep>
    if(log.committing){
    800047b6:	50dc                	lw	a5,36(s1)
    800047b8:	fbed                	bnez	a5,800047aa <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047ba:	509c                	lw	a5,32(s1)
    800047bc:	0017871b          	addiw	a4,a5,1
    800047c0:	0007069b          	sext.w	a3,a4
    800047c4:	0027179b          	slliw	a5,a4,0x2
    800047c8:	9fb9                	addw	a5,a5,a4
    800047ca:	0017979b          	slliw	a5,a5,0x1
    800047ce:	54d8                	lw	a4,44(s1)
    800047d0:	9fb9                	addw	a5,a5,a4
    800047d2:	00f95963          	bge	s2,a5,800047e4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047d6:	85a6                	mv	a1,s1
    800047d8:	8526                	mv	a0,s1
    800047da:	ffffe097          	auipc	ra,0xffffe
    800047de:	81c080e7          	jalr	-2020(ra) # 80001ff6 <sleep>
    800047e2:	bfd1                	j	800047b6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047e4:	0001e517          	auipc	a0,0x1e
    800047e8:	70450513          	addi	a0,a0,1796 # 80022ee8 <log>
    800047ec:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	4aa080e7          	jalr	1194(ra) # 80000c98 <release>
      break;
    }
  }
}
    800047f6:	60e2                	ld	ra,24(sp)
    800047f8:	6442                	ld	s0,16(sp)
    800047fa:	64a2                	ld	s1,8(sp)
    800047fc:	6902                	ld	s2,0(sp)
    800047fe:	6105                	addi	sp,sp,32
    80004800:	8082                	ret

0000000080004802 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004802:	7139                	addi	sp,sp,-64
    80004804:	fc06                	sd	ra,56(sp)
    80004806:	f822                	sd	s0,48(sp)
    80004808:	f426                	sd	s1,40(sp)
    8000480a:	f04a                	sd	s2,32(sp)
    8000480c:	ec4e                	sd	s3,24(sp)
    8000480e:	e852                	sd	s4,16(sp)
    80004810:	e456                	sd	s5,8(sp)
    80004812:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004814:	0001e497          	auipc	s1,0x1e
    80004818:	6d448493          	addi	s1,s1,1748 # 80022ee8 <log>
    8000481c:	8526                	mv	a0,s1
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	3c6080e7          	jalr	966(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004826:	509c                	lw	a5,32(s1)
    80004828:	37fd                	addiw	a5,a5,-1
    8000482a:	0007891b          	sext.w	s2,a5
    8000482e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004830:	50dc                	lw	a5,36(s1)
    80004832:	efb9                	bnez	a5,80004890 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004834:	06091663          	bnez	s2,800048a0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004838:	0001e497          	auipc	s1,0x1e
    8000483c:	6b048493          	addi	s1,s1,1712 # 80022ee8 <log>
    80004840:	4785                	li	a5,1
    80004842:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004844:	8526                	mv	a0,s1
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000484e:	54dc                	lw	a5,44(s1)
    80004850:	06f04763          	bgtz	a5,800048be <end_op+0xbc>
    acquire(&log.lock);
    80004854:	0001e497          	auipc	s1,0x1e
    80004858:	69448493          	addi	s1,s1,1684 # 80022ee8 <log>
    8000485c:	8526                	mv	a0,s1
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	386080e7          	jalr	902(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004866:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000486a:	8526                	mv	a0,s1
    8000486c:	ffffe097          	auipc	ra,0xffffe
    80004870:	916080e7          	jalr	-1770(ra) # 80002182 <wakeup>
    release(&log.lock);
    80004874:	8526                	mv	a0,s1
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
}
    8000487e:	70e2                	ld	ra,56(sp)
    80004880:	7442                	ld	s0,48(sp)
    80004882:	74a2                	ld	s1,40(sp)
    80004884:	7902                	ld	s2,32(sp)
    80004886:	69e2                	ld	s3,24(sp)
    80004888:	6a42                	ld	s4,16(sp)
    8000488a:	6aa2                	ld	s5,8(sp)
    8000488c:	6121                	addi	sp,sp,64
    8000488e:	8082                	ret
    panic("log.committing");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	ea050513          	addi	a0,a0,-352 # 80008730 <syscalls+0x1f0>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	ca6080e7          	jalr	-858(ra) # 8000053e <panic>
    wakeup(&log);
    800048a0:	0001e497          	auipc	s1,0x1e
    800048a4:	64848493          	addi	s1,s1,1608 # 80022ee8 <log>
    800048a8:	8526                	mv	a0,s1
    800048aa:	ffffe097          	auipc	ra,0xffffe
    800048ae:	8d8080e7          	jalr	-1832(ra) # 80002182 <wakeup>
  release(&log.lock);
    800048b2:	8526                	mv	a0,s1
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	3e4080e7          	jalr	996(ra) # 80000c98 <release>
  if(do_commit){
    800048bc:	b7c9                	j	8000487e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048be:	0001ea97          	auipc	s5,0x1e
    800048c2:	65aa8a93          	addi	s5,s5,1626 # 80022f18 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048c6:	0001ea17          	auipc	s4,0x1e
    800048ca:	622a0a13          	addi	s4,s4,1570 # 80022ee8 <log>
    800048ce:	018a2583          	lw	a1,24(s4)
    800048d2:	012585bb          	addw	a1,a1,s2
    800048d6:	2585                	addiw	a1,a1,1
    800048d8:	028a2503          	lw	a0,40(s4)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	cd2080e7          	jalr	-814(ra) # 800035ae <bread>
    800048e4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048e6:	000aa583          	lw	a1,0(s5)
    800048ea:	028a2503          	lw	a0,40(s4)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	cc0080e7          	jalr	-832(ra) # 800035ae <bread>
    800048f6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048f8:	40000613          	li	a2,1024
    800048fc:	05850593          	addi	a1,a0,88
    80004900:	05848513          	addi	a0,s1,88
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	43c080e7          	jalr	1084(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000490c:	8526                	mv	a0,s1
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	d92080e7          	jalr	-622(ra) # 800036a0 <bwrite>
    brelse(from);
    80004916:	854e                	mv	a0,s3
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	dc6080e7          	jalr	-570(ra) # 800036de <brelse>
    brelse(to);
    80004920:	8526                	mv	a0,s1
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	dbc080e7          	jalr	-580(ra) # 800036de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000492a:	2905                	addiw	s2,s2,1
    8000492c:	0a91                	addi	s5,s5,4
    8000492e:	02ca2783          	lw	a5,44(s4)
    80004932:	f8f94ee3          	blt	s2,a5,800048ce <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	c6a080e7          	jalr	-918(ra) # 800045a0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000493e:	4501                	li	a0,0
    80004940:	00000097          	auipc	ra,0x0
    80004944:	cda080e7          	jalr	-806(ra) # 8000461a <install_trans>
    log.lh.n = 0;
    80004948:	0001e797          	auipc	a5,0x1e
    8000494c:	5c07a623          	sw	zero,1484(a5) # 80022f14 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004950:	00000097          	auipc	ra,0x0
    80004954:	c50080e7          	jalr	-944(ra) # 800045a0 <write_head>
    80004958:	bdf5                	j	80004854 <end_op+0x52>

000000008000495a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000495a:	1101                	addi	sp,sp,-32
    8000495c:	ec06                	sd	ra,24(sp)
    8000495e:	e822                	sd	s0,16(sp)
    80004960:	e426                	sd	s1,8(sp)
    80004962:	e04a                	sd	s2,0(sp)
    80004964:	1000                	addi	s0,sp,32
    80004966:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004968:	0001e917          	auipc	s2,0x1e
    8000496c:	58090913          	addi	s2,s2,1408 # 80022ee8 <log>
    80004970:	854a                	mv	a0,s2
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	272080e7          	jalr	626(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000497a:	02c92603          	lw	a2,44(s2)
    8000497e:	47f5                	li	a5,29
    80004980:	06c7c563          	blt	a5,a2,800049ea <log_write+0x90>
    80004984:	0001e797          	auipc	a5,0x1e
    80004988:	5807a783          	lw	a5,1408(a5) # 80022f04 <log+0x1c>
    8000498c:	37fd                	addiw	a5,a5,-1
    8000498e:	04f65e63          	bge	a2,a5,800049ea <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004992:	0001e797          	auipc	a5,0x1e
    80004996:	5767a783          	lw	a5,1398(a5) # 80022f08 <log+0x20>
    8000499a:	06f05063          	blez	a5,800049fa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000499e:	4781                	li	a5,0
    800049a0:	06c05563          	blez	a2,80004a0a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049a4:	44cc                	lw	a1,12(s1)
    800049a6:	0001e717          	auipc	a4,0x1e
    800049aa:	57270713          	addi	a4,a4,1394 # 80022f18 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049ae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049b0:	4314                	lw	a3,0(a4)
    800049b2:	04b68c63          	beq	a3,a1,80004a0a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049b6:	2785                	addiw	a5,a5,1
    800049b8:	0711                	addi	a4,a4,4
    800049ba:	fef61be3          	bne	a2,a5,800049b0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049be:	0621                	addi	a2,a2,8
    800049c0:	060a                	slli	a2,a2,0x2
    800049c2:	0001e797          	auipc	a5,0x1e
    800049c6:	52678793          	addi	a5,a5,1318 # 80022ee8 <log>
    800049ca:	963e                	add	a2,a2,a5
    800049cc:	44dc                	lw	a5,12(s1)
    800049ce:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049d0:	8526                	mv	a0,s1
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	daa080e7          	jalr	-598(ra) # 8000377c <bpin>
    log.lh.n++;
    800049da:	0001e717          	auipc	a4,0x1e
    800049de:	50e70713          	addi	a4,a4,1294 # 80022ee8 <log>
    800049e2:	575c                	lw	a5,44(a4)
    800049e4:	2785                	addiw	a5,a5,1
    800049e6:	d75c                	sw	a5,44(a4)
    800049e8:	a835                	j	80004a24 <log_write+0xca>
    panic("too big a transaction");
    800049ea:	00004517          	auipc	a0,0x4
    800049ee:	d5650513          	addi	a0,a0,-682 # 80008740 <syscalls+0x200>
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	b4c080e7          	jalr	-1204(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800049fa:	00004517          	auipc	a0,0x4
    800049fe:	d5e50513          	addi	a0,a0,-674 # 80008758 <syscalls+0x218>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	b3c080e7          	jalr	-1220(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a0a:	00878713          	addi	a4,a5,8
    80004a0e:	00271693          	slli	a3,a4,0x2
    80004a12:	0001e717          	auipc	a4,0x1e
    80004a16:	4d670713          	addi	a4,a4,1238 # 80022ee8 <log>
    80004a1a:	9736                	add	a4,a4,a3
    80004a1c:	44d4                	lw	a3,12(s1)
    80004a1e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a20:	faf608e3          	beq	a2,a5,800049d0 <log_write+0x76>
  }
  release(&log.lock);
    80004a24:	0001e517          	auipc	a0,0x1e
    80004a28:	4c450513          	addi	a0,a0,1220 # 80022ee8 <log>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	26c080e7          	jalr	620(ra) # 80000c98 <release>
}
    80004a34:	60e2                	ld	ra,24(sp)
    80004a36:	6442                	ld	s0,16(sp)
    80004a38:	64a2                	ld	s1,8(sp)
    80004a3a:	6902                	ld	s2,0(sp)
    80004a3c:	6105                	addi	sp,sp,32
    80004a3e:	8082                	ret

0000000080004a40 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a40:	1101                	addi	sp,sp,-32
    80004a42:	ec06                	sd	ra,24(sp)
    80004a44:	e822                	sd	s0,16(sp)
    80004a46:	e426                	sd	s1,8(sp)
    80004a48:	e04a                	sd	s2,0(sp)
    80004a4a:	1000                	addi	s0,sp,32
    80004a4c:	84aa                	mv	s1,a0
    80004a4e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a50:	00004597          	auipc	a1,0x4
    80004a54:	d2858593          	addi	a1,a1,-728 # 80008778 <syscalls+0x238>
    80004a58:	0521                	addi	a0,a0,8
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	0fa080e7          	jalr	250(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a62:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a66:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a6a:	0204a423          	sw	zero,40(s1)
}
    80004a6e:	60e2                	ld	ra,24(sp)
    80004a70:	6442                	ld	s0,16(sp)
    80004a72:	64a2                	ld	s1,8(sp)
    80004a74:	6902                	ld	s2,0(sp)
    80004a76:	6105                	addi	sp,sp,32
    80004a78:	8082                	ret

0000000080004a7a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a7a:	1101                	addi	sp,sp,-32
    80004a7c:	ec06                	sd	ra,24(sp)
    80004a7e:	e822                	sd	s0,16(sp)
    80004a80:	e426                	sd	s1,8(sp)
    80004a82:	e04a                	sd	s2,0(sp)
    80004a84:	1000                	addi	s0,sp,32
    80004a86:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a88:	00850913          	addi	s2,a0,8
    80004a8c:	854a                	mv	a0,s2
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	156080e7          	jalr	342(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004a96:	409c                	lw	a5,0(s1)
    80004a98:	cb89                	beqz	a5,80004aaa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a9a:	85ca                	mv	a1,s2
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	ffffd097          	auipc	ra,0xffffd
    80004aa2:	558080e7          	jalr	1368(ra) # 80001ff6 <sleep>
  while (lk->locked) {
    80004aa6:	409c                	lw	a5,0(s1)
    80004aa8:	fbed                	bnez	a5,80004a9a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004aaa:	4785                	li	a5,1
    80004aac:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	f02080e7          	jalr	-254(ra) # 800019b0 <myproc>
    80004ab6:	591c                	lw	a5,48(a0)
    80004ab8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004aba:	854a                	mv	a0,s2
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	1dc080e7          	jalr	476(ra) # 80000c98 <release>
}
    80004ac4:	60e2                	ld	ra,24(sp)
    80004ac6:	6442                	ld	s0,16(sp)
    80004ac8:	64a2                	ld	s1,8(sp)
    80004aca:	6902                	ld	s2,0(sp)
    80004acc:	6105                	addi	sp,sp,32
    80004ace:	8082                	ret

0000000080004ad0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ad0:	1101                	addi	sp,sp,-32
    80004ad2:	ec06                	sd	ra,24(sp)
    80004ad4:	e822                	sd	s0,16(sp)
    80004ad6:	e426                	sd	s1,8(sp)
    80004ad8:	e04a                	sd	s2,0(sp)
    80004ada:	1000                	addi	s0,sp,32
    80004adc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ade:	00850913          	addi	s2,a0,8
    80004ae2:	854a                	mv	a0,s2
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	100080e7          	jalr	256(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004aec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004af0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	68c080e7          	jalr	1676(ra) # 80002182 <wakeup>
  release(&lk->lk);
    80004afe:	854a                	mv	a0,s2
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
}
    80004b08:	60e2                	ld	ra,24(sp)
    80004b0a:	6442                	ld	s0,16(sp)
    80004b0c:	64a2                	ld	s1,8(sp)
    80004b0e:	6902                	ld	s2,0(sp)
    80004b10:	6105                	addi	sp,sp,32
    80004b12:	8082                	ret

0000000080004b14 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b14:	7179                	addi	sp,sp,-48
    80004b16:	f406                	sd	ra,40(sp)
    80004b18:	f022                	sd	s0,32(sp)
    80004b1a:	ec26                	sd	s1,24(sp)
    80004b1c:	e84a                	sd	s2,16(sp)
    80004b1e:	e44e                	sd	s3,8(sp)
    80004b20:	1800                	addi	s0,sp,48
    80004b22:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b24:	00850913          	addi	s2,a0,8
    80004b28:	854a                	mv	a0,s2
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	0ba080e7          	jalr	186(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b32:	409c                	lw	a5,0(s1)
    80004b34:	ef99                	bnez	a5,80004b52 <holdingsleep+0x3e>
    80004b36:	4481                	li	s1,0
  release(&lk->lk);
    80004b38:	854a                	mv	a0,s2
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	15e080e7          	jalr	350(ra) # 80000c98 <release>
  return r;
}
    80004b42:	8526                	mv	a0,s1
    80004b44:	70a2                	ld	ra,40(sp)
    80004b46:	7402                	ld	s0,32(sp)
    80004b48:	64e2                	ld	s1,24(sp)
    80004b4a:	6942                	ld	s2,16(sp)
    80004b4c:	69a2                	ld	s3,8(sp)
    80004b4e:	6145                	addi	sp,sp,48
    80004b50:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b52:	0284a983          	lw	s3,40(s1)
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	e5a080e7          	jalr	-422(ra) # 800019b0 <myproc>
    80004b5e:	5904                	lw	s1,48(a0)
    80004b60:	413484b3          	sub	s1,s1,s3
    80004b64:	0014b493          	seqz	s1,s1
    80004b68:	bfc1                	j	80004b38 <holdingsleep+0x24>

0000000080004b6a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b6a:	1141                	addi	sp,sp,-16
    80004b6c:	e406                	sd	ra,8(sp)
    80004b6e:	e022                	sd	s0,0(sp)
    80004b70:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b72:	00004597          	auipc	a1,0x4
    80004b76:	c1658593          	addi	a1,a1,-1002 # 80008788 <syscalls+0x248>
    80004b7a:	0001e517          	auipc	a0,0x1e
    80004b7e:	4b650513          	addi	a0,a0,1206 # 80023030 <ftable>
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	fd2080e7          	jalr	-46(ra) # 80000b54 <initlock>
}
    80004b8a:	60a2                	ld	ra,8(sp)
    80004b8c:	6402                	ld	s0,0(sp)
    80004b8e:	0141                	addi	sp,sp,16
    80004b90:	8082                	ret

0000000080004b92 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b92:	1101                	addi	sp,sp,-32
    80004b94:	ec06                	sd	ra,24(sp)
    80004b96:	e822                	sd	s0,16(sp)
    80004b98:	e426                	sd	s1,8(sp)
    80004b9a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b9c:	0001e517          	auipc	a0,0x1e
    80004ba0:	49450513          	addi	a0,a0,1172 # 80023030 <ftable>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	040080e7          	jalr	64(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bac:	0001e497          	auipc	s1,0x1e
    80004bb0:	49c48493          	addi	s1,s1,1180 # 80023048 <ftable+0x18>
    80004bb4:	0001f717          	auipc	a4,0x1f
    80004bb8:	43470713          	addi	a4,a4,1076 # 80023fe8 <ftable+0xfb8>
    if(f->ref == 0){
    80004bbc:	40dc                	lw	a5,4(s1)
    80004bbe:	cf99                	beqz	a5,80004bdc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bc0:	02848493          	addi	s1,s1,40
    80004bc4:	fee49ce3          	bne	s1,a4,80004bbc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bc8:	0001e517          	auipc	a0,0x1e
    80004bcc:	46850513          	addi	a0,a0,1128 # 80023030 <ftable>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0c8080e7          	jalr	200(ra) # 80000c98 <release>
  return 0;
    80004bd8:	4481                	li	s1,0
    80004bda:	a819                	j	80004bf0 <filealloc+0x5e>
      f->ref = 1;
    80004bdc:	4785                	li	a5,1
    80004bde:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004be0:	0001e517          	auipc	a0,0x1e
    80004be4:	45050513          	addi	a0,a0,1104 # 80023030 <ftable>
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	0b0080e7          	jalr	176(ra) # 80000c98 <release>
}
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	60e2                	ld	ra,24(sp)
    80004bf4:	6442                	ld	s0,16(sp)
    80004bf6:	64a2                	ld	s1,8(sp)
    80004bf8:	6105                	addi	sp,sp,32
    80004bfa:	8082                	ret

0000000080004bfc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bfc:	1101                	addi	sp,sp,-32
    80004bfe:	ec06                	sd	ra,24(sp)
    80004c00:	e822                	sd	s0,16(sp)
    80004c02:	e426                	sd	s1,8(sp)
    80004c04:	1000                	addi	s0,sp,32
    80004c06:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c08:	0001e517          	auipc	a0,0x1e
    80004c0c:	42850513          	addi	a0,a0,1064 # 80023030 <ftable>
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	fd4080e7          	jalr	-44(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c18:	40dc                	lw	a5,4(s1)
    80004c1a:	02f05263          	blez	a5,80004c3e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c1e:	2785                	addiw	a5,a5,1
    80004c20:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c22:	0001e517          	auipc	a0,0x1e
    80004c26:	40e50513          	addi	a0,a0,1038 # 80023030 <ftable>
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	06e080e7          	jalr	110(ra) # 80000c98 <release>
  return f;
}
    80004c32:	8526                	mv	a0,s1
    80004c34:	60e2                	ld	ra,24(sp)
    80004c36:	6442                	ld	s0,16(sp)
    80004c38:	64a2                	ld	s1,8(sp)
    80004c3a:	6105                	addi	sp,sp,32
    80004c3c:	8082                	ret
    panic("filedup");
    80004c3e:	00004517          	auipc	a0,0x4
    80004c42:	b5250513          	addi	a0,a0,-1198 # 80008790 <syscalls+0x250>
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	8f8080e7          	jalr	-1800(ra) # 8000053e <panic>

0000000080004c4e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c4e:	7139                	addi	sp,sp,-64
    80004c50:	fc06                	sd	ra,56(sp)
    80004c52:	f822                	sd	s0,48(sp)
    80004c54:	f426                	sd	s1,40(sp)
    80004c56:	f04a                	sd	s2,32(sp)
    80004c58:	ec4e                	sd	s3,24(sp)
    80004c5a:	e852                	sd	s4,16(sp)
    80004c5c:	e456                	sd	s5,8(sp)
    80004c5e:	0080                	addi	s0,sp,64
    80004c60:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c62:	0001e517          	auipc	a0,0x1e
    80004c66:	3ce50513          	addi	a0,a0,974 # 80023030 <ftable>
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	f7a080e7          	jalr	-134(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c72:	40dc                	lw	a5,4(s1)
    80004c74:	06f05163          	blez	a5,80004cd6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c78:	37fd                	addiw	a5,a5,-1
    80004c7a:	0007871b          	sext.w	a4,a5
    80004c7e:	c0dc                	sw	a5,4(s1)
    80004c80:	06e04363          	bgtz	a4,80004ce6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c84:	0004a903          	lw	s2,0(s1)
    80004c88:	0094ca83          	lbu	s5,9(s1)
    80004c8c:	0104ba03          	ld	s4,16(s1)
    80004c90:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c94:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c98:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c9c:	0001e517          	auipc	a0,0x1e
    80004ca0:	39450513          	addi	a0,a0,916 # 80023030 <ftable>
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	ff4080e7          	jalr	-12(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004cac:	4785                	li	a5,1
    80004cae:	04f90d63          	beq	s2,a5,80004d08 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cb2:	3979                	addiw	s2,s2,-2
    80004cb4:	4785                	li	a5,1
    80004cb6:	0527e063          	bltu	a5,s2,80004cf6 <fileclose+0xa8>
    begin_op();
    80004cba:	00000097          	auipc	ra,0x0
    80004cbe:	ac8080e7          	jalr	-1336(ra) # 80004782 <begin_op>
    iput(ff.ip);
    80004cc2:	854e                	mv	a0,s3
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	2a6080e7          	jalr	678(ra) # 80003f6a <iput>
    end_op();
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	b36080e7          	jalr	-1226(ra) # 80004802 <end_op>
    80004cd4:	a00d                	j	80004cf6 <fileclose+0xa8>
    panic("fileclose");
    80004cd6:	00004517          	auipc	a0,0x4
    80004cda:	ac250513          	addi	a0,a0,-1342 # 80008798 <syscalls+0x258>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	860080e7          	jalr	-1952(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ce6:	0001e517          	auipc	a0,0x1e
    80004cea:	34a50513          	addi	a0,a0,842 # 80023030 <ftable>
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	faa080e7          	jalr	-86(ra) # 80000c98 <release>
  }
}
    80004cf6:	70e2                	ld	ra,56(sp)
    80004cf8:	7442                	ld	s0,48(sp)
    80004cfa:	74a2                	ld	s1,40(sp)
    80004cfc:	7902                	ld	s2,32(sp)
    80004cfe:	69e2                	ld	s3,24(sp)
    80004d00:	6a42                	ld	s4,16(sp)
    80004d02:	6aa2                	ld	s5,8(sp)
    80004d04:	6121                	addi	sp,sp,64
    80004d06:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d08:	85d6                	mv	a1,s5
    80004d0a:	8552                	mv	a0,s4
    80004d0c:	00000097          	auipc	ra,0x0
    80004d10:	34c080e7          	jalr	844(ra) # 80005058 <pipeclose>
    80004d14:	b7cd                	j	80004cf6 <fileclose+0xa8>

0000000080004d16 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d16:	715d                	addi	sp,sp,-80
    80004d18:	e486                	sd	ra,72(sp)
    80004d1a:	e0a2                	sd	s0,64(sp)
    80004d1c:	fc26                	sd	s1,56(sp)
    80004d1e:	f84a                	sd	s2,48(sp)
    80004d20:	f44e                	sd	s3,40(sp)
    80004d22:	0880                	addi	s0,sp,80
    80004d24:	84aa                	mv	s1,a0
    80004d26:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	c88080e7          	jalr	-888(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d30:	409c                	lw	a5,0(s1)
    80004d32:	37f9                	addiw	a5,a5,-2
    80004d34:	4705                	li	a4,1
    80004d36:	04f76763          	bltu	a4,a5,80004d84 <filestat+0x6e>
    80004d3a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d3c:	6c88                	ld	a0,24(s1)
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	072080e7          	jalr	114(ra) # 80003db0 <ilock>
    stati(f->ip, &st);
    80004d46:	fb840593          	addi	a1,s0,-72
    80004d4a:	6c88                	ld	a0,24(s1)
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	2ee080e7          	jalr	750(ra) # 8000403a <stati>
    iunlock(f->ip);
    80004d54:	6c88                	ld	a0,24(s1)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	11c080e7          	jalr	284(ra) # 80003e72 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d5e:	46e1                	li	a3,24
    80004d60:	fb840613          	addi	a2,s0,-72
    80004d64:	85ce                	mv	a1,s3
    80004d66:	05093503          	ld	a0,80(s2)
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	908080e7          	jalr	-1784(ra) # 80001672 <copyout>
    80004d72:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d76:	60a6                	ld	ra,72(sp)
    80004d78:	6406                	ld	s0,64(sp)
    80004d7a:	74e2                	ld	s1,56(sp)
    80004d7c:	7942                	ld	s2,48(sp)
    80004d7e:	79a2                	ld	s3,40(sp)
    80004d80:	6161                	addi	sp,sp,80
    80004d82:	8082                	ret
  return -1;
    80004d84:	557d                	li	a0,-1
    80004d86:	bfc5                	j	80004d76 <filestat+0x60>

0000000080004d88 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d88:	7179                	addi	sp,sp,-48
    80004d8a:	f406                	sd	ra,40(sp)
    80004d8c:	f022                	sd	s0,32(sp)
    80004d8e:	ec26                	sd	s1,24(sp)
    80004d90:	e84a                	sd	s2,16(sp)
    80004d92:	e44e                	sd	s3,8(sp)
    80004d94:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d96:	00854783          	lbu	a5,8(a0)
    80004d9a:	c3d5                	beqz	a5,80004e3e <fileread+0xb6>
    80004d9c:	84aa                	mv	s1,a0
    80004d9e:	89ae                	mv	s3,a1
    80004da0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004da2:	411c                	lw	a5,0(a0)
    80004da4:	4705                	li	a4,1
    80004da6:	04e78963          	beq	a5,a4,80004df8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004daa:	470d                	li	a4,3
    80004dac:	04e78d63          	beq	a5,a4,80004e06 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004db0:	4709                	li	a4,2
    80004db2:	06e79e63          	bne	a5,a4,80004e2e <fileread+0xa6>
    ilock(f->ip);
    80004db6:	6d08                	ld	a0,24(a0)
    80004db8:	fffff097          	auipc	ra,0xfffff
    80004dbc:	ff8080e7          	jalr	-8(ra) # 80003db0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004dc0:	874a                	mv	a4,s2
    80004dc2:	5094                	lw	a3,32(s1)
    80004dc4:	864e                	mv	a2,s3
    80004dc6:	4585                	li	a1,1
    80004dc8:	6c88                	ld	a0,24(s1)
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	29a080e7          	jalr	666(ra) # 80004064 <readi>
    80004dd2:	892a                	mv	s2,a0
    80004dd4:	00a05563          	blez	a0,80004dde <fileread+0x56>
      f->off += r;
    80004dd8:	509c                	lw	a5,32(s1)
    80004dda:	9fa9                	addw	a5,a5,a0
    80004ddc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004dde:	6c88                	ld	a0,24(s1)
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	092080e7          	jalr	146(ra) # 80003e72 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004de8:	854a                	mv	a0,s2
    80004dea:	70a2                	ld	ra,40(sp)
    80004dec:	7402                	ld	s0,32(sp)
    80004dee:	64e2                	ld	s1,24(sp)
    80004df0:	6942                	ld	s2,16(sp)
    80004df2:	69a2                	ld	s3,8(sp)
    80004df4:	6145                	addi	sp,sp,48
    80004df6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004df8:	6908                	ld	a0,16(a0)
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	3c8080e7          	jalr	968(ra) # 800051c2 <piperead>
    80004e02:	892a                	mv	s2,a0
    80004e04:	b7d5                	j	80004de8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e06:	02451783          	lh	a5,36(a0)
    80004e0a:	03079693          	slli	a3,a5,0x30
    80004e0e:	92c1                	srli	a3,a3,0x30
    80004e10:	4725                	li	a4,9
    80004e12:	02d76863          	bltu	a4,a3,80004e42 <fileread+0xba>
    80004e16:	0792                	slli	a5,a5,0x4
    80004e18:	0001e717          	auipc	a4,0x1e
    80004e1c:	17870713          	addi	a4,a4,376 # 80022f90 <devsw>
    80004e20:	97ba                	add	a5,a5,a4
    80004e22:	639c                	ld	a5,0(a5)
    80004e24:	c38d                	beqz	a5,80004e46 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e26:	4505                	li	a0,1
    80004e28:	9782                	jalr	a5
    80004e2a:	892a                	mv	s2,a0
    80004e2c:	bf75                	j	80004de8 <fileread+0x60>
    panic("fileread");
    80004e2e:	00004517          	auipc	a0,0x4
    80004e32:	97a50513          	addi	a0,a0,-1670 # 800087a8 <syscalls+0x268>
    80004e36:	ffffb097          	auipc	ra,0xffffb
    80004e3a:	708080e7          	jalr	1800(ra) # 8000053e <panic>
    return -1;
    80004e3e:	597d                	li	s2,-1
    80004e40:	b765                	j	80004de8 <fileread+0x60>
      return -1;
    80004e42:	597d                	li	s2,-1
    80004e44:	b755                	j	80004de8 <fileread+0x60>
    80004e46:	597d                	li	s2,-1
    80004e48:	b745                	j	80004de8 <fileread+0x60>

0000000080004e4a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e4a:	715d                	addi	sp,sp,-80
    80004e4c:	e486                	sd	ra,72(sp)
    80004e4e:	e0a2                	sd	s0,64(sp)
    80004e50:	fc26                	sd	s1,56(sp)
    80004e52:	f84a                	sd	s2,48(sp)
    80004e54:	f44e                	sd	s3,40(sp)
    80004e56:	f052                	sd	s4,32(sp)
    80004e58:	ec56                	sd	s5,24(sp)
    80004e5a:	e85a                	sd	s6,16(sp)
    80004e5c:	e45e                	sd	s7,8(sp)
    80004e5e:	e062                	sd	s8,0(sp)
    80004e60:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e62:	00954783          	lbu	a5,9(a0)
    80004e66:	10078663          	beqz	a5,80004f72 <filewrite+0x128>
    80004e6a:	892a                	mv	s2,a0
    80004e6c:	8aae                	mv	s5,a1
    80004e6e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e70:	411c                	lw	a5,0(a0)
    80004e72:	4705                	li	a4,1
    80004e74:	02e78263          	beq	a5,a4,80004e98 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e78:	470d                	li	a4,3
    80004e7a:	02e78663          	beq	a5,a4,80004ea6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e7e:	4709                	li	a4,2
    80004e80:	0ee79163          	bne	a5,a4,80004f62 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e84:	0ac05d63          	blez	a2,80004f3e <filewrite+0xf4>
    int i = 0;
    80004e88:	4981                	li	s3,0
    80004e8a:	6b05                	lui	s6,0x1
    80004e8c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e90:	6b85                	lui	s7,0x1
    80004e92:	c00b8b9b          	addiw	s7,s7,-1024
    80004e96:	a861                	j	80004f2e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e98:	6908                	ld	a0,16(a0)
    80004e9a:	00000097          	auipc	ra,0x0
    80004e9e:	22e080e7          	jalr	558(ra) # 800050c8 <pipewrite>
    80004ea2:	8a2a                	mv	s4,a0
    80004ea4:	a045                	j	80004f44 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ea6:	02451783          	lh	a5,36(a0)
    80004eaa:	03079693          	slli	a3,a5,0x30
    80004eae:	92c1                	srli	a3,a3,0x30
    80004eb0:	4725                	li	a4,9
    80004eb2:	0cd76263          	bltu	a4,a3,80004f76 <filewrite+0x12c>
    80004eb6:	0792                	slli	a5,a5,0x4
    80004eb8:	0001e717          	auipc	a4,0x1e
    80004ebc:	0d870713          	addi	a4,a4,216 # 80022f90 <devsw>
    80004ec0:	97ba                	add	a5,a5,a4
    80004ec2:	679c                	ld	a5,8(a5)
    80004ec4:	cbdd                	beqz	a5,80004f7a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ec6:	4505                	li	a0,1
    80004ec8:	9782                	jalr	a5
    80004eca:	8a2a                	mv	s4,a0
    80004ecc:	a8a5                	j	80004f44 <filewrite+0xfa>
    80004ece:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ed2:	00000097          	auipc	ra,0x0
    80004ed6:	8b0080e7          	jalr	-1872(ra) # 80004782 <begin_op>
      ilock(f->ip);
    80004eda:	01893503          	ld	a0,24(s2)
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	ed2080e7          	jalr	-302(ra) # 80003db0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ee6:	8762                	mv	a4,s8
    80004ee8:	02092683          	lw	a3,32(s2)
    80004eec:	01598633          	add	a2,s3,s5
    80004ef0:	4585                	li	a1,1
    80004ef2:	01893503          	ld	a0,24(s2)
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	266080e7          	jalr	614(ra) # 8000415c <writei>
    80004efe:	84aa                	mv	s1,a0
    80004f00:	00a05763          	blez	a0,80004f0e <filewrite+0xc4>
        f->off += r;
    80004f04:	02092783          	lw	a5,32(s2)
    80004f08:	9fa9                	addw	a5,a5,a0
    80004f0a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f0e:	01893503          	ld	a0,24(s2)
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	f60080e7          	jalr	-160(ra) # 80003e72 <iunlock>
      end_op();
    80004f1a:	00000097          	auipc	ra,0x0
    80004f1e:	8e8080e7          	jalr	-1816(ra) # 80004802 <end_op>

      if(r != n1){
    80004f22:	009c1f63          	bne	s8,s1,80004f40 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f26:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f2a:	0149db63          	bge	s3,s4,80004f40 <filewrite+0xf6>
      int n1 = n - i;
    80004f2e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f32:	84be                	mv	s1,a5
    80004f34:	2781                	sext.w	a5,a5
    80004f36:	f8fb5ce3          	bge	s6,a5,80004ece <filewrite+0x84>
    80004f3a:	84de                	mv	s1,s7
    80004f3c:	bf49                	j	80004ece <filewrite+0x84>
    int i = 0;
    80004f3e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f40:	013a1f63          	bne	s4,s3,80004f5e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f44:	8552                	mv	a0,s4
    80004f46:	60a6                	ld	ra,72(sp)
    80004f48:	6406                	ld	s0,64(sp)
    80004f4a:	74e2                	ld	s1,56(sp)
    80004f4c:	7942                	ld	s2,48(sp)
    80004f4e:	79a2                	ld	s3,40(sp)
    80004f50:	7a02                	ld	s4,32(sp)
    80004f52:	6ae2                	ld	s5,24(sp)
    80004f54:	6b42                	ld	s6,16(sp)
    80004f56:	6ba2                	ld	s7,8(sp)
    80004f58:	6c02                	ld	s8,0(sp)
    80004f5a:	6161                	addi	sp,sp,80
    80004f5c:	8082                	ret
    ret = (i == n ? n : -1);
    80004f5e:	5a7d                	li	s4,-1
    80004f60:	b7d5                	j	80004f44 <filewrite+0xfa>
    panic("filewrite");
    80004f62:	00004517          	auipc	a0,0x4
    80004f66:	85650513          	addi	a0,a0,-1962 # 800087b8 <syscalls+0x278>
    80004f6a:	ffffb097          	auipc	ra,0xffffb
    80004f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    return -1;
    80004f72:	5a7d                	li	s4,-1
    80004f74:	bfc1                	j	80004f44 <filewrite+0xfa>
      return -1;
    80004f76:	5a7d                	li	s4,-1
    80004f78:	b7f1                	j	80004f44 <filewrite+0xfa>
    80004f7a:	5a7d                	li	s4,-1
    80004f7c:	b7e1                	j	80004f44 <filewrite+0xfa>

0000000080004f7e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f7e:	7179                	addi	sp,sp,-48
    80004f80:	f406                	sd	ra,40(sp)
    80004f82:	f022                	sd	s0,32(sp)
    80004f84:	ec26                	sd	s1,24(sp)
    80004f86:	e84a                	sd	s2,16(sp)
    80004f88:	e44e                	sd	s3,8(sp)
    80004f8a:	e052                	sd	s4,0(sp)
    80004f8c:	1800                	addi	s0,sp,48
    80004f8e:	84aa                	mv	s1,a0
    80004f90:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f92:	0005b023          	sd	zero,0(a1)
    80004f96:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f9a:	00000097          	auipc	ra,0x0
    80004f9e:	bf8080e7          	jalr	-1032(ra) # 80004b92 <filealloc>
    80004fa2:	e088                	sd	a0,0(s1)
    80004fa4:	c551                	beqz	a0,80005030 <pipealloc+0xb2>
    80004fa6:	00000097          	auipc	ra,0x0
    80004faa:	bec080e7          	jalr	-1044(ra) # 80004b92 <filealloc>
    80004fae:	00aa3023          	sd	a0,0(s4)
    80004fb2:	c92d                	beqz	a0,80005024 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	b40080e7          	jalr	-1216(ra) # 80000af4 <kalloc>
    80004fbc:	892a                	mv	s2,a0
    80004fbe:	c125                	beqz	a0,8000501e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fc0:	4985                	li	s3,1
    80004fc2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fc6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fca:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fce:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fd2:	00003597          	auipc	a1,0x3
    80004fd6:	46658593          	addi	a1,a1,1126 # 80008438 <states.2473+0x168>
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	b7a080e7          	jalr	-1158(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004fe2:	609c                	ld	a5,0(s1)
    80004fe4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fe8:	609c                	ld	a5,0(s1)
    80004fea:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fee:	609c                	ld	a5,0(s1)
    80004ff0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ff4:	609c                	ld	a5,0(s1)
    80004ff6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ffa:	000a3783          	ld	a5,0(s4)
    80004ffe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005002:	000a3783          	ld	a5,0(s4)
    80005006:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000500a:	000a3783          	ld	a5,0(s4)
    8000500e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005012:	000a3783          	ld	a5,0(s4)
    80005016:	0127b823          	sd	s2,16(a5)
  return 0;
    8000501a:	4501                	li	a0,0
    8000501c:	a025                	j	80005044 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000501e:	6088                	ld	a0,0(s1)
    80005020:	e501                	bnez	a0,80005028 <pipealloc+0xaa>
    80005022:	a039                	j	80005030 <pipealloc+0xb2>
    80005024:	6088                	ld	a0,0(s1)
    80005026:	c51d                	beqz	a0,80005054 <pipealloc+0xd6>
    fileclose(*f0);
    80005028:	00000097          	auipc	ra,0x0
    8000502c:	c26080e7          	jalr	-986(ra) # 80004c4e <fileclose>
  if(*f1)
    80005030:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005034:	557d                	li	a0,-1
  if(*f1)
    80005036:	c799                	beqz	a5,80005044 <pipealloc+0xc6>
    fileclose(*f1);
    80005038:	853e                	mv	a0,a5
    8000503a:	00000097          	auipc	ra,0x0
    8000503e:	c14080e7          	jalr	-1004(ra) # 80004c4e <fileclose>
  return -1;
    80005042:	557d                	li	a0,-1
}
    80005044:	70a2                	ld	ra,40(sp)
    80005046:	7402                	ld	s0,32(sp)
    80005048:	64e2                	ld	s1,24(sp)
    8000504a:	6942                	ld	s2,16(sp)
    8000504c:	69a2                	ld	s3,8(sp)
    8000504e:	6a02                	ld	s4,0(sp)
    80005050:	6145                	addi	sp,sp,48
    80005052:	8082                	ret
  return -1;
    80005054:	557d                	li	a0,-1
    80005056:	b7fd                	j	80005044 <pipealloc+0xc6>

0000000080005058 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005058:	1101                	addi	sp,sp,-32
    8000505a:	ec06                	sd	ra,24(sp)
    8000505c:	e822                	sd	s0,16(sp)
    8000505e:	e426                	sd	s1,8(sp)
    80005060:	e04a                	sd	s2,0(sp)
    80005062:	1000                	addi	s0,sp,32
    80005064:	84aa                	mv	s1,a0
    80005066:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	b7c080e7          	jalr	-1156(ra) # 80000be4 <acquire>
  if(writable){
    80005070:	02090d63          	beqz	s2,800050aa <pipeclose+0x52>
    pi->writeopen = 0;
    80005074:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005078:	21848513          	addi	a0,s1,536
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	106080e7          	jalr	262(ra) # 80002182 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005084:	2204b783          	ld	a5,544(s1)
    80005088:	eb95                	bnez	a5,800050bc <pipeclose+0x64>
    release(&pi->lock);
    8000508a:	8526                	mv	a0,s1
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	c0c080e7          	jalr	-1012(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005094:	8526                	mv	a0,s1
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	962080e7          	jalr	-1694(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000509e:	60e2                	ld	ra,24(sp)
    800050a0:	6442                	ld	s0,16(sp)
    800050a2:	64a2                	ld	s1,8(sp)
    800050a4:	6902                	ld	s2,0(sp)
    800050a6:	6105                	addi	sp,sp,32
    800050a8:	8082                	ret
    pi->readopen = 0;
    800050aa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050ae:	21c48513          	addi	a0,s1,540
    800050b2:	ffffd097          	auipc	ra,0xffffd
    800050b6:	0d0080e7          	jalr	208(ra) # 80002182 <wakeup>
    800050ba:	b7e9                	j	80005084 <pipeclose+0x2c>
    release(&pi->lock);
    800050bc:	8526                	mv	a0,s1
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	bda080e7          	jalr	-1062(ra) # 80000c98 <release>
}
    800050c6:	bfe1                	j	8000509e <pipeclose+0x46>

00000000800050c8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050c8:	7159                	addi	sp,sp,-112
    800050ca:	f486                	sd	ra,104(sp)
    800050cc:	f0a2                	sd	s0,96(sp)
    800050ce:	eca6                	sd	s1,88(sp)
    800050d0:	e8ca                	sd	s2,80(sp)
    800050d2:	e4ce                	sd	s3,72(sp)
    800050d4:	e0d2                	sd	s4,64(sp)
    800050d6:	fc56                	sd	s5,56(sp)
    800050d8:	f85a                	sd	s6,48(sp)
    800050da:	f45e                	sd	s7,40(sp)
    800050dc:	f062                	sd	s8,32(sp)
    800050de:	ec66                	sd	s9,24(sp)
    800050e0:	1880                	addi	s0,sp,112
    800050e2:	84aa                	mv	s1,a0
    800050e4:	8aae                	mv	s5,a1
    800050e6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	8c8080e7          	jalr	-1848(ra) # 800019b0 <myproc>
    800050f0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	af0080e7          	jalr	-1296(ra) # 80000be4 <acquire>
  while(i < n){
    800050fc:	0d405163          	blez	s4,800051be <pipewrite+0xf6>
    80005100:	8ba6                	mv	s7,s1
  int i = 0;
    80005102:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005104:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005106:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000510a:	21c48c13          	addi	s8,s1,540
    8000510e:	a08d                	j	80005170 <pipewrite+0xa8>
      release(&pi->lock);
    80005110:	8526                	mv	a0,s1
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	b86080e7          	jalr	-1146(ra) # 80000c98 <release>
      return -1;
    8000511a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000511c:	854a                	mv	a0,s2
    8000511e:	70a6                	ld	ra,104(sp)
    80005120:	7406                	ld	s0,96(sp)
    80005122:	64e6                	ld	s1,88(sp)
    80005124:	6946                	ld	s2,80(sp)
    80005126:	69a6                	ld	s3,72(sp)
    80005128:	6a06                	ld	s4,64(sp)
    8000512a:	7ae2                	ld	s5,56(sp)
    8000512c:	7b42                	ld	s6,48(sp)
    8000512e:	7ba2                	ld	s7,40(sp)
    80005130:	7c02                	ld	s8,32(sp)
    80005132:	6ce2                	ld	s9,24(sp)
    80005134:	6165                	addi	sp,sp,112
    80005136:	8082                	ret
      wakeup(&pi->nread);
    80005138:	8566                	mv	a0,s9
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	048080e7          	jalr	72(ra) # 80002182 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005142:	85de                	mv	a1,s7
    80005144:	8562                	mv	a0,s8
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	eb0080e7          	jalr	-336(ra) # 80001ff6 <sleep>
    8000514e:	a839                	j	8000516c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005150:	21c4a783          	lw	a5,540(s1)
    80005154:	0017871b          	addiw	a4,a5,1
    80005158:	20e4ae23          	sw	a4,540(s1)
    8000515c:	1ff7f793          	andi	a5,a5,511
    80005160:	97a6                	add	a5,a5,s1
    80005162:	f9f44703          	lbu	a4,-97(s0)
    80005166:	00e78c23          	sb	a4,24(a5)
      i++;
    8000516a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000516c:	03495d63          	bge	s2,s4,800051a6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005170:	2204a783          	lw	a5,544(s1)
    80005174:	dfd1                	beqz	a5,80005110 <pipewrite+0x48>
    80005176:	0289a783          	lw	a5,40(s3)
    8000517a:	fbd9                	bnez	a5,80005110 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000517c:	2184a783          	lw	a5,536(s1)
    80005180:	21c4a703          	lw	a4,540(s1)
    80005184:	2007879b          	addiw	a5,a5,512
    80005188:	faf708e3          	beq	a4,a5,80005138 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000518c:	4685                	li	a3,1
    8000518e:	01590633          	add	a2,s2,s5
    80005192:	f9f40593          	addi	a1,s0,-97
    80005196:	0509b503          	ld	a0,80(s3)
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	564080e7          	jalr	1380(ra) # 800016fe <copyin>
    800051a2:	fb6517e3          	bne	a0,s6,80005150 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051a6:	21848513          	addi	a0,s1,536
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	fd8080e7          	jalr	-40(ra) # 80002182 <wakeup>
  release(&pi->lock);
    800051b2:	8526                	mv	a0,s1
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	ae4080e7          	jalr	-1308(ra) # 80000c98 <release>
  return i;
    800051bc:	b785                	j	8000511c <pipewrite+0x54>
  int i = 0;
    800051be:	4901                	li	s2,0
    800051c0:	b7dd                	j	800051a6 <pipewrite+0xde>

00000000800051c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051c2:	715d                	addi	sp,sp,-80
    800051c4:	e486                	sd	ra,72(sp)
    800051c6:	e0a2                	sd	s0,64(sp)
    800051c8:	fc26                	sd	s1,56(sp)
    800051ca:	f84a                	sd	s2,48(sp)
    800051cc:	f44e                	sd	s3,40(sp)
    800051ce:	f052                	sd	s4,32(sp)
    800051d0:	ec56                	sd	s5,24(sp)
    800051d2:	e85a                	sd	s6,16(sp)
    800051d4:	0880                	addi	s0,sp,80
    800051d6:	84aa                	mv	s1,a0
    800051d8:	892e                	mv	s2,a1
    800051da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	7d4080e7          	jalr	2004(ra) # 800019b0 <myproc>
    800051e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051e6:	8b26                	mv	s6,s1
    800051e8:	8526                	mv	a0,s1
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	9fa080e7          	jalr	-1542(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051f2:	2184a703          	lw	a4,536(s1)
    800051f6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051fa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051fe:	02f71463          	bne	a4,a5,80005226 <piperead+0x64>
    80005202:	2244a783          	lw	a5,548(s1)
    80005206:	c385                	beqz	a5,80005226 <piperead+0x64>
    if(pr->killed){
    80005208:	028a2783          	lw	a5,40(s4)
    8000520c:	ebc1                	bnez	a5,8000529c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000520e:	85da                	mv	a1,s6
    80005210:	854e                	mv	a0,s3
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	de4080e7          	jalr	-540(ra) # 80001ff6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000521a:	2184a703          	lw	a4,536(s1)
    8000521e:	21c4a783          	lw	a5,540(s1)
    80005222:	fef700e3          	beq	a4,a5,80005202 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005226:	09505263          	blez	s5,800052aa <piperead+0xe8>
    8000522a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000522c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000522e:	2184a783          	lw	a5,536(s1)
    80005232:	21c4a703          	lw	a4,540(s1)
    80005236:	02f70d63          	beq	a4,a5,80005270 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000523a:	0017871b          	addiw	a4,a5,1
    8000523e:	20e4ac23          	sw	a4,536(s1)
    80005242:	1ff7f793          	andi	a5,a5,511
    80005246:	97a6                	add	a5,a5,s1
    80005248:	0187c783          	lbu	a5,24(a5)
    8000524c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005250:	4685                	li	a3,1
    80005252:	fbf40613          	addi	a2,s0,-65
    80005256:	85ca                	mv	a1,s2
    80005258:	050a3503          	ld	a0,80(s4)
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	416080e7          	jalr	1046(ra) # 80001672 <copyout>
    80005264:	01650663          	beq	a0,s6,80005270 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005268:	2985                	addiw	s3,s3,1
    8000526a:	0905                	addi	s2,s2,1
    8000526c:	fd3a91e3          	bne	s5,s3,8000522e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005270:	21c48513          	addi	a0,s1,540
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	f0e080e7          	jalr	-242(ra) # 80002182 <wakeup>
  release(&pi->lock);
    8000527c:	8526                	mv	a0,s1
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	a1a080e7          	jalr	-1510(ra) # 80000c98 <release>
  return i;
}
    80005286:	854e                	mv	a0,s3
    80005288:	60a6                	ld	ra,72(sp)
    8000528a:	6406                	ld	s0,64(sp)
    8000528c:	74e2                	ld	s1,56(sp)
    8000528e:	7942                	ld	s2,48(sp)
    80005290:	79a2                	ld	s3,40(sp)
    80005292:	7a02                	ld	s4,32(sp)
    80005294:	6ae2                	ld	s5,24(sp)
    80005296:	6b42                	ld	s6,16(sp)
    80005298:	6161                	addi	sp,sp,80
    8000529a:	8082                	ret
      release(&pi->lock);
    8000529c:	8526                	mv	a0,s1
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	9fa080e7          	jalr	-1542(ra) # 80000c98 <release>
      return -1;
    800052a6:	59fd                	li	s3,-1
    800052a8:	bff9                	j	80005286 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052aa:	4981                	li	s3,0
    800052ac:	b7d1                	j	80005270 <piperead+0xae>

00000000800052ae <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052ae:	df010113          	addi	sp,sp,-528
    800052b2:	20113423          	sd	ra,520(sp)
    800052b6:	20813023          	sd	s0,512(sp)
    800052ba:	ffa6                	sd	s1,504(sp)
    800052bc:	fbca                	sd	s2,496(sp)
    800052be:	f7ce                	sd	s3,488(sp)
    800052c0:	f3d2                	sd	s4,480(sp)
    800052c2:	efd6                	sd	s5,472(sp)
    800052c4:	ebda                	sd	s6,464(sp)
    800052c6:	e7de                	sd	s7,456(sp)
    800052c8:	e3e2                	sd	s8,448(sp)
    800052ca:	ff66                	sd	s9,440(sp)
    800052cc:	fb6a                	sd	s10,432(sp)
    800052ce:	f76e                	sd	s11,424(sp)
    800052d0:	0c00                	addi	s0,sp,528
    800052d2:	84aa                	mv	s1,a0
    800052d4:	dea43c23          	sd	a0,-520(s0)
    800052d8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	6d4080e7          	jalr	1748(ra) # 800019b0 <myproc>
    800052e4:	892a                	mv	s2,a0

  begin_op();
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	49c080e7          	jalr	1180(ra) # 80004782 <begin_op>

  if((ip = namei(path)) == 0){
    800052ee:	8526                	mv	a0,s1
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	276080e7          	jalr	630(ra) # 80004566 <namei>
    800052f8:	c92d                	beqz	a0,8000536a <exec+0xbc>
    800052fa:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	ab4080e7          	jalr	-1356(ra) # 80003db0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005304:	04000713          	li	a4,64
    80005308:	4681                	li	a3,0
    8000530a:	e5040613          	addi	a2,s0,-432
    8000530e:	4581                	li	a1,0
    80005310:	8526                	mv	a0,s1
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	d52080e7          	jalr	-686(ra) # 80004064 <readi>
    8000531a:	04000793          	li	a5,64
    8000531e:	00f51a63          	bne	a0,a5,80005332 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005322:	e5042703          	lw	a4,-432(s0)
    80005326:	464c47b7          	lui	a5,0x464c4
    8000532a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000532e:	04f70463          	beq	a4,a5,80005376 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005332:	8526                	mv	a0,s1
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	cde080e7          	jalr	-802(ra) # 80004012 <iunlockput>
    end_op();
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	4c6080e7          	jalr	1222(ra) # 80004802 <end_op>
  }
  return -1;
    80005344:	557d                	li	a0,-1
}
    80005346:	20813083          	ld	ra,520(sp)
    8000534a:	20013403          	ld	s0,512(sp)
    8000534e:	74fe                	ld	s1,504(sp)
    80005350:	795e                	ld	s2,496(sp)
    80005352:	79be                	ld	s3,488(sp)
    80005354:	7a1e                	ld	s4,480(sp)
    80005356:	6afe                	ld	s5,472(sp)
    80005358:	6b5e                	ld	s6,464(sp)
    8000535a:	6bbe                	ld	s7,456(sp)
    8000535c:	6c1e                	ld	s8,448(sp)
    8000535e:	7cfa                	ld	s9,440(sp)
    80005360:	7d5a                	ld	s10,432(sp)
    80005362:	7dba                	ld	s11,424(sp)
    80005364:	21010113          	addi	sp,sp,528
    80005368:	8082                	ret
    end_op();
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	498080e7          	jalr	1176(ra) # 80004802 <end_op>
    return -1;
    80005372:	557d                	li	a0,-1
    80005374:	bfc9                	j	80005346 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005376:	854a                	mv	a0,s2
    80005378:	ffffc097          	auipc	ra,0xffffc
    8000537c:	6fc080e7          	jalr	1788(ra) # 80001a74 <proc_pagetable>
    80005380:	8baa                	mv	s7,a0
    80005382:	d945                	beqz	a0,80005332 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005384:	e7042983          	lw	s3,-400(s0)
    80005388:	e8845783          	lhu	a5,-376(s0)
    8000538c:	c7ad                	beqz	a5,800053f6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000538e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005390:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005392:	6c85                	lui	s9,0x1
    80005394:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005398:	def43823          	sd	a5,-528(s0)
    8000539c:	a42d                	j	800055c6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000539e:	00003517          	auipc	a0,0x3
    800053a2:	42a50513          	addi	a0,a0,1066 # 800087c8 <syscalls+0x288>
    800053a6:	ffffb097          	auipc	ra,0xffffb
    800053aa:	198080e7          	jalr	408(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053ae:	8756                	mv	a4,s5
    800053b0:	012d86bb          	addw	a3,s11,s2
    800053b4:	4581                	li	a1,0
    800053b6:	8526                	mv	a0,s1
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	cac080e7          	jalr	-852(ra) # 80004064 <readi>
    800053c0:	2501                	sext.w	a0,a0
    800053c2:	1aaa9963          	bne	s5,a0,80005574 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800053c6:	6785                	lui	a5,0x1
    800053c8:	0127893b          	addw	s2,a5,s2
    800053cc:	77fd                	lui	a5,0xfffff
    800053ce:	01478a3b          	addw	s4,a5,s4
    800053d2:	1f897163          	bgeu	s2,s8,800055b4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800053d6:	02091593          	slli	a1,s2,0x20
    800053da:	9181                	srli	a1,a1,0x20
    800053dc:	95ea                	add	a1,a1,s10
    800053de:	855e                	mv	a0,s7
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	c8e080e7          	jalr	-882(ra) # 8000106e <walkaddr>
    800053e8:	862a                	mv	a2,a0
    if(pa == 0)
    800053ea:	d955                	beqz	a0,8000539e <exec+0xf0>
      n = PGSIZE;
    800053ec:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800053ee:	fd9a70e3          	bgeu	s4,s9,800053ae <exec+0x100>
      n = sz - i;
    800053f2:	8ad2                	mv	s5,s4
    800053f4:	bf6d                	j	800053ae <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053f6:	4901                	li	s2,0
  iunlockput(ip);
    800053f8:	8526                	mv	a0,s1
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	c18080e7          	jalr	-1000(ra) # 80004012 <iunlockput>
  end_op();
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	400080e7          	jalr	1024(ra) # 80004802 <end_op>
  p = myproc();
    8000540a:	ffffc097          	auipc	ra,0xffffc
    8000540e:	5a6080e7          	jalr	1446(ra) # 800019b0 <myproc>
    80005412:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005414:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005418:	6785                	lui	a5,0x1
    8000541a:	17fd                	addi	a5,a5,-1
    8000541c:	993e                	add	s2,s2,a5
    8000541e:	757d                	lui	a0,0xfffff
    80005420:	00a977b3          	and	a5,s2,a0
    80005424:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005428:	6609                	lui	a2,0x2
    8000542a:	963e                	add	a2,a2,a5
    8000542c:	85be                	mv	a1,a5
    8000542e:	855e                	mv	a0,s7
    80005430:	ffffc097          	auipc	ra,0xffffc
    80005434:	ff2080e7          	jalr	-14(ra) # 80001422 <uvmalloc>
    80005438:	8b2a                	mv	s6,a0
  ip = 0;
    8000543a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000543c:	12050c63          	beqz	a0,80005574 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005440:	75f9                	lui	a1,0xffffe
    80005442:	95aa                	add	a1,a1,a0
    80005444:	855e                	mv	a0,s7
    80005446:	ffffc097          	auipc	ra,0xffffc
    8000544a:	1fa080e7          	jalr	506(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000544e:	7c7d                	lui	s8,0xfffff
    80005450:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005452:	e0043783          	ld	a5,-512(s0)
    80005456:	6388                	ld	a0,0(a5)
    80005458:	c535                	beqz	a0,800054c4 <exec+0x216>
    8000545a:	e9040993          	addi	s3,s0,-368
    8000545e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005462:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	a00080e7          	jalr	-1536(ra) # 80000e64 <strlen>
    8000546c:	2505                	addiw	a0,a0,1
    8000546e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005472:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005476:	13896363          	bltu	s2,s8,8000559c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000547a:	e0043d83          	ld	s11,-512(s0)
    8000547e:	000dba03          	ld	s4,0(s11)
    80005482:	8552                	mv	a0,s4
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	9e0080e7          	jalr	-1568(ra) # 80000e64 <strlen>
    8000548c:	0015069b          	addiw	a3,a0,1
    80005490:	8652                	mv	a2,s4
    80005492:	85ca                	mv	a1,s2
    80005494:	855e                	mv	a0,s7
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	1dc080e7          	jalr	476(ra) # 80001672 <copyout>
    8000549e:	10054363          	bltz	a0,800055a4 <exec+0x2f6>
    ustack[argc] = sp;
    800054a2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054a6:	0485                	addi	s1,s1,1
    800054a8:	008d8793          	addi	a5,s11,8
    800054ac:	e0f43023          	sd	a5,-512(s0)
    800054b0:	008db503          	ld	a0,8(s11)
    800054b4:	c911                	beqz	a0,800054c8 <exec+0x21a>
    if(argc >= MAXARG)
    800054b6:	09a1                	addi	s3,s3,8
    800054b8:	fb3c96e3          	bne	s9,s3,80005464 <exec+0x1b6>
  sz = sz1;
    800054bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054c0:	4481                	li	s1,0
    800054c2:	a84d                	j	80005574 <exec+0x2c6>
  sp = sz;
    800054c4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054c6:	4481                	li	s1,0
  ustack[argc] = 0;
    800054c8:	00349793          	slli	a5,s1,0x3
    800054cc:	f9040713          	addi	a4,s0,-112
    800054d0:	97ba                	add	a5,a5,a4
    800054d2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800054d6:	00148693          	addi	a3,s1,1
    800054da:	068e                	slli	a3,a3,0x3
    800054dc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054e0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800054e4:	01897663          	bgeu	s2,s8,800054f0 <exec+0x242>
  sz = sz1;
    800054e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054ec:	4481                	li	s1,0
    800054ee:	a059                	j	80005574 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054f0:	e9040613          	addi	a2,s0,-368
    800054f4:	85ca                	mv	a1,s2
    800054f6:	855e                	mv	a0,s7
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	17a080e7          	jalr	378(ra) # 80001672 <copyout>
    80005500:	0a054663          	bltz	a0,800055ac <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005504:	058ab783          	ld	a5,88(s5)
    80005508:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000550c:	df843783          	ld	a5,-520(s0)
    80005510:	0007c703          	lbu	a4,0(a5)
    80005514:	cf11                	beqz	a4,80005530 <exec+0x282>
    80005516:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005518:	02f00693          	li	a3,47
    8000551c:	a039                	j	8000552a <exec+0x27c>
      last = s+1;
    8000551e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005522:	0785                	addi	a5,a5,1
    80005524:	fff7c703          	lbu	a4,-1(a5)
    80005528:	c701                	beqz	a4,80005530 <exec+0x282>
    if(*s == '/')
    8000552a:	fed71ce3          	bne	a4,a3,80005522 <exec+0x274>
    8000552e:	bfc5                	j	8000551e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005530:	4641                	li	a2,16
    80005532:	df843583          	ld	a1,-520(s0)
    80005536:	158a8513          	addi	a0,s5,344
    8000553a:	ffffc097          	auipc	ra,0xffffc
    8000553e:	8f8080e7          	jalr	-1800(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005542:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005546:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000554a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000554e:	058ab783          	ld	a5,88(s5)
    80005552:	e6843703          	ld	a4,-408(s0)
    80005556:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005558:	058ab783          	ld	a5,88(s5)
    8000555c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005560:	85ea                	mv	a1,s10
    80005562:	ffffc097          	auipc	ra,0xffffc
    80005566:	5ae080e7          	jalr	1454(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000556a:	0004851b          	sext.w	a0,s1
    8000556e:	bbe1                	j	80005346 <exec+0x98>
    80005570:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005574:	e0843583          	ld	a1,-504(s0)
    80005578:	855e                	mv	a0,s7
    8000557a:	ffffc097          	auipc	ra,0xffffc
    8000557e:	596080e7          	jalr	1430(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005582:	da0498e3          	bnez	s1,80005332 <exec+0x84>
  return -1;
    80005586:	557d                	li	a0,-1
    80005588:	bb7d                	j	80005346 <exec+0x98>
    8000558a:	e1243423          	sd	s2,-504(s0)
    8000558e:	b7dd                	j	80005574 <exec+0x2c6>
    80005590:	e1243423          	sd	s2,-504(s0)
    80005594:	b7c5                	j	80005574 <exec+0x2c6>
    80005596:	e1243423          	sd	s2,-504(s0)
    8000559a:	bfe9                	j	80005574 <exec+0x2c6>
  sz = sz1;
    8000559c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055a0:	4481                	li	s1,0
    800055a2:	bfc9                	j	80005574 <exec+0x2c6>
  sz = sz1;
    800055a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055a8:	4481                	li	s1,0
    800055aa:	b7e9                	j	80005574 <exec+0x2c6>
  sz = sz1;
    800055ac:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055b0:	4481                	li	s1,0
    800055b2:	b7c9                	j	80005574 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055b4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055b8:	2b05                	addiw	s6,s6,1
    800055ba:	0389899b          	addiw	s3,s3,56
    800055be:	e8845783          	lhu	a5,-376(s0)
    800055c2:	e2fb5be3          	bge	s6,a5,800053f8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055c6:	2981                	sext.w	s3,s3
    800055c8:	03800713          	li	a4,56
    800055cc:	86ce                	mv	a3,s3
    800055ce:	e1840613          	addi	a2,s0,-488
    800055d2:	4581                	li	a1,0
    800055d4:	8526                	mv	a0,s1
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	a8e080e7          	jalr	-1394(ra) # 80004064 <readi>
    800055de:	03800793          	li	a5,56
    800055e2:	f8f517e3          	bne	a0,a5,80005570 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800055e6:	e1842783          	lw	a5,-488(s0)
    800055ea:	4705                	li	a4,1
    800055ec:	fce796e3          	bne	a5,a4,800055b8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800055f0:	e4043603          	ld	a2,-448(s0)
    800055f4:	e3843783          	ld	a5,-456(s0)
    800055f8:	f8f669e3          	bltu	a2,a5,8000558a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055fc:	e2843783          	ld	a5,-472(s0)
    80005600:	963e                	add	a2,a2,a5
    80005602:	f8f667e3          	bltu	a2,a5,80005590 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005606:	85ca                	mv	a1,s2
    80005608:	855e                	mv	a0,s7
    8000560a:	ffffc097          	auipc	ra,0xffffc
    8000560e:	e18080e7          	jalr	-488(ra) # 80001422 <uvmalloc>
    80005612:	e0a43423          	sd	a0,-504(s0)
    80005616:	d141                	beqz	a0,80005596 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005618:	e2843d03          	ld	s10,-472(s0)
    8000561c:	df043783          	ld	a5,-528(s0)
    80005620:	00fd77b3          	and	a5,s10,a5
    80005624:	fba1                	bnez	a5,80005574 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005626:	e2042d83          	lw	s11,-480(s0)
    8000562a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000562e:	f80c03e3          	beqz	s8,800055b4 <exec+0x306>
    80005632:	8a62                	mv	s4,s8
    80005634:	4901                	li	s2,0
    80005636:	b345                	j	800053d6 <exec+0x128>

0000000080005638 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005638:	7179                	addi	sp,sp,-48
    8000563a:	f406                	sd	ra,40(sp)
    8000563c:	f022                	sd	s0,32(sp)
    8000563e:	ec26                	sd	s1,24(sp)
    80005640:	e84a                	sd	s2,16(sp)
    80005642:	1800                	addi	s0,sp,48
    80005644:	892e                	mv	s2,a1
    80005646:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005648:	fdc40593          	addi	a1,s0,-36
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	8e2080e7          	jalr	-1822(ra) # 80002f2e <argint>
    80005654:	04054063          	bltz	a0,80005694 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005658:	fdc42703          	lw	a4,-36(s0)
    8000565c:	47bd                	li	a5,15
    8000565e:	02e7ed63          	bltu	a5,a4,80005698 <argfd+0x60>
    80005662:	ffffc097          	auipc	ra,0xffffc
    80005666:	34e080e7          	jalr	846(ra) # 800019b0 <myproc>
    8000566a:	fdc42703          	lw	a4,-36(s0)
    8000566e:	01a70793          	addi	a5,a4,26
    80005672:	078e                	slli	a5,a5,0x3
    80005674:	953e                	add	a0,a0,a5
    80005676:	611c                	ld	a5,0(a0)
    80005678:	c395                	beqz	a5,8000569c <argfd+0x64>
    return -1;
  if(pfd)
    8000567a:	00090463          	beqz	s2,80005682 <argfd+0x4a>
    *pfd = fd;
    8000567e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005682:	4501                	li	a0,0
  if(pf)
    80005684:	c091                	beqz	s1,80005688 <argfd+0x50>
    *pf = f;
    80005686:	e09c                	sd	a5,0(s1)
}
    80005688:	70a2                	ld	ra,40(sp)
    8000568a:	7402                	ld	s0,32(sp)
    8000568c:	64e2                	ld	s1,24(sp)
    8000568e:	6942                	ld	s2,16(sp)
    80005690:	6145                	addi	sp,sp,48
    80005692:	8082                	ret
    return -1;
    80005694:	557d                	li	a0,-1
    80005696:	bfcd                	j	80005688 <argfd+0x50>
    return -1;
    80005698:	557d                	li	a0,-1
    8000569a:	b7fd                	j	80005688 <argfd+0x50>
    8000569c:	557d                	li	a0,-1
    8000569e:	b7ed                	j	80005688 <argfd+0x50>

00000000800056a0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056a0:	1101                	addi	sp,sp,-32
    800056a2:	ec06                	sd	ra,24(sp)
    800056a4:	e822                	sd	s0,16(sp)
    800056a6:	e426                	sd	s1,8(sp)
    800056a8:	1000                	addi	s0,sp,32
    800056aa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056ac:	ffffc097          	auipc	ra,0xffffc
    800056b0:	304080e7          	jalr	772(ra) # 800019b0 <myproc>
    800056b4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056b6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    800056ba:	4501                	li	a0,0
    800056bc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056be:	6398                	ld	a4,0(a5)
    800056c0:	cb19                	beqz	a4,800056d6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056c2:	2505                	addiw	a0,a0,1
    800056c4:	07a1                	addi	a5,a5,8
    800056c6:	fed51ce3          	bne	a0,a3,800056be <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056ca:	557d                	li	a0,-1
}
    800056cc:	60e2                	ld	ra,24(sp)
    800056ce:	6442                	ld	s0,16(sp)
    800056d0:	64a2                	ld	s1,8(sp)
    800056d2:	6105                	addi	sp,sp,32
    800056d4:	8082                	ret
      p->ofile[fd] = f;
    800056d6:	01a50793          	addi	a5,a0,26
    800056da:	078e                	slli	a5,a5,0x3
    800056dc:	963e                	add	a2,a2,a5
    800056de:	e204                	sd	s1,0(a2)
      return fd;
    800056e0:	b7f5                	j	800056cc <fdalloc+0x2c>

00000000800056e2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056e2:	715d                	addi	sp,sp,-80
    800056e4:	e486                	sd	ra,72(sp)
    800056e6:	e0a2                	sd	s0,64(sp)
    800056e8:	fc26                	sd	s1,56(sp)
    800056ea:	f84a                	sd	s2,48(sp)
    800056ec:	f44e                	sd	s3,40(sp)
    800056ee:	f052                	sd	s4,32(sp)
    800056f0:	ec56                	sd	s5,24(sp)
    800056f2:	0880                	addi	s0,sp,80
    800056f4:	89ae                	mv	s3,a1
    800056f6:	8ab2                	mv	s5,a2
    800056f8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056fa:	fb040593          	addi	a1,s0,-80
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	e86080e7          	jalr	-378(ra) # 80004584 <nameiparent>
    80005706:	892a                	mv	s2,a0
    80005708:	12050f63          	beqz	a0,80005846 <create+0x164>
    return 0;

  ilock(dp);
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	6a4080e7          	jalr	1700(ra) # 80003db0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005714:	4601                	li	a2,0
    80005716:	fb040593          	addi	a1,s0,-80
    8000571a:	854a                	mv	a0,s2
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	b78080e7          	jalr	-1160(ra) # 80004294 <dirlookup>
    80005724:	84aa                	mv	s1,a0
    80005726:	c921                	beqz	a0,80005776 <create+0x94>
    iunlockput(dp);
    80005728:	854a                	mv	a0,s2
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	8e8080e7          	jalr	-1816(ra) # 80004012 <iunlockput>
    ilock(ip);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	67c080e7          	jalr	1660(ra) # 80003db0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000573c:	2981                	sext.w	s3,s3
    8000573e:	4789                	li	a5,2
    80005740:	02f99463          	bne	s3,a5,80005768 <create+0x86>
    80005744:	0444d783          	lhu	a5,68(s1)
    80005748:	37f9                	addiw	a5,a5,-2
    8000574a:	17c2                	slli	a5,a5,0x30
    8000574c:	93c1                	srli	a5,a5,0x30
    8000574e:	4705                	li	a4,1
    80005750:	00f76c63          	bltu	a4,a5,80005768 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005754:	8526                	mv	a0,s1
    80005756:	60a6                	ld	ra,72(sp)
    80005758:	6406                	ld	s0,64(sp)
    8000575a:	74e2                	ld	s1,56(sp)
    8000575c:	7942                	ld	s2,48(sp)
    8000575e:	79a2                	ld	s3,40(sp)
    80005760:	7a02                	ld	s4,32(sp)
    80005762:	6ae2                	ld	s5,24(sp)
    80005764:	6161                	addi	sp,sp,80
    80005766:	8082                	ret
    iunlockput(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	8a8080e7          	jalr	-1880(ra) # 80004012 <iunlockput>
    return 0;
    80005772:	4481                	li	s1,0
    80005774:	b7c5                	j	80005754 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005776:	85ce                	mv	a1,s3
    80005778:	00092503          	lw	a0,0(s2)
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	49c080e7          	jalr	1180(ra) # 80003c18 <ialloc>
    80005784:	84aa                	mv	s1,a0
    80005786:	c529                	beqz	a0,800057d0 <create+0xee>
  ilock(ip);
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	628080e7          	jalr	1576(ra) # 80003db0 <ilock>
  ip->major = major;
    80005790:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005794:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005798:	4785                	li	a5,1
    8000579a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	546080e7          	jalr	1350(ra) # 80003ce6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057a8:	2981                	sext.w	s3,s3
    800057aa:	4785                	li	a5,1
    800057ac:	02f98a63          	beq	s3,a5,800057e0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057b0:	40d0                	lw	a2,4(s1)
    800057b2:	fb040593          	addi	a1,s0,-80
    800057b6:	854a                	mv	a0,s2
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	cec080e7          	jalr	-788(ra) # 800044a4 <dirlink>
    800057c0:	06054b63          	bltz	a0,80005836 <create+0x154>
  iunlockput(dp);
    800057c4:	854a                	mv	a0,s2
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	84c080e7          	jalr	-1972(ra) # 80004012 <iunlockput>
  return ip;
    800057ce:	b759                	j	80005754 <create+0x72>
    panic("create: ialloc");
    800057d0:	00003517          	auipc	a0,0x3
    800057d4:	01850513          	addi	a0,a0,24 # 800087e8 <syscalls+0x2a8>
    800057d8:	ffffb097          	auipc	ra,0xffffb
    800057dc:	d66080e7          	jalr	-666(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800057e0:	04a95783          	lhu	a5,74(s2)
    800057e4:	2785                	addiw	a5,a5,1
    800057e6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	4fa080e7          	jalr	1274(ra) # 80003ce6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057f4:	40d0                	lw	a2,4(s1)
    800057f6:	00003597          	auipc	a1,0x3
    800057fa:	00258593          	addi	a1,a1,2 # 800087f8 <syscalls+0x2b8>
    800057fe:	8526                	mv	a0,s1
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	ca4080e7          	jalr	-860(ra) # 800044a4 <dirlink>
    80005808:	00054f63          	bltz	a0,80005826 <create+0x144>
    8000580c:	00492603          	lw	a2,4(s2)
    80005810:	00003597          	auipc	a1,0x3
    80005814:	ff058593          	addi	a1,a1,-16 # 80008800 <syscalls+0x2c0>
    80005818:	8526                	mv	a0,s1
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	c8a080e7          	jalr	-886(ra) # 800044a4 <dirlink>
    80005822:	f80557e3          	bgez	a0,800057b0 <create+0xce>
      panic("create dots");
    80005826:	00003517          	auipc	a0,0x3
    8000582a:	fe250513          	addi	a0,a0,-30 # 80008808 <syscalls+0x2c8>
    8000582e:	ffffb097          	auipc	ra,0xffffb
    80005832:	d10080e7          	jalr	-752(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005836:	00003517          	auipc	a0,0x3
    8000583a:	fe250513          	addi	a0,a0,-30 # 80008818 <syscalls+0x2d8>
    8000583e:	ffffb097          	auipc	ra,0xffffb
    80005842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>
    return 0;
    80005846:	84aa                	mv	s1,a0
    80005848:	b731                	j	80005754 <create+0x72>

000000008000584a <sys_dup>:
{
    8000584a:	7179                	addi	sp,sp,-48
    8000584c:	f406                	sd	ra,40(sp)
    8000584e:	f022                	sd	s0,32(sp)
    80005850:	ec26                	sd	s1,24(sp)
    80005852:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005854:	fd840613          	addi	a2,s0,-40
    80005858:	4581                	li	a1,0
    8000585a:	4501                	li	a0,0
    8000585c:	00000097          	auipc	ra,0x0
    80005860:	ddc080e7          	jalr	-548(ra) # 80005638 <argfd>
    return -1;
    80005864:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005866:	02054363          	bltz	a0,8000588c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000586a:	fd843503          	ld	a0,-40(s0)
    8000586e:	00000097          	auipc	ra,0x0
    80005872:	e32080e7          	jalr	-462(ra) # 800056a0 <fdalloc>
    80005876:	84aa                	mv	s1,a0
    return -1;
    80005878:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000587a:	00054963          	bltz	a0,8000588c <sys_dup+0x42>
  filedup(f);
    8000587e:	fd843503          	ld	a0,-40(s0)
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	37a080e7          	jalr	890(ra) # 80004bfc <filedup>
  return fd;
    8000588a:	87a6                	mv	a5,s1
}
    8000588c:	853e                	mv	a0,a5
    8000588e:	70a2                	ld	ra,40(sp)
    80005890:	7402                	ld	s0,32(sp)
    80005892:	64e2                	ld	s1,24(sp)
    80005894:	6145                	addi	sp,sp,48
    80005896:	8082                	ret

0000000080005898 <sys_read>:
{
    80005898:	7179                	addi	sp,sp,-48
    8000589a:	f406                	sd	ra,40(sp)
    8000589c:	f022                	sd	s0,32(sp)
    8000589e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058a0:	fe840613          	addi	a2,s0,-24
    800058a4:	4581                	li	a1,0
    800058a6:	4501                	li	a0,0
    800058a8:	00000097          	auipc	ra,0x0
    800058ac:	d90080e7          	jalr	-624(ra) # 80005638 <argfd>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058b2:	04054163          	bltz	a0,800058f4 <sys_read+0x5c>
    800058b6:	fe440593          	addi	a1,s0,-28
    800058ba:	4509                	li	a0,2
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	672080e7          	jalr	1650(ra) # 80002f2e <argint>
    return -1;
    800058c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058c6:	02054763          	bltz	a0,800058f4 <sys_read+0x5c>
    800058ca:	fd840593          	addi	a1,s0,-40
    800058ce:	4505                	li	a0,1
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	680080e7          	jalr	1664(ra) # 80002f50 <argaddr>
    return -1;
    800058d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058da:	00054d63          	bltz	a0,800058f4 <sys_read+0x5c>
  return fileread(f, p, n);
    800058de:	fe442603          	lw	a2,-28(s0)
    800058e2:	fd843583          	ld	a1,-40(s0)
    800058e6:	fe843503          	ld	a0,-24(s0)
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	49e080e7          	jalr	1182(ra) # 80004d88 <fileread>
    800058f2:	87aa                	mv	a5,a0
}
    800058f4:	853e                	mv	a0,a5
    800058f6:	70a2                	ld	ra,40(sp)
    800058f8:	7402                	ld	s0,32(sp)
    800058fa:	6145                	addi	sp,sp,48
    800058fc:	8082                	ret

00000000800058fe <sys_write>:
{
    800058fe:	7179                	addi	sp,sp,-48
    80005900:	f406                	sd	ra,40(sp)
    80005902:	f022                	sd	s0,32(sp)
    80005904:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005906:	fe840613          	addi	a2,s0,-24
    8000590a:	4581                	li	a1,0
    8000590c:	4501                	li	a0,0
    8000590e:	00000097          	auipc	ra,0x0
    80005912:	d2a080e7          	jalr	-726(ra) # 80005638 <argfd>
    return -1;
    80005916:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005918:	04054163          	bltz	a0,8000595a <sys_write+0x5c>
    8000591c:	fe440593          	addi	a1,s0,-28
    80005920:	4509                	li	a0,2
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	60c080e7          	jalr	1548(ra) # 80002f2e <argint>
    return -1;
    8000592a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000592c:	02054763          	bltz	a0,8000595a <sys_write+0x5c>
    80005930:	fd840593          	addi	a1,s0,-40
    80005934:	4505                	li	a0,1
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	61a080e7          	jalr	1562(ra) # 80002f50 <argaddr>
    return -1;
    8000593e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005940:	00054d63          	bltz	a0,8000595a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005944:	fe442603          	lw	a2,-28(s0)
    80005948:	fd843583          	ld	a1,-40(s0)
    8000594c:	fe843503          	ld	a0,-24(s0)
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	4fa080e7          	jalr	1274(ra) # 80004e4a <filewrite>
    80005958:	87aa                	mv	a5,a0
}
    8000595a:	853e                	mv	a0,a5
    8000595c:	70a2                	ld	ra,40(sp)
    8000595e:	7402                	ld	s0,32(sp)
    80005960:	6145                	addi	sp,sp,48
    80005962:	8082                	ret

0000000080005964 <sys_close>:
{
    80005964:	1101                	addi	sp,sp,-32
    80005966:	ec06                	sd	ra,24(sp)
    80005968:	e822                	sd	s0,16(sp)
    8000596a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000596c:	fe040613          	addi	a2,s0,-32
    80005970:	fec40593          	addi	a1,s0,-20
    80005974:	4501                	li	a0,0
    80005976:	00000097          	auipc	ra,0x0
    8000597a:	cc2080e7          	jalr	-830(ra) # 80005638 <argfd>
    return -1;
    8000597e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005980:	02054463          	bltz	a0,800059a8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005984:	ffffc097          	auipc	ra,0xffffc
    80005988:	02c080e7          	jalr	44(ra) # 800019b0 <myproc>
    8000598c:	fec42783          	lw	a5,-20(s0)
    80005990:	07e9                	addi	a5,a5,26
    80005992:	078e                	slli	a5,a5,0x3
    80005994:	97aa                	add	a5,a5,a0
    80005996:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000599a:	fe043503          	ld	a0,-32(s0)
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	2b0080e7          	jalr	688(ra) # 80004c4e <fileclose>
  return 0;
    800059a6:	4781                	li	a5,0
}
    800059a8:	853e                	mv	a0,a5
    800059aa:	60e2                	ld	ra,24(sp)
    800059ac:	6442                	ld	s0,16(sp)
    800059ae:	6105                	addi	sp,sp,32
    800059b0:	8082                	ret

00000000800059b2 <sys_fstat>:
{
    800059b2:	1101                	addi	sp,sp,-32
    800059b4:	ec06                	sd	ra,24(sp)
    800059b6:	e822                	sd	s0,16(sp)
    800059b8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059ba:	fe840613          	addi	a2,s0,-24
    800059be:	4581                	li	a1,0
    800059c0:	4501                	li	a0,0
    800059c2:	00000097          	auipc	ra,0x0
    800059c6:	c76080e7          	jalr	-906(ra) # 80005638 <argfd>
    return -1;
    800059ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059cc:	02054563          	bltz	a0,800059f6 <sys_fstat+0x44>
    800059d0:	fe040593          	addi	a1,s0,-32
    800059d4:	4505                	li	a0,1
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	57a080e7          	jalr	1402(ra) # 80002f50 <argaddr>
    return -1;
    800059de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059e0:	00054b63          	bltz	a0,800059f6 <sys_fstat+0x44>
  return filestat(f, st);
    800059e4:	fe043583          	ld	a1,-32(s0)
    800059e8:	fe843503          	ld	a0,-24(s0)
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	32a080e7          	jalr	810(ra) # 80004d16 <filestat>
    800059f4:	87aa                	mv	a5,a0
}
    800059f6:	853e                	mv	a0,a5
    800059f8:	60e2                	ld	ra,24(sp)
    800059fa:	6442                	ld	s0,16(sp)
    800059fc:	6105                	addi	sp,sp,32
    800059fe:	8082                	ret

0000000080005a00 <sys_link>:
{
    80005a00:	7169                	addi	sp,sp,-304
    80005a02:	f606                	sd	ra,296(sp)
    80005a04:	f222                	sd	s0,288(sp)
    80005a06:	ee26                	sd	s1,280(sp)
    80005a08:	ea4a                	sd	s2,272(sp)
    80005a0a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a0c:	08000613          	li	a2,128
    80005a10:	ed040593          	addi	a1,s0,-304
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	55c080e7          	jalr	1372(ra) # 80002f72 <argstr>
    return -1;
    80005a1e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a20:	10054e63          	bltz	a0,80005b3c <sys_link+0x13c>
    80005a24:	08000613          	li	a2,128
    80005a28:	f5040593          	addi	a1,s0,-176
    80005a2c:	4505                	li	a0,1
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	544080e7          	jalr	1348(ra) # 80002f72 <argstr>
    return -1;
    80005a36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a38:	10054263          	bltz	a0,80005b3c <sys_link+0x13c>
  begin_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	d46080e7          	jalr	-698(ra) # 80004782 <begin_op>
  if((ip = namei(old)) == 0){
    80005a44:	ed040513          	addi	a0,s0,-304
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	b1e080e7          	jalr	-1250(ra) # 80004566 <namei>
    80005a50:	84aa                	mv	s1,a0
    80005a52:	c551                	beqz	a0,80005ade <sys_link+0xde>
  ilock(ip);
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	35c080e7          	jalr	860(ra) # 80003db0 <ilock>
  if(ip->type == T_DIR){
    80005a5c:	04449703          	lh	a4,68(s1)
    80005a60:	4785                	li	a5,1
    80005a62:	08f70463          	beq	a4,a5,80005aea <sys_link+0xea>
  ip->nlink++;
    80005a66:	04a4d783          	lhu	a5,74(s1)
    80005a6a:	2785                	addiw	a5,a5,1
    80005a6c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a70:	8526                	mv	a0,s1
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	274080e7          	jalr	628(ra) # 80003ce6 <iupdate>
  iunlock(ip);
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	3f6080e7          	jalr	1014(ra) # 80003e72 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a84:	fd040593          	addi	a1,s0,-48
    80005a88:	f5040513          	addi	a0,s0,-176
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	af8080e7          	jalr	-1288(ra) # 80004584 <nameiparent>
    80005a94:	892a                	mv	s2,a0
    80005a96:	c935                	beqz	a0,80005b0a <sys_link+0x10a>
  ilock(dp);
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	318080e7          	jalr	792(ra) # 80003db0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005aa0:	00092703          	lw	a4,0(s2)
    80005aa4:	409c                	lw	a5,0(s1)
    80005aa6:	04f71d63          	bne	a4,a5,80005b00 <sys_link+0x100>
    80005aaa:	40d0                	lw	a2,4(s1)
    80005aac:	fd040593          	addi	a1,s0,-48
    80005ab0:	854a                	mv	a0,s2
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	9f2080e7          	jalr	-1550(ra) # 800044a4 <dirlink>
    80005aba:	04054363          	bltz	a0,80005b00 <sys_link+0x100>
  iunlockput(dp);
    80005abe:	854a                	mv	a0,s2
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	552080e7          	jalr	1362(ra) # 80004012 <iunlockput>
  iput(ip);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	4a0080e7          	jalr	1184(ra) # 80003f6a <iput>
  end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	d30080e7          	jalr	-720(ra) # 80004802 <end_op>
  return 0;
    80005ada:	4781                	li	a5,0
    80005adc:	a085                	j	80005b3c <sys_link+0x13c>
    end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	d24080e7          	jalr	-732(ra) # 80004802 <end_op>
    return -1;
    80005ae6:	57fd                	li	a5,-1
    80005ae8:	a891                	j	80005b3c <sys_link+0x13c>
    iunlockput(ip);
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	526080e7          	jalr	1318(ra) # 80004012 <iunlockput>
    end_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	d0e080e7          	jalr	-754(ra) # 80004802 <end_op>
    return -1;
    80005afc:	57fd                	li	a5,-1
    80005afe:	a83d                	j	80005b3c <sys_link+0x13c>
    iunlockput(dp);
    80005b00:	854a                	mv	a0,s2
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	510080e7          	jalr	1296(ra) # 80004012 <iunlockput>
  ilock(ip);
    80005b0a:	8526                	mv	a0,s1
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	2a4080e7          	jalr	676(ra) # 80003db0 <ilock>
  ip->nlink--;
    80005b14:	04a4d783          	lhu	a5,74(s1)
    80005b18:	37fd                	addiw	a5,a5,-1
    80005b1a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	1c6080e7          	jalr	454(ra) # 80003ce6 <iupdate>
  iunlockput(ip);
    80005b28:	8526                	mv	a0,s1
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	4e8080e7          	jalr	1256(ra) # 80004012 <iunlockput>
  end_op();
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	cd0080e7          	jalr	-816(ra) # 80004802 <end_op>
  return -1;
    80005b3a:	57fd                	li	a5,-1
}
    80005b3c:	853e                	mv	a0,a5
    80005b3e:	70b2                	ld	ra,296(sp)
    80005b40:	7412                	ld	s0,288(sp)
    80005b42:	64f2                	ld	s1,280(sp)
    80005b44:	6952                	ld	s2,272(sp)
    80005b46:	6155                	addi	sp,sp,304
    80005b48:	8082                	ret

0000000080005b4a <sys_unlink>:
{
    80005b4a:	7151                	addi	sp,sp,-240
    80005b4c:	f586                	sd	ra,232(sp)
    80005b4e:	f1a2                	sd	s0,224(sp)
    80005b50:	eda6                	sd	s1,216(sp)
    80005b52:	e9ca                	sd	s2,208(sp)
    80005b54:	e5ce                	sd	s3,200(sp)
    80005b56:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b58:	08000613          	li	a2,128
    80005b5c:	f3040593          	addi	a1,s0,-208
    80005b60:	4501                	li	a0,0
    80005b62:	ffffd097          	auipc	ra,0xffffd
    80005b66:	410080e7          	jalr	1040(ra) # 80002f72 <argstr>
    80005b6a:	18054163          	bltz	a0,80005cec <sys_unlink+0x1a2>
  begin_op();
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	c14080e7          	jalr	-1004(ra) # 80004782 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b76:	fb040593          	addi	a1,s0,-80
    80005b7a:	f3040513          	addi	a0,s0,-208
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	a06080e7          	jalr	-1530(ra) # 80004584 <nameiparent>
    80005b86:	84aa                	mv	s1,a0
    80005b88:	c979                	beqz	a0,80005c5e <sys_unlink+0x114>
  ilock(dp);
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	226080e7          	jalr	550(ra) # 80003db0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b92:	00003597          	auipc	a1,0x3
    80005b96:	c6658593          	addi	a1,a1,-922 # 800087f8 <syscalls+0x2b8>
    80005b9a:	fb040513          	addi	a0,s0,-80
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	6dc080e7          	jalr	1756(ra) # 8000427a <namecmp>
    80005ba6:	14050a63          	beqz	a0,80005cfa <sys_unlink+0x1b0>
    80005baa:	00003597          	auipc	a1,0x3
    80005bae:	c5658593          	addi	a1,a1,-938 # 80008800 <syscalls+0x2c0>
    80005bb2:	fb040513          	addi	a0,s0,-80
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	6c4080e7          	jalr	1732(ra) # 8000427a <namecmp>
    80005bbe:	12050e63          	beqz	a0,80005cfa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bc2:	f2c40613          	addi	a2,s0,-212
    80005bc6:	fb040593          	addi	a1,s0,-80
    80005bca:	8526                	mv	a0,s1
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	6c8080e7          	jalr	1736(ra) # 80004294 <dirlookup>
    80005bd4:	892a                	mv	s2,a0
    80005bd6:	12050263          	beqz	a0,80005cfa <sys_unlink+0x1b0>
  ilock(ip);
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	1d6080e7          	jalr	470(ra) # 80003db0 <ilock>
  if(ip->nlink < 1)
    80005be2:	04a91783          	lh	a5,74(s2)
    80005be6:	08f05263          	blez	a5,80005c6a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005bea:	04491703          	lh	a4,68(s2)
    80005bee:	4785                	li	a5,1
    80005bf0:	08f70563          	beq	a4,a5,80005c7a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bf4:	4641                	li	a2,16
    80005bf6:	4581                	li	a1,0
    80005bf8:	fc040513          	addi	a0,s0,-64
    80005bfc:	ffffb097          	auipc	ra,0xffffb
    80005c00:	0e4080e7          	jalr	228(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c04:	4741                	li	a4,16
    80005c06:	f2c42683          	lw	a3,-212(s0)
    80005c0a:	fc040613          	addi	a2,s0,-64
    80005c0e:	4581                	li	a1,0
    80005c10:	8526                	mv	a0,s1
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	54a080e7          	jalr	1354(ra) # 8000415c <writei>
    80005c1a:	47c1                	li	a5,16
    80005c1c:	0af51563          	bne	a0,a5,80005cc6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c20:	04491703          	lh	a4,68(s2)
    80005c24:	4785                	li	a5,1
    80005c26:	0af70863          	beq	a4,a5,80005cd6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c2a:	8526                	mv	a0,s1
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	3e6080e7          	jalr	998(ra) # 80004012 <iunlockput>
  ip->nlink--;
    80005c34:	04a95783          	lhu	a5,74(s2)
    80005c38:	37fd                	addiw	a5,a5,-1
    80005c3a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c3e:	854a                	mv	a0,s2
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	0a6080e7          	jalr	166(ra) # 80003ce6 <iupdate>
  iunlockput(ip);
    80005c48:	854a                	mv	a0,s2
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	3c8080e7          	jalr	968(ra) # 80004012 <iunlockput>
  end_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	bb0080e7          	jalr	-1104(ra) # 80004802 <end_op>
  return 0;
    80005c5a:	4501                	li	a0,0
    80005c5c:	a84d                	j	80005d0e <sys_unlink+0x1c4>
    end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	ba4080e7          	jalr	-1116(ra) # 80004802 <end_op>
    return -1;
    80005c66:	557d                	li	a0,-1
    80005c68:	a05d                	j	80005d0e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c6a:	00003517          	auipc	a0,0x3
    80005c6e:	bbe50513          	addi	a0,a0,-1090 # 80008828 <syscalls+0x2e8>
    80005c72:	ffffb097          	auipc	ra,0xffffb
    80005c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c7a:	04c92703          	lw	a4,76(s2)
    80005c7e:	02000793          	li	a5,32
    80005c82:	f6e7f9e3          	bgeu	a5,a4,80005bf4 <sys_unlink+0xaa>
    80005c86:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c8a:	4741                	li	a4,16
    80005c8c:	86ce                	mv	a3,s3
    80005c8e:	f1840613          	addi	a2,s0,-232
    80005c92:	4581                	li	a1,0
    80005c94:	854a                	mv	a0,s2
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	3ce080e7          	jalr	974(ra) # 80004064 <readi>
    80005c9e:	47c1                	li	a5,16
    80005ca0:	00f51b63          	bne	a0,a5,80005cb6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ca4:	f1845783          	lhu	a5,-232(s0)
    80005ca8:	e7a1                	bnez	a5,80005cf0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005caa:	29c1                	addiw	s3,s3,16
    80005cac:	04c92783          	lw	a5,76(s2)
    80005cb0:	fcf9ede3          	bltu	s3,a5,80005c8a <sys_unlink+0x140>
    80005cb4:	b781                	j	80005bf4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cb6:	00003517          	auipc	a0,0x3
    80005cba:	b8a50513          	addi	a0,a0,-1142 # 80008840 <syscalls+0x300>
    80005cbe:	ffffb097          	auipc	ra,0xffffb
    80005cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005cc6:	00003517          	auipc	a0,0x3
    80005cca:	b9250513          	addi	a0,a0,-1134 # 80008858 <syscalls+0x318>
    80005cce:	ffffb097          	auipc	ra,0xffffb
    80005cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>
    dp->nlink--;
    80005cd6:	04a4d783          	lhu	a5,74(s1)
    80005cda:	37fd                	addiw	a5,a5,-1
    80005cdc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	004080e7          	jalr	4(ra) # 80003ce6 <iupdate>
    80005cea:	b781                	j	80005c2a <sys_unlink+0xe0>
    return -1;
    80005cec:	557d                	li	a0,-1
    80005cee:	a005                	j	80005d0e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005cf0:	854a                	mv	a0,s2
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	320080e7          	jalr	800(ra) # 80004012 <iunlockput>
  iunlockput(dp);
    80005cfa:	8526                	mv	a0,s1
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	316080e7          	jalr	790(ra) # 80004012 <iunlockput>
  end_op();
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	afe080e7          	jalr	-1282(ra) # 80004802 <end_op>
  return -1;
    80005d0c:	557d                	li	a0,-1
}
    80005d0e:	70ae                	ld	ra,232(sp)
    80005d10:	740e                	ld	s0,224(sp)
    80005d12:	64ee                	ld	s1,216(sp)
    80005d14:	694e                	ld	s2,208(sp)
    80005d16:	69ae                	ld	s3,200(sp)
    80005d18:	616d                	addi	sp,sp,240
    80005d1a:	8082                	ret

0000000080005d1c <sys_open>:

uint64
sys_open(void)
{
    80005d1c:	7131                	addi	sp,sp,-192
    80005d1e:	fd06                	sd	ra,184(sp)
    80005d20:	f922                	sd	s0,176(sp)
    80005d22:	f526                	sd	s1,168(sp)
    80005d24:	f14a                	sd	s2,160(sp)
    80005d26:	ed4e                	sd	s3,152(sp)
    80005d28:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d2a:	08000613          	li	a2,128
    80005d2e:	f5040593          	addi	a1,s0,-176
    80005d32:	4501                	li	a0,0
    80005d34:	ffffd097          	auipc	ra,0xffffd
    80005d38:	23e080e7          	jalr	574(ra) # 80002f72 <argstr>
    return -1;
    80005d3c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d3e:	0c054163          	bltz	a0,80005e00 <sys_open+0xe4>
    80005d42:	f4c40593          	addi	a1,s0,-180
    80005d46:	4505                	li	a0,1
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	1e6080e7          	jalr	486(ra) # 80002f2e <argint>
    80005d50:	0a054863          	bltz	a0,80005e00 <sys_open+0xe4>

  begin_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	a2e080e7          	jalr	-1490(ra) # 80004782 <begin_op>

  if(omode & O_CREATE){
    80005d5c:	f4c42783          	lw	a5,-180(s0)
    80005d60:	2007f793          	andi	a5,a5,512
    80005d64:	cbdd                	beqz	a5,80005e1a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d66:	4681                	li	a3,0
    80005d68:	4601                	li	a2,0
    80005d6a:	4589                	li	a1,2
    80005d6c:	f5040513          	addi	a0,s0,-176
    80005d70:	00000097          	auipc	ra,0x0
    80005d74:	972080e7          	jalr	-1678(ra) # 800056e2 <create>
    80005d78:	892a                	mv	s2,a0
    if(ip == 0){
    80005d7a:	c959                	beqz	a0,80005e10 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d7c:	04491703          	lh	a4,68(s2)
    80005d80:	478d                	li	a5,3
    80005d82:	00f71763          	bne	a4,a5,80005d90 <sys_open+0x74>
    80005d86:	04695703          	lhu	a4,70(s2)
    80005d8a:	47a5                	li	a5,9
    80005d8c:	0ce7ec63          	bltu	a5,a4,80005e64 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	e02080e7          	jalr	-510(ra) # 80004b92 <filealloc>
    80005d98:	89aa                	mv	s3,a0
    80005d9a:	10050263          	beqz	a0,80005e9e <sys_open+0x182>
    80005d9e:	00000097          	auipc	ra,0x0
    80005da2:	902080e7          	jalr	-1790(ra) # 800056a0 <fdalloc>
    80005da6:	84aa                	mv	s1,a0
    80005da8:	0e054663          	bltz	a0,80005e94 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dac:	04491703          	lh	a4,68(s2)
    80005db0:	478d                	li	a5,3
    80005db2:	0cf70463          	beq	a4,a5,80005e7a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005db6:	4789                	li	a5,2
    80005db8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005dbc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005dc0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dc4:	f4c42783          	lw	a5,-180(s0)
    80005dc8:	0017c713          	xori	a4,a5,1
    80005dcc:	8b05                	andi	a4,a4,1
    80005dce:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005dd2:	0037f713          	andi	a4,a5,3
    80005dd6:	00e03733          	snez	a4,a4
    80005dda:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005dde:	4007f793          	andi	a5,a5,1024
    80005de2:	c791                	beqz	a5,80005dee <sys_open+0xd2>
    80005de4:	04491703          	lh	a4,68(s2)
    80005de8:	4789                	li	a5,2
    80005dea:	08f70f63          	beq	a4,a5,80005e88 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005dee:	854a                	mv	a0,s2
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	082080e7          	jalr	130(ra) # 80003e72 <iunlock>
  end_op();
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	a0a080e7          	jalr	-1526(ra) # 80004802 <end_op>

  return fd;
}
    80005e00:	8526                	mv	a0,s1
    80005e02:	70ea                	ld	ra,184(sp)
    80005e04:	744a                	ld	s0,176(sp)
    80005e06:	74aa                	ld	s1,168(sp)
    80005e08:	790a                	ld	s2,160(sp)
    80005e0a:	69ea                	ld	s3,152(sp)
    80005e0c:	6129                	addi	sp,sp,192
    80005e0e:	8082                	ret
      end_op();
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	9f2080e7          	jalr	-1550(ra) # 80004802 <end_op>
      return -1;
    80005e18:	b7e5                	j	80005e00 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e1a:	f5040513          	addi	a0,s0,-176
    80005e1e:	ffffe097          	auipc	ra,0xffffe
    80005e22:	748080e7          	jalr	1864(ra) # 80004566 <namei>
    80005e26:	892a                	mv	s2,a0
    80005e28:	c905                	beqz	a0,80005e58 <sys_open+0x13c>
    ilock(ip);
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	f86080e7          	jalr	-122(ra) # 80003db0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e32:	04491703          	lh	a4,68(s2)
    80005e36:	4785                	li	a5,1
    80005e38:	f4f712e3          	bne	a4,a5,80005d7c <sys_open+0x60>
    80005e3c:	f4c42783          	lw	a5,-180(s0)
    80005e40:	dba1                	beqz	a5,80005d90 <sys_open+0x74>
      iunlockput(ip);
    80005e42:	854a                	mv	a0,s2
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	1ce080e7          	jalr	462(ra) # 80004012 <iunlockput>
      end_op();
    80005e4c:	fffff097          	auipc	ra,0xfffff
    80005e50:	9b6080e7          	jalr	-1610(ra) # 80004802 <end_op>
      return -1;
    80005e54:	54fd                	li	s1,-1
    80005e56:	b76d                	j	80005e00 <sys_open+0xe4>
      end_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	9aa080e7          	jalr	-1622(ra) # 80004802 <end_op>
      return -1;
    80005e60:	54fd                	li	s1,-1
    80005e62:	bf79                	j	80005e00 <sys_open+0xe4>
    iunlockput(ip);
    80005e64:	854a                	mv	a0,s2
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	1ac080e7          	jalr	428(ra) # 80004012 <iunlockput>
    end_op();
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	994080e7          	jalr	-1644(ra) # 80004802 <end_op>
    return -1;
    80005e76:	54fd                	li	s1,-1
    80005e78:	b761                	j	80005e00 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e7a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e7e:	04691783          	lh	a5,70(s2)
    80005e82:	02f99223          	sh	a5,36(s3)
    80005e86:	bf2d                	j	80005dc0 <sys_open+0xa4>
    itrunc(ip);
    80005e88:	854a                	mv	a0,s2
    80005e8a:	ffffe097          	auipc	ra,0xffffe
    80005e8e:	034080e7          	jalr	52(ra) # 80003ebe <itrunc>
    80005e92:	bfb1                	j	80005dee <sys_open+0xd2>
      fileclose(f);
    80005e94:	854e                	mv	a0,s3
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	db8080e7          	jalr	-584(ra) # 80004c4e <fileclose>
    iunlockput(ip);
    80005e9e:	854a                	mv	a0,s2
    80005ea0:	ffffe097          	auipc	ra,0xffffe
    80005ea4:	172080e7          	jalr	370(ra) # 80004012 <iunlockput>
    end_op();
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	95a080e7          	jalr	-1702(ra) # 80004802 <end_op>
    return -1;
    80005eb0:	54fd                	li	s1,-1
    80005eb2:	b7b9                	j	80005e00 <sys_open+0xe4>

0000000080005eb4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eb4:	7175                	addi	sp,sp,-144
    80005eb6:	e506                	sd	ra,136(sp)
    80005eb8:	e122                	sd	s0,128(sp)
    80005eba:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	8c6080e7          	jalr	-1850(ra) # 80004782 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ec4:	08000613          	li	a2,128
    80005ec8:	f7040593          	addi	a1,s0,-144
    80005ecc:	4501                	li	a0,0
    80005ece:	ffffd097          	auipc	ra,0xffffd
    80005ed2:	0a4080e7          	jalr	164(ra) # 80002f72 <argstr>
    80005ed6:	02054963          	bltz	a0,80005f08 <sys_mkdir+0x54>
    80005eda:	4681                	li	a3,0
    80005edc:	4601                	li	a2,0
    80005ede:	4585                	li	a1,1
    80005ee0:	f7040513          	addi	a0,s0,-144
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	7fe080e7          	jalr	2046(ra) # 800056e2 <create>
    80005eec:	cd11                	beqz	a0,80005f08 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	124080e7          	jalr	292(ra) # 80004012 <iunlockput>
  end_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	90c080e7          	jalr	-1780(ra) # 80004802 <end_op>
  return 0;
    80005efe:	4501                	li	a0,0
}
    80005f00:	60aa                	ld	ra,136(sp)
    80005f02:	640a                	ld	s0,128(sp)
    80005f04:	6149                	addi	sp,sp,144
    80005f06:	8082                	ret
    end_op();
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	8fa080e7          	jalr	-1798(ra) # 80004802 <end_op>
    return -1;
    80005f10:	557d                	li	a0,-1
    80005f12:	b7fd                	j	80005f00 <sys_mkdir+0x4c>

0000000080005f14 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f14:	7135                	addi	sp,sp,-160
    80005f16:	ed06                	sd	ra,152(sp)
    80005f18:	e922                	sd	s0,144(sp)
    80005f1a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f1c:	fffff097          	auipc	ra,0xfffff
    80005f20:	866080e7          	jalr	-1946(ra) # 80004782 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f24:	08000613          	li	a2,128
    80005f28:	f7040593          	addi	a1,s0,-144
    80005f2c:	4501                	li	a0,0
    80005f2e:	ffffd097          	auipc	ra,0xffffd
    80005f32:	044080e7          	jalr	68(ra) # 80002f72 <argstr>
    80005f36:	04054a63          	bltz	a0,80005f8a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f3a:	f6c40593          	addi	a1,s0,-148
    80005f3e:	4505                	li	a0,1
    80005f40:	ffffd097          	auipc	ra,0xffffd
    80005f44:	fee080e7          	jalr	-18(ra) # 80002f2e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f48:	04054163          	bltz	a0,80005f8a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f4c:	f6840593          	addi	a1,s0,-152
    80005f50:	4509                	li	a0,2
    80005f52:	ffffd097          	auipc	ra,0xffffd
    80005f56:	fdc080e7          	jalr	-36(ra) # 80002f2e <argint>
     argint(1, &major) < 0 ||
    80005f5a:	02054863          	bltz	a0,80005f8a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f5e:	f6841683          	lh	a3,-152(s0)
    80005f62:	f6c41603          	lh	a2,-148(s0)
    80005f66:	458d                	li	a1,3
    80005f68:	f7040513          	addi	a0,s0,-144
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	776080e7          	jalr	1910(ra) # 800056e2 <create>
     argint(2, &minor) < 0 ||
    80005f74:	c919                	beqz	a0,80005f8a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	09c080e7          	jalr	156(ra) # 80004012 <iunlockput>
  end_op();
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	884080e7          	jalr	-1916(ra) # 80004802 <end_op>
  return 0;
    80005f86:	4501                	li	a0,0
    80005f88:	a031                	j	80005f94 <sys_mknod+0x80>
    end_op();
    80005f8a:	fffff097          	auipc	ra,0xfffff
    80005f8e:	878080e7          	jalr	-1928(ra) # 80004802 <end_op>
    return -1;
    80005f92:	557d                	li	a0,-1
}
    80005f94:	60ea                	ld	ra,152(sp)
    80005f96:	644a                	ld	s0,144(sp)
    80005f98:	610d                	addi	sp,sp,160
    80005f9a:	8082                	ret

0000000080005f9c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f9c:	7135                	addi	sp,sp,-160
    80005f9e:	ed06                	sd	ra,152(sp)
    80005fa0:	e922                	sd	s0,144(sp)
    80005fa2:	e526                	sd	s1,136(sp)
    80005fa4:	e14a                	sd	s2,128(sp)
    80005fa6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	a08080e7          	jalr	-1528(ra) # 800019b0 <myproc>
    80005fb0:	892a                	mv	s2,a0
  
  begin_op();
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	7d0080e7          	jalr	2000(ra) # 80004782 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fba:	08000613          	li	a2,128
    80005fbe:	f6040593          	addi	a1,s0,-160
    80005fc2:	4501                	li	a0,0
    80005fc4:	ffffd097          	auipc	ra,0xffffd
    80005fc8:	fae080e7          	jalr	-82(ra) # 80002f72 <argstr>
    80005fcc:	04054b63          	bltz	a0,80006022 <sys_chdir+0x86>
    80005fd0:	f6040513          	addi	a0,s0,-160
    80005fd4:	ffffe097          	auipc	ra,0xffffe
    80005fd8:	592080e7          	jalr	1426(ra) # 80004566 <namei>
    80005fdc:	84aa                	mv	s1,a0
    80005fde:	c131                	beqz	a0,80006022 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fe0:	ffffe097          	auipc	ra,0xffffe
    80005fe4:	dd0080e7          	jalr	-560(ra) # 80003db0 <ilock>
  if(ip->type != T_DIR){
    80005fe8:	04449703          	lh	a4,68(s1)
    80005fec:	4785                	li	a5,1
    80005fee:	04f71063          	bne	a4,a5,8000602e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ff2:	8526                	mv	a0,s1
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	e7e080e7          	jalr	-386(ra) # 80003e72 <iunlock>
  iput(p->cwd);
    80005ffc:	15093503          	ld	a0,336(s2)
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	f6a080e7          	jalr	-150(ra) # 80003f6a <iput>
  end_op();
    80006008:	ffffe097          	auipc	ra,0xffffe
    8000600c:	7fa080e7          	jalr	2042(ra) # 80004802 <end_op>
  p->cwd = ip;
    80006010:	14993823          	sd	s1,336(s2)
  return 0;
    80006014:	4501                	li	a0,0
}
    80006016:	60ea                	ld	ra,152(sp)
    80006018:	644a                	ld	s0,144(sp)
    8000601a:	64aa                	ld	s1,136(sp)
    8000601c:	690a                	ld	s2,128(sp)
    8000601e:	610d                	addi	sp,sp,160
    80006020:	8082                	ret
    end_op();
    80006022:	ffffe097          	auipc	ra,0xffffe
    80006026:	7e0080e7          	jalr	2016(ra) # 80004802 <end_op>
    return -1;
    8000602a:	557d                	li	a0,-1
    8000602c:	b7ed                	j	80006016 <sys_chdir+0x7a>
    iunlockput(ip);
    8000602e:	8526                	mv	a0,s1
    80006030:	ffffe097          	auipc	ra,0xffffe
    80006034:	fe2080e7          	jalr	-30(ra) # 80004012 <iunlockput>
    end_op();
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	7ca080e7          	jalr	1994(ra) # 80004802 <end_op>
    return -1;
    80006040:	557d                	li	a0,-1
    80006042:	bfd1                	j	80006016 <sys_chdir+0x7a>

0000000080006044 <sys_exec>:

uint64
sys_exec(void)
{
    80006044:	7145                	addi	sp,sp,-464
    80006046:	e786                	sd	ra,456(sp)
    80006048:	e3a2                	sd	s0,448(sp)
    8000604a:	ff26                	sd	s1,440(sp)
    8000604c:	fb4a                	sd	s2,432(sp)
    8000604e:	f74e                	sd	s3,424(sp)
    80006050:	f352                	sd	s4,416(sp)
    80006052:	ef56                	sd	s5,408(sp)
    80006054:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006056:	08000613          	li	a2,128
    8000605a:	f4040593          	addi	a1,s0,-192
    8000605e:	4501                	li	a0,0
    80006060:	ffffd097          	auipc	ra,0xffffd
    80006064:	f12080e7          	jalr	-238(ra) # 80002f72 <argstr>
    return -1;
    80006068:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000606a:	0c054a63          	bltz	a0,8000613e <sys_exec+0xfa>
    8000606e:	e3840593          	addi	a1,s0,-456
    80006072:	4505                	li	a0,1
    80006074:	ffffd097          	auipc	ra,0xffffd
    80006078:	edc080e7          	jalr	-292(ra) # 80002f50 <argaddr>
    8000607c:	0c054163          	bltz	a0,8000613e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006080:	10000613          	li	a2,256
    80006084:	4581                	li	a1,0
    80006086:	e4040513          	addi	a0,s0,-448
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	c56080e7          	jalr	-938(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006092:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006096:	89a6                	mv	s3,s1
    80006098:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000609a:	02000a13          	li	s4,32
    8000609e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060a2:	00391513          	slli	a0,s2,0x3
    800060a6:	e3040593          	addi	a1,s0,-464
    800060aa:	e3843783          	ld	a5,-456(s0)
    800060ae:	953e                	add	a0,a0,a5
    800060b0:	ffffd097          	auipc	ra,0xffffd
    800060b4:	de4080e7          	jalr	-540(ra) # 80002e94 <fetchaddr>
    800060b8:	02054a63          	bltz	a0,800060ec <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060bc:	e3043783          	ld	a5,-464(s0)
    800060c0:	c3b9                	beqz	a5,80006106 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	a32080e7          	jalr	-1486(ra) # 80000af4 <kalloc>
    800060ca:	85aa                	mv	a1,a0
    800060cc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060d0:	cd11                	beqz	a0,800060ec <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060d2:	6605                	lui	a2,0x1
    800060d4:	e3043503          	ld	a0,-464(s0)
    800060d8:	ffffd097          	auipc	ra,0xffffd
    800060dc:	e0e080e7          	jalr	-498(ra) # 80002ee6 <fetchstr>
    800060e0:	00054663          	bltz	a0,800060ec <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800060e4:	0905                	addi	s2,s2,1
    800060e6:	09a1                	addi	s3,s3,8
    800060e8:	fb491be3          	bne	s2,s4,8000609e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ec:	10048913          	addi	s2,s1,256
    800060f0:	6088                	ld	a0,0(s1)
    800060f2:	c529                	beqz	a0,8000613c <sys_exec+0xf8>
    kfree(argv[i]);
    800060f4:	ffffb097          	auipc	ra,0xffffb
    800060f8:	904080e7          	jalr	-1788(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060fc:	04a1                	addi	s1,s1,8
    800060fe:	ff2499e3          	bne	s1,s2,800060f0 <sys_exec+0xac>
  return -1;
    80006102:	597d                	li	s2,-1
    80006104:	a82d                	j	8000613e <sys_exec+0xfa>
      argv[i] = 0;
    80006106:	0a8e                	slli	s5,s5,0x3
    80006108:	fc040793          	addi	a5,s0,-64
    8000610c:	9abe                	add	s5,s5,a5
    8000610e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006112:	e4040593          	addi	a1,s0,-448
    80006116:	f4040513          	addi	a0,s0,-192
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	194080e7          	jalr	404(ra) # 800052ae <exec>
    80006122:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006124:	10048993          	addi	s3,s1,256
    80006128:	6088                	ld	a0,0(s1)
    8000612a:	c911                	beqz	a0,8000613e <sys_exec+0xfa>
    kfree(argv[i]);
    8000612c:	ffffb097          	auipc	ra,0xffffb
    80006130:	8cc080e7          	jalr	-1844(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006134:	04a1                	addi	s1,s1,8
    80006136:	ff3499e3          	bne	s1,s3,80006128 <sys_exec+0xe4>
    8000613a:	a011                	j	8000613e <sys_exec+0xfa>
  return -1;
    8000613c:	597d                	li	s2,-1
}
    8000613e:	854a                	mv	a0,s2
    80006140:	60be                	ld	ra,456(sp)
    80006142:	641e                	ld	s0,448(sp)
    80006144:	74fa                	ld	s1,440(sp)
    80006146:	795a                	ld	s2,432(sp)
    80006148:	79ba                	ld	s3,424(sp)
    8000614a:	7a1a                	ld	s4,416(sp)
    8000614c:	6afa                	ld	s5,408(sp)
    8000614e:	6179                	addi	sp,sp,464
    80006150:	8082                	ret

0000000080006152 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006152:	7139                	addi	sp,sp,-64
    80006154:	fc06                	sd	ra,56(sp)
    80006156:	f822                	sd	s0,48(sp)
    80006158:	f426                	sd	s1,40(sp)
    8000615a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000615c:	ffffc097          	auipc	ra,0xffffc
    80006160:	854080e7          	jalr	-1964(ra) # 800019b0 <myproc>
    80006164:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006166:	fd840593          	addi	a1,s0,-40
    8000616a:	4501                	li	a0,0
    8000616c:	ffffd097          	auipc	ra,0xffffd
    80006170:	de4080e7          	jalr	-540(ra) # 80002f50 <argaddr>
    return -1;
    80006174:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006176:	0e054063          	bltz	a0,80006256 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000617a:	fc840593          	addi	a1,s0,-56
    8000617e:	fd040513          	addi	a0,s0,-48
    80006182:	fffff097          	auipc	ra,0xfffff
    80006186:	dfc080e7          	jalr	-516(ra) # 80004f7e <pipealloc>
    return -1;
    8000618a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000618c:	0c054563          	bltz	a0,80006256 <sys_pipe+0x104>
  fd0 = -1;
    80006190:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006194:	fd043503          	ld	a0,-48(s0)
    80006198:	fffff097          	auipc	ra,0xfffff
    8000619c:	508080e7          	jalr	1288(ra) # 800056a0 <fdalloc>
    800061a0:	fca42223          	sw	a0,-60(s0)
    800061a4:	08054c63          	bltz	a0,8000623c <sys_pipe+0xea>
    800061a8:	fc843503          	ld	a0,-56(s0)
    800061ac:	fffff097          	auipc	ra,0xfffff
    800061b0:	4f4080e7          	jalr	1268(ra) # 800056a0 <fdalloc>
    800061b4:	fca42023          	sw	a0,-64(s0)
    800061b8:	06054863          	bltz	a0,80006228 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061bc:	4691                	li	a3,4
    800061be:	fc440613          	addi	a2,s0,-60
    800061c2:	fd843583          	ld	a1,-40(s0)
    800061c6:	68a8                	ld	a0,80(s1)
    800061c8:	ffffb097          	auipc	ra,0xffffb
    800061cc:	4aa080e7          	jalr	1194(ra) # 80001672 <copyout>
    800061d0:	02054063          	bltz	a0,800061f0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061d4:	4691                	li	a3,4
    800061d6:	fc040613          	addi	a2,s0,-64
    800061da:	fd843583          	ld	a1,-40(s0)
    800061de:	0591                	addi	a1,a1,4
    800061e0:	68a8                	ld	a0,80(s1)
    800061e2:	ffffb097          	auipc	ra,0xffffb
    800061e6:	490080e7          	jalr	1168(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061ea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061ec:	06055563          	bgez	a0,80006256 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800061f0:	fc442783          	lw	a5,-60(s0)
    800061f4:	07e9                	addi	a5,a5,26
    800061f6:	078e                	slli	a5,a5,0x3
    800061f8:	97a6                	add	a5,a5,s1
    800061fa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061fe:	fc042503          	lw	a0,-64(s0)
    80006202:	0569                	addi	a0,a0,26
    80006204:	050e                	slli	a0,a0,0x3
    80006206:	9526                	add	a0,a0,s1
    80006208:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000620c:	fd043503          	ld	a0,-48(s0)
    80006210:	fffff097          	auipc	ra,0xfffff
    80006214:	a3e080e7          	jalr	-1474(ra) # 80004c4e <fileclose>
    fileclose(wf);
    80006218:	fc843503          	ld	a0,-56(s0)
    8000621c:	fffff097          	auipc	ra,0xfffff
    80006220:	a32080e7          	jalr	-1486(ra) # 80004c4e <fileclose>
    return -1;
    80006224:	57fd                	li	a5,-1
    80006226:	a805                	j	80006256 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006228:	fc442783          	lw	a5,-60(s0)
    8000622c:	0007c863          	bltz	a5,8000623c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006230:	01a78513          	addi	a0,a5,26
    80006234:	050e                	slli	a0,a0,0x3
    80006236:	9526                	add	a0,a0,s1
    80006238:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000623c:	fd043503          	ld	a0,-48(s0)
    80006240:	fffff097          	auipc	ra,0xfffff
    80006244:	a0e080e7          	jalr	-1522(ra) # 80004c4e <fileclose>
    fileclose(wf);
    80006248:	fc843503          	ld	a0,-56(s0)
    8000624c:	fffff097          	auipc	ra,0xfffff
    80006250:	a02080e7          	jalr	-1534(ra) # 80004c4e <fileclose>
    return -1;
    80006254:	57fd                	li	a5,-1
}
    80006256:	853e                	mv	a0,a5
    80006258:	70e2                	ld	ra,56(sp)
    8000625a:	7442                	ld	s0,48(sp)
    8000625c:	74a2                	ld	s1,40(sp)
    8000625e:	6121                	addi	sp,sp,64
    80006260:	8082                	ret
	...

0000000080006270 <kernelvec>:
    80006270:	7111                	addi	sp,sp,-256
    80006272:	e006                	sd	ra,0(sp)
    80006274:	e40a                	sd	sp,8(sp)
    80006276:	e80e                	sd	gp,16(sp)
    80006278:	ec12                	sd	tp,24(sp)
    8000627a:	f016                	sd	t0,32(sp)
    8000627c:	f41a                	sd	t1,40(sp)
    8000627e:	f81e                	sd	t2,48(sp)
    80006280:	fc22                	sd	s0,56(sp)
    80006282:	e0a6                	sd	s1,64(sp)
    80006284:	e4aa                	sd	a0,72(sp)
    80006286:	e8ae                	sd	a1,80(sp)
    80006288:	ecb2                	sd	a2,88(sp)
    8000628a:	f0b6                	sd	a3,96(sp)
    8000628c:	f4ba                	sd	a4,104(sp)
    8000628e:	f8be                	sd	a5,112(sp)
    80006290:	fcc2                	sd	a6,120(sp)
    80006292:	e146                	sd	a7,128(sp)
    80006294:	e54a                	sd	s2,136(sp)
    80006296:	e94e                	sd	s3,144(sp)
    80006298:	ed52                	sd	s4,152(sp)
    8000629a:	f156                	sd	s5,160(sp)
    8000629c:	f55a                	sd	s6,168(sp)
    8000629e:	f95e                	sd	s7,176(sp)
    800062a0:	fd62                	sd	s8,184(sp)
    800062a2:	e1e6                	sd	s9,192(sp)
    800062a4:	e5ea                	sd	s10,200(sp)
    800062a6:	e9ee                	sd	s11,208(sp)
    800062a8:	edf2                	sd	t3,216(sp)
    800062aa:	f1f6                	sd	t4,224(sp)
    800062ac:	f5fa                	sd	t5,232(sp)
    800062ae:	f9fe                	sd	t6,240(sp)
    800062b0:	a91fc0ef          	jal	ra,80002d40 <kerneltrap>
    800062b4:	6082                	ld	ra,0(sp)
    800062b6:	6122                	ld	sp,8(sp)
    800062b8:	61c2                	ld	gp,16(sp)
    800062ba:	7282                	ld	t0,32(sp)
    800062bc:	7322                	ld	t1,40(sp)
    800062be:	73c2                	ld	t2,48(sp)
    800062c0:	7462                	ld	s0,56(sp)
    800062c2:	6486                	ld	s1,64(sp)
    800062c4:	6526                	ld	a0,72(sp)
    800062c6:	65c6                	ld	a1,80(sp)
    800062c8:	6666                	ld	a2,88(sp)
    800062ca:	7686                	ld	a3,96(sp)
    800062cc:	7726                	ld	a4,104(sp)
    800062ce:	77c6                	ld	a5,112(sp)
    800062d0:	7866                	ld	a6,120(sp)
    800062d2:	688a                	ld	a7,128(sp)
    800062d4:	692a                	ld	s2,136(sp)
    800062d6:	69ca                	ld	s3,144(sp)
    800062d8:	6a6a                	ld	s4,152(sp)
    800062da:	7a8a                	ld	s5,160(sp)
    800062dc:	7b2a                	ld	s6,168(sp)
    800062de:	7bca                	ld	s7,176(sp)
    800062e0:	7c6a                	ld	s8,184(sp)
    800062e2:	6c8e                	ld	s9,192(sp)
    800062e4:	6d2e                	ld	s10,200(sp)
    800062e6:	6dce                	ld	s11,208(sp)
    800062e8:	6e6e                	ld	t3,216(sp)
    800062ea:	7e8e                	ld	t4,224(sp)
    800062ec:	7f2e                	ld	t5,232(sp)
    800062ee:	7fce                	ld	t6,240(sp)
    800062f0:	6111                	addi	sp,sp,256
    800062f2:	10200073          	sret
    800062f6:	00000013          	nop
    800062fa:	00000013          	nop
    800062fe:	0001                	nop

0000000080006300 <timervec>:
    80006300:	34051573          	csrrw	a0,mscratch,a0
    80006304:	e10c                	sd	a1,0(a0)
    80006306:	e510                	sd	a2,8(a0)
    80006308:	e914                	sd	a3,16(a0)
    8000630a:	6d0c                	ld	a1,24(a0)
    8000630c:	7110                	ld	a2,32(a0)
    8000630e:	6194                	ld	a3,0(a1)
    80006310:	96b2                	add	a3,a3,a2
    80006312:	e194                	sd	a3,0(a1)
    80006314:	4589                	li	a1,2
    80006316:	14459073          	csrw	sip,a1
    8000631a:	6914                	ld	a3,16(a0)
    8000631c:	6510                	ld	a2,8(a0)
    8000631e:	610c                	ld	a1,0(a0)
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	30200073          	mret
	...

000000008000632a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000632a:	1141                	addi	sp,sp,-16
    8000632c:	e422                	sd	s0,8(sp)
    8000632e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006330:	0c0007b7          	lui	a5,0xc000
    80006334:	4705                	li	a4,1
    80006336:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006338:	c3d8                	sw	a4,4(a5)
}
    8000633a:	6422                	ld	s0,8(sp)
    8000633c:	0141                	addi	sp,sp,16
    8000633e:	8082                	ret

0000000080006340 <plicinithart>:

void
plicinithart(void)
{
    80006340:	1141                	addi	sp,sp,-16
    80006342:	e406                	sd	ra,8(sp)
    80006344:	e022                	sd	s0,0(sp)
    80006346:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	63c080e7          	jalr	1596(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006350:	0085171b          	slliw	a4,a0,0x8
    80006354:	0c0027b7          	lui	a5,0xc002
    80006358:	97ba                	add	a5,a5,a4
    8000635a:	40200713          	li	a4,1026
    8000635e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006362:	00d5151b          	slliw	a0,a0,0xd
    80006366:	0c2017b7          	lui	a5,0xc201
    8000636a:	953e                	add	a0,a0,a5
    8000636c:	00052023          	sw	zero,0(a0)
}
    80006370:	60a2                	ld	ra,8(sp)
    80006372:	6402                	ld	s0,0(sp)
    80006374:	0141                	addi	sp,sp,16
    80006376:	8082                	ret

0000000080006378 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006378:	1141                	addi	sp,sp,-16
    8000637a:	e406                	sd	ra,8(sp)
    8000637c:	e022                	sd	s0,0(sp)
    8000637e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	604080e7          	jalr	1540(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006388:	00d5179b          	slliw	a5,a0,0xd
    8000638c:	0c201537          	lui	a0,0xc201
    80006390:	953e                	add	a0,a0,a5
  return irq;
}
    80006392:	4148                	lw	a0,4(a0)
    80006394:	60a2                	ld	ra,8(sp)
    80006396:	6402                	ld	s0,0(sp)
    80006398:	0141                	addi	sp,sp,16
    8000639a:	8082                	ret

000000008000639c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	1000                	addi	s0,sp,32
    800063a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063a8:	ffffb097          	auipc	ra,0xffffb
    800063ac:	5dc080e7          	jalr	1500(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063b0:	00d5151b          	slliw	a0,a0,0xd
    800063b4:	0c2017b7          	lui	a5,0xc201
    800063b8:	97aa                	add	a5,a5,a0
    800063ba:	c3c4                	sw	s1,4(a5)
}
    800063bc:	60e2                	ld	ra,24(sp)
    800063be:	6442                	ld	s0,16(sp)
    800063c0:	64a2                	ld	s1,8(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret

00000000800063c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063c6:	1141                	addi	sp,sp,-16
    800063c8:	e406                	sd	ra,8(sp)
    800063ca:	e022                	sd	s0,0(sp)
    800063cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ce:	479d                	li	a5,7
    800063d0:	06a7c963          	blt	a5,a0,80006442 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800063d4:	0001e797          	auipc	a5,0x1e
    800063d8:	c2c78793          	addi	a5,a5,-980 # 80024000 <disk>
    800063dc:	00a78733          	add	a4,a5,a0
    800063e0:	6789                	lui	a5,0x2
    800063e2:	97ba                	add	a5,a5,a4
    800063e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800063e8:	e7ad                	bnez	a5,80006452 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063ea:	00451793          	slli	a5,a0,0x4
    800063ee:	00020717          	auipc	a4,0x20
    800063f2:	c1270713          	addi	a4,a4,-1006 # 80026000 <disk+0x2000>
    800063f6:	6314                	ld	a3,0(a4)
    800063f8:	96be                	add	a3,a3,a5
    800063fa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800063fe:	6314                	ld	a3,0(a4)
    80006400:	96be                	add	a3,a3,a5
    80006402:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006406:	6314                	ld	a3,0(a4)
    80006408:	96be                	add	a3,a3,a5
    8000640a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000640e:	6318                	ld	a4,0(a4)
    80006410:	97ba                	add	a5,a5,a4
    80006412:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006416:	0001e797          	auipc	a5,0x1e
    8000641a:	bea78793          	addi	a5,a5,-1046 # 80024000 <disk>
    8000641e:	97aa                	add	a5,a5,a0
    80006420:	6509                	lui	a0,0x2
    80006422:	953e                	add	a0,a0,a5
    80006424:	4785                	li	a5,1
    80006426:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000642a:	00020517          	auipc	a0,0x20
    8000642e:	bee50513          	addi	a0,a0,-1042 # 80026018 <disk+0x2018>
    80006432:	ffffc097          	auipc	ra,0xffffc
    80006436:	d50080e7          	jalr	-688(ra) # 80002182 <wakeup>
}
    8000643a:	60a2                	ld	ra,8(sp)
    8000643c:	6402                	ld	s0,0(sp)
    8000643e:	0141                	addi	sp,sp,16
    80006440:	8082                	ret
    panic("free_desc 1");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	42650513          	addi	a0,a0,1062 # 80008868 <syscalls+0x328>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0f4080e7          	jalr	244(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	42650513          	addi	a0,a0,1062 # 80008878 <syscalls+0x338>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>

0000000080006462 <virtio_disk_init>:
{
    80006462:	1101                	addi	sp,sp,-32
    80006464:	ec06                	sd	ra,24(sp)
    80006466:	e822                	sd	s0,16(sp)
    80006468:	e426                	sd	s1,8(sp)
    8000646a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000646c:	00002597          	auipc	a1,0x2
    80006470:	41c58593          	addi	a1,a1,1052 # 80008888 <syscalls+0x348>
    80006474:	00020517          	auipc	a0,0x20
    80006478:	cb450513          	addi	a0,a0,-844 # 80026128 <disk+0x2128>
    8000647c:	ffffa097          	auipc	ra,0xffffa
    80006480:	6d8080e7          	jalr	1752(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006484:	100017b7          	lui	a5,0x10001
    80006488:	4398                	lw	a4,0(a5)
    8000648a:	2701                	sext.w	a4,a4
    8000648c:	747277b7          	lui	a5,0x74727
    80006490:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006494:	0ef71163          	bne	a4,a5,80006576 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006498:	100017b7          	lui	a5,0x10001
    8000649c:	43dc                	lw	a5,4(a5)
    8000649e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064a0:	4705                	li	a4,1
    800064a2:	0ce79a63          	bne	a5,a4,80006576 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064a6:	100017b7          	lui	a5,0x10001
    800064aa:	479c                	lw	a5,8(a5)
    800064ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064ae:	4709                	li	a4,2
    800064b0:	0ce79363          	bne	a5,a4,80006576 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	47d8                	lw	a4,12(a5)
    800064ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064bc:	554d47b7          	lui	a5,0x554d4
    800064c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064c4:	0af71963          	bne	a4,a5,80006576 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064c8:	100017b7          	lui	a5,0x10001
    800064cc:	4705                	li	a4,1
    800064ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064d0:	470d                	li	a4,3
    800064d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064d6:	c7ffe737          	lui	a4,0xc7ffe
    800064da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800064de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064e0:	2701                	sext.w	a4,a4
    800064e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e4:	472d                	li	a4,11
    800064e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e8:	473d                	li	a4,15
    800064ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800064ec:	6705                	lui	a4,0x1
    800064ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064f4:	5bdc                	lw	a5,52(a5)
    800064f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800064f8:	c7d9                	beqz	a5,80006586 <virtio_disk_init+0x124>
  if(max < NUM)
    800064fa:	471d                	li	a4,7
    800064fc:	08f77d63          	bgeu	a4,a5,80006596 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006500:	100014b7          	lui	s1,0x10001
    80006504:	47a1                	li	a5,8
    80006506:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006508:	6609                	lui	a2,0x2
    8000650a:	4581                	li	a1,0
    8000650c:	0001e517          	auipc	a0,0x1e
    80006510:	af450513          	addi	a0,a0,-1292 # 80024000 <disk>
    80006514:	ffffa097          	auipc	ra,0xffffa
    80006518:	7cc080e7          	jalr	1996(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000651c:	0001e717          	auipc	a4,0x1e
    80006520:	ae470713          	addi	a4,a4,-1308 # 80024000 <disk>
    80006524:	00c75793          	srli	a5,a4,0xc
    80006528:	2781                	sext.w	a5,a5
    8000652a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000652c:	00020797          	auipc	a5,0x20
    80006530:	ad478793          	addi	a5,a5,-1324 # 80026000 <disk+0x2000>
    80006534:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006536:	0001e717          	auipc	a4,0x1e
    8000653a:	b4a70713          	addi	a4,a4,-1206 # 80024080 <disk+0x80>
    8000653e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006540:	0001f717          	auipc	a4,0x1f
    80006544:	ac070713          	addi	a4,a4,-1344 # 80025000 <disk+0x1000>
    80006548:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000654a:	4705                	li	a4,1
    8000654c:	00e78c23          	sb	a4,24(a5)
    80006550:	00e78ca3          	sb	a4,25(a5)
    80006554:	00e78d23          	sb	a4,26(a5)
    80006558:	00e78da3          	sb	a4,27(a5)
    8000655c:	00e78e23          	sb	a4,28(a5)
    80006560:	00e78ea3          	sb	a4,29(a5)
    80006564:	00e78f23          	sb	a4,30(a5)
    80006568:	00e78fa3          	sb	a4,31(a5)
}
    8000656c:	60e2                	ld	ra,24(sp)
    8000656e:	6442                	ld	s0,16(sp)
    80006570:	64a2                	ld	s1,8(sp)
    80006572:	6105                	addi	sp,sp,32
    80006574:	8082                	ret
    panic("could not find virtio disk");
    80006576:	00002517          	auipc	a0,0x2
    8000657a:	32250513          	addi	a0,a0,802 # 80008898 <syscalls+0x358>
    8000657e:	ffffa097          	auipc	ra,0xffffa
    80006582:	fc0080e7          	jalr	-64(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006586:	00002517          	auipc	a0,0x2
    8000658a:	33250513          	addi	a0,a0,818 # 800088b8 <syscalls+0x378>
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	fb0080e7          	jalr	-80(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006596:	00002517          	auipc	a0,0x2
    8000659a:	34250513          	addi	a0,a0,834 # 800088d8 <syscalls+0x398>
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	fa0080e7          	jalr	-96(ra) # 8000053e <panic>

00000000800065a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065a6:	7159                	addi	sp,sp,-112
    800065a8:	f486                	sd	ra,104(sp)
    800065aa:	f0a2                	sd	s0,96(sp)
    800065ac:	eca6                	sd	s1,88(sp)
    800065ae:	e8ca                	sd	s2,80(sp)
    800065b0:	e4ce                	sd	s3,72(sp)
    800065b2:	e0d2                	sd	s4,64(sp)
    800065b4:	fc56                	sd	s5,56(sp)
    800065b6:	f85a                	sd	s6,48(sp)
    800065b8:	f45e                	sd	s7,40(sp)
    800065ba:	f062                	sd	s8,32(sp)
    800065bc:	ec66                	sd	s9,24(sp)
    800065be:	e86a                	sd	s10,16(sp)
    800065c0:	1880                	addi	s0,sp,112
    800065c2:	892a                	mv	s2,a0
    800065c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065c6:	00c52c83          	lw	s9,12(a0)
    800065ca:	001c9c9b          	slliw	s9,s9,0x1
    800065ce:	1c82                	slli	s9,s9,0x20
    800065d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065d4:	00020517          	auipc	a0,0x20
    800065d8:	b5450513          	addi	a0,a0,-1196 # 80026128 <disk+0x2128>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	608080e7          	jalr	1544(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800065e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800065e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800065e8:	0001eb97          	auipc	s7,0x1e
    800065ec:	a18b8b93          	addi	s7,s7,-1512 # 80024000 <disk>
    800065f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800065f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800065f4:	8a4e                	mv	s4,s3
    800065f6:	a051                	j	8000667a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800065f8:	00fb86b3          	add	a3,s7,a5
    800065fc:	96da                	add	a3,a3,s6
    800065fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006602:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006604:	0207c563          	bltz	a5,8000662e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006608:	2485                	addiw	s1,s1,1
    8000660a:	0711                	addi	a4,a4,4
    8000660c:	25548063          	beq	s1,s5,8000684c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006610:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006612:	00020697          	auipc	a3,0x20
    80006616:	a0668693          	addi	a3,a3,-1530 # 80026018 <disk+0x2018>
    8000661a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000661c:	0006c583          	lbu	a1,0(a3)
    80006620:	fde1                	bnez	a1,800065f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006622:	2785                	addiw	a5,a5,1
    80006624:	0685                	addi	a3,a3,1
    80006626:	ff879be3          	bne	a5,s8,8000661c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000662a:	57fd                	li	a5,-1
    8000662c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000662e:	02905a63          	blez	s1,80006662 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006632:	f9042503          	lw	a0,-112(s0)
    80006636:	00000097          	auipc	ra,0x0
    8000663a:	d90080e7          	jalr	-624(ra) # 800063c6 <free_desc>
      for(int j = 0; j < i; j++)
    8000663e:	4785                	li	a5,1
    80006640:	0297d163          	bge	a5,s1,80006662 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006644:	f9442503          	lw	a0,-108(s0)
    80006648:	00000097          	auipc	ra,0x0
    8000664c:	d7e080e7          	jalr	-642(ra) # 800063c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006650:	4789                	li	a5,2
    80006652:	0097d863          	bge	a5,s1,80006662 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006656:	f9842503          	lw	a0,-104(s0)
    8000665a:	00000097          	auipc	ra,0x0
    8000665e:	d6c080e7          	jalr	-660(ra) # 800063c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006662:	00020597          	auipc	a1,0x20
    80006666:	ac658593          	addi	a1,a1,-1338 # 80026128 <disk+0x2128>
    8000666a:	00020517          	auipc	a0,0x20
    8000666e:	9ae50513          	addi	a0,a0,-1618 # 80026018 <disk+0x2018>
    80006672:	ffffc097          	auipc	ra,0xffffc
    80006676:	984080e7          	jalr	-1660(ra) # 80001ff6 <sleep>
  for(int i = 0; i < 3; i++){
    8000667a:	f9040713          	addi	a4,s0,-112
    8000667e:	84ce                	mv	s1,s3
    80006680:	bf41                	j	80006610 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006682:	20058713          	addi	a4,a1,512
    80006686:	00471693          	slli	a3,a4,0x4
    8000668a:	0001e717          	auipc	a4,0x1e
    8000668e:	97670713          	addi	a4,a4,-1674 # 80024000 <disk>
    80006692:	9736                	add	a4,a4,a3
    80006694:	4685                	li	a3,1
    80006696:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000669a:	20058713          	addi	a4,a1,512
    8000669e:	00471693          	slli	a3,a4,0x4
    800066a2:	0001e717          	auipc	a4,0x1e
    800066a6:	95e70713          	addi	a4,a4,-1698 # 80024000 <disk>
    800066aa:	9736                	add	a4,a4,a3
    800066ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066b4:	7679                	lui	a2,0xffffe
    800066b6:	963e                	add	a2,a2,a5
    800066b8:	00020697          	auipc	a3,0x20
    800066bc:	94868693          	addi	a3,a3,-1720 # 80026000 <disk+0x2000>
    800066c0:	6298                	ld	a4,0(a3)
    800066c2:	9732                	add	a4,a4,a2
    800066c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066c6:	6298                	ld	a4,0(a3)
    800066c8:	9732                	add	a4,a4,a2
    800066ca:	4541                	li	a0,16
    800066cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066ce:	6298                	ld	a4,0(a3)
    800066d0:	9732                	add	a4,a4,a2
    800066d2:	4505                	li	a0,1
    800066d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800066d8:	f9442703          	lw	a4,-108(s0)
    800066dc:	6288                	ld	a0,0(a3)
    800066de:	962a                	add	a2,a2,a0
    800066e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066e4:	0712                	slli	a4,a4,0x4
    800066e6:	6290                	ld	a2,0(a3)
    800066e8:	963a                	add	a2,a2,a4
    800066ea:	05890513          	addi	a0,s2,88
    800066ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800066f0:	6294                	ld	a3,0(a3)
    800066f2:	96ba                	add	a3,a3,a4
    800066f4:	40000613          	li	a2,1024
    800066f8:	c690                	sw	a2,8(a3)
  if(write)
    800066fa:	140d0063          	beqz	s10,8000683a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800066fe:	00020697          	auipc	a3,0x20
    80006702:	9026b683          	ld	a3,-1790(a3) # 80026000 <disk+0x2000>
    80006706:	96ba                	add	a3,a3,a4
    80006708:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000670c:	0001e817          	auipc	a6,0x1e
    80006710:	8f480813          	addi	a6,a6,-1804 # 80024000 <disk>
    80006714:	00020517          	auipc	a0,0x20
    80006718:	8ec50513          	addi	a0,a0,-1812 # 80026000 <disk+0x2000>
    8000671c:	6114                	ld	a3,0(a0)
    8000671e:	96ba                	add	a3,a3,a4
    80006720:	00c6d603          	lhu	a2,12(a3)
    80006724:	00166613          	ori	a2,a2,1
    80006728:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000672c:	f9842683          	lw	a3,-104(s0)
    80006730:	6110                	ld	a2,0(a0)
    80006732:	9732                	add	a4,a4,a2
    80006734:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006738:	20058613          	addi	a2,a1,512
    8000673c:	0612                	slli	a2,a2,0x4
    8000673e:	9642                	add	a2,a2,a6
    80006740:	577d                	li	a4,-1
    80006742:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006746:	00469713          	slli	a4,a3,0x4
    8000674a:	6114                	ld	a3,0(a0)
    8000674c:	96ba                	add	a3,a3,a4
    8000674e:	03078793          	addi	a5,a5,48
    80006752:	97c2                	add	a5,a5,a6
    80006754:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006756:	611c                	ld	a5,0(a0)
    80006758:	97ba                	add	a5,a5,a4
    8000675a:	4685                	li	a3,1
    8000675c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000675e:	611c                	ld	a5,0(a0)
    80006760:	97ba                	add	a5,a5,a4
    80006762:	4809                	li	a6,2
    80006764:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006768:	611c                	ld	a5,0(a0)
    8000676a:	973e                	add	a4,a4,a5
    8000676c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006770:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006774:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006778:	6518                	ld	a4,8(a0)
    8000677a:	00275783          	lhu	a5,2(a4)
    8000677e:	8b9d                	andi	a5,a5,7
    80006780:	0786                	slli	a5,a5,0x1
    80006782:	97ba                	add	a5,a5,a4
    80006784:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006788:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000678c:	6518                	ld	a4,8(a0)
    8000678e:	00275783          	lhu	a5,2(a4)
    80006792:	2785                	addiw	a5,a5,1
    80006794:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006798:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000679c:	100017b7          	lui	a5,0x10001
    800067a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067a4:	00492703          	lw	a4,4(s2)
    800067a8:	4785                	li	a5,1
    800067aa:	02f71163          	bne	a4,a5,800067cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067ae:	00020997          	auipc	s3,0x20
    800067b2:	97a98993          	addi	s3,s3,-1670 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    800067b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067b8:	85ce                	mv	a1,s3
    800067ba:	854a                	mv	a0,s2
    800067bc:	ffffc097          	auipc	ra,0xffffc
    800067c0:	83a080e7          	jalr	-1990(ra) # 80001ff6 <sleep>
  while(b->disk == 1) {
    800067c4:	00492783          	lw	a5,4(s2)
    800067c8:	fe9788e3          	beq	a5,s1,800067b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067cc:	f9042903          	lw	s2,-112(s0)
    800067d0:	20090793          	addi	a5,s2,512
    800067d4:	00479713          	slli	a4,a5,0x4
    800067d8:	0001e797          	auipc	a5,0x1e
    800067dc:	82878793          	addi	a5,a5,-2008 # 80024000 <disk>
    800067e0:	97ba                	add	a5,a5,a4
    800067e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800067e6:	00020997          	auipc	s3,0x20
    800067ea:	81a98993          	addi	s3,s3,-2022 # 80026000 <disk+0x2000>
    800067ee:	00491713          	slli	a4,s2,0x4
    800067f2:	0009b783          	ld	a5,0(s3)
    800067f6:	97ba                	add	a5,a5,a4
    800067f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067fc:	854a                	mv	a0,s2
    800067fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006802:	00000097          	auipc	ra,0x0
    80006806:	bc4080e7          	jalr	-1084(ra) # 800063c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000680a:	8885                	andi	s1,s1,1
    8000680c:	f0ed                	bnez	s1,800067ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000680e:	00020517          	auipc	a0,0x20
    80006812:	91a50513          	addi	a0,a0,-1766 # 80026128 <disk+0x2128>
    80006816:	ffffa097          	auipc	ra,0xffffa
    8000681a:	482080e7          	jalr	1154(ra) # 80000c98 <release>
}
    8000681e:	70a6                	ld	ra,104(sp)
    80006820:	7406                	ld	s0,96(sp)
    80006822:	64e6                	ld	s1,88(sp)
    80006824:	6946                	ld	s2,80(sp)
    80006826:	69a6                	ld	s3,72(sp)
    80006828:	6a06                	ld	s4,64(sp)
    8000682a:	7ae2                	ld	s5,56(sp)
    8000682c:	7b42                	ld	s6,48(sp)
    8000682e:	7ba2                	ld	s7,40(sp)
    80006830:	7c02                	ld	s8,32(sp)
    80006832:	6ce2                	ld	s9,24(sp)
    80006834:	6d42                	ld	s10,16(sp)
    80006836:	6165                	addi	sp,sp,112
    80006838:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000683a:	0001f697          	auipc	a3,0x1f
    8000683e:	7c66b683          	ld	a3,1990(a3) # 80026000 <disk+0x2000>
    80006842:	96ba                	add	a3,a3,a4
    80006844:	4609                	li	a2,2
    80006846:	00c69623          	sh	a2,12(a3)
    8000684a:	b5c9                	j	8000670c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000684c:	f9042583          	lw	a1,-112(s0)
    80006850:	20058793          	addi	a5,a1,512
    80006854:	0792                	slli	a5,a5,0x4
    80006856:	0001e517          	auipc	a0,0x1e
    8000685a:	85250513          	addi	a0,a0,-1966 # 800240a8 <disk+0xa8>
    8000685e:	953e                	add	a0,a0,a5
  if(write)
    80006860:	e20d11e3          	bnez	s10,80006682 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006864:	20058713          	addi	a4,a1,512
    80006868:	00471693          	slli	a3,a4,0x4
    8000686c:	0001d717          	auipc	a4,0x1d
    80006870:	79470713          	addi	a4,a4,1940 # 80024000 <disk>
    80006874:	9736                	add	a4,a4,a3
    80006876:	0a072423          	sw	zero,168(a4)
    8000687a:	b505                	j	8000669a <virtio_disk_rw+0xf4>

000000008000687c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000687c:	1101                	addi	sp,sp,-32
    8000687e:	ec06                	sd	ra,24(sp)
    80006880:	e822                	sd	s0,16(sp)
    80006882:	e426                	sd	s1,8(sp)
    80006884:	e04a                	sd	s2,0(sp)
    80006886:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006888:	00020517          	auipc	a0,0x20
    8000688c:	8a050513          	addi	a0,a0,-1888 # 80026128 <disk+0x2128>
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	354080e7          	jalr	852(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006898:	10001737          	lui	a4,0x10001
    8000689c:	533c                	lw	a5,96(a4)
    8000689e:	8b8d                	andi	a5,a5,3
    800068a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068a6:	0001f797          	auipc	a5,0x1f
    800068aa:	75a78793          	addi	a5,a5,1882 # 80026000 <disk+0x2000>
    800068ae:	6b94                	ld	a3,16(a5)
    800068b0:	0207d703          	lhu	a4,32(a5)
    800068b4:	0026d783          	lhu	a5,2(a3)
    800068b8:	06f70163          	beq	a4,a5,8000691a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068bc:	0001d917          	auipc	s2,0x1d
    800068c0:	74490913          	addi	s2,s2,1860 # 80024000 <disk>
    800068c4:	0001f497          	auipc	s1,0x1f
    800068c8:	73c48493          	addi	s1,s1,1852 # 80026000 <disk+0x2000>
    __sync_synchronize();
    800068cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068d0:	6898                	ld	a4,16(s1)
    800068d2:	0204d783          	lhu	a5,32(s1)
    800068d6:	8b9d                	andi	a5,a5,7
    800068d8:	078e                	slli	a5,a5,0x3
    800068da:	97ba                	add	a5,a5,a4
    800068dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068de:	20078713          	addi	a4,a5,512
    800068e2:	0712                	slli	a4,a4,0x4
    800068e4:	974a                	add	a4,a4,s2
    800068e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800068ea:	e731                	bnez	a4,80006936 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068ec:	20078793          	addi	a5,a5,512
    800068f0:	0792                	slli	a5,a5,0x4
    800068f2:	97ca                	add	a5,a5,s2
    800068f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800068f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068fa:	ffffc097          	auipc	ra,0xffffc
    800068fe:	888080e7          	jalr	-1912(ra) # 80002182 <wakeup>

    disk.used_idx += 1;
    80006902:	0204d783          	lhu	a5,32(s1)
    80006906:	2785                	addiw	a5,a5,1
    80006908:	17c2                	slli	a5,a5,0x30
    8000690a:	93c1                	srli	a5,a5,0x30
    8000690c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006910:	6898                	ld	a4,16(s1)
    80006912:	00275703          	lhu	a4,2(a4)
    80006916:	faf71be3          	bne	a4,a5,800068cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000691a:	00020517          	auipc	a0,0x20
    8000691e:	80e50513          	addi	a0,a0,-2034 # 80026128 <disk+0x2128>
    80006922:	ffffa097          	auipc	ra,0xffffa
    80006926:	376080e7          	jalr	886(ra) # 80000c98 <release>
}
    8000692a:	60e2                	ld	ra,24(sp)
    8000692c:	6442                	ld	s0,16(sp)
    8000692e:	64a2                	ld	s1,8(sp)
    80006930:	6902                	ld	s2,0(sp)
    80006932:	6105                	addi	sp,sp,32
    80006934:	8082                	ret
      panic("virtio_disk_intr status");
    80006936:	00002517          	auipc	a0,0x2
    8000693a:	fc250513          	addi	a0,a0,-62 # 800088f8 <syscalls+0x3b8>
    8000693e:	ffffa097          	auipc	ra,0xffffa
    80006942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>

0000000080006946 <push>:


void
push (struct Queue *list, struct proc *element)
{
  if (list->size == NPROC) {
    80006946:	21052703          	lw	a4,528(a0)
    8000694a:	04000793          	li	a5,64
    8000694e:	02f70363          	beq	a4,a5,80006974 <push+0x2e>
    panic("Proccess limit exceeded");
  }  

  list->array[list->tail] = element;
    80006952:	415c                	lw	a5,4(a0)
    80006954:	00379693          	slli	a3,a5,0x3
    80006958:	96aa                	add	a3,a3,a0
    8000695a:	e68c                	sd	a1,8(a3)
  list->tail++;
    8000695c:	2785                	addiw	a5,a5,1
    8000695e:	0007861b          	sext.w	a2,a5
  if (list->tail == NPROC + 1) {
    80006962:	04100693          	li	a3,65
    80006966:	02d60363          	beq	a2,a3,8000698c <push+0x46>
  list->tail++;
    8000696a:	c15c                	sw	a5,4(a0)
    list->tail = 0;
  }
  list->size++;
    8000696c:	2705                	addiw	a4,a4,1
    8000696e:	20e52823          	sw	a4,528(a0)
    80006972:	8082                	ret
{
    80006974:	1141                	addi	sp,sp,-16
    80006976:	e406                	sd	ra,8(sp)
    80006978:	e022                	sd	s0,0(sp)
    8000697a:	0800                	addi	s0,sp,16
    panic("Proccess limit exceeded");
    8000697c:	00002517          	auipc	a0,0x2
    80006980:	f9450513          	addi	a0,a0,-108 # 80008910 <syscalls+0x3d0>
    80006984:	ffffa097          	auipc	ra,0xffffa
    80006988:	bba080e7          	jalr	-1094(ra) # 8000053e <panic>
    list->tail = 0;
    8000698c:	00052223          	sw	zero,4(a0)
    80006990:	bff1                	j	8000696c <push+0x26>

0000000080006992 <pop>:
}

void
pop(struct Queue *list)
{
  if (list->size == 0) {
    80006992:	21052783          	lw	a5,528(a0)
    80006996:	cf91                	beqz	a5,800069b2 <pop+0x20>
    panic("Poping from empty queue");
  }

  list->head++;
    80006998:	4118                	lw	a4,0(a0)
    8000699a:	2705                	addiw	a4,a4,1
    8000699c:	0007061b          	sext.w	a2,a4
  if (list->head == NPROC + 1) {
    800069a0:	04100693          	li	a3,65
    800069a4:	02d60363          	beq	a2,a3,800069ca <pop+0x38>
  list->head++;
    800069a8:	c118                	sw	a4,0(a0)
    list->head = 0;
  }

  list->size--;
    800069aa:	37fd                	addiw	a5,a5,-1
    800069ac:	20f52823          	sw	a5,528(a0)
    800069b0:	8082                	ret
{
    800069b2:	1141                	addi	sp,sp,-16
    800069b4:	e406                	sd	ra,8(sp)
    800069b6:	e022                	sd	s0,0(sp)
    800069b8:	0800                	addi	s0,sp,16
    panic("Poping from empty queue");
    800069ba:	00002517          	auipc	a0,0x2
    800069be:	f6e50513          	addi	a0,a0,-146 # 80008928 <syscalls+0x3e8>
    800069c2:	ffffa097          	auipc	ra,0xffffa
    800069c6:	b7c080e7          	jalr	-1156(ra) # 8000053e <panic>
    list->head = 0;
    800069ca:	00052023          	sw	zero,0(a0)
    800069ce:	bff1                	j	800069aa <pop+0x18>

00000000800069d0 <front>:
}

struct proc*
front(struct Queue *list)
{
    800069d0:	1141                	addi	sp,sp,-16
    800069d2:	e422                	sd	s0,8(sp)
    800069d4:	0800                	addi	s0,sp,16
  if (list->head == list->tail) {
    800069d6:	411c                	lw	a5,0(a0)
    800069d8:	4158                	lw	a4,4(a0)
    800069da:	00f70863          	beq	a4,a5,800069ea <front+0x1a>
    return 0;
  } 
  return list->array[list->head];
    800069de:	078e                	slli	a5,a5,0x3
    800069e0:	953e                	add	a0,a0,a5
    800069e2:	6508                	ld	a0,8(a0)
}
    800069e4:	6422                	ld	s0,8(sp)
    800069e6:	0141                	addi	sp,sp,16
    800069e8:	8082                	ret
    return 0;
    800069ea:	4501                	li	a0,0
    800069ec:	bfe5                	j	800069e4 <front+0x14>

00000000800069ee <qerase>:

void 
qerase(struct Queue *list, int pid) 
{
    800069ee:	1141                	addi	sp,sp,-16
    800069f0:	e422                	sd	s0,8(sp)
    800069f2:	0800                	addi	s0,sp,16
  for (int curr = list->head; curr != list->tail; curr = (curr + 1) % (NPROC + 1)) {
    800069f4:	411c                	lw	a5,0(a0)
    800069f6:	00452803          	lw	a6,4(a0)
    800069fa:	03078d63          	beq	a5,a6,80006a34 <qerase+0x46>
    if (list->array[curr]->pid == pid) {
      struct proc *temp = list->array[curr];
      list->array[curr] = list->array[(curr + 1) % (NPROC + 1)];
    800069fe:	04100893          	li	a7,65
    80006a02:	a031                	j	80006a0e <qerase+0x20>
  for (int curr = list->head; curr != list->tail; curr = (curr + 1) % (NPROC + 1)) {
    80006a04:	2785                	addiw	a5,a5,1
    80006a06:	0317e7bb          	remw	a5,a5,a7
    80006a0a:	03078563          	beq	a5,a6,80006a34 <qerase+0x46>
    if (list->array[curr]->pid == pid) {
    80006a0e:	00379713          	slli	a4,a5,0x3
    80006a12:	972a                	add	a4,a4,a0
    80006a14:	6710                	ld	a2,8(a4)
    80006a16:	5a14                	lw	a3,48(a2)
    80006a18:	feb696e3          	bne	a3,a1,80006a04 <qerase+0x16>
      list->array[curr] = list->array[(curr + 1) % (NPROC + 1)];
    80006a1c:	0017869b          	addiw	a3,a5,1
    80006a20:	0316e6bb          	remw	a3,a3,a7
    80006a24:	068e                	slli	a3,a3,0x3
    80006a26:	96aa                	add	a3,a3,a0
    80006a28:	0086b303          	ld	t1,8(a3)
    80006a2c:	00673423          	sd	t1,8(a4)
      list->array[(curr + 1) % (NPROC + 1)] = temp;
    80006a30:	e690                	sd	a2,8(a3)
    80006a32:	bfc9                	j	80006a04 <qerase+0x16>
    } 
  }

  list->tail--;
    80006a34:	387d                	addiw	a6,a6,-1
    80006a36:	01052223          	sw	a6,4(a0)
  list->size--;
    80006a3a:	21052783          	lw	a5,528(a0)
    80006a3e:	37fd                	addiw	a5,a5,-1
    80006a40:	20f52823          	sw	a5,528(a0)
  if (list->tail < 0) {
    80006a44:	02081793          	slli	a5,a6,0x20
    80006a48:	0007c563          	bltz	a5,80006a52 <qerase+0x64>
    list->tail = NPROC;
  }
    80006a4c:	6422                	ld	s0,8(sp)
    80006a4e:	0141                	addi	sp,sp,16
    80006a50:	8082                	ret
    list->tail = NPROC;
    80006a52:	04000793          	li	a5,64
    80006a56:	c15c                	sw	a5,4(a0)
    80006a58:	bfd5                	j	80006a4c <qerase+0x5e>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...