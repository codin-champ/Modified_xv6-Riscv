
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	96013103          	ld	sp,-1696(sp) # 80008960 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	d2c78793          	addi	a5,a5,-724 # 80005d90 <timervec>
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
    80000130:	396080e7          	jalr	918(ra) # 800024c2 <either_copyin>
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
    800001d8:	ef4080e7          	jalr	-268(ra) # 800020c8 <sleep>
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
    80000214:	25c080e7          	jalr	604(ra) # 8000246c <either_copyout>
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
    800002f6:	226080e7          	jalr	550(ra) # 80002518 <procdump>
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
    8000044a:	e0e080e7          	jalr	-498(ra) # 80002254 <wakeup>
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
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	ca078793          	addi	a5,a5,-864 # 80022118 <devsw>
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
    800008a4:	9b4080e7          	jalr	-1612(ra) # 80002254 <wakeup>
    
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
    80000930:	79c080e7          	jalr	1948(ra) # 800020c8 <sleep>
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
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	784080e7          	jalr	1924(ra) # 80002658 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	ef4080e7          	jalr	-268(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fee080e7          	jalr	-18(ra) # 80001ed2 <scheduler>
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
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	6e4080e7          	jalr	1764(ra) # 80002630 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	704080e7          	jalr	1796(ra) # 80002658 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e5e080e7          	jalr	-418(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e6c080e7          	jalr	-404(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	046080e7          	jalr	70(ra) # 80002fb2 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	6d6080e7          	jalr	1750(ra) # 8000364a <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	680080e7          	jalr	1664(ra) # 800045fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f6e080e7          	jalr	-146(ra) # 80005ef2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d0c080e7          	jalr	-756(ra) # 80001c98 <userinit>
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
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
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
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	662a0a13          	addi	s4,s4,1634 # 80017ed0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if (pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8595                	srai	a1,a1,0x5
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
    800018a8:	1a048493          	addi	s1,s1,416
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
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
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
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	59698993          	addi	s3,s3,1430 # 80017ed0 <tickslock>
    initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8795                	srai	a5,a5,0x5
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001968:	1a048493          	addi	s1,s1,416
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
    80001a04:	f107a783          	lw	a5,-240(a5) # 80008910 <first.2395>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	c66080e7          	jalr	-922(ra) # 80002670 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ee07ab23          	sw	zero,-266(a5) # 80008910 <first.2395>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	ba6080e7          	jalr	-1114(ra) # 800035ca <fsinit>
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
    80001a50:	ec878793          	addi	a5,a5,-312 # 80008914 <nextpid>
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
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	30290913          	addi	s2,s2,770 # 80017ed0 <tickslock>
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
    80001bee:	1a048493          	addi	s1,s1,416
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a08d                	j	80001c5a <allocproc+0xa0>
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
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	edc080e7          	jalr	-292(ra) # 80000af4 <kalloc>
    80001c20:	892a                	mv	s2,a0
    80001c22:	eca8                	sd	a0,88(s1)
    80001c24:	c131                	beqz	a0,80001c68 <allocproc+0xae>
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e4c080e7          	jalr	-436(ra) # 80001a74 <proc_pagetable>
    80001c30:	892a                	mv	s2,a0
    80001c32:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c34:	c531                	beqz	a0,80001c80 <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	06048513          	addi	a0,s1,96
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	0a0080e7          	jalr	160(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	da078793          	addi	a5,a5,-608 # 800019e8 <forkret>
    80001c50:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60bc                	ld	a5,64(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	f4bc                	sd	a5,104(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	ef8080e7          	jalr	-264(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0xa0>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ee0080e7          	jalr	-288(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	00c080e7          	jalr	12(ra) # 80000c98 <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0xa0>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f18080e7          	jalr	-232(ra) # 80001bba <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	38a7b223          	sd	a0,900(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	c6858593          	addi	a1,a1,-920 # 80008920 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	6a6080e7          	jalr	1702(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	52658593          	addi	a1,a1,1318 # 80008200 <digits+0x1c0>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	14c080e7          	jalr	332(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	52250513          	addi	a0,a0,1314 # 80008210 <digits+0x1d0>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	302080e7          	jalr	770(ra) # 80003ff8 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f90080e7          	jalr	-112(ra) # 80000c98 <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c88080e7          	jalr	-888(ra) # 800019b0 <myproc>
    80001d30:	892a                	mv	s2,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
    80001d34:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d38:	00904f63          	bgtz	s1,80001d56 <growproc+0x3c>
  else if (n < 0)
    80001d3c:	0204cc63          	bltz	s1,80001d74 <growproc+0x5a>
  p->sz = sz;
    80001d40:	1602                	slli	a2,a2,0x20
    80001d42:	9201                	srli	a2,a2,0x20
    80001d44:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d48:	4501                	li	a0,0
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d56:	9e25                	addw	a2,a2,s1
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	6c0080e7          	jalr	1728(ra) # 80001422 <uvmalloc>
    80001d6a:	0005061b          	sext.w	a2,a0
    80001d6e:	fa69                	bnez	a2,80001d40 <growproc+0x26>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bfe1                	j	80001d4a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	9e25                	addw	a2,a2,s1
    80001d76:	1602                	slli	a2,a2,0x20
    80001d78:	9201                	srli	a2,a2,0x20
    80001d7a:	1582                	slli	a1,a1,0x20
    80001d7c:	9181                	srli	a1,a1,0x20
    80001d7e:	6928                	ld	a0,80(a0)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	65a080e7          	jalr	1626(ra) # 800013da <uvmdealloc>
    80001d88:	0005061b          	sext.w	a2,a0
    80001d8c:	bf55                	j	80001d40 <growproc+0x26>

0000000080001d8e <fork>:
{
    80001d8e:	7179                	addi	sp,sp,-48
    80001d90:	f406                	sd	ra,40(sp)
    80001d92:	f022                	sd	s0,32(sp)
    80001d94:	ec26                	sd	s1,24(sp)
    80001d96:	e84a                	sd	s2,16(sp)
    80001d98:	e44e                	sd	s3,8(sp)
    80001d9a:	e052                	sd	s4,0(sp)
    80001d9c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	c12080e7          	jalr	-1006(ra) # 800019b0 <myproc>
    80001da6:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	e12080e7          	jalr	-494(ra) # 80001bba <allocproc>
    80001db0:	10050f63          	beqz	a0,80001ece <fork+0x140>
    80001db4:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001db6:	04893603          	ld	a2,72(s2)
    80001dba:	692c                	ld	a1,80(a0)
    80001dbc:	05093503          	ld	a0,80(s2)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	7ae080e7          	jalr	1966(ra) # 8000156e <uvmcopy>
    80001dc8:	04054a63          	bltz	a0,80001e1c <fork+0x8e>
  np->sz = p->sz;
    80001dcc:	04893783          	ld	a5,72(s2)
    80001dd0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd4:	05893683          	ld	a3,88(s2)
    80001dd8:	87b6                	mv	a5,a3
    80001dda:	0589b703          	ld	a4,88(s3)
    80001dde:	12068693          	addi	a3,a3,288
    80001de2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de6:	6788                	ld	a0,8(a5)
    80001de8:	6b8c                	ld	a1,16(a5)
    80001dea:	6f90                	ld	a2,24(a5)
    80001dec:	01073023          	sd	a6,0(a4)
    80001df0:	e708                	sd	a0,8(a4)
    80001df2:	eb0c                	sd	a1,16(a4)
    80001df4:	ef10                	sd	a2,24(a4)
    80001df6:	02078793          	addi	a5,a5,32
    80001dfa:	02070713          	addi	a4,a4,32
    80001dfe:	fed792e3          	bne	a5,a3,80001de2 <fork+0x54>
  (np->mask) = (p->mask);
    80001e02:	16892783          	lw	a5,360(s2)
    80001e06:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001e0a:	0589b783          	ld	a5,88(s3)
    80001e0e:	0607b823          	sd	zero,112(a5)
    80001e12:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e16:	15000a13          	li	s4,336
    80001e1a:	a03d                	j	80001e48 <fork+0xba>
    freeproc(np);
    80001e1c:	854e                	mv	a0,s3
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	d44080e7          	jalr	-700(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e26:	854e                	mv	a0,s3
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	e70080e7          	jalr	-400(ra) # 80000c98 <release>
    return -1;
    80001e30:	5a7d                	li	s4,-1
    80001e32:	a069                	j	80001ebc <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e34:	00003097          	auipc	ra,0x3
    80001e38:	85a080e7          	jalr	-1958(ra) # 8000468e <filedup>
    80001e3c:	009987b3          	add	a5,s3,s1
    80001e40:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e42:	04a1                	addi	s1,s1,8
    80001e44:	01448763          	beq	s1,s4,80001e52 <fork+0xc4>
    if (p->ofile[i])
    80001e48:	009907b3          	add	a5,s2,s1
    80001e4c:	6388                	ld	a0,0(a5)
    80001e4e:	f17d                	bnez	a0,80001e34 <fork+0xa6>
    80001e50:	bfcd                	j	80001e42 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e52:	15093503          	ld	a0,336(s2)
    80001e56:	00002097          	auipc	ra,0x2
    80001e5a:	9ae080e7          	jalr	-1618(ra) # 80003804 <idup>
    80001e5e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e62:	4641                	li	a2,16
    80001e64:	15890593          	addi	a1,s2,344
    80001e68:	15898513          	addi	a0,s3,344
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	fc6080e7          	jalr	-58(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e74:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e78:	854e                	mv	a0,s3
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e1e080e7          	jalr	-482(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e82:	0000f497          	auipc	s1,0xf
    80001e86:	43648493          	addi	s1,s1,1078 # 800112b8 <wait_lock>
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e94:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	dfe080e7          	jalr	-514(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	d40080e7          	jalr	-704(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001eac:	478d                	li	a5,3
    80001eae:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb2:	854e                	mv	a0,s3
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	de4080e7          	jalr	-540(ra) # 80000c98 <release>
}
    80001ebc:	8552                	mv	a0,s4
    80001ebe:	70a2                	ld	ra,40(sp)
    80001ec0:	7402                	ld	s0,32(sp)
    80001ec2:	64e2                	ld	s1,24(sp)
    80001ec4:	6942                	ld	s2,16(sp)
    80001ec6:	69a2                	ld	s3,8(sp)
    80001ec8:	6a02                	ld	s4,0(sp)
    80001eca:	6145                	addi	sp,sp,48
    80001ecc:	8082                	ret
    return -1;
    80001ece:	5a7d                	li	s4,-1
    80001ed0:	b7f5                	j	80001ebc <fork+0x12e>

0000000080001ed2 <scheduler>:
{
    80001ed2:	711d                	addi	sp,sp,-96
    80001ed4:	ec86                	sd	ra,88(sp)
    80001ed6:	e8a2                	sd	s0,80(sp)
    80001ed8:	e4a6                	sd	s1,72(sp)
    80001eda:	e0ca                	sd	s2,64(sp)
    80001edc:	fc4e                	sd	s3,56(sp)
    80001ede:	f852                	sd	s4,48(sp)
    80001ee0:	f456                	sd	s5,40(sp)
    80001ee2:	f05a                	sd	s6,32(sp)
    80001ee4:	ec5e                	sd	s7,24(sp)
    80001ee6:	e862                	sd	s8,16(sp)
    80001ee8:	e466                	sd	s9,8(sp)
    80001eea:	e06a                	sd	s10,0(sp)
    80001eec:	1080                	addi	s0,sp,96
    80001eee:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef2:	00779c93          	slli	s9,a5,0x7
    80001ef6:	0000f717          	auipc	a4,0xf
    80001efa:	3aa70713          	addi	a4,a4,938 # 800112a0 <pid_lock>
    80001efe:	9766                	add	a4,a4,s9
    80001f00:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f04:	0000f717          	auipc	a4,0xf
    80001f08:	3d470713          	addi	a4,a4,980 # 800112d8 <cpus+0x8>
    80001f0c:	9cba                	add	s9,s9,a4
  int mintime = ticks;
    80001f0e:	00007c17          	auipc	s8,0x7
    80001f12:	12ac0c13          	addi	s8,s8,298 # 80009038 <ticks>
  int index = 0;
    80001f16:	4b01                	li	s6,0
    if (proc[i].state != RUNNABLE)
    80001f18:	498d                	li	s3,3
  for (int i = 0; i < NPROC; i++)
    80001f1a:	04000a93          	li	s5,64
  return &proc[index];
    80001f1e:	0000fa17          	auipc	s4,0xf
    80001f22:	7b2a0a13          	addi	s4,s4,1970 # 800116d0 <proc>
        c->proc = p;
    80001f26:	079e                	slli	a5,a5,0x7
    80001f28:	0000fb97          	auipc	s7,0xf
    80001f2c:	378b8b93          	addi	s7,s7,888 # 800112a0 <pid_lock>
    80001f30:	9bbe                	add	s7,s7,a5
    80001f32:	a09d                	j	80001f98 <scheduler+0xc6>
  for (int i = 0; i < NPROC; i++)
    80001f34:	2785                	addiw	a5,a5,1
    80001f36:	1a070713          	addi	a4,a4,416
    80001f3a:	01578c63          	beq	a5,s5,80001f52 <scheduler+0x80>
    if (proc[i].state != RUNNABLE)
    80001f3e:	4314                	lw	a3,0(a4)
    80001f40:	ff369ae3          	bne	a3,s3,80001f34 <scheduler+0x62>
    if (proc[i].ctime <= mintime)
    80001f44:	15472683          	lw	a3,340(a4)
    80001f48:	fed646e3          	blt	a2,a3,80001f34 <scheduler+0x62>
      mintime = proc[i].ctime;
    80001f4c:	8636                	mv	a2,a3
    if (proc[i].ctime <= mintime)
    80001f4e:	893e                	mv	s2,a5
    80001f50:	b7d5                	j	80001f34 <scheduler+0x62>
  return &proc[index];
    80001f52:	1a000493          	li	s1,416
    80001f56:	029904b3          	mul	s1,s2,s1
    80001f5a:	01448d33          	add	s10,s1,s4
      acquire(&p->lock);
    80001f5e:	856a                	mv	a0,s10
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	c84080e7          	jalr	-892(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    80001f68:	018d2783          	lw	a5,24(s10)
    80001f6c:	03379163          	bne	a5,s3,80001f8e <scheduler+0xbc>
        p->state = RUNNING;
    80001f70:	4791                	li	a5,4
    80001f72:	00fd2c23          	sw	a5,24(s10)
        c->proc = p;
    80001f76:	03abb823          	sd	s10,48(s7)
        swtch(&c->context, &p->context);
    80001f7a:	06048593          	addi	a1,s1,96
    80001f7e:	95d2                	add	a1,a1,s4
    80001f80:	8566                	mv	a0,s9
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	644080e7          	jalr	1604(ra) # 800025c6 <swtch>
        c->proc = 0;
    80001f8a:	020bb823          	sd	zero,48(s7)
      release(&p->lock);
    80001f8e:	856a                	mv	a0,s10
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	d08080e7          	jalr	-760(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f9c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fa0:	10079073          	csrw	sstatus,a5
  int mintime = ticks;
    80001fa4:	000c2603          	lw	a2,0(s8)
  for (int i = 0; i < NPROC; i++)
    80001fa8:	0000f717          	auipc	a4,0xf
    80001fac:	74070713          	addi	a4,a4,1856 # 800116e8 <proc+0x18>
  int index = 0;
    80001fb0:	895a                	mv	s2,s6
  for (int i = 0; i < NPROC; i++)
    80001fb2:	87da                	mv	a5,s6
    80001fb4:	b769                	j	80001f3e <scheduler+0x6c>

0000000080001fb6 <sched>:
{
    80001fb6:	7179                	addi	sp,sp,-48
    80001fb8:	f406                	sd	ra,40(sp)
    80001fba:	f022                	sd	s0,32(sp)
    80001fbc:	ec26                	sd	s1,24(sp)
    80001fbe:	e84a                	sd	s2,16(sp)
    80001fc0:	e44e                	sd	s3,8(sp)
    80001fc2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	9ec080e7          	jalr	-1556(ra) # 800019b0 <myproc>
    80001fcc:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	b9c080e7          	jalr	-1124(ra) # 80000b6a <holding>
    80001fd6:	c93d                	beqz	a0,8000204c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fd8:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fda:	2781                	sext.w	a5,a5
    80001fdc:	079e                	slli	a5,a5,0x7
    80001fde:	0000f717          	auipc	a4,0xf
    80001fe2:	2c270713          	addi	a4,a4,706 # 800112a0 <pid_lock>
    80001fe6:	97ba                	add	a5,a5,a4
    80001fe8:	0a87a703          	lw	a4,168(a5)
    80001fec:	4785                	li	a5,1
    80001fee:	06f71763          	bne	a4,a5,8000205c <sched+0xa6>
  if (p->state == RUNNING)
    80001ff2:	4c98                	lw	a4,24(s1)
    80001ff4:	4791                	li	a5,4
    80001ff6:	06f70b63          	beq	a4,a5,8000206c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ffe:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002000:	efb5                	bnez	a5,8000207c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002002:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002004:	0000f917          	auipc	s2,0xf
    80002008:	29c90913          	addi	s2,s2,668 # 800112a0 <pid_lock>
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	97ca                	add	a5,a5,s2
    80002012:	0ac7a983          	lw	s3,172(a5)
    80002016:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002018:	2781                	sext.w	a5,a5
    8000201a:	079e                	slli	a5,a5,0x7
    8000201c:	0000f597          	auipc	a1,0xf
    80002020:	2bc58593          	addi	a1,a1,700 # 800112d8 <cpus+0x8>
    80002024:	95be                	add	a1,a1,a5
    80002026:	06048513          	addi	a0,s1,96
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	59c080e7          	jalr	1436(ra) # 800025c6 <swtch>
    80002032:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002034:	2781                	sext.w	a5,a5
    80002036:	079e                	slli	a5,a5,0x7
    80002038:	97ca                	add	a5,a5,s2
    8000203a:	0b37a623          	sw	s3,172(a5)
}
    8000203e:	70a2                	ld	ra,40(sp)
    80002040:	7402                	ld	s0,32(sp)
    80002042:	64e2                	ld	s1,24(sp)
    80002044:	6942                	ld	s2,16(sp)
    80002046:	69a2                	ld	s3,8(sp)
    80002048:	6145                	addi	sp,sp,48
    8000204a:	8082                	ret
    panic("sched p->lock");
    8000204c:	00006517          	auipc	a0,0x6
    80002050:	1cc50513          	addi	a0,a0,460 # 80008218 <digits+0x1d8>
    80002054:	ffffe097          	auipc	ra,0xffffe
    80002058:	4ea080e7          	jalr	1258(ra) # 8000053e <panic>
    panic("sched locks");
    8000205c:	00006517          	auipc	a0,0x6
    80002060:	1cc50513          	addi	a0,a0,460 # 80008228 <digits+0x1e8>
    80002064:	ffffe097          	auipc	ra,0xffffe
    80002068:	4da080e7          	jalr	1242(ra) # 8000053e <panic>
    panic("sched running");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	1cc50513          	addi	a0,a0,460 # 80008238 <digits+0x1f8>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4ca080e7          	jalr	1226(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	1cc50513          	addi	a0,a0,460 # 80008248 <digits+0x208>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4ba080e7          	jalr	1210(ra) # 8000053e <panic>

000000008000208c <yield>:
{
    8000208c:	1101                	addi	sp,sp,-32
    8000208e:	ec06                	sd	ra,24(sp)
    80002090:	e822                	sd	s0,16(sp)
    80002092:	e426                	sd	s1,8(sp)
    80002094:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	91a080e7          	jalr	-1766(ra) # 800019b0 <myproc>
    8000209e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b44080e7          	jalr	-1212(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020a8:	478d                	li	a5,3
    800020aa:	cc9c                	sw	a5,24(s1)
  sched();
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	f0a080e7          	jalr	-246(ra) # 80001fb6 <sched>
  release(&p->lock);
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	be2080e7          	jalr	-1054(ra) # 80000c98 <release>
}
    800020be:	60e2                	ld	ra,24(sp)
    800020c0:	6442                	ld	s0,16(sp)
    800020c2:	64a2                	ld	s1,8(sp)
    800020c4:	6105                	addi	sp,sp,32
    800020c6:	8082                	ret

00000000800020c8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020c8:	7179                	addi	sp,sp,-48
    800020ca:	f406                	sd	ra,40(sp)
    800020cc:	f022                	sd	s0,32(sp)
    800020ce:	ec26                	sd	s1,24(sp)
    800020d0:	e84a                	sd	s2,16(sp)
    800020d2:	e44e                	sd	s3,8(sp)
    800020d4:	1800                	addi	s0,sp,48
    800020d6:	89aa                	mv	s3,a0
    800020d8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020da:	00000097          	auipc	ra,0x0
    800020de:	8d6080e7          	jalr	-1834(ra) # 800019b0 <myproc>
    800020e2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	b00080e7          	jalr	-1280(ra) # 80000be4 <acquire>
  release(lk);
    800020ec:	854a                	mv	a0,s2
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	baa080e7          	jalr	-1110(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020f6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020fa:	4789                	li	a5,2
    800020fc:	cc9c                	sw	a5,24(s1)

  sched();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	eb8080e7          	jalr	-328(ra) # 80001fb6 <sched>

  // Tidy up.
  p->chan = 0;
    80002106:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
  acquire(lk);
    80002114:	854a                	mv	a0,s2
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	ace080e7          	jalr	-1330(ra) # 80000be4 <acquire>
}
    8000211e:	70a2                	ld	ra,40(sp)
    80002120:	7402                	ld	s0,32(sp)
    80002122:	64e2                	ld	s1,24(sp)
    80002124:	6942                	ld	s2,16(sp)
    80002126:	69a2                	ld	s3,8(sp)
    80002128:	6145                	addi	sp,sp,48
    8000212a:	8082                	ret

000000008000212c <wait>:
{
    8000212c:	715d                	addi	sp,sp,-80
    8000212e:	e486                	sd	ra,72(sp)
    80002130:	e0a2                	sd	s0,64(sp)
    80002132:	fc26                	sd	s1,56(sp)
    80002134:	f84a                	sd	s2,48(sp)
    80002136:	f44e                	sd	s3,40(sp)
    80002138:	f052                	sd	s4,32(sp)
    8000213a:	ec56                	sd	s5,24(sp)
    8000213c:	e85a                	sd	s6,16(sp)
    8000213e:	e45e                	sd	s7,8(sp)
    80002140:	e062                	sd	s8,0(sp)
    80002142:	0880                	addi	s0,sp,80
    80002144:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	86a080e7          	jalr	-1942(ra) # 800019b0 <myproc>
    8000214e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002150:	0000f517          	auipc	a0,0xf
    80002154:	16850513          	addi	a0,a0,360 # 800112b8 <wait_lock>
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a8c080e7          	jalr	-1396(ra) # 80000be4 <acquire>
    havekids = 0;
    80002160:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002162:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002164:	00016997          	auipc	s3,0x16
    80002168:	d6c98993          	addi	s3,s3,-660 # 80017ed0 <tickslock>
        havekids = 1;
    8000216c:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000216e:	0000fc17          	auipc	s8,0xf
    80002172:	14ac0c13          	addi	s8,s8,330 # 800112b8 <wait_lock>
    havekids = 0;
    80002176:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002178:	0000f497          	auipc	s1,0xf
    8000217c:	55848493          	addi	s1,s1,1368 # 800116d0 <proc>
    80002180:	a0bd                	j	800021ee <wait+0xc2>
          pid = np->pid;
    80002182:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002186:	000b0e63          	beqz	s6,800021a2 <wait+0x76>
    8000218a:	4691                	li	a3,4
    8000218c:	02c48613          	addi	a2,s1,44
    80002190:	85da                	mv	a1,s6
    80002192:	05093503          	ld	a0,80(s2)
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	4dc080e7          	jalr	1244(ra) # 80001672 <copyout>
    8000219e:	02054563          	bltz	a0,800021c8 <wait+0x9c>
          freeproc(np);
    800021a2:	8526                	mv	a0,s1
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	9be080e7          	jalr	-1602(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aea080e7          	jalr	-1302(ra) # 80000c98 <release>
          release(&wait_lock);
    800021b6:	0000f517          	auipc	a0,0xf
    800021ba:	10250513          	addi	a0,a0,258 # 800112b8 <wait_lock>
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	ada080e7          	jalr	-1318(ra) # 80000c98 <release>
          return pid;
    800021c6:	a09d                	j	8000222c <wait+0x100>
            release(&np->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	ace080e7          	jalr	-1330(ra) # 80000c98 <release>
            release(&wait_lock);
    800021d2:	0000f517          	auipc	a0,0xf
    800021d6:	0e650513          	addi	a0,a0,230 # 800112b8 <wait_lock>
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	abe080e7          	jalr	-1346(ra) # 80000c98 <release>
            return -1;
    800021e2:	59fd                	li	s3,-1
    800021e4:	a0a1                	j	8000222c <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800021e6:	1a048493          	addi	s1,s1,416
    800021ea:	03348463          	beq	s1,s3,80002212 <wait+0xe6>
      if (np->parent == p)
    800021ee:	7c9c                	ld	a5,56(s1)
    800021f0:	ff279be3          	bne	a5,s2,800021e6 <wait+0xba>
        acquire(&np->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	9ee080e7          	jalr	-1554(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800021fe:	4c9c                	lw	a5,24(s1)
    80002200:	f94781e3          	beq	a5,s4,80002182 <wait+0x56>
        release(&np->lock);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
        havekids = 1;
    8000220e:	8756                	mv	a4,s5
    80002210:	bfd9                	j	800021e6 <wait+0xba>
    if (!havekids || p->killed)
    80002212:	c701                	beqz	a4,8000221a <wait+0xee>
    80002214:	02892783          	lw	a5,40(s2)
    80002218:	c79d                	beqz	a5,80002246 <wait+0x11a>
      release(&wait_lock);
    8000221a:	0000f517          	auipc	a0,0xf
    8000221e:	09e50513          	addi	a0,a0,158 # 800112b8 <wait_lock>
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
      return -1;
    8000222a:	59fd                	li	s3,-1
}
    8000222c:	854e                	mv	a0,s3
    8000222e:	60a6                	ld	ra,72(sp)
    80002230:	6406                	ld	s0,64(sp)
    80002232:	74e2                	ld	s1,56(sp)
    80002234:	7942                	ld	s2,48(sp)
    80002236:	79a2                	ld	s3,40(sp)
    80002238:	7a02                	ld	s4,32(sp)
    8000223a:	6ae2                	ld	s5,24(sp)
    8000223c:	6b42                	ld	s6,16(sp)
    8000223e:	6ba2                	ld	s7,8(sp)
    80002240:	6c02                	ld	s8,0(sp)
    80002242:	6161                	addi	sp,sp,80
    80002244:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002246:	85e2                	mv	a1,s8
    80002248:	854a                	mv	a0,s2
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	e7e080e7          	jalr	-386(ra) # 800020c8 <sleep>
    havekids = 0;
    80002252:	b715                	j	80002176 <wait+0x4a>

0000000080002254 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002254:	7139                	addi	sp,sp,-64
    80002256:	fc06                	sd	ra,56(sp)
    80002258:	f822                	sd	s0,48(sp)
    8000225a:	f426                	sd	s1,40(sp)
    8000225c:	f04a                	sd	s2,32(sp)
    8000225e:	ec4e                	sd	s3,24(sp)
    80002260:	e852                	sd	s4,16(sp)
    80002262:	e456                	sd	s5,8(sp)
    80002264:	0080                	addi	s0,sp,64
    80002266:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002268:	0000f497          	auipc	s1,0xf
    8000226c:	46848493          	addi	s1,s1,1128 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002270:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002272:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002274:	00016917          	auipc	s2,0x16
    80002278:	c5c90913          	addi	s2,s2,-932 # 80017ed0 <tickslock>
    8000227c:	a821                	j	80002294 <wakeup+0x40>
        p->state = RUNNABLE;
    8000227e:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a14080e7          	jalr	-1516(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000228c:	1a048493          	addi	s1,s1,416
    80002290:	03248463          	beq	s1,s2,800022b8 <wakeup+0x64>
    if (p != myproc())
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	71c080e7          	jalr	1820(ra) # 800019b0 <myproc>
    8000229c:	fea488e3          	beq	s1,a0,8000228c <wakeup+0x38>
      acquire(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	942080e7          	jalr	-1726(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022aa:	4c9c                	lw	a5,24(s1)
    800022ac:	fd379be3          	bne	a5,s3,80002282 <wakeup+0x2e>
    800022b0:	709c                	ld	a5,32(s1)
    800022b2:	fd4798e3          	bne	a5,s4,80002282 <wakeup+0x2e>
    800022b6:	b7e1                	j	8000227e <wakeup+0x2a>
    }
  }
}
    800022b8:	70e2                	ld	ra,56(sp)
    800022ba:	7442                	ld	s0,48(sp)
    800022bc:	74a2                	ld	s1,40(sp)
    800022be:	7902                	ld	s2,32(sp)
    800022c0:	69e2                	ld	s3,24(sp)
    800022c2:	6a42                	ld	s4,16(sp)
    800022c4:	6aa2                	ld	s5,8(sp)
    800022c6:	6121                	addi	sp,sp,64
    800022c8:	8082                	ret

00000000800022ca <reparent>:
{
    800022ca:	7179                	addi	sp,sp,-48
    800022cc:	f406                	sd	ra,40(sp)
    800022ce:	f022                	sd	s0,32(sp)
    800022d0:	ec26                	sd	s1,24(sp)
    800022d2:	e84a                	sd	s2,16(sp)
    800022d4:	e44e                	sd	s3,8(sp)
    800022d6:	e052                	sd	s4,0(sp)
    800022d8:	1800                	addi	s0,sp,48
    800022da:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022dc:	0000f497          	auipc	s1,0xf
    800022e0:	3f448493          	addi	s1,s1,1012 # 800116d0 <proc>
      pp->parent = initproc;
    800022e4:	00007a17          	auipc	s4,0x7
    800022e8:	d4ca0a13          	addi	s4,s4,-692 # 80009030 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022ec:	00016997          	auipc	s3,0x16
    800022f0:	be498993          	addi	s3,s3,-1052 # 80017ed0 <tickslock>
    800022f4:	a029                	j	800022fe <reparent+0x34>
    800022f6:	1a048493          	addi	s1,s1,416
    800022fa:	01348d63          	beq	s1,s3,80002314 <reparent+0x4a>
    if (pp->parent == p)
    800022fe:	7c9c                	ld	a5,56(s1)
    80002300:	ff279be3          	bne	a5,s2,800022f6 <reparent+0x2c>
      pp->parent = initproc;
    80002304:	000a3503          	ld	a0,0(s4)
    80002308:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	f4a080e7          	jalr	-182(ra) # 80002254 <wakeup>
    80002312:	b7d5                	j	800022f6 <reparent+0x2c>
}
    80002314:	70a2                	ld	ra,40(sp)
    80002316:	7402                	ld	s0,32(sp)
    80002318:	64e2                	ld	s1,24(sp)
    8000231a:	6942                	ld	s2,16(sp)
    8000231c:	69a2                	ld	s3,8(sp)
    8000231e:	6a02                	ld	s4,0(sp)
    80002320:	6145                	addi	sp,sp,48
    80002322:	8082                	ret

0000000080002324 <exit>:
{
    80002324:	7179                	addi	sp,sp,-48
    80002326:	f406                	sd	ra,40(sp)
    80002328:	f022                	sd	s0,32(sp)
    8000232a:	ec26                	sd	s1,24(sp)
    8000232c:	e84a                	sd	s2,16(sp)
    8000232e:	e44e                	sd	s3,8(sp)
    80002330:	e052                	sd	s4,0(sp)
    80002332:	1800                	addi	s0,sp,48
    80002334:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	67a080e7          	jalr	1658(ra) # 800019b0 <myproc>
    8000233e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002340:	00007797          	auipc	a5,0x7
    80002344:	cf07b783          	ld	a5,-784(a5) # 80009030 <initproc>
    80002348:	0d050493          	addi	s1,a0,208
    8000234c:	15050913          	addi	s2,a0,336
    80002350:	02a79363          	bne	a5,a0,80002376 <exit+0x52>
    panic("init exiting");
    80002354:	00006517          	auipc	a0,0x6
    80002358:	f0c50513          	addi	a0,a0,-244 # 80008260 <digits+0x220>
    8000235c:	ffffe097          	auipc	ra,0xffffe
    80002360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
      fileclose(f);
    80002364:	00002097          	auipc	ra,0x2
    80002368:	37c080e7          	jalr	892(ra) # 800046e0 <fileclose>
      p->ofile[fd] = 0;
    8000236c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002370:	04a1                	addi	s1,s1,8
    80002372:	01248563          	beq	s1,s2,8000237c <exit+0x58>
    if (p->ofile[fd])
    80002376:	6088                	ld	a0,0(s1)
    80002378:	f575                	bnez	a0,80002364 <exit+0x40>
    8000237a:	bfdd                	j	80002370 <exit+0x4c>
  begin_op();
    8000237c:	00002097          	auipc	ra,0x2
    80002380:	e98080e7          	jalr	-360(ra) # 80004214 <begin_op>
  iput(p->cwd);
    80002384:	1509b503          	ld	a0,336(s3)
    80002388:	00001097          	auipc	ra,0x1
    8000238c:	674080e7          	jalr	1652(ra) # 800039fc <iput>
  end_op();
    80002390:	00002097          	auipc	ra,0x2
    80002394:	f04080e7          	jalr	-252(ra) # 80004294 <end_op>
  p->cwd = 0;
    80002398:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	f1c48493          	addi	s1,s1,-228 # 800112b8 <wait_lock>
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	83e080e7          	jalr	-1986(ra) # 80000be4 <acquire>
  reparent(p);
    800023ae:	854e                	mv	a0,s3
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	f1a080e7          	jalr	-230(ra) # 800022ca <reparent>
  wakeup(p->parent);
    800023b8:	0389b503          	ld	a0,56(s3)
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	e98080e7          	jalr	-360(ra) # 80002254 <wakeup>
  acquire(&p->lock);
    800023c4:	854e                	mv	a0,s3
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	81e080e7          	jalr	-2018(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023ce:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023d2:	4795                	li	a5,5
    800023d4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	8be080e7          	jalr	-1858(ra) # 80000c98 <release>
  sched();
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	bd4080e7          	jalr	-1068(ra) # 80001fb6 <sched>
  panic("zombie exit");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	e8650513          	addi	a0,a0,-378 # 80008270 <digits+0x230>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	14c080e7          	jalr	332(ra) # 8000053e <panic>

00000000800023fa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	1800                	addi	s0,sp,48
    80002408:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000240a:	0000f497          	auipc	s1,0xf
    8000240e:	2c648493          	addi	s1,s1,710 # 800116d0 <proc>
    80002412:	00016997          	auipc	s3,0x16
    80002416:	abe98993          	addi	s3,s3,-1346 # 80017ed0 <tickslock>
  {
    acquire(&p->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7c8080e7          	jalr	1992(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002424:	589c                	lw	a5,48(s1)
    80002426:	01278d63          	beq	a5,s2,80002440 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002434:	1a048493          	addi	s1,s1,416
    80002438:	ff3491e3          	bne	s1,s3,8000241a <kill+0x20>
  }
  return -1;
    8000243c:	557d                	li	a0,-1
    8000243e:	a829                	j	80002458 <kill+0x5e>
      p->killed = 1;
    80002440:	4785                	li	a5,1
    80002442:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002444:	4c98                	lw	a4,24(s1)
    80002446:	4789                	li	a5,2
    80002448:	00f70f63          	beq	a4,a5,80002466 <kill+0x6c>
      release(&p->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
      return 0;
    80002456:	4501                	li	a0,0
}
    80002458:	70a2                	ld	ra,40(sp)
    8000245a:	7402                	ld	s0,32(sp)
    8000245c:	64e2                	ld	s1,24(sp)
    8000245e:	6942                	ld	s2,16(sp)
    80002460:	69a2                	ld	s3,8(sp)
    80002462:	6145                	addi	sp,sp,48
    80002464:	8082                	ret
        p->state = RUNNABLE;
    80002466:	478d                	li	a5,3
    80002468:	cc9c                	sw	a5,24(s1)
    8000246a:	b7cd                	j	8000244c <kill+0x52>

000000008000246c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000246c:	7179                	addi	sp,sp,-48
    8000246e:	f406                	sd	ra,40(sp)
    80002470:	f022                	sd	s0,32(sp)
    80002472:	ec26                	sd	s1,24(sp)
    80002474:	e84a                	sd	s2,16(sp)
    80002476:	e44e                	sd	s3,8(sp)
    80002478:	e052                	sd	s4,0(sp)
    8000247a:	1800                	addi	s0,sp,48
    8000247c:	84aa                	mv	s1,a0
    8000247e:	892e                	mv	s2,a1
    80002480:	89b2                	mv	s3,a2
    80002482:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	52c080e7          	jalr	1324(ra) # 800019b0 <myproc>
  if (user_dst)
    8000248c:	c08d                	beqz	s1,800024ae <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000248e:	86d2                	mv	a3,s4
    80002490:	864e                	mv	a2,s3
    80002492:	85ca                	mv	a1,s2
    80002494:	6928                	ld	a0,80(a0)
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	1dc080e7          	jalr	476(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000249e:	70a2                	ld	ra,40(sp)
    800024a0:	7402                	ld	s0,32(sp)
    800024a2:	64e2                	ld	s1,24(sp)
    800024a4:	6942                	ld	s2,16(sp)
    800024a6:	69a2                	ld	s3,8(sp)
    800024a8:	6a02                	ld	s4,0(sp)
    800024aa:	6145                	addi	sp,sp,48
    800024ac:	8082                	ret
    memmove((char *)dst, src, len);
    800024ae:	000a061b          	sext.w	a2,s4
    800024b2:	85ce                	mv	a1,s3
    800024b4:	854a                	mv	a0,s2
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	88a080e7          	jalr	-1910(ra) # 80000d40 <memmove>
    return 0;
    800024be:	8526                	mv	a0,s1
    800024c0:	bff9                	j	8000249e <either_copyout+0x32>

00000000800024c2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024c2:	7179                	addi	sp,sp,-48
    800024c4:	f406                	sd	ra,40(sp)
    800024c6:	f022                	sd	s0,32(sp)
    800024c8:	ec26                	sd	s1,24(sp)
    800024ca:	e84a                	sd	s2,16(sp)
    800024cc:	e44e                	sd	s3,8(sp)
    800024ce:	e052                	sd	s4,0(sp)
    800024d0:	1800                	addi	s0,sp,48
    800024d2:	892a                	mv	s2,a0
    800024d4:	84ae                	mv	s1,a1
    800024d6:	89b2                	mv	s3,a2
    800024d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	4d6080e7          	jalr	1238(ra) # 800019b0 <myproc>
  if (user_src)
    800024e2:	c08d                	beqz	s1,80002504 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024e4:	86d2                	mv	a3,s4
    800024e6:	864e                	mv	a2,s3
    800024e8:	85ca                	mv	a1,s2
    800024ea:	6928                	ld	a0,80(a0)
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	212080e7          	jalr	530(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024f4:	70a2                	ld	ra,40(sp)
    800024f6:	7402                	ld	s0,32(sp)
    800024f8:	64e2                	ld	s1,24(sp)
    800024fa:	6942                	ld	s2,16(sp)
    800024fc:	69a2                	ld	s3,8(sp)
    800024fe:	6a02                	ld	s4,0(sp)
    80002500:	6145                	addi	sp,sp,48
    80002502:	8082                	ret
    memmove(dst, (char *)src, len);
    80002504:	000a061b          	sext.w	a2,s4
    80002508:	85ce                	mv	a1,s3
    8000250a:	854a                	mv	a0,s2
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	834080e7          	jalr	-1996(ra) # 80000d40 <memmove>
    return 0;
    80002514:	8526                	mv	a0,s1
    80002516:	bff9                	j	800024f4 <either_copyin+0x32>

0000000080002518 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002518:	715d                	addi	sp,sp,-80
    8000251a:	e486                	sd	ra,72(sp)
    8000251c:	e0a2                	sd	s0,64(sp)
    8000251e:	fc26                	sd	s1,56(sp)
    80002520:	f84a                	sd	s2,48(sp)
    80002522:	f44e                	sd	s3,40(sp)
    80002524:	f052                	sd	s4,32(sp)
    80002526:	ec56                	sd	s5,24(sp)
    80002528:	e85a                	sd	s6,16(sp)
    8000252a:	e45e                	sd	s7,8(sp)
    8000252c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000252e:	00006517          	auipc	a0,0x6
    80002532:	b9a50513          	addi	a0,a0,-1126 # 800080c8 <digits+0x88>
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	052080e7          	jalr	82(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000253e:	0000f497          	auipc	s1,0xf
    80002542:	2ea48493          	addi	s1,s1,746 # 80011828 <proc+0x158>
    80002546:	00016917          	auipc	s2,0x16
    8000254a:	ae290913          	addi	s2,s2,-1310 # 80018028 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002550:	00006997          	auipc	s3,0x6
    80002554:	d3098993          	addi	s3,s3,-720 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002558:	00006a97          	auipc	s5,0x6
    8000255c:	d30a8a93          	addi	s5,s5,-720 # 80008288 <digits+0x248>
    printf("\n");
    80002560:	00006a17          	auipc	s4,0x6
    80002564:	b68a0a13          	addi	s4,s4,-1176 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002568:	00006b97          	auipc	s7,0x6
    8000256c:	d58b8b93          	addi	s7,s7,-680 # 800082c0 <states.2432>
    80002570:	a00d                	j	80002592 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002572:	ed86a583          	lw	a1,-296(a3)
    80002576:	8556                	mv	a0,s5
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	010080e7          	jalr	16(ra) # 80000588 <printf>
    printf("\n");
    80002580:	8552                	mv	a0,s4
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	006080e7          	jalr	6(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000258a:	1a048493          	addi	s1,s1,416
    8000258e:	03248163          	beq	s1,s2,800025b0 <procdump+0x98>
    if (p->state == UNUSED)
    80002592:	86a6                	mv	a3,s1
    80002594:	ec04a783          	lw	a5,-320(s1)
    80002598:	dbed                	beqz	a5,8000258a <procdump+0x72>
      state = "???";
    8000259a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259c:	fcfb6be3          	bltu	s6,a5,80002572 <procdump+0x5a>
    800025a0:	1782                	slli	a5,a5,0x20
    800025a2:	9381                	srli	a5,a5,0x20
    800025a4:	078e                	slli	a5,a5,0x3
    800025a6:	97de                	add	a5,a5,s7
    800025a8:	6390                	ld	a2,0(a5)
    800025aa:	f661                	bnez	a2,80002572 <procdump+0x5a>
      state = "???";
    800025ac:	864e                	mv	a2,s3
    800025ae:	b7d1                	j	80002572 <procdump+0x5a>
  }
}
    800025b0:	60a6                	ld	ra,72(sp)
    800025b2:	6406                	ld	s0,64(sp)
    800025b4:	74e2                	ld	s1,56(sp)
    800025b6:	7942                	ld	s2,48(sp)
    800025b8:	79a2                	ld	s3,40(sp)
    800025ba:	7a02                	ld	s4,32(sp)
    800025bc:	6ae2                	ld	s5,24(sp)
    800025be:	6b42                	ld	s6,16(sp)
    800025c0:	6ba2                	ld	s7,8(sp)
    800025c2:	6161                	addi	sp,sp,80
    800025c4:	8082                	ret

00000000800025c6 <swtch>:
    800025c6:	00153023          	sd	ra,0(a0)
    800025ca:	00253423          	sd	sp,8(a0)
    800025ce:	e900                	sd	s0,16(a0)
    800025d0:	ed04                	sd	s1,24(a0)
    800025d2:	03253023          	sd	s2,32(a0)
    800025d6:	03353423          	sd	s3,40(a0)
    800025da:	03453823          	sd	s4,48(a0)
    800025de:	03553c23          	sd	s5,56(a0)
    800025e2:	05653023          	sd	s6,64(a0)
    800025e6:	05753423          	sd	s7,72(a0)
    800025ea:	05853823          	sd	s8,80(a0)
    800025ee:	05953c23          	sd	s9,88(a0)
    800025f2:	07a53023          	sd	s10,96(a0)
    800025f6:	07b53423          	sd	s11,104(a0)
    800025fa:	0005b083          	ld	ra,0(a1)
    800025fe:	0085b103          	ld	sp,8(a1)
    80002602:	6980                	ld	s0,16(a1)
    80002604:	6d84                	ld	s1,24(a1)
    80002606:	0205b903          	ld	s2,32(a1)
    8000260a:	0285b983          	ld	s3,40(a1)
    8000260e:	0305ba03          	ld	s4,48(a1)
    80002612:	0385ba83          	ld	s5,56(a1)
    80002616:	0405bb03          	ld	s6,64(a1)
    8000261a:	0485bb83          	ld	s7,72(a1)
    8000261e:	0505bc03          	ld	s8,80(a1)
    80002622:	0585bc83          	ld	s9,88(a1)
    80002626:	0605bd03          	ld	s10,96(a1)
    8000262a:	0685bd83          	ld	s11,104(a1)
    8000262e:	8082                	ret

0000000080002630 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002630:	1141                	addi	sp,sp,-16
    80002632:	e406                	sd	ra,8(sp)
    80002634:	e022                	sd	s0,0(sp)
    80002636:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002638:	00006597          	auipc	a1,0x6
    8000263c:	cb858593          	addi	a1,a1,-840 # 800082f0 <states.2432+0x30>
    80002640:	00016517          	auipc	a0,0x16
    80002644:	89050513          	addi	a0,a0,-1904 # 80017ed0 <tickslock>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	50c080e7          	jalr	1292(ra) # 80000b54 <initlock>
}
    80002650:	60a2                	ld	ra,8(sp)
    80002652:	6402                	ld	s0,0(sp)
    80002654:	0141                	addi	sp,sp,16
    80002656:	8082                	ret

0000000080002658 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002658:	1141                	addi	sp,sp,-16
    8000265a:	e422                	sd	s0,8(sp)
    8000265c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000265e:	00003797          	auipc	a5,0x3
    80002662:	6a278793          	addi	a5,a5,1698 # 80005d00 <kernelvec>
    80002666:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000266a:	6422                	ld	s0,8(sp)
    8000266c:	0141                	addi	sp,sp,16
    8000266e:	8082                	ret

0000000080002670 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002670:	1141                	addi	sp,sp,-16
    80002672:	e406                	sd	ra,8(sp)
    80002674:	e022                	sd	s0,0(sp)
    80002676:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002678:	fffff097          	auipc	ra,0xfffff
    8000267c:	338080e7          	jalr	824(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002680:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002684:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002686:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000268a:	00005617          	auipc	a2,0x5
    8000268e:	97660613          	addi	a2,a2,-1674 # 80007000 <_trampoline>
    80002692:	00005697          	auipc	a3,0x5
    80002696:	96e68693          	addi	a3,a3,-1682 # 80007000 <_trampoline>
    8000269a:	8e91                	sub	a3,a3,a2
    8000269c:	040007b7          	lui	a5,0x4000
    800026a0:	17fd                	addi	a5,a5,-1
    800026a2:	07b2                	slli	a5,a5,0xc
    800026a4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ac:	180026f3          	csrr	a3,satp
    800026b0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026b2:	6d38                	ld	a4,88(a0)
    800026b4:	6134                	ld	a3,64(a0)
    800026b6:	6585                	lui	a1,0x1
    800026b8:	96ae                	add	a3,a3,a1
    800026ba:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026bc:	6d38                	ld	a4,88(a0)
    800026be:	00000697          	auipc	a3,0x0
    800026c2:	13868693          	addi	a3,a3,312 # 800027f6 <usertrap>
    800026c6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026c8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026ca:	8692                	mv	a3,tp
    800026cc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ce:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026d2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026d6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026da:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026de:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026e0:	6f18                	ld	a4,24(a4)
    800026e2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026e6:	692c                	ld	a1,80(a0)
    800026e8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026ea:	00005717          	auipc	a4,0x5
    800026ee:	9a670713          	addi	a4,a4,-1626 # 80007090 <userret>
    800026f2:	8f11                	sub	a4,a4,a2
    800026f4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026f6:	577d                	li	a4,-1
    800026f8:	177e                	slli	a4,a4,0x3f
    800026fa:	8dd9                	or	a1,a1,a4
    800026fc:	02000537          	lui	a0,0x2000
    80002700:	157d                	addi	a0,a0,-1
    80002702:	0536                	slli	a0,a0,0xd
    80002704:	9782                	jalr	a5
}
    80002706:	60a2                	ld	ra,8(sp)
    80002708:	6402                	ld	s0,0(sp)
    8000270a:	0141                	addi	sp,sp,16
    8000270c:	8082                	ret

000000008000270e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000270e:	1101                	addi	sp,sp,-32
    80002710:	ec06                	sd	ra,24(sp)
    80002712:	e822                	sd	s0,16(sp)
    80002714:	e426                	sd	s1,8(sp)
    80002716:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002718:	00015497          	auipc	s1,0x15
    8000271c:	7b848493          	addi	s1,s1,1976 # 80017ed0 <tickslock>
    80002720:	8526                	mv	a0,s1
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	4c2080e7          	jalr	1218(ra) # 80000be4 <acquire>
  ticks++;
    8000272a:	00007517          	auipc	a0,0x7
    8000272e:	90e50513          	addi	a0,a0,-1778 # 80009038 <ticks>
    80002732:	411c                	lw	a5,0(a0)
    80002734:	2785                	addiw	a5,a5,1
    80002736:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002738:	00000097          	auipc	ra,0x0
    8000273c:	b1c080e7          	jalr	-1252(ra) # 80002254 <wakeup>
  release(&tickslock);
    80002740:	8526                	mv	a0,s1
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	556080e7          	jalr	1366(ra) # 80000c98 <release>
}
    8000274a:	60e2                	ld	ra,24(sp)
    8000274c:	6442                	ld	s0,16(sp)
    8000274e:	64a2                	ld	s1,8(sp)
    80002750:	6105                	addi	sp,sp,32
    80002752:	8082                	ret

0000000080002754 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002754:	1101                	addi	sp,sp,-32
    80002756:	ec06                	sd	ra,24(sp)
    80002758:	e822                	sd	s0,16(sp)
    8000275a:	e426                	sd	s1,8(sp)
    8000275c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000275e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002762:	00074d63          	bltz	a4,8000277c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002766:	57fd                	li	a5,-1
    80002768:	17fe                	slli	a5,a5,0x3f
    8000276a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000276c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000276e:	06f70363          	beq	a4,a5,800027d4 <devintr+0x80>
  }
}
    80002772:	60e2                	ld	ra,24(sp)
    80002774:	6442                	ld	s0,16(sp)
    80002776:	64a2                	ld	s1,8(sp)
    80002778:	6105                	addi	sp,sp,32
    8000277a:	8082                	ret
     (scause & 0xff) == 9){
    8000277c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002780:	46a5                	li	a3,9
    80002782:	fed792e3          	bne	a5,a3,80002766 <devintr+0x12>
    int irq = plic_claim();
    80002786:	00003097          	auipc	ra,0x3
    8000278a:	682080e7          	jalr	1666(ra) # 80005e08 <plic_claim>
    8000278e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002790:	47a9                	li	a5,10
    80002792:	02f50763          	beq	a0,a5,800027c0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002796:	4785                	li	a5,1
    80002798:	02f50963          	beq	a0,a5,800027ca <devintr+0x76>
    return 1;
    8000279c:	4505                	li	a0,1
    } else if(irq){
    8000279e:	d8f1                	beqz	s1,80002772 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027a0:	85a6                	mv	a1,s1
    800027a2:	00006517          	auipc	a0,0x6
    800027a6:	b5650513          	addi	a0,a0,-1194 # 800082f8 <states.2432+0x38>
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	dde080e7          	jalr	-546(ra) # 80000588 <printf>
      plic_complete(irq);
    800027b2:	8526                	mv	a0,s1
    800027b4:	00003097          	auipc	ra,0x3
    800027b8:	678080e7          	jalr	1656(ra) # 80005e2c <plic_complete>
    return 1;
    800027bc:	4505                	li	a0,1
    800027be:	bf55                	j	80002772 <devintr+0x1e>
      uartintr();
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	1e8080e7          	jalr	488(ra) # 800009a8 <uartintr>
    800027c8:	b7ed                	j	800027b2 <devintr+0x5e>
      virtio_disk_intr();
    800027ca:	00004097          	auipc	ra,0x4
    800027ce:	b42080e7          	jalr	-1214(ra) # 8000630c <virtio_disk_intr>
    800027d2:	b7c5                	j	800027b2 <devintr+0x5e>
    if(cpuid() == 0){
    800027d4:	fffff097          	auipc	ra,0xfffff
    800027d8:	1b0080e7          	jalr	432(ra) # 80001984 <cpuid>
    800027dc:	c901                	beqz	a0,800027ec <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027de:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027e2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027e4:	14479073          	csrw	sip,a5
    return 2;
    800027e8:	4509                	li	a0,2
    800027ea:	b761                	j	80002772 <devintr+0x1e>
      clockintr();
    800027ec:	00000097          	auipc	ra,0x0
    800027f0:	f22080e7          	jalr	-222(ra) # 8000270e <clockintr>
    800027f4:	b7ed                	j	800027de <devintr+0x8a>

00000000800027f6 <usertrap>:
{
    800027f6:	1101                	addi	sp,sp,-32
    800027f8:	ec06                	sd	ra,24(sp)
    800027fa:	e822                	sd	s0,16(sp)
    800027fc:	e426                	sd	s1,8(sp)
    800027fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002800:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002804:	1007f793          	andi	a5,a5,256
    80002808:	e3a5                	bnez	a5,80002868 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000280a:	00003797          	auipc	a5,0x3
    8000280e:	4f678793          	addi	a5,a5,1270 # 80005d00 <kernelvec>
    80002812:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	19a080e7          	jalr	410(ra) # 800019b0 <myproc>
    8000281e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002820:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002822:	14102773          	csrr	a4,sepc
    80002826:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002828:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000282c:	47a1                	li	a5,8
    8000282e:	04f71b63          	bne	a4,a5,80002884 <usertrap+0x8e>
    if(p->killed)
    80002832:	551c                	lw	a5,40(a0)
    80002834:	e3b1                	bnez	a5,80002878 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002836:	6cb8                	ld	a4,88(s1)
    80002838:	6f1c                	ld	a5,24(a4)
    8000283a:	0791                	addi	a5,a5,4
    8000283c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002842:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002846:	10079073          	csrw	sstatus,a5
    syscall();
    8000284a:	00000097          	auipc	ra,0x0
    8000284e:	3c8080e7          	jalr	968(ra) # 80002c12 <syscall>
  if(p->killed)
    80002852:	549c                	lw	a5,40(s1)
    80002854:	e7b5                	bnez	a5,800028c0 <usertrap+0xca>
  usertrapret();
    80002856:	00000097          	auipc	ra,0x0
    8000285a:	e1a080e7          	jalr	-486(ra) # 80002670 <usertrapret>
}
    8000285e:	60e2                	ld	ra,24(sp)
    80002860:	6442                	ld	s0,16(sp)
    80002862:	64a2                	ld	s1,8(sp)
    80002864:	6105                	addi	sp,sp,32
    80002866:	8082                	ret
    panic("usertrap: not from user mode");
    80002868:	00006517          	auipc	a0,0x6
    8000286c:	ab050513          	addi	a0,a0,-1360 # 80008318 <states.2432+0x58>
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	cce080e7          	jalr	-818(ra) # 8000053e <panic>
      exit(-1);
    80002878:	557d                	li	a0,-1
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	aaa080e7          	jalr	-1366(ra) # 80002324 <exit>
    80002882:	bf55                	j	80002836 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002884:	00000097          	auipc	ra,0x0
    80002888:	ed0080e7          	jalr	-304(ra) # 80002754 <devintr>
    8000288c:	f179                	bnez	a0,80002852 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002892:	5890                	lw	a2,48(s1)
    80002894:	00006517          	auipc	a0,0x6
    80002898:	aa450513          	addi	a0,a0,-1372 # 80008338 <states.2432+0x78>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	cec080e7          	jalr	-788(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028a8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ac:	00006517          	auipc	a0,0x6
    800028b0:	abc50513          	addi	a0,a0,-1348 # 80008368 <states.2432+0xa8>
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	cd4080e7          	jalr	-812(ra) # 80000588 <printf>
    p->killed = 1;
    800028bc:	4785                	li	a5,1
    800028be:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028c0:	557d                	li	a0,-1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	a62080e7          	jalr	-1438(ra) # 80002324 <exit>
    800028ca:	b771                	j	80002856 <usertrap+0x60>

00000000800028cc <kerneltrap>:
{
    800028cc:	7179                	addi	sp,sp,-48
    800028ce:	f406                	sd	ra,40(sp)
    800028d0:	f022                	sd	s0,32(sp)
    800028d2:	ec26                	sd	s1,24(sp)
    800028d4:	e84a                	sd	s2,16(sp)
    800028d6:	e44e                	sd	s3,8(sp)
    800028d8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028da:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028de:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028e6:	1004f793          	andi	a5,s1,256
    800028ea:	c78d                	beqz	a5,80002914 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028f2:	eb8d                	bnez	a5,80002924 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    800028f4:	00000097          	auipc	ra,0x0
    800028f8:	e60080e7          	jalr	-416(ra) # 80002754 <devintr>
    800028fc:	cd05                	beqz	a0,80002934 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028fe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002902:	10049073          	csrw	sstatus,s1
}
    80002906:	70a2                	ld	ra,40(sp)
    80002908:	7402                	ld	s0,32(sp)
    8000290a:	64e2                	ld	s1,24(sp)
    8000290c:	6942                	ld	s2,16(sp)
    8000290e:	69a2                	ld	s3,8(sp)
    80002910:	6145                	addi	sp,sp,48
    80002912:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002914:	00006517          	auipc	a0,0x6
    80002918:	a7450513          	addi	a0,a0,-1420 # 80008388 <states.2432+0xc8>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c22080e7          	jalr	-990(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002924:	00006517          	auipc	a0,0x6
    80002928:	a8c50513          	addi	a0,a0,-1396 # 800083b0 <states.2432+0xf0>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c12080e7          	jalr	-1006(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002934:	85ce                	mv	a1,s3
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a9a50513          	addi	a0,a0,-1382 # 800083d0 <states.2432+0x110>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c4a080e7          	jalr	-950(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002946:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000294a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	a9250513          	addi	a0,a0,-1390 # 800083e0 <states.2432+0x120>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	c32080e7          	jalr	-974(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	a9a50513          	addi	a0,a0,-1382 # 800083f8 <states.2432+0x138>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	bd8080e7          	jalr	-1064(ra) # 8000053e <panic>

000000008000296e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000296e:	1101                	addi	sp,sp,-32
    80002970:	ec06                	sd	ra,24(sp)
    80002972:	e822                	sd	s0,16(sp)
    80002974:	e426                	sd	s1,8(sp)
    80002976:	1000                	addi	s0,sp,32
    80002978:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	036080e7          	jalr	54(ra) # 800019b0 <myproc>
  switch (n) {
    80002982:	4795                	li	a5,5
    80002984:	0497e163          	bltu	a5,s1,800029c6 <argraw+0x58>
    80002988:	048a                	slli	s1,s1,0x2
    8000298a:	00006717          	auipc	a4,0x6
    8000298e:	b9e70713          	addi	a4,a4,-1122 # 80008528 <states.2432+0x268>
    80002992:	94ba                	add	s1,s1,a4
    80002994:	409c                	lw	a5,0(s1)
    80002996:	97ba                	add	a5,a5,a4
    80002998:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000299a:	6d3c                	ld	a5,88(a0)
    8000299c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000299e:	60e2                	ld	ra,24(sp)
    800029a0:	6442                	ld	s0,16(sp)
    800029a2:	64a2                	ld	s1,8(sp)
    800029a4:	6105                	addi	sp,sp,32
    800029a6:	8082                	ret
    return p->trapframe->a1;
    800029a8:	6d3c                	ld	a5,88(a0)
    800029aa:	7fa8                	ld	a0,120(a5)
    800029ac:	bfcd                	j	8000299e <argraw+0x30>
    return p->trapframe->a2;
    800029ae:	6d3c                	ld	a5,88(a0)
    800029b0:	63c8                	ld	a0,128(a5)
    800029b2:	b7f5                	j	8000299e <argraw+0x30>
    return p->trapframe->a3;
    800029b4:	6d3c                	ld	a5,88(a0)
    800029b6:	67c8                	ld	a0,136(a5)
    800029b8:	b7dd                	j	8000299e <argraw+0x30>
    return p->trapframe->a4;
    800029ba:	6d3c                	ld	a5,88(a0)
    800029bc:	6bc8                	ld	a0,144(a5)
    800029be:	b7c5                	j	8000299e <argraw+0x30>
    return p->trapframe->a5;
    800029c0:	6d3c                	ld	a5,88(a0)
    800029c2:	6fc8                	ld	a0,152(a5)
    800029c4:	bfe9                	j	8000299e <argraw+0x30>
  panic("argraw");
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	a4250513          	addi	a0,a0,-1470 # 80008408 <states.2432+0x148>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	b70080e7          	jalr	-1168(ra) # 8000053e <panic>

00000000800029d6 <fetchaddr>:
{
    800029d6:	1101                	addi	sp,sp,-32
    800029d8:	ec06                	sd	ra,24(sp)
    800029da:	e822                	sd	s0,16(sp)
    800029dc:	e426                	sd	s1,8(sp)
    800029de:	e04a                	sd	s2,0(sp)
    800029e0:	1000                	addi	s0,sp,32
    800029e2:	84aa                	mv	s1,a0
    800029e4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	fca080e7          	jalr	-54(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029ee:	653c                	ld	a5,72(a0)
    800029f0:	02f4f863          	bgeu	s1,a5,80002a20 <fetchaddr+0x4a>
    800029f4:	00848713          	addi	a4,s1,8
    800029f8:	02e7e663          	bltu	a5,a4,80002a24 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029fc:	46a1                	li	a3,8
    800029fe:	8626                	mv	a2,s1
    80002a00:	85ca                	mv	a1,s2
    80002a02:	6928                	ld	a0,80(a0)
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	cfa080e7          	jalr	-774(ra) # 800016fe <copyin>
    80002a0c:	00a03533          	snez	a0,a0
    80002a10:	40a00533          	neg	a0,a0
}
    80002a14:	60e2                	ld	ra,24(sp)
    80002a16:	6442                	ld	s0,16(sp)
    80002a18:	64a2                	ld	s1,8(sp)
    80002a1a:	6902                	ld	s2,0(sp)
    80002a1c:	6105                	addi	sp,sp,32
    80002a1e:	8082                	ret
    return -1;
    80002a20:	557d                	li	a0,-1
    80002a22:	bfcd                	j	80002a14 <fetchaddr+0x3e>
    80002a24:	557d                	li	a0,-1
    80002a26:	b7fd                	j	80002a14 <fetchaddr+0x3e>

0000000080002a28 <fetchstr>:
{
    80002a28:	7179                	addi	sp,sp,-48
    80002a2a:	f406                	sd	ra,40(sp)
    80002a2c:	f022                	sd	s0,32(sp)
    80002a2e:	ec26                	sd	s1,24(sp)
    80002a30:	e84a                	sd	s2,16(sp)
    80002a32:	e44e                	sd	s3,8(sp)
    80002a34:	1800                	addi	s0,sp,48
    80002a36:	892a                	mv	s2,a0
    80002a38:	84ae                	mv	s1,a1
    80002a3a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	f74080e7          	jalr	-140(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a44:	86ce                	mv	a3,s3
    80002a46:	864a                	mv	a2,s2
    80002a48:	85a6                	mv	a1,s1
    80002a4a:	6928                	ld	a0,80(a0)
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	d3e080e7          	jalr	-706(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002a54:	00054763          	bltz	a0,80002a62 <fetchstr+0x3a>
  return strlen(buf);
    80002a58:	8526                	mv	a0,s1
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	40a080e7          	jalr	1034(ra) # 80000e64 <strlen>
}
    80002a62:	70a2                	ld	ra,40(sp)
    80002a64:	7402                	ld	s0,32(sp)
    80002a66:	64e2                	ld	s1,24(sp)
    80002a68:	6942                	ld	s2,16(sp)
    80002a6a:	69a2                	ld	s3,8(sp)
    80002a6c:	6145                	addi	sp,sp,48
    80002a6e:	8082                	ret

0000000080002a70 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	1000                	addi	s0,sp,32
    80002a7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	ef2080e7          	jalr	-270(ra) # 8000296e <argraw>
    80002a84:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a86:	4501                	li	a0,0
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret

0000000080002a92 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a92:	1101                	addi	sp,sp,-32
    80002a94:	ec06                	sd	ra,24(sp)
    80002a96:	e822                	sd	s0,16(sp)
    80002a98:	e426                	sd	s1,8(sp)
    80002a9a:	1000                	addi	s0,sp,32
    80002a9c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	ed0080e7          	jalr	-304(ra) # 8000296e <argraw>
    80002aa6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002aa8:	4501                	li	a0,0
    80002aaa:	60e2                	ld	ra,24(sp)
    80002aac:	6442                	ld	s0,16(sp)
    80002aae:	64a2                	ld	s1,8(sp)
    80002ab0:	6105                	addi	sp,sp,32
    80002ab2:	8082                	ret

0000000080002ab4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	e04a                	sd	s2,0(sp)
    80002abe:	1000                	addi	s0,sp,32
    80002ac0:	84ae                	mv	s1,a1
    80002ac2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	eaa080e7          	jalr	-342(ra) # 8000296e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002acc:	864a                	mv	a2,s2
    80002ace:	85a6                	mv	a1,s1
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	f58080e7          	jalr	-168(ra) # 80002a28 <fetchstr>
}
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6902                	ld	s2,0(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret

0000000080002ae4 <SyscallNamesArray>:
[SYS_close]   sys_close,
[SYS_trace]   sys_trace,
};

void SyscallNamesArray(char *names[NELEM(syscalls)])
{
    80002ae4:	1141                	addi	sp,sp,-16
    80002ae6:	e422                	sd	s0,8(sp)
    80002ae8:	0800                	addi	s0,sp,16
  names[1] = "fork";
    80002aea:	00006797          	auipc	a5,0x6
    80002aee:	92678793          	addi	a5,a5,-1754 # 80008410 <states.2432+0x150>
    80002af2:	e51c                	sd	a5,8(a0)
  names[2] = "exit";
    80002af4:	00006797          	auipc	a5,0x6
    80002af8:	92478793          	addi	a5,a5,-1756 # 80008418 <states.2432+0x158>
    80002afc:	e91c                	sd	a5,16(a0)
  names[3] = "wait";
    80002afe:	00006797          	auipc	a5,0x6
    80002b02:	92278793          	addi	a5,a5,-1758 # 80008420 <states.2432+0x160>
    80002b06:	ed1c                	sd	a5,24(a0)
  names[4] = "pipe";
    80002b08:	00006797          	auipc	a5,0x6
    80002b0c:	92078793          	addi	a5,a5,-1760 # 80008428 <states.2432+0x168>
    80002b10:	f11c                	sd	a5,32(a0)
  names[5] = "read";
    80002b12:	00006797          	auipc	a5,0x6
    80002b16:	c0678793          	addi	a5,a5,-1018 # 80008718 <syscalls+0x1d8>
    80002b1a:	f51c                	sd	a5,40(a0)
  names[6] = "kill";
    80002b1c:	00006797          	auipc	a5,0x6
    80002b20:	91478793          	addi	a5,a5,-1772 # 80008430 <states.2432+0x170>
    80002b24:	f91c                	sd	a5,48(a0)
  names[7] = "exec";
    80002b26:	00006797          	auipc	a5,0x6
    80002b2a:	91278793          	addi	a5,a5,-1774 # 80008438 <states.2432+0x178>
    80002b2e:	fd1c                	sd	a5,56(a0)
  names[8] = "fstat";
    80002b30:	00006797          	auipc	a5,0x6
    80002b34:	91078793          	addi	a5,a5,-1776 # 80008440 <states.2432+0x180>
    80002b38:	e13c                	sd	a5,64(a0)
  names[9] = "chdir";
    80002b3a:	00006797          	auipc	a5,0x6
    80002b3e:	90e78793          	addi	a5,a5,-1778 # 80008448 <states.2432+0x188>
    80002b42:	e53c                	sd	a5,72(a0)
  names[10] = "dup";
    80002b44:	00006797          	auipc	a5,0x6
    80002b48:	90c78793          	addi	a5,a5,-1780 # 80008450 <states.2432+0x190>
    80002b4c:	e93c                	sd	a5,80(a0)
  names[11] = "getpid";
    80002b4e:	00006797          	auipc	a5,0x6
    80002b52:	90a78793          	addi	a5,a5,-1782 # 80008458 <states.2432+0x198>
    80002b56:	ed3c                	sd	a5,88(a0)
  names[12] = "sbrk";
    80002b58:	00006797          	auipc	a5,0x6
    80002b5c:	90878793          	addi	a5,a5,-1784 # 80008460 <states.2432+0x1a0>
    80002b60:	f13c                	sd	a5,96(a0)
  names[13] = "sleep";
    80002b62:	00006797          	auipc	a5,0x6
    80002b66:	90678793          	addi	a5,a5,-1786 # 80008468 <states.2432+0x1a8>
    80002b6a:	f53c                	sd	a5,104(a0)
  names[14] = "uptime";
    80002b6c:	00006797          	auipc	a5,0x6
    80002b70:	90478793          	addi	a5,a5,-1788 # 80008470 <states.2432+0x1b0>
    80002b74:	f93c                	sd	a5,112(a0)
  names[15] = "open";
    80002b76:	00006797          	auipc	a5,0x6
    80002b7a:	90278793          	addi	a5,a5,-1790 # 80008478 <states.2432+0x1b8>
    80002b7e:	fd3c                	sd	a5,120(a0)
  names[16] = "write";
    80002b80:	00006797          	auipc	a5,0x6
    80002b84:	90078793          	addi	a5,a5,-1792 # 80008480 <states.2432+0x1c0>
    80002b88:	e15c                	sd	a5,128(a0)
  names[17] = "mknod";
    80002b8a:	00006797          	auipc	a5,0x6
    80002b8e:	8fe78793          	addi	a5,a5,-1794 # 80008488 <states.2432+0x1c8>
    80002b92:	e55c                	sd	a5,136(a0)
  names[18] = "unlink";
    80002b94:	00006797          	auipc	a5,0x6
    80002b98:	8fc78793          	addi	a5,a5,-1796 # 80008490 <states.2432+0x1d0>
    80002b9c:	e95c                	sd	a5,144(a0)
  names[19] = "link";
    80002b9e:	00006797          	auipc	a5,0x6
    80002ba2:	8fa78793          	addi	a5,a5,-1798 # 80008498 <states.2432+0x1d8>
    80002ba6:	ed5c                	sd	a5,152(a0)
  names[20] = "mkdir";
    80002ba8:	00006797          	auipc	a5,0x6
    80002bac:	8f878793          	addi	a5,a5,-1800 # 800084a0 <states.2432+0x1e0>
    80002bb0:	f15c                	sd	a5,160(a0)
  names[21] = "close";
    80002bb2:	00006797          	auipc	a5,0x6
    80002bb6:	8f678793          	addi	a5,a5,-1802 # 800084a8 <states.2432+0x1e8>
    80002bba:	f55c                	sd	a5,168(a0)
  names[22] = "trace";
    80002bbc:	00006797          	auipc	a5,0x6
    80002bc0:	8f478793          	addi	a5,a5,-1804 # 800084b0 <states.2432+0x1f0>
    80002bc4:	f95c                	sd	a5,176(a0)
}
    80002bc6:	6422                	ld	s0,8(sp)
    80002bc8:	0141                	addi	sp,sp,16
    80002bca:	8082                	ret

0000000080002bcc <ArgumentCount>:

void ArgumentCount(int *count)
{
    80002bcc:	1141                	addi	sp,sp,-16
    80002bce:	e422                	sd	s0,8(sp)
    80002bd0:	0800                	addi	s0,sp,16
  count[1] = 0;
    80002bd2:	00052223          	sw	zero,4(a0)
  count[2] = 1;
    80002bd6:	4785                	li	a5,1
    80002bd8:	c51c                	sw	a5,8(a0)
  count[3] = 1;
    80002bda:	c55c                	sw	a5,12(a0)
  count[4] = 0;
    80002bdc:	00052823          	sw	zero,16(a0)
  count[5] = 3;
    80002be0:	468d                	li	a3,3
    80002be2:	c954                	sw	a3,20(a0)
  count[6] = 2;
    80002be4:	4709                	li	a4,2
    80002be6:	cd18                	sw	a4,24(a0)
  count[7] = 2;
    80002be8:	cd58                	sw	a4,28(a0)
  count[8] = 1;
    80002bea:	d11c                	sw	a5,32(a0)
  count[9] = 1;
    80002bec:	d15c                	sw	a5,36(a0)
  count[10] = 1;
    80002bee:	d51c                	sw	a5,40(a0)
  count[11] = 0;
    80002bf0:	02052623          	sw	zero,44(a0)
  count[12] = 1;
    80002bf4:	d91c                	sw	a5,48(a0)
  count[13] = 1;
    80002bf6:	d95c                	sw	a5,52(a0)
  count[14] = 0;
    80002bf8:	02052c23          	sw	zero,56(a0)
  count[15] = 2;
    80002bfc:	dd58                	sw	a4,60(a0)
  count[16] = 3;
    80002bfe:	c134                	sw	a3,64(a0)
  count[17] = 3;
    80002c00:	c174                	sw	a3,68(a0)
  count[18] = 1;
    80002c02:	c53c                	sw	a5,72(a0)
  count[19] = 2;
    80002c04:	c578                	sw	a4,76(a0)
  count[20] = 1;
    80002c06:	c93c                	sw	a5,80(a0)
  count[21] = 1;
    80002c08:	c97c                	sw	a5,84(a0)
  count[22] = 1;
    80002c0a:	cd3c                	sw	a5,88(a0)
}
    80002c0c:	6422                	ld	s0,8(sp)
    80002c0e:	0141                	addi	sp,sp,16
    80002c10:	8082                	ret

0000000080002c12 <syscall>:

void
syscall(void)
{
    80002c12:	710d                	addi	sp,sp,-352
    80002c14:	ee86                	sd	ra,344(sp)
    80002c16:	eaa2                	sd	s0,336(sp)
    80002c18:	e6a6                	sd	s1,328(sp)
    80002c1a:	e2ca                	sd	s2,320(sp)
    80002c1c:	fe4e                	sd	s3,312(sp)
    80002c1e:	1280                	addi	s0,sp,352
  char *names[25];
  SyscallNamesArray(names);
    80002c20:	f0840513          	addi	a0,s0,-248
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	ec0080e7          	jalr	-320(ra) # 80002ae4 <SyscallNamesArray>
  int count[25];
  ArgumentCount(count);
    80002c2c:	ea040513          	addi	a0,s0,-352
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	f9c080e7          	jalr	-100(ra) # 80002bcc <ArgumentCount>
  int num;
  struct proc *p = myproc();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	d78080e7          	jalr	-648(ra) # 800019b0 <myproc>
    80002c40:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c42:	05853903          	ld	s2,88(a0)
    80002c46:	0a893783          	ld	a5,168(s2)
    80002c4a:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) 
    80002c4e:	37fd                	addiw	a5,a5,-1
    80002c50:	4755                	li	a4,21
    80002c52:	0ef76b63          	bltu	a4,a5,80002d48 <syscall+0x136>
    80002c56:	00399713          	slli	a4,s3,0x3
    80002c5a:	00006797          	auipc	a5,0x6
    80002c5e:	8e678793          	addi	a5,a5,-1818 # 80008540 <syscalls>
    80002c62:	97ba                	add	a5,a5,a4
    80002c64:	639c                	ld	a5,0(a5)
    80002c66:	c3ed                	beqz	a5,80002d48 <syscall+0x136>
  {
    p->trapframe->a0 = syscalls[num]();
    80002c68:	9782                	jalr	a5
    80002c6a:	06a93823          	sd	a0,112(s2)
    int mask = p->mask;
    if((mask >> num) &0x1 )
    80002c6e:	1684a783          	lw	a5,360(s1)
    80002c72:	4137d7bb          	sraw	a5,a5,s3
    80002c76:	8b85                	andi	a5,a5,1
    80002c78:	c7fd                	beqz	a5,80002d66 <syscall+0x154>
    {
      //printf("%d: sycscall %s (%d, %d, %d) ->%d\n",p->pid,names[num],p->trapframe->a2,p->trapframe->a1,p->trapframe->a3,p->trapframe->a0);
      printf("%d: syscall %s (",p->pid,names[num]);
    80002c7a:	00399793          	slli	a5,s3,0x3
    80002c7e:	fd040713          	addi	a4,s0,-48
    80002c82:	97ba                	add	a5,a5,a4
    80002c84:	f387b603          	ld	a2,-200(a5)
    80002c88:	588c                	lw	a1,48(s1)
    80002c8a:	00006517          	auipc	a0,0x6
    80002c8e:	82e50513          	addi	a0,a0,-2002 # 800084b8 <states.2432+0x1f8>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8f6080e7          	jalr	-1802(ra) # 80000588 <printf>
      if(count[num]==3)
    80002c9a:	00299793          	slli	a5,s3,0x2
    80002c9e:	fd040713          	addi	a4,s0,-48
    80002ca2:	97ba                	add	a5,a5,a4
    80002ca4:	ed07a703          	lw	a4,-304(a5)
    80002ca8:	478d                	li	a5,3
    80002caa:	04f70863          	beq	a4,a5,80002cfa <syscall+0xe8>
      {
        printf("%d, %d, %d) -> %d\n", p->trapframe->a3,p->trapframe->a2,p->trapframe->a1, p->trapframe->a0);
      }
      if(count[num]==2)
    80002cae:	00299793          	slli	a5,s3,0x2
    80002cb2:	fd040713          	addi	a4,s0,-48
    80002cb6:	97ba                	add	a5,a5,a4
    80002cb8:	ed07a703          	lw	a4,-304(a5)
    80002cbc:	4789                	li	a5,2
    80002cbe:	04f70c63          	beq	a4,a5,80002d16 <syscall+0x104>
      {
        printf("%d, %d) -> %d\n", p->trapframe->a2,p->trapframe->a1, p->trapframe->a0);
      }
      if(count[num]==1)
    80002cc2:	00299793          	slli	a5,s3,0x2
    80002cc6:	fd040713          	addi	a4,s0,-48
    80002cca:	97ba                	add	a5,a5,a4
    80002ccc:	ed07a703          	lw	a4,-304(a5)
    80002cd0:	4785                	li	a5,1
    80002cd2:	04f70f63          	beq	a4,a5,80002d30 <syscall+0x11e>
      {
        printf("%d) -> %d\n",p->trapframe->a1, p->trapframe->a0);
      }
      if(count[num]==0)
    80002cd6:	098a                	slli	s3,s3,0x2
    80002cd8:	fd040793          	addi	a5,s0,-48
    80002cdc:	99be                	add	s3,s3,a5
    80002cde:	ed09a783          	lw	a5,-304(s3)
    80002ce2:	e3d1                	bnez	a5,80002d66 <syscall+0x154>
      {
        printf(") -> %d\n",p->trapframe->a0);
    80002ce4:	6cbc                	ld	a5,88(s1)
    80002ce6:	7bac                	ld	a1,112(a5)
    80002ce8:	00006517          	auipc	a0,0x6
    80002cec:	81050513          	addi	a0,a0,-2032 # 800084f8 <states.2432+0x238>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	898080e7          	jalr	-1896(ra) # 80000588 <printf>
    80002cf8:	a0bd                	j	80002d66 <syscall+0x154>
        printf("%d, %d, %d) -> %d\n", p->trapframe->a3,p->trapframe->a2,p->trapframe->a1, p->trapframe->a0);
    80002cfa:	6cbc                	ld	a5,88(s1)
    80002cfc:	7bb8                	ld	a4,112(a5)
    80002cfe:	7fb4                	ld	a3,120(a5)
    80002d00:	63d0                	ld	a2,128(a5)
    80002d02:	67cc                	ld	a1,136(a5)
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	7cc50513          	addi	a0,a0,1996 # 800084d0 <states.2432+0x210>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	87c080e7          	jalr	-1924(ra) # 80000588 <printf>
    80002d14:	bf69                	j	80002cae <syscall+0x9c>
        printf("%d, %d) -> %d\n", p->trapframe->a2,p->trapframe->a1, p->trapframe->a0);
    80002d16:	6cbc                	ld	a5,88(s1)
    80002d18:	7bb4                	ld	a3,112(a5)
    80002d1a:	7fb0                	ld	a2,120(a5)
    80002d1c:	63cc                	ld	a1,128(a5)
    80002d1e:	00005517          	auipc	a0,0x5
    80002d22:	7ca50513          	addi	a0,a0,1994 # 800084e8 <states.2432+0x228>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	862080e7          	jalr	-1950(ra) # 80000588 <printf>
    80002d2e:	bf51                	j	80002cc2 <syscall+0xb0>
        printf("%d) -> %d\n",p->trapframe->a1, p->trapframe->a0);
    80002d30:	6cbc                	ld	a5,88(s1)
    80002d32:	7bb0                	ld	a2,112(a5)
    80002d34:	7fac                	ld	a1,120(a5)
    80002d36:	00005517          	auipc	a0,0x5
    80002d3a:	7a250513          	addi	a0,a0,1954 # 800084d8 <states.2432+0x218>
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	84a080e7          	jalr	-1974(ra) # 80000588 <printf>
    80002d46:	bf41                	j	80002cd6 <syscall+0xc4>
      }
    }
  } 
  else 
  {
    printf("%d %s: unknown sys call %d\n",
    80002d48:	86ce                	mv	a3,s3
    80002d4a:	15848613          	addi	a2,s1,344
    80002d4e:	588c                	lw	a1,48(s1)
    80002d50:	00005517          	auipc	a0,0x5
    80002d54:	7b850513          	addi	a0,a0,1976 # 80008508 <states.2432+0x248>
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	830080e7          	jalr	-2000(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d60:	6cbc                	ld	a5,88(s1)
    80002d62:	577d                	li	a4,-1
    80002d64:	fbb8                	sd	a4,112(a5)
  }
}
    80002d66:	60f6                	ld	ra,344(sp)
    80002d68:	6456                	ld	s0,336(sp)
    80002d6a:	64b6                	ld	s1,328(sp)
    80002d6c:	6916                	ld	s2,320(sp)
    80002d6e:	79f2                	ld	s3,312(sp)
    80002d70:	6135                	addi	sp,sp,352
    80002d72:	8082                	ret

0000000080002d74 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d74:	1101                	addi	sp,sp,-32
    80002d76:	ec06                	sd	ra,24(sp)
    80002d78:	e822                	sd	s0,16(sp)
    80002d7a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d7c:	fec40593          	addi	a1,s0,-20
    80002d80:	4501                	li	a0,0
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	cee080e7          	jalr	-786(ra) # 80002a70 <argint>
    return -1;
    80002d8a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d8c:	00054963          	bltz	a0,80002d9e <sys_exit+0x2a>
  exit(n);
    80002d90:	fec42503          	lw	a0,-20(s0)
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	590080e7          	jalr	1424(ra) # 80002324 <exit>
  return 0;  // not reached
    80002d9c:	4781                	li	a5,0
}
    80002d9e:	853e                	mv	a0,a5
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002da8:	1141                	addi	sp,sp,-16
    80002daa:	e406                	sd	ra,8(sp)
    80002dac:	e022                	sd	s0,0(sp)
    80002dae:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	c00080e7          	jalr	-1024(ra) # 800019b0 <myproc>
}
    80002db8:	5908                	lw	a0,48(a0)
    80002dba:	60a2                	ld	ra,8(sp)
    80002dbc:	6402                	ld	s0,0(sp)
    80002dbe:	0141                	addi	sp,sp,16
    80002dc0:	8082                	ret

0000000080002dc2 <sys_fork>:

uint64
sys_fork(void)
{
    80002dc2:	1141                	addi	sp,sp,-16
    80002dc4:	e406                	sd	ra,8(sp)
    80002dc6:	e022                	sd	s0,0(sp)
    80002dc8:	0800                	addi	s0,sp,16
  return fork();
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	fc4080e7          	jalr	-60(ra) # 80001d8e <fork>
}
    80002dd2:	60a2                	ld	ra,8(sp)
    80002dd4:	6402                	ld	s0,0(sp)
    80002dd6:	0141                	addi	sp,sp,16
    80002dd8:	8082                	ret

0000000080002dda <sys_wait>:

uint64
sys_wait(void)
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002de2:	fe840593          	addi	a1,s0,-24
    80002de6:	4501                	li	a0,0
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	caa080e7          	jalr	-854(ra) # 80002a92 <argaddr>
    80002df0:	87aa                	mv	a5,a0
    return -1;
    80002df2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002df4:	0007c863          	bltz	a5,80002e04 <sys_wait+0x2a>
  return wait(p);
    80002df8:	fe843503          	ld	a0,-24(s0)
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	330080e7          	jalr	816(ra) # 8000212c <wait>
}
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	6105                	addi	sp,sp,32
    80002e0a:	8082                	ret

0000000080002e0c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e0c:	7179                	addi	sp,sp,-48
    80002e0e:	f406                	sd	ra,40(sp)
    80002e10:	f022                	sd	s0,32(sp)
    80002e12:	ec26                	sd	s1,24(sp)
    80002e14:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e16:	fdc40593          	addi	a1,s0,-36
    80002e1a:	4501                	li	a0,0
    80002e1c:	00000097          	auipc	ra,0x0
    80002e20:	c54080e7          	jalr	-940(ra) # 80002a70 <argint>
    80002e24:	87aa                	mv	a5,a0
    return -1;
    80002e26:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e28:	0207c063          	bltz	a5,80002e48 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	b84080e7          	jalr	-1148(ra) # 800019b0 <myproc>
    80002e34:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e36:	fdc42503          	lw	a0,-36(s0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	ee0080e7          	jalr	-288(ra) # 80001d1a <growproc>
    80002e42:	00054863          	bltz	a0,80002e52 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e46:	8526                	mv	a0,s1
}
    80002e48:	70a2                	ld	ra,40(sp)
    80002e4a:	7402                	ld	s0,32(sp)
    80002e4c:	64e2                	ld	s1,24(sp)
    80002e4e:	6145                	addi	sp,sp,48
    80002e50:	8082                	ret
    return -1;
    80002e52:	557d                	li	a0,-1
    80002e54:	bfd5                	j	80002e48 <sys_sbrk+0x3c>

0000000080002e56 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e56:	7139                	addi	sp,sp,-64
    80002e58:	fc06                	sd	ra,56(sp)
    80002e5a:	f822                	sd	s0,48(sp)
    80002e5c:	f426                	sd	s1,40(sp)
    80002e5e:	f04a                	sd	s2,32(sp)
    80002e60:	ec4e                	sd	s3,24(sp)
    80002e62:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e64:	fcc40593          	addi	a1,s0,-52
    80002e68:	4501                	li	a0,0
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	c06080e7          	jalr	-1018(ra) # 80002a70 <argint>
    return -1;
    80002e72:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e74:	06054563          	bltz	a0,80002ede <sys_sleep+0x88>
  acquire(&tickslock);
    80002e78:	00015517          	auipc	a0,0x15
    80002e7c:	05850513          	addi	a0,a0,88 # 80017ed0 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	d64080e7          	jalr	-668(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e88:	00006917          	auipc	s2,0x6
    80002e8c:	1b092903          	lw	s2,432(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002e90:	fcc42783          	lw	a5,-52(s0)
    80002e94:	cf85                	beqz	a5,80002ecc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e96:	00015997          	auipc	s3,0x15
    80002e9a:	03a98993          	addi	s3,s3,58 # 80017ed0 <tickslock>
    80002e9e:	00006497          	auipc	s1,0x6
    80002ea2:	19a48493          	addi	s1,s1,410 # 80009038 <ticks>
    if(myproc()->killed){
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	b0a080e7          	jalr	-1270(ra) # 800019b0 <myproc>
    80002eae:	551c                	lw	a5,40(a0)
    80002eb0:	ef9d                	bnez	a5,80002eee <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002eb2:	85ce                	mv	a1,s3
    80002eb4:	8526                	mv	a0,s1
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	212080e7          	jalr	530(ra) # 800020c8 <sleep>
  while(ticks - ticks0 < n){
    80002ebe:	409c                	lw	a5,0(s1)
    80002ec0:	412787bb          	subw	a5,a5,s2
    80002ec4:	fcc42703          	lw	a4,-52(s0)
    80002ec8:	fce7efe3          	bltu	a5,a4,80002ea6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ecc:	00015517          	auipc	a0,0x15
    80002ed0:	00450513          	addi	a0,a0,4 # 80017ed0 <tickslock>
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	dc4080e7          	jalr	-572(ra) # 80000c98 <release>
  return 0;
    80002edc:	4781                	li	a5,0
}
    80002ede:	853e                	mv	a0,a5
    80002ee0:	70e2                	ld	ra,56(sp)
    80002ee2:	7442                	ld	s0,48(sp)
    80002ee4:	74a2                	ld	s1,40(sp)
    80002ee6:	7902                	ld	s2,32(sp)
    80002ee8:	69e2                	ld	s3,24(sp)
    80002eea:	6121                	addi	sp,sp,64
    80002eec:	8082                	ret
      release(&tickslock);
    80002eee:	00015517          	auipc	a0,0x15
    80002ef2:	fe250513          	addi	a0,a0,-30 # 80017ed0 <tickslock>
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	da2080e7          	jalr	-606(ra) # 80000c98 <release>
      return -1;
    80002efe:	57fd                	li	a5,-1
    80002f00:	bff9                	j	80002ede <sys_sleep+0x88>

0000000080002f02 <sys_kill>:

uint64
sys_kill(void)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f0a:	fec40593          	addi	a1,s0,-20
    80002f0e:	4501                	li	a0,0
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	b60080e7          	jalr	-1184(ra) # 80002a70 <argint>
    80002f18:	87aa                	mv	a5,a0
    return -1;
    80002f1a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f1c:	0007c863          	bltz	a5,80002f2c <sys_kill+0x2a>
  return kill(pid);
    80002f20:	fec42503          	lw	a0,-20(s0)
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	4d6080e7          	jalr	1238(ra) # 800023fa <kill>
}
    80002f2c:	60e2                	ld	ra,24(sp)
    80002f2e:	6442                	ld	s0,16(sp)
    80002f30:	6105                	addi	sp,sp,32
    80002f32:	8082                	ret

0000000080002f34 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f34:	1101                	addi	sp,sp,-32
    80002f36:	ec06                	sd	ra,24(sp)
    80002f38:	e822                	sd	s0,16(sp)
    80002f3a:	e426                	sd	s1,8(sp)
    80002f3c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f3e:	00015517          	auipc	a0,0x15
    80002f42:	f9250513          	addi	a0,a0,-110 # 80017ed0 <tickslock>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	c9e080e7          	jalr	-866(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f4e:	00006497          	auipc	s1,0x6
    80002f52:	0ea4a483          	lw	s1,234(s1) # 80009038 <ticks>
  release(&tickslock);
    80002f56:	00015517          	auipc	a0,0x15
    80002f5a:	f7a50513          	addi	a0,a0,-134 # 80017ed0 <tickslock>
    80002f5e:	ffffe097          	auipc	ra,0xffffe
    80002f62:	d3a080e7          	jalr	-710(ra) # 80000c98 <release>
  return xticks;
}
    80002f66:	02049513          	slli	a0,s1,0x20
    80002f6a:	9101                	srli	a0,a0,0x20
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	64a2                	ld	s1,8(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret

0000000080002f76 <sys_trace>:

uint64
sys_trace(void)
{
    80002f76:	1101                	addi	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	1000                	addi	s0,sp,32
  int mask=0;
    80002f7e:	fe042623          	sw	zero,-20(s0)
  if(argint(0,&mask)<0)
    80002f82:	fec40593          	addi	a1,s0,-20
    80002f86:	4501                	li	a0,0
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	ae8080e7          	jalr	-1304(ra) # 80002a70 <argint>
  {
    return -1;
    80002f90:	57fd                	li	a5,-1
  if(argint(0,&mask)<0)
    80002f92:	00054b63          	bltz	a0,80002fa8 <sys_trace+0x32>
  }
  myproc()->mask = mask;
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	a1a080e7          	jalr	-1510(ra) # 800019b0 <myproc>
    80002f9e:	fec42783          	lw	a5,-20(s0)
    80002fa2:	16f52423          	sw	a5,360(a0)
  return 0;
    80002fa6:	4781                	li	a5,0
}
    80002fa8:	853e                	mv	a0,a5
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	6105                	addi	sp,sp,32
    80002fb0:	8082                	ret

0000000080002fb2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fb2:	7179                	addi	sp,sp,-48
    80002fb4:	f406                	sd	ra,40(sp)
    80002fb6:	f022                	sd	s0,32(sp)
    80002fb8:	ec26                	sd	s1,24(sp)
    80002fba:	e84a                	sd	s2,16(sp)
    80002fbc:	e44e                	sd	s3,8(sp)
    80002fbe:	e052                	sd	s4,0(sp)
    80002fc0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fc2:	00005597          	auipc	a1,0x5
    80002fc6:	63658593          	addi	a1,a1,1590 # 800085f8 <syscalls+0xb8>
    80002fca:	00015517          	auipc	a0,0x15
    80002fce:	f1e50513          	addi	a0,a0,-226 # 80017ee8 <bcache>
    80002fd2:	ffffe097          	auipc	ra,0xffffe
    80002fd6:	b82080e7          	jalr	-1150(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fda:	0001d797          	auipc	a5,0x1d
    80002fde:	f0e78793          	addi	a5,a5,-242 # 8001fee8 <bcache+0x8000>
    80002fe2:	0001d717          	auipc	a4,0x1d
    80002fe6:	16e70713          	addi	a4,a4,366 # 80020150 <bcache+0x8268>
    80002fea:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fee:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ff2:	00015497          	auipc	s1,0x15
    80002ff6:	f0e48493          	addi	s1,s1,-242 # 80017f00 <bcache+0x18>
    b->next = bcache.head.next;
    80002ffa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ffc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ffe:	00005a17          	auipc	s4,0x5
    80003002:	602a0a13          	addi	s4,s4,1538 # 80008600 <syscalls+0xc0>
    b->next = bcache.head.next;
    80003006:	2b893783          	ld	a5,696(s2)
    8000300a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000300c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003010:	85d2                	mv	a1,s4
    80003012:	01048513          	addi	a0,s1,16
    80003016:	00001097          	auipc	ra,0x1
    8000301a:	4bc080e7          	jalr	1212(ra) # 800044d2 <initsleeplock>
    bcache.head.next->prev = b;
    8000301e:	2b893783          	ld	a5,696(s2)
    80003022:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003024:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003028:	45848493          	addi	s1,s1,1112
    8000302c:	fd349de3          	bne	s1,s3,80003006 <binit+0x54>
  }
}
    80003030:	70a2                	ld	ra,40(sp)
    80003032:	7402                	ld	s0,32(sp)
    80003034:	64e2                	ld	s1,24(sp)
    80003036:	6942                	ld	s2,16(sp)
    80003038:	69a2                	ld	s3,8(sp)
    8000303a:	6a02                	ld	s4,0(sp)
    8000303c:	6145                	addi	sp,sp,48
    8000303e:	8082                	ret

0000000080003040 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003040:	7179                	addi	sp,sp,-48
    80003042:	f406                	sd	ra,40(sp)
    80003044:	f022                	sd	s0,32(sp)
    80003046:	ec26                	sd	s1,24(sp)
    80003048:	e84a                	sd	s2,16(sp)
    8000304a:	e44e                	sd	s3,8(sp)
    8000304c:	1800                	addi	s0,sp,48
    8000304e:	89aa                	mv	s3,a0
    80003050:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003052:	00015517          	auipc	a0,0x15
    80003056:	e9650513          	addi	a0,a0,-362 # 80017ee8 <bcache>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	b8a080e7          	jalr	-1142(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003062:	0001d497          	auipc	s1,0x1d
    80003066:	13e4b483          	ld	s1,318(s1) # 800201a0 <bcache+0x82b8>
    8000306a:	0001d797          	auipc	a5,0x1d
    8000306e:	0e678793          	addi	a5,a5,230 # 80020150 <bcache+0x8268>
    80003072:	02f48f63          	beq	s1,a5,800030b0 <bread+0x70>
    80003076:	873e                	mv	a4,a5
    80003078:	a021                	j	80003080 <bread+0x40>
    8000307a:	68a4                	ld	s1,80(s1)
    8000307c:	02e48a63          	beq	s1,a4,800030b0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003080:	449c                	lw	a5,8(s1)
    80003082:	ff379ce3          	bne	a5,s3,8000307a <bread+0x3a>
    80003086:	44dc                	lw	a5,12(s1)
    80003088:	ff2799e3          	bne	a5,s2,8000307a <bread+0x3a>
      b->refcnt++;
    8000308c:	40bc                	lw	a5,64(s1)
    8000308e:	2785                	addiw	a5,a5,1
    80003090:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003092:	00015517          	auipc	a0,0x15
    80003096:	e5650513          	addi	a0,a0,-426 # 80017ee8 <bcache>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030a2:	01048513          	addi	a0,s1,16
    800030a6:	00001097          	auipc	ra,0x1
    800030aa:	466080e7          	jalr	1126(ra) # 8000450c <acquiresleep>
      return b;
    800030ae:	a8b9                	j	8000310c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030b0:	0001d497          	auipc	s1,0x1d
    800030b4:	0e84b483          	ld	s1,232(s1) # 80020198 <bcache+0x82b0>
    800030b8:	0001d797          	auipc	a5,0x1d
    800030bc:	09878793          	addi	a5,a5,152 # 80020150 <bcache+0x8268>
    800030c0:	00f48863          	beq	s1,a5,800030d0 <bread+0x90>
    800030c4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030c6:	40bc                	lw	a5,64(s1)
    800030c8:	cf81                	beqz	a5,800030e0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ca:	64a4                	ld	s1,72(s1)
    800030cc:	fee49de3          	bne	s1,a4,800030c6 <bread+0x86>
  panic("bget: no buffers");
    800030d0:	00005517          	auipc	a0,0x5
    800030d4:	53850513          	addi	a0,a0,1336 # 80008608 <syscalls+0xc8>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	466080e7          	jalr	1126(ra) # 8000053e <panic>
      b->dev = dev;
    800030e0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030e4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030e8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030ec:	4785                	li	a5,1
    800030ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030f0:	00015517          	auipc	a0,0x15
    800030f4:	df850513          	addi	a0,a0,-520 # 80017ee8 <bcache>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003100:	01048513          	addi	a0,s1,16
    80003104:	00001097          	auipc	ra,0x1
    80003108:	408080e7          	jalr	1032(ra) # 8000450c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000310c:	409c                	lw	a5,0(s1)
    8000310e:	cb89                	beqz	a5,80003120 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003110:	8526                	mv	a0,s1
    80003112:	70a2                	ld	ra,40(sp)
    80003114:	7402                	ld	s0,32(sp)
    80003116:	64e2                	ld	s1,24(sp)
    80003118:	6942                	ld	s2,16(sp)
    8000311a:	69a2                	ld	s3,8(sp)
    8000311c:	6145                	addi	sp,sp,48
    8000311e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003120:	4581                	li	a1,0
    80003122:	8526                	mv	a0,s1
    80003124:	00003097          	auipc	ra,0x3
    80003128:	f12080e7          	jalr	-238(ra) # 80006036 <virtio_disk_rw>
    b->valid = 1;
    8000312c:	4785                	li	a5,1
    8000312e:	c09c                	sw	a5,0(s1)
  return b;
    80003130:	b7c5                	j	80003110 <bread+0xd0>

0000000080003132 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	e426                	sd	s1,8(sp)
    8000313a:	1000                	addi	s0,sp,32
    8000313c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000313e:	0541                	addi	a0,a0,16
    80003140:	00001097          	auipc	ra,0x1
    80003144:	466080e7          	jalr	1126(ra) # 800045a6 <holdingsleep>
    80003148:	cd01                	beqz	a0,80003160 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000314a:	4585                	li	a1,1
    8000314c:	8526                	mv	a0,s1
    8000314e:	00003097          	auipc	ra,0x3
    80003152:	ee8080e7          	jalr	-280(ra) # 80006036 <virtio_disk_rw>
}
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	64a2                	ld	s1,8(sp)
    8000315c:	6105                	addi	sp,sp,32
    8000315e:	8082                	ret
    panic("bwrite");
    80003160:	00005517          	auipc	a0,0x5
    80003164:	4c050513          	addi	a0,a0,1216 # 80008620 <syscalls+0xe0>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	3d6080e7          	jalr	982(ra) # 8000053e <panic>

0000000080003170 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003170:	1101                	addi	sp,sp,-32
    80003172:	ec06                	sd	ra,24(sp)
    80003174:	e822                	sd	s0,16(sp)
    80003176:	e426                	sd	s1,8(sp)
    80003178:	e04a                	sd	s2,0(sp)
    8000317a:	1000                	addi	s0,sp,32
    8000317c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000317e:	01050913          	addi	s2,a0,16
    80003182:	854a                	mv	a0,s2
    80003184:	00001097          	auipc	ra,0x1
    80003188:	422080e7          	jalr	1058(ra) # 800045a6 <holdingsleep>
    8000318c:	c92d                	beqz	a0,800031fe <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000318e:	854a                	mv	a0,s2
    80003190:	00001097          	auipc	ra,0x1
    80003194:	3d2080e7          	jalr	978(ra) # 80004562 <releasesleep>

  acquire(&bcache.lock);
    80003198:	00015517          	auipc	a0,0x15
    8000319c:	d5050513          	addi	a0,a0,-688 # 80017ee8 <bcache>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	a44080e7          	jalr	-1468(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031a8:	40bc                	lw	a5,64(s1)
    800031aa:	37fd                	addiw	a5,a5,-1
    800031ac:	0007871b          	sext.w	a4,a5
    800031b0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031b2:	eb05                	bnez	a4,800031e2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031b4:	68bc                	ld	a5,80(s1)
    800031b6:	64b8                	ld	a4,72(s1)
    800031b8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031ba:	64bc                	ld	a5,72(s1)
    800031bc:	68b8                	ld	a4,80(s1)
    800031be:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031c0:	0001d797          	auipc	a5,0x1d
    800031c4:	d2878793          	addi	a5,a5,-728 # 8001fee8 <bcache+0x8000>
    800031c8:	2b87b703          	ld	a4,696(a5)
    800031cc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031ce:	0001d717          	auipc	a4,0x1d
    800031d2:	f8270713          	addi	a4,a4,-126 # 80020150 <bcache+0x8268>
    800031d6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031d8:	2b87b703          	ld	a4,696(a5)
    800031dc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031de:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031e2:	00015517          	auipc	a0,0x15
    800031e6:	d0650513          	addi	a0,a0,-762 # 80017ee8 <bcache>
    800031ea:	ffffe097          	auipc	ra,0xffffe
    800031ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6902                	ld	s2,0(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret
    panic("brelse");
    800031fe:	00005517          	auipc	a0,0x5
    80003202:	42a50513          	addi	a0,a0,1066 # 80008628 <syscalls+0xe8>
    80003206:	ffffd097          	auipc	ra,0xffffd
    8000320a:	338080e7          	jalr	824(ra) # 8000053e <panic>

000000008000320e <bpin>:

void
bpin(struct buf *b) {
    8000320e:	1101                	addi	sp,sp,-32
    80003210:	ec06                	sd	ra,24(sp)
    80003212:	e822                	sd	s0,16(sp)
    80003214:	e426                	sd	s1,8(sp)
    80003216:	1000                	addi	s0,sp,32
    80003218:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000321a:	00015517          	auipc	a0,0x15
    8000321e:	cce50513          	addi	a0,a0,-818 # 80017ee8 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	9c2080e7          	jalr	-1598(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000322a:	40bc                	lw	a5,64(s1)
    8000322c:	2785                	addiw	a5,a5,1
    8000322e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003230:	00015517          	auipc	a0,0x15
    80003234:	cb850513          	addi	a0,a0,-840 # 80017ee8 <bcache>
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	a60080e7          	jalr	-1440(ra) # 80000c98 <release>
}
    80003240:	60e2                	ld	ra,24(sp)
    80003242:	6442                	ld	s0,16(sp)
    80003244:	64a2                	ld	s1,8(sp)
    80003246:	6105                	addi	sp,sp,32
    80003248:	8082                	ret

000000008000324a <bunpin>:

void
bunpin(struct buf *b) {
    8000324a:	1101                	addi	sp,sp,-32
    8000324c:	ec06                	sd	ra,24(sp)
    8000324e:	e822                	sd	s0,16(sp)
    80003250:	e426                	sd	s1,8(sp)
    80003252:	1000                	addi	s0,sp,32
    80003254:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003256:	00015517          	auipc	a0,0x15
    8000325a:	c9250513          	addi	a0,a0,-878 # 80017ee8 <bcache>
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	986080e7          	jalr	-1658(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003266:	40bc                	lw	a5,64(s1)
    80003268:	37fd                	addiw	a5,a5,-1
    8000326a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000326c:	00015517          	auipc	a0,0x15
    80003270:	c7c50513          	addi	a0,a0,-900 # 80017ee8 <bcache>
    80003274:	ffffe097          	auipc	ra,0xffffe
    80003278:	a24080e7          	jalr	-1500(ra) # 80000c98 <release>
}
    8000327c:	60e2                	ld	ra,24(sp)
    8000327e:	6442                	ld	s0,16(sp)
    80003280:	64a2                	ld	s1,8(sp)
    80003282:	6105                	addi	sp,sp,32
    80003284:	8082                	ret

0000000080003286 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003286:	1101                	addi	sp,sp,-32
    80003288:	ec06                	sd	ra,24(sp)
    8000328a:	e822                	sd	s0,16(sp)
    8000328c:	e426                	sd	s1,8(sp)
    8000328e:	e04a                	sd	s2,0(sp)
    80003290:	1000                	addi	s0,sp,32
    80003292:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003294:	00d5d59b          	srliw	a1,a1,0xd
    80003298:	0001d797          	auipc	a5,0x1d
    8000329c:	32c7a783          	lw	a5,812(a5) # 800205c4 <sb+0x1c>
    800032a0:	9dbd                	addw	a1,a1,a5
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	d9e080e7          	jalr	-610(ra) # 80003040 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032aa:	0074f713          	andi	a4,s1,7
    800032ae:	4785                	li	a5,1
    800032b0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032b4:	14ce                	slli	s1,s1,0x33
    800032b6:	90d9                	srli	s1,s1,0x36
    800032b8:	00950733          	add	a4,a0,s1
    800032bc:	05874703          	lbu	a4,88(a4)
    800032c0:	00e7f6b3          	and	a3,a5,a4
    800032c4:	c69d                	beqz	a3,800032f2 <bfree+0x6c>
    800032c6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032c8:	94aa                	add	s1,s1,a0
    800032ca:	fff7c793          	not	a5,a5
    800032ce:	8ff9                	and	a5,a5,a4
    800032d0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032d4:	00001097          	auipc	ra,0x1
    800032d8:	118080e7          	jalr	280(ra) # 800043ec <log_write>
  brelse(bp);
    800032dc:	854a                	mv	a0,s2
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	e92080e7          	jalr	-366(ra) # 80003170 <brelse>
}
    800032e6:	60e2                	ld	ra,24(sp)
    800032e8:	6442                	ld	s0,16(sp)
    800032ea:	64a2                	ld	s1,8(sp)
    800032ec:	6902                	ld	s2,0(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret
    panic("freeing free block");
    800032f2:	00005517          	auipc	a0,0x5
    800032f6:	33e50513          	addi	a0,a0,830 # 80008630 <syscalls+0xf0>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	244080e7          	jalr	580(ra) # 8000053e <panic>

0000000080003302 <balloc>:
{
    80003302:	711d                	addi	sp,sp,-96
    80003304:	ec86                	sd	ra,88(sp)
    80003306:	e8a2                	sd	s0,80(sp)
    80003308:	e4a6                	sd	s1,72(sp)
    8000330a:	e0ca                	sd	s2,64(sp)
    8000330c:	fc4e                	sd	s3,56(sp)
    8000330e:	f852                	sd	s4,48(sp)
    80003310:	f456                	sd	s5,40(sp)
    80003312:	f05a                	sd	s6,32(sp)
    80003314:	ec5e                	sd	s7,24(sp)
    80003316:	e862                	sd	s8,16(sp)
    80003318:	e466                	sd	s9,8(sp)
    8000331a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000331c:	0001d797          	auipc	a5,0x1d
    80003320:	2907a783          	lw	a5,656(a5) # 800205ac <sb+0x4>
    80003324:	cbd1                	beqz	a5,800033b8 <balloc+0xb6>
    80003326:	8baa                	mv	s7,a0
    80003328:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000332a:	0001db17          	auipc	s6,0x1d
    8000332e:	27eb0b13          	addi	s6,s6,638 # 800205a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003332:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003334:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003336:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003338:	6c89                	lui	s9,0x2
    8000333a:	a831                	j	80003356 <balloc+0x54>
    brelse(bp);
    8000333c:	854a                	mv	a0,s2
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	e32080e7          	jalr	-462(ra) # 80003170 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003346:	015c87bb          	addw	a5,s9,s5
    8000334a:	00078a9b          	sext.w	s5,a5
    8000334e:	004b2703          	lw	a4,4(s6)
    80003352:	06eaf363          	bgeu	s5,a4,800033b8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003356:	41fad79b          	sraiw	a5,s5,0x1f
    8000335a:	0137d79b          	srliw	a5,a5,0x13
    8000335e:	015787bb          	addw	a5,a5,s5
    80003362:	40d7d79b          	sraiw	a5,a5,0xd
    80003366:	01cb2583          	lw	a1,28(s6)
    8000336a:	9dbd                	addw	a1,a1,a5
    8000336c:	855e                	mv	a0,s7
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	cd2080e7          	jalr	-814(ra) # 80003040 <bread>
    80003376:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003378:	004b2503          	lw	a0,4(s6)
    8000337c:	000a849b          	sext.w	s1,s5
    80003380:	8662                	mv	a2,s8
    80003382:	faa4fde3          	bgeu	s1,a0,8000333c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003386:	41f6579b          	sraiw	a5,a2,0x1f
    8000338a:	01d7d69b          	srliw	a3,a5,0x1d
    8000338e:	00c6873b          	addw	a4,a3,a2
    80003392:	00777793          	andi	a5,a4,7
    80003396:	9f95                	subw	a5,a5,a3
    80003398:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000339c:	4037571b          	sraiw	a4,a4,0x3
    800033a0:	00e906b3          	add	a3,s2,a4
    800033a4:	0586c683          	lbu	a3,88(a3)
    800033a8:	00d7f5b3          	and	a1,a5,a3
    800033ac:	cd91                	beqz	a1,800033c8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ae:	2605                	addiw	a2,a2,1
    800033b0:	2485                	addiw	s1,s1,1
    800033b2:	fd4618e3          	bne	a2,s4,80003382 <balloc+0x80>
    800033b6:	b759                	j	8000333c <balloc+0x3a>
  panic("balloc: out of blocks");
    800033b8:	00005517          	auipc	a0,0x5
    800033bc:	29050513          	addi	a0,a0,656 # 80008648 <syscalls+0x108>
    800033c0:	ffffd097          	auipc	ra,0xffffd
    800033c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033c8:	974a                	add	a4,a4,s2
    800033ca:	8fd5                	or	a5,a5,a3
    800033cc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033d0:	854a                	mv	a0,s2
    800033d2:	00001097          	auipc	ra,0x1
    800033d6:	01a080e7          	jalr	26(ra) # 800043ec <log_write>
        brelse(bp);
    800033da:	854a                	mv	a0,s2
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	d94080e7          	jalr	-620(ra) # 80003170 <brelse>
  bp = bread(dev, bno);
    800033e4:	85a6                	mv	a1,s1
    800033e6:	855e                	mv	a0,s7
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	c58080e7          	jalr	-936(ra) # 80003040 <bread>
    800033f0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033f2:	40000613          	li	a2,1024
    800033f6:	4581                	li	a1,0
    800033f8:	05850513          	addi	a0,a0,88
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	8e4080e7          	jalr	-1820(ra) # 80000ce0 <memset>
  log_write(bp);
    80003404:	854a                	mv	a0,s2
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	fe6080e7          	jalr	-26(ra) # 800043ec <log_write>
  brelse(bp);
    8000340e:	854a                	mv	a0,s2
    80003410:	00000097          	auipc	ra,0x0
    80003414:	d60080e7          	jalr	-672(ra) # 80003170 <brelse>
}
    80003418:	8526                	mv	a0,s1
    8000341a:	60e6                	ld	ra,88(sp)
    8000341c:	6446                	ld	s0,80(sp)
    8000341e:	64a6                	ld	s1,72(sp)
    80003420:	6906                	ld	s2,64(sp)
    80003422:	79e2                	ld	s3,56(sp)
    80003424:	7a42                	ld	s4,48(sp)
    80003426:	7aa2                	ld	s5,40(sp)
    80003428:	7b02                	ld	s6,32(sp)
    8000342a:	6be2                	ld	s7,24(sp)
    8000342c:	6c42                	ld	s8,16(sp)
    8000342e:	6ca2                	ld	s9,8(sp)
    80003430:	6125                	addi	sp,sp,96
    80003432:	8082                	ret

0000000080003434 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003434:	7179                	addi	sp,sp,-48
    80003436:	f406                	sd	ra,40(sp)
    80003438:	f022                	sd	s0,32(sp)
    8000343a:	ec26                	sd	s1,24(sp)
    8000343c:	e84a                	sd	s2,16(sp)
    8000343e:	e44e                	sd	s3,8(sp)
    80003440:	e052                	sd	s4,0(sp)
    80003442:	1800                	addi	s0,sp,48
    80003444:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003446:	47ad                	li	a5,11
    80003448:	04b7fe63          	bgeu	a5,a1,800034a4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000344c:	ff45849b          	addiw	s1,a1,-12
    80003450:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003454:	0ff00793          	li	a5,255
    80003458:	0ae7e363          	bltu	a5,a4,800034fe <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000345c:	08052583          	lw	a1,128(a0)
    80003460:	c5ad                	beqz	a1,800034ca <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003462:	00092503          	lw	a0,0(s2)
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	bda080e7          	jalr	-1062(ra) # 80003040 <bread>
    8000346e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003470:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003474:	02049593          	slli	a1,s1,0x20
    80003478:	9181                	srli	a1,a1,0x20
    8000347a:	058a                	slli	a1,a1,0x2
    8000347c:	00b784b3          	add	s1,a5,a1
    80003480:	0004a983          	lw	s3,0(s1)
    80003484:	04098d63          	beqz	s3,800034de <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003488:	8552                	mv	a0,s4
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	ce6080e7          	jalr	-794(ra) # 80003170 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003492:	854e                	mv	a0,s3
    80003494:	70a2                	ld	ra,40(sp)
    80003496:	7402                	ld	s0,32(sp)
    80003498:	64e2                	ld	s1,24(sp)
    8000349a:	6942                	ld	s2,16(sp)
    8000349c:	69a2                	ld	s3,8(sp)
    8000349e:	6a02                	ld	s4,0(sp)
    800034a0:	6145                	addi	sp,sp,48
    800034a2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034a4:	02059493          	slli	s1,a1,0x20
    800034a8:	9081                	srli	s1,s1,0x20
    800034aa:	048a                	slli	s1,s1,0x2
    800034ac:	94aa                	add	s1,s1,a0
    800034ae:	0504a983          	lw	s3,80(s1)
    800034b2:	fe0990e3          	bnez	s3,80003492 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034b6:	4108                	lw	a0,0(a0)
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	e4a080e7          	jalr	-438(ra) # 80003302 <balloc>
    800034c0:	0005099b          	sext.w	s3,a0
    800034c4:	0534a823          	sw	s3,80(s1)
    800034c8:	b7e9                	j	80003492 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034ca:	4108                	lw	a0,0(a0)
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	e36080e7          	jalr	-458(ra) # 80003302 <balloc>
    800034d4:	0005059b          	sext.w	a1,a0
    800034d8:	08b92023          	sw	a1,128(s2)
    800034dc:	b759                	j	80003462 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034de:	00092503          	lw	a0,0(s2)
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	e20080e7          	jalr	-480(ra) # 80003302 <balloc>
    800034ea:	0005099b          	sext.w	s3,a0
    800034ee:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034f2:	8552                	mv	a0,s4
    800034f4:	00001097          	auipc	ra,0x1
    800034f8:	ef8080e7          	jalr	-264(ra) # 800043ec <log_write>
    800034fc:	b771                	j	80003488 <bmap+0x54>
  panic("bmap: out of range");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	16250513          	addi	a0,a0,354 # 80008660 <syscalls+0x120>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	038080e7          	jalr	56(ra) # 8000053e <panic>

000000008000350e <iget>:
{
    8000350e:	7179                	addi	sp,sp,-48
    80003510:	f406                	sd	ra,40(sp)
    80003512:	f022                	sd	s0,32(sp)
    80003514:	ec26                	sd	s1,24(sp)
    80003516:	e84a                	sd	s2,16(sp)
    80003518:	e44e                	sd	s3,8(sp)
    8000351a:	e052                	sd	s4,0(sp)
    8000351c:	1800                	addi	s0,sp,48
    8000351e:	89aa                	mv	s3,a0
    80003520:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003522:	0001d517          	auipc	a0,0x1d
    80003526:	0a650513          	addi	a0,a0,166 # 800205c8 <itable>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	6ba080e7          	jalr	1722(ra) # 80000be4 <acquire>
  empty = 0;
    80003532:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003534:	0001d497          	auipc	s1,0x1d
    80003538:	0ac48493          	addi	s1,s1,172 # 800205e0 <itable+0x18>
    8000353c:	0001f697          	auipc	a3,0x1f
    80003540:	b3468693          	addi	a3,a3,-1228 # 80022070 <log>
    80003544:	a039                	j	80003552 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003546:	02090b63          	beqz	s2,8000357c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000354a:	08848493          	addi	s1,s1,136
    8000354e:	02d48a63          	beq	s1,a3,80003582 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003552:	449c                	lw	a5,8(s1)
    80003554:	fef059e3          	blez	a5,80003546 <iget+0x38>
    80003558:	4098                	lw	a4,0(s1)
    8000355a:	ff3716e3          	bne	a4,s3,80003546 <iget+0x38>
    8000355e:	40d8                	lw	a4,4(s1)
    80003560:	ff4713e3          	bne	a4,s4,80003546 <iget+0x38>
      ip->ref++;
    80003564:	2785                	addiw	a5,a5,1
    80003566:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003568:	0001d517          	auipc	a0,0x1d
    8000356c:	06050513          	addi	a0,a0,96 # 800205c8 <itable>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	728080e7          	jalr	1832(ra) # 80000c98 <release>
      return ip;
    80003578:	8926                	mv	s2,s1
    8000357a:	a03d                	j	800035a8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000357c:	f7f9                	bnez	a5,8000354a <iget+0x3c>
    8000357e:	8926                	mv	s2,s1
    80003580:	b7e9                	j	8000354a <iget+0x3c>
  if(empty == 0)
    80003582:	02090c63          	beqz	s2,800035ba <iget+0xac>
  ip->dev = dev;
    80003586:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000358a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000358e:	4785                	li	a5,1
    80003590:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003594:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003598:	0001d517          	auipc	a0,0x1d
    8000359c:	03050513          	addi	a0,a0,48 # 800205c8 <itable>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	6f8080e7          	jalr	1784(ra) # 80000c98 <release>
}
    800035a8:	854a                	mv	a0,s2
    800035aa:	70a2                	ld	ra,40(sp)
    800035ac:	7402                	ld	s0,32(sp)
    800035ae:	64e2                	ld	s1,24(sp)
    800035b0:	6942                	ld	s2,16(sp)
    800035b2:	69a2                	ld	s3,8(sp)
    800035b4:	6a02                	ld	s4,0(sp)
    800035b6:	6145                	addi	sp,sp,48
    800035b8:	8082                	ret
    panic("iget: no inodes");
    800035ba:	00005517          	auipc	a0,0x5
    800035be:	0be50513          	addi	a0,a0,190 # 80008678 <syscalls+0x138>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	f7c080e7          	jalr	-132(ra) # 8000053e <panic>

00000000800035ca <fsinit>:
fsinit(int dev) {
    800035ca:	7179                	addi	sp,sp,-48
    800035cc:	f406                	sd	ra,40(sp)
    800035ce:	f022                	sd	s0,32(sp)
    800035d0:	ec26                	sd	s1,24(sp)
    800035d2:	e84a                	sd	s2,16(sp)
    800035d4:	e44e                	sd	s3,8(sp)
    800035d6:	1800                	addi	s0,sp,48
    800035d8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035da:	4585                	li	a1,1
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	a64080e7          	jalr	-1436(ra) # 80003040 <bread>
    800035e4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035e6:	0001d997          	auipc	s3,0x1d
    800035ea:	fc298993          	addi	s3,s3,-62 # 800205a8 <sb>
    800035ee:	02000613          	li	a2,32
    800035f2:	05850593          	addi	a1,a0,88
    800035f6:	854e                	mv	a0,s3
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	748080e7          	jalr	1864(ra) # 80000d40 <memmove>
  brelse(bp);
    80003600:	8526                	mv	a0,s1
    80003602:	00000097          	auipc	ra,0x0
    80003606:	b6e080e7          	jalr	-1170(ra) # 80003170 <brelse>
  if(sb.magic != FSMAGIC)
    8000360a:	0009a703          	lw	a4,0(s3)
    8000360e:	102037b7          	lui	a5,0x10203
    80003612:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003616:	02f71263          	bne	a4,a5,8000363a <fsinit+0x70>
  initlog(dev, &sb);
    8000361a:	0001d597          	auipc	a1,0x1d
    8000361e:	f8e58593          	addi	a1,a1,-114 # 800205a8 <sb>
    80003622:	854a                	mv	a0,s2
    80003624:	00001097          	auipc	ra,0x1
    80003628:	b4c080e7          	jalr	-1204(ra) # 80004170 <initlog>
}
    8000362c:	70a2                	ld	ra,40(sp)
    8000362e:	7402                	ld	s0,32(sp)
    80003630:	64e2                	ld	s1,24(sp)
    80003632:	6942                	ld	s2,16(sp)
    80003634:	69a2                	ld	s3,8(sp)
    80003636:	6145                	addi	sp,sp,48
    80003638:	8082                	ret
    panic("invalid file system");
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	04e50513          	addi	a0,a0,78 # 80008688 <syscalls+0x148>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>

000000008000364a <iinit>:
{
    8000364a:	7179                	addi	sp,sp,-48
    8000364c:	f406                	sd	ra,40(sp)
    8000364e:	f022                	sd	s0,32(sp)
    80003650:	ec26                	sd	s1,24(sp)
    80003652:	e84a                	sd	s2,16(sp)
    80003654:	e44e                	sd	s3,8(sp)
    80003656:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003658:	00005597          	auipc	a1,0x5
    8000365c:	04858593          	addi	a1,a1,72 # 800086a0 <syscalls+0x160>
    80003660:	0001d517          	auipc	a0,0x1d
    80003664:	f6850513          	addi	a0,a0,-152 # 800205c8 <itable>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	4ec080e7          	jalr	1260(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003670:	0001d497          	auipc	s1,0x1d
    80003674:	f8048493          	addi	s1,s1,-128 # 800205f0 <itable+0x28>
    80003678:	0001f997          	auipc	s3,0x1f
    8000367c:	a0898993          	addi	s3,s3,-1528 # 80022080 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003680:	00005917          	auipc	s2,0x5
    80003684:	02890913          	addi	s2,s2,40 # 800086a8 <syscalls+0x168>
    80003688:	85ca                	mv	a1,s2
    8000368a:	8526                	mv	a0,s1
    8000368c:	00001097          	auipc	ra,0x1
    80003690:	e46080e7          	jalr	-442(ra) # 800044d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003694:	08848493          	addi	s1,s1,136
    80003698:	ff3498e3          	bne	s1,s3,80003688 <iinit+0x3e>
}
    8000369c:	70a2                	ld	ra,40(sp)
    8000369e:	7402                	ld	s0,32(sp)
    800036a0:	64e2                	ld	s1,24(sp)
    800036a2:	6942                	ld	s2,16(sp)
    800036a4:	69a2                	ld	s3,8(sp)
    800036a6:	6145                	addi	sp,sp,48
    800036a8:	8082                	ret

00000000800036aa <ialloc>:
{
    800036aa:	715d                	addi	sp,sp,-80
    800036ac:	e486                	sd	ra,72(sp)
    800036ae:	e0a2                	sd	s0,64(sp)
    800036b0:	fc26                	sd	s1,56(sp)
    800036b2:	f84a                	sd	s2,48(sp)
    800036b4:	f44e                	sd	s3,40(sp)
    800036b6:	f052                	sd	s4,32(sp)
    800036b8:	ec56                	sd	s5,24(sp)
    800036ba:	e85a                	sd	s6,16(sp)
    800036bc:	e45e                	sd	s7,8(sp)
    800036be:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036c0:	0001d717          	auipc	a4,0x1d
    800036c4:	ef472703          	lw	a4,-268(a4) # 800205b4 <sb+0xc>
    800036c8:	4785                	li	a5,1
    800036ca:	04e7fa63          	bgeu	a5,a4,8000371e <ialloc+0x74>
    800036ce:	8aaa                	mv	s5,a0
    800036d0:	8bae                	mv	s7,a1
    800036d2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036d4:	0001da17          	auipc	s4,0x1d
    800036d8:	ed4a0a13          	addi	s4,s4,-300 # 800205a8 <sb>
    800036dc:	00048b1b          	sext.w	s6,s1
    800036e0:	0044d593          	srli	a1,s1,0x4
    800036e4:	018a2783          	lw	a5,24(s4)
    800036e8:	9dbd                	addw	a1,a1,a5
    800036ea:	8556                	mv	a0,s5
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	954080e7          	jalr	-1708(ra) # 80003040 <bread>
    800036f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036f6:	05850993          	addi	s3,a0,88
    800036fa:	00f4f793          	andi	a5,s1,15
    800036fe:	079a                	slli	a5,a5,0x6
    80003700:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003702:	00099783          	lh	a5,0(s3)
    80003706:	c785                	beqz	a5,8000372e <ialloc+0x84>
    brelse(bp);
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	a68080e7          	jalr	-1432(ra) # 80003170 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003710:	0485                	addi	s1,s1,1
    80003712:	00ca2703          	lw	a4,12(s4)
    80003716:	0004879b          	sext.w	a5,s1
    8000371a:	fce7e1e3          	bltu	a5,a4,800036dc <ialloc+0x32>
  panic("ialloc: no inodes");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	f9250513          	addi	a0,a0,-110 # 800086b0 <syscalls+0x170>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000372e:	04000613          	li	a2,64
    80003732:	4581                	li	a1,0
    80003734:	854e                	mv	a0,s3
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	5aa080e7          	jalr	1450(ra) # 80000ce0 <memset>
      dip->type = type;
    8000373e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003742:	854a                	mv	a0,s2
    80003744:	00001097          	auipc	ra,0x1
    80003748:	ca8080e7          	jalr	-856(ra) # 800043ec <log_write>
      brelse(bp);
    8000374c:	854a                	mv	a0,s2
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	a22080e7          	jalr	-1502(ra) # 80003170 <brelse>
      return iget(dev, inum);
    80003756:	85da                	mv	a1,s6
    80003758:	8556                	mv	a0,s5
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	db4080e7          	jalr	-588(ra) # 8000350e <iget>
}
    80003762:	60a6                	ld	ra,72(sp)
    80003764:	6406                	ld	s0,64(sp)
    80003766:	74e2                	ld	s1,56(sp)
    80003768:	7942                	ld	s2,48(sp)
    8000376a:	79a2                	ld	s3,40(sp)
    8000376c:	7a02                	ld	s4,32(sp)
    8000376e:	6ae2                	ld	s5,24(sp)
    80003770:	6b42                	ld	s6,16(sp)
    80003772:	6ba2                	ld	s7,8(sp)
    80003774:	6161                	addi	sp,sp,80
    80003776:	8082                	ret

0000000080003778 <iupdate>:
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	e04a                	sd	s2,0(sp)
    80003782:	1000                	addi	s0,sp,32
    80003784:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003786:	415c                	lw	a5,4(a0)
    80003788:	0047d79b          	srliw	a5,a5,0x4
    8000378c:	0001d597          	auipc	a1,0x1d
    80003790:	e345a583          	lw	a1,-460(a1) # 800205c0 <sb+0x18>
    80003794:	9dbd                	addw	a1,a1,a5
    80003796:	4108                	lw	a0,0(a0)
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	8a8080e7          	jalr	-1880(ra) # 80003040 <bread>
    800037a0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a2:	05850793          	addi	a5,a0,88
    800037a6:	40c8                	lw	a0,4(s1)
    800037a8:	893d                	andi	a0,a0,15
    800037aa:	051a                	slli	a0,a0,0x6
    800037ac:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037ae:	04449703          	lh	a4,68(s1)
    800037b2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037b6:	04649703          	lh	a4,70(s1)
    800037ba:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037be:	04849703          	lh	a4,72(s1)
    800037c2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037c6:	04a49703          	lh	a4,74(s1)
    800037ca:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037ce:	44f8                	lw	a4,76(s1)
    800037d0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037d2:	03400613          	li	a2,52
    800037d6:	05048593          	addi	a1,s1,80
    800037da:	0531                	addi	a0,a0,12
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	564080e7          	jalr	1380(ra) # 80000d40 <memmove>
  log_write(bp);
    800037e4:	854a                	mv	a0,s2
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	c06080e7          	jalr	-1018(ra) # 800043ec <log_write>
  brelse(bp);
    800037ee:	854a                	mv	a0,s2
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	980080e7          	jalr	-1664(ra) # 80003170 <brelse>
}
    800037f8:	60e2                	ld	ra,24(sp)
    800037fa:	6442                	ld	s0,16(sp)
    800037fc:	64a2                	ld	s1,8(sp)
    800037fe:	6902                	ld	s2,0(sp)
    80003800:	6105                	addi	sp,sp,32
    80003802:	8082                	ret

0000000080003804 <idup>:
{
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	1000                	addi	s0,sp,32
    8000380e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003810:	0001d517          	auipc	a0,0x1d
    80003814:	db850513          	addi	a0,a0,-584 # 800205c8 <itable>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	3cc080e7          	jalr	972(ra) # 80000be4 <acquire>
  ip->ref++;
    80003820:	449c                	lw	a5,8(s1)
    80003822:	2785                	addiw	a5,a5,1
    80003824:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003826:	0001d517          	auipc	a0,0x1d
    8000382a:	da250513          	addi	a0,a0,-606 # 800205c8 <itable>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	46a080e7          	jalr	1130(ra) # 80000c98 <release>
}
    80003836:	8526                	mv	a0,s1
    80003838:	60e2                	ld	ra,24(sp)
    8000383a:	6442                	ld	s0,16(sp)
    8000383c:	64a2                	ld	s1,8(sp)
    8000383e:	6105                	addi	sp,sp,32
    80003840:	8082                	ret

0000000080003842 <ilock>:
{
    80003842:	1101                	addi	sp,sp,-32
    80003844:	ec06                	sd	ra,24(sp)
    80003846:	e822                	sd	s0,16(sp)
    80003848:	e426                	sd	s1,8(sp)
    8000384a:	e04a                	sd	s2,0(sp)
    8000384c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000384e:	c115                	beqz	a0,80003872 <ilock+0x30>
    80003850:	84aa                	mv	s1,a0
    80003852:	451c                	lw	a5,8(a0)
    80003854:	00f05f63          	blez	a5,80003872 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003858:	0541                	addi	a0,a0,16
    8000385a:	00001097          	auipc	ra,0x1
    8000385e:	cb2080e7          	jalr	-846(ra) # 8000450c <acquiresleep>
  if(ip->valid == 0){
    80003862:	40bc                	lw	a5,64(s1)
    80003864:	cf99                	beqz	a5,80003882 <ilock+0x40>
}
    80003866:	60e2                	ld	ra,24(sp)
    80003868:	6442                	ld	s0,16(sp)
    8000386a:	64a2                	ld	s1,8(sp)
    8000386c:	6902                	ld	s2,0(sp)
    8000386e:	6105                	addi	sp,sp,32
    80003870:	8082                	ret
    panic("ilock");
    80003872:	00005517          	auipc	a0,0x5
    80003876:	e5650513          	addi	a0,a0,-426 # 800086c8 <syscalls+0x188>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	cc4080e7          	jalr	-828(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003882:	40dc                	lw	a5,4(s1)
    80003884:	0047d79b          	srliw	a5,a5,0x4
    80003888:	0001d597          	auipc	a1,0x1d
    8000388c:	d385a583          	lw	a1,-712(a1) # 800205c0 <sb+0x18>
    80003890:	9dbd                	addw	a1,a1,a5
    80003892:	4088                	lw	a0,0(s1)
    80003894:	fffff097          	auipc	ra,0xfffff
    80003898:	7ac080e7          	jalr	1964(ra) # 80003040 <bread>
    8000389c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000389e:	05850593          	addi	a1,a0,88
    800038a2:	40dc                	lw	a5,4(s1)
    800038a4:	8bbd                	andi	a5,a5,15
    800038a6:	079a                	slli	a5,a5,0x6
    800038a8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038aa:	00059783          	lh	a5,0(a1)
    800038ae:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038b2:	00259783          	lh	a5,2(a1)
    800038b6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038ba:	00459783          	lh	a5,4(a1)
    800038be:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038c2:	00659783          	lh	a5,6(a1)
    800038c6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038ca:	459c                	lw	a5,8(a1)
    800038cc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038ce:	03400613          	li	a2,52
    800038d2:	05b1                	addi	a1,a1,12
    800038d4:	05048513          	addi	a0,s1,80
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	468080e7          	jalr	1128(ra) # 80000d40 <memmove>
    brelse(bp);
    800038e0:	854a                	mv	a0,s2
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	88e080e7          	jalr	-1906(ra) # 80003170 <brelse>
    ip->valid = 1;
    800038ea:	4785                	li	a5,1
    800038ec:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038ee:	04449783          	lh	a5,68(s1)
    800038f2:	fbb5                	bnez	a5,80003866 <ilock+0x24>
      panic("ilock: no type");
    800038f4:	00005517          	auipc	a0,0x5
    800038f8:	ddc50513          	addi	a0,a0,-548 # 800086d0 <syscalls+0x190>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>

0000000080003904 <iunlock>:
{
    80003904:	1101                	addi	sp,sp,-32
    80003906:	ec06                	sd	ra,24(sp)
    80003908:	e822                	sd	s0,16(sp)
    8000390a:	e426                	sd	s1,8(sp)
    8000390c:	e04a                	sd	s2,0(sp)
    8000390e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003910:	c905                	beqz	a0,80003940 <iunlock+0x3c>
    80003912:	84aa                	mv	s1,a0
    80003914:	01050913          	addi	s2,a0,16
    80003918:	854a                	mv	a0,s2
    8000391a:	00001097          	auipc	ra,0x1
    8000391e:	c8c080e7          	jalr	-884(ra) # 800045a6 <holdingsleep>
    80003922:	cd19                	beqz	a0,80003940 <iunlock+0x3c>
    80003924:	449c                	lw	a5,8(s1)
    80003926:	00f05d63          	blez	a5,80003940 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000392a:	854a                	mv	a0,s2
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	c36080e7          	jalr	-970(ra) # 80004562 <releasesleep>
}
    80003934:	60e2                	ld	ra,24(sp)
    80003936:	6442                	ld	s0,16(sp)
    80003938:	64a2                	ld	s1,8(sp)
    8000393a:	6902                	ld	s2,0(sp)
    8000393c:	6105                	addi	sp,sp,32
    8000393e:	8082                	ret
    panic("iunlock");
    80003940:	00005517          	auipc	a0,0x5
    80003944:	da050513          	addi	a0,a0,-608 # 800086e0 <syscalls+0x1a0>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	bf6080e7          	jalr	-1034(ra) # 8000053e <panic>

0000000080003950 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003950:	7179                	addi	sp,sp,-48
    80003952:	f406                	sd	ra,40(sp)
    80003954:	f022                	sd	s0,32(sp)
    80003956:	ec26                	sd	s1,24(sp)
    80003958:	e84a                	sd	s2,16(sp)
    8000395a:	e44e                	sd	s3,8(sp)
    8000395c:	e052                	sd	s4,0(sp)
    8000395e:	1800                	addi	s0,sp,48
    80003960:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003962:	05050493          	addi	s1,a0,80
    80003966:	08050913          	addi	s2,a0,128
    8000396a:	a021                	j	80003972 <itrunc+0x22>
    8000396c:	0491                	addi	s1,s1,4
    8000396e:	01248d63          	beq	s1,s2,80003988 <itrunc+0x38>
    if(ip->addrs[i]){
    80003972:	408c                	lw	a1,0(s1)
    80003974:	dde5                	beqz	a1,8000396c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003976:	0009a503          	lw	a0,0(s3)
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	90c080e7          	jalr	-1780(ra) # 80003286 <bfree>
      ip->addrs[i] = 0;
    80003982:	0004a023          	sw	zero,0(s1)
    80003986:	b7dd                	j	8000396c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003988:	0809a583          	lw	a1,128(s3)
    8000398c:	e185                	bnez	a1,800039ac <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000398e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003992:	854e                	mv	a0,s3
    80003994:	00000097          	auipc	ra,0x0
    80003998:	de4080e7          	jalr	-540(ra) # 80003778 <iupdate>
}
    8000399c:	70a2                	ld	ra,40(sp)
    8000399e:	7402                	ld	s0,32(sp)
    800039a0:	64e2                	ld	s1,24(sp)
    800039a2:	6942                	ld	s2,16(sp)
    800039a4:	69a2                	ld	s3,8(sp)
    800039a6:	6a02                	ld	s4,0(sp)
    800039a8:	6145                	addi	sp,sp,48
    800039aa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039ac:	0009a503          	lw	a0,0(s3)
    800039b0:	fffff097          	auipc	ra,0xfffff
    800039b4:	690080e7          	jalr	1680(ra) # 80003040 <bread>
    800039b8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039ba:	05850493          	addi	s1,a0,88
    800039be:	45850913          	addi	s2,a0,1112
    800039c2:	a811                	j	800039d6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039c4:	0009a503          	lw	a0,0(s3)
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	8be080e7          	jalr	-1858(ra) # 80003286 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039d0:	0491                	addi	s1,s1,4
    800039d2:	01248563          	beq	s1,s2,800039dc <itrunc+0x8c>
      if(a[j])
    800039d6:	408c                	lw	a1,0(s1)
    800039d8:	dde5                	beqz	a1,800039d0 <itrunc+0x80>
    800039da:	b7ed                	j	800039c4 <itrunc+0x74>
    brelse(bp);
    800039dc:	8552                	mv	a0,s4
    800039de:	fffff097          	auipc	ra,0xfffff
    800039e2:	792080e7          	jalr	1938(ra) # 80003170 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039e6:	0809a583          	lw	a1,128(s3)
    800039ea:	0009a503          	lw	a0,0(s3)
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	898080e7          	jalr	-1896(ra) # 80003286 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039f6:	0809a023          	sw	zero,128(s3)
    800039fa:	bf51                	j	8000398e <itrunc+0x3e>

00000000800039fc <iput>:
{
    800039fc:	1101                	addi	sp,sp,-32
    800039fe:	ec06                	sd	ra,24(sp)
    80003a00:	e822                	sd	s0,16(sp)
    80003a02:	e426                	sd	s1,8(sp)
    80003a04:	e04a                	sd	s2,0(sp)
    80003a06:	1000                	addi	s0,sp,32
    80003a08:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a0a:	0001d517          	auipc	a0,0x1d
    80003a0e:	bbe50513          	addi	a0,a0,-1090 # 800205c8 <itable>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	1d2080e7          	jalr	466(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a1a:	4498                	lw	a4,8(s1)
    80003a1c:	4785                	li	a5,1
    80003a1e:	02f70363          	beq	a4,a5,80003a44 <iput+0x48>
  ip->ref--;
    80003a22:	449c                	lw	a5,8(s1)
    80003a24:	37fd                	addiw	a5,a5,-1
    80003a26:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a28:	0001d517          	auipc	a0,0x1d
    80003a2c:	ba050513          	addi	a0,a0,-1120 # 800205c8 <itable>
    80003a30:	ffffd097          	auipc	ra,0xffffd
    80003a34:	268080e7          	jalr	616(ra) # 80000c98 <release>
}
    80003a38:	60e2                	ld	ra,24(sp)
    80003a3a:	6442                	ld	s0,16(sp)
    80003a3c:	64a2                	ld	s1,8(sp)
    80003a3e:	6902                	ld	s2,0(sp)
    80003a40:	6105                	addi	sp,sp,32
    80003a42:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a44:	40bc                	lw	a5,64(s1)
    80003a46:	dff1                	beqz	a5,80003a22 <iput+0x26>
    80003a48:	04a49783          	lh	a5,74(s1)
    80003a4c:	fbf9                	bnez	a5,80003a22 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a4e:	01048913          	addi	s2,s1,16
    80003a52:	854a                	mv	a0,s2
    80003a54:	00001097          	auipc	ra,0x1
    80003a58:	ab8080e7          	jalr	-1352(ra) # 8000450c <acquiresleep>
    release(&itable.lock);
    80003a5c:	0001d517          	auipc	a0,0x1d
    80003a60:	b6c50513          	addi	a0,a0,-1172 # 800205c8 <itable>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
    itrunc(ip);
    80003a6c:	8526                	mv	a0,s1
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	ee2080e7          	jalr	-286(ra) # 80003950 <itrunc>
    ip->type = 0;
    80003a76:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a7a:	8526                	mv	a0,s1
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	cfc080e7          	jalr	-772(ra) # 80003778 <iupdate>
    ip->valid = 0;
    80003a84:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00001097          	auipc	ra,0x1
    80003a8e:	ad8080e7          	jalr	-1320(ra) # 80004562 <releasesleep>
    acquire(&itable.lock);
    80003a92:	0001d517          	auipc	a0,0x1d
    80003a96:	b3650513          	addi	a0,a0,-1226 # 800205c8 <itable>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	14a080e7          	jalr	330(ra) # 80000be4 <acquire>
    80003aa2:	b741                	j	80003a22 <iput+0x26>

0000000080003aa4 <iunlockput>:
{
    80003aa4:	1101                	addi	sp,sp,-32
    80003aa6:	ec06                	sd	ra,24(sp)
    80003aa8:	e822                	sd	s0,16(sp)
    80003aaa:	e426                	sd	s1,8(sp)
    80003aac:	1000                	addi	s0,sp,32
    80003aae:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	e54080e7          	jalr	-428(ra) # 80003904 <iunlock>
  iput(ip);
    80003ab8:	8526                	mv	a0,s1
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	f42080e7          	jalr	-190(ra) # 800039fc <iput>
}
    80003ac2:	60e2                	ld	ra,24(sp)
    80003ac4:	6442                	ld	s0,16(sp)
    80003ac6:	64a2                	ld	s1,8(sp)
    80003ac8:	6105                	addi	sp,sp,32
    80003aca:	8082                	ret

0000000080003acc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003acc:	1141                	addi	sp,sp,-16
    80003ace:	e422                	sd	s0,8(sp)
    80003ad0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ad2:	411c                	lw	a5,0(a0)
    80003ad4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ad6:	415c                	lw	a5,4(a0)
    80003ad8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ada:	04451783          	lh	a5,68(a0)
    80003ade:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ae2:	04a51783          	lh	a5,74(a0)
    80003ae6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003aea:	04c56783          	lwu	a5,76(a0)
    80003aee:	e99c                	sd	a5,16(a1)
}
    80003af0:	6422                	ld	s0,8(sp)
    80003af2:	0141                	addi	sp,sp,16
    80003af4:	8082                	ret

0000000080003af6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af6:	457c                	lw	a5,76(a0)
    80003af8:	0ed7e963          	bltu	a5,a3,80003bea <readi+0xf4>
{
    80003afc:	7159                	addi	sp,sp,-112
    80003afe:	f486                	sd	ra,104(sp)
    80003b00:	f0a2                	sd	s0,96(sp)
    80003b02:	eca6                	sd	s1,88(sp)
    80003b04:	e8ca                	sd	s2,80(sp)
    80003b06:	e4ce                	sd	s3,72(sp)
    80003b08:	e0d2                	sd	s4,64(sp)
    80003b0a:	fc56                	sd	s5,56(sp)
    80003b0c:	f85a                	sd	s6,48(sp)
    80003b0e:	f45e                	sd	s7,40(sp)
    80003b10:	f062                	sd	s8,32(sp)
    80003b12:	ec66                	sd	s9,24(sp)
    80003b14:	e86a                	sd	s10,16(sp)
    80003b16:	e46e                	sd	s11,8(sp)
    80003b18:	1880                	addi	s0,sp,112
    80003b1a:	8baa                	mv	s7,a0
    80003b1c:	8c2e                	mv	s8,a1
    80003b1e:	8ab2                	mv	s5,a2
    80003b20:	84b6                	mv	s1,a3
    80003b22:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b24:	9f35                	addw	a4,a4,a3
    return 0;
    80003b26:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b28:	0ad76063          	bltu	a4,a3,80003bc8 <readi+0xd2>
  if(off + n > ip->size)
    80003b2c:	00e7f463          	bgeu	a5,a4,80003b34 <readi+0x3e>
    n = ip->size - off;
    80003b30:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b34:	0a0b0963          	beqz	s6,80003be6 <readi+0xf0>
    80003b38:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b3e:	5cfd                	li	s9,-1
    80003b40:	a82d                	j	80003b7a <readi+0x84>
    80003b42:	020a1d93          	slli	s11,s4,0x20
    80003b46:	020ddd93          	srli	s11,s11,0x20
    80003b4a:	05890613          	addi	a2,s2,88
    80003b4e:	86ee                	mv	a3,s11
    80003b50:	963a                	add	a2,a2,a4
    80003b52:	85d6                	mv	a1,s5
    80003b54:	8562                	mv	a0,s8
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	916080e7          	jalr	-1770(ra) # 8000246c <either_copyout>
    80003b5e:	05950d63          	beq	a0,s9,80003bb8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b62:	854a                	mv	a0,s2
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	60c080e7          	jalr	1548(ra) # 80003170 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6c:	013a09bb          	addw	s3,s4,s3
    80003b70:	009a04bb          	addw	s1,s4,s1
    80003b74:	9aee                	add	s5,s5,s11
    80003b76:	0569f763          	bgeu	s3,s6,80003bc4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b7a:	000ba903          	lw	s2,0(s7)
    80003b7e:	00a4d59b          	srliw	a1,s1,0xa
    80003b82:	855e                	mv	a0,s7
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	8b0080e7          	jalr	-1872(ra) # 80003434 <bmap>
    80003b8c:	0005059b          	sext.w	a1,a0
    80003b90:	854a                	mv	a0,s2
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	4ae080e7          	jalr	1198(ra) # 80003040 <bread>
    80003b9a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9c:	3ff4f713          	andi	a4,s1,1023
    80003ba0:	40ed07bb          	subw	a5,s10,a4
    80003ba4:	413b06bb          	subw	a3,s6,s3
    80003ba8:	8a3e                	mv	s4,a5
    80003baa:	2781                	sext.w	a5,a5
    80003bac:	0006861b          	sext.w	a2,a3
    80003bb0:	f8f679e3          	bgeu	a2,a5,80003b42 <readi+0x4c>
    80003bb4:	8a36                	mv	s4,a3
    80003bb6:	b771                	j	80003b42 <readi+0x4c>
      brelse(bp);
    80003bb8:	854a                	mv	a0,s2
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	5b6080e7          	jalr	1462(ra) # 80003170 <brelse>
      tot = -1;
    80003bc2:	59fd                	li	s3,-1
  }
  return tot;
    80003bc4:	0009851b          	sext.w	a0,s3
}
    80003bc8:	70a6                	ld	ra,104(sp)
    80003bca:	7406                	ld	s0,96(sp)
    80003bcc:	64e6                	ld	s1,88(sp)
    80003bce:	6946                	ld	s2,80(sp)
    80003bd0:	69a6                	ld	s3,72(sp)
    80003bd2:	6a06                	ld	s4,64(sp)
    80003bd4:	7ae2                	ld	s5,56(sp)
    80003bd6:	7b42                	ld	s6,48(sp)
    80003bd8:	7ba2                	ld	s7,40(sp)
    80003bda:	7c02                	ld	s8,32(sp)
    80003bdc:	6ce2                	ld	s9,24(sp)
    80003bde:	6d42                	ld	s10,16(sp)
    80003be0:	6da2                	ld	s11,8(sp)
    80003be2:	6165                	addi	sp,sp,112
    80003be4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be6:	89da                	mv	s3,s6
    80003be8:	bff1                	j	80003bc4 <readi+0xce>
    return 0;
    80003bea:	4501                	li	a0,0
}
    80003bec:	8082                	ret

0000000080003bee <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bee:	457c                	lw	a5,76(a0)
    80003bf0:	10d7e863          	bltu	a5,a3,80003d00 <writei+0x112>
{
    80003bf4:	7159                	addi	sp,sp,-112
    80003bf6:	f486                	sd	ra,104(sp)
    80003bf8:	f0a2                	sd	s0,96(sp)
    80003bfa:	eca6                	sd	s1,88(sp)
    80003bfc:	e8ca                	sd	s2,80(sp)
    80003bfe:	e4ce                	sd	s3,72(sp)
    80003c00:	e0d2                	sd	s4,64(sp)
    80003c02:	fc56                	sd	s5,56(sp)
    80003c04:	f85a                	sd	s6,48(sp)
    80003c06:	f45e                	sd	s7,40(sp)
    80003c08:	f062                	sd	s8,32(sp)
    80003c0a:	ec66                	sd	s9,24(sp)
    80003c0c:	e86a                	sd	s10,16(sp)
    80003c0e:	e46e                	sd	s11,8(sp)
    80003c10:	1880                	addi	s0,sp,112
    80003c12:	8b2a                	mv	s6,a0
    80003c14:	8c2e                	mv	s8,a1
    80003c16:	8ab2                	mv	s5,a2
    80003c18:	8936                	mv	s2,a3
    80003c1a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c1c:	00e687bb          	addw	a5,a3,a4
    80003c20:	0ed7e263          	bltu	a5,a3,80003d04 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c24:	00043737          	lui	a4,0x43
    80003c28:	0ef76063          	bltu	a4,a5,80003d08 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c2c:	0c0b8863          	beqz	s7,80003cfc <writei+0x10e>
    80003c30:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c32:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c36:	5cfd                	li	s9,-1
    80003c38:	a091                	j	80003c7c <writei+0x8e>
    80003c3a:	02099d93          	slli	s11,s3,0x20
    80003c3e:	020ddd93          	srli	s11,s11,0x20
    80003c42:	05848513          	addi	a0,s1,88
    80003c46:	86ee                	mv	a3,s11
    80003c48:	8656                	mv	a2,s5
    80003c4a:	85e2                	mv	a1,s8
    80003c4c:	953a                	add	a0,a0,a4
    80003c4e:	fffff097          	auipc	ra,0xfffff
    80003c52:	874080e7          	jalr	-1932(ra) # 800024c2 <either_copyin>
    80003c56:	07950263          	beq	a0,s9,80003cba <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c5a:	8526                	mv	a0,s1
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	790080e7          	jalr	1936(ra) # 800043ec <log_write>
    brelse(bp);
    80003c64:	8526                	mv	a0,s1
    80003c66:	fffff097          	auipc	ra,0xfffff
    80003c6a:	50a080e7          	jalr	1290(ra) # 80003170 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6e:	01498a3b          	addw	s4,s3,s4
    80003c72:	0129893b          	addw	s2,s3,s2
    80003c76:	9aee                	add	s5,s5,s11
    80003c78:	057a7663          	bgeu	s4,s7,80003cc4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c7c:	000b2483          	lw	s1,0(s6)
    80003c80:	00a9559b          	srliw	a1,s2,0xa
    80003c84:	855a                	mv	a0,s6
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	7ae080e7          	jalr	1966(ra) # 80003434 <bmap>
    80003c8e:	0005059b          	sext.w	a1,a0
    80003c92:	8526                	mv	a0,s1
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	3ac080e7          	jalr	940(ra) # 80003040 <bread>
    80003c9c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c9e:	3ff97713          	andi	a4,s2,1023
    80003ca2:	40ed07bb          	subw	a5,s10,a4
    80003ca6:	414b86bb          	subw	a3,s7,s4
    80003caa:	89be                	mv	s3,a5
    80003cac:	2781                	sext.w	a5,a5
    80003cae:	0006861b          	sext.w	a2,a3
    80003cb2:	f8f674e3          	bgeu	a2,a5,80003c3a <writei+0x4c>
    80003cb6:	89b6                	mv	s3,a3
    80003cb8:	b749                	j	80003c3a <writei+0x4c>
      brelse(bp);
    80003cba:	8526                	mv	a0,s1
    80003cbc:	fffff097          	auipc	ra,0xfffff
    80003cc0:	4b4080e7          	jalr	1204(ra) # 80003170 <brelse>
  }

  if(off > ip->size)
    80003cc4:	04cb2783          	lw	a5,76(s6)
    80003cc8:	0127f463          	bgeu	a5,s2,80003cd0 <writei+0xe2>
    ip->size = off;
    80003ccc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cd0:	855a                	mv	a0,s6
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	aa6080e7          	jalr	-1370(ra) # 80003778 <iupdate>

  return tot;
    80003cda:	000a051b          	sext.w	a0,s4
}
    80003cde:	70a6                	ld	ra,104(sp)
    80003ce0:	7406                	ld	s0,96(sp)
    80003ce2:	64e6                	ld	s1,88(sp)
    80003ce4:	6946                	ld	s2,80(sp)
    80003ce6:	69a6                	ld	s3,72(sp)
    80003ce8:	6a06                	ld	s4,64(sp)
    80003cea:	7ae2                	ld	s5,56(sp)
    80003cec:	7b42                	ld	s6,48(sp)
    80003cee:	7ba2                	ld	s7,40(sp)
    80003cf0:	7c02                	ld	s8,32(sp)
    80003cf2:	6ce2                	ld	s9,24(sp)
    80003cf4:	6d42                	ld	s10,16(sp)
    80003cf6:	6da2                	ld	s11,8(sp)
    80003cf8:	6165                	addi	sp,sp,112
    80003cfa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cfc:	8a5e                	mv	s4,s7
    80003cfe:	bfc9                	j	80003cd0 <writei+0xe2>
    return -1;
    80003d00:	557d                	li	a0,-1
}
    80003d02:	8082                	ret
    return -1;
    80003d04:	557d                	li	a0,-1
    80003d06:	bfe1                	j	80003cde <writei+0xf0>
    return -1;
    80003d08:	557d                	li	a0,-1
    80003d0a:	bfd1                	j	80003cde <writei+0xf0>

0000000080003d0c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d0c:	1141                	addi	sp,sp,-16
    80003d0e:	e406                	sd	ra,8(sp)
    80003d10:	e022                	sd	s0,0(sp)
    80003d12:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d14:	4639                	li	a2,14
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	0a2080e7          	jalr	162(ra) # 80000db8 <strncmp>
}
    80003d1e:	60a2                	ld	ra,8(sp)
    80003d20:	6402                	ld	s0,0(sp)
    80003d22:	0141                	addi	sp,sp,16
    80003d24:	8082                	ret

0000000080003d26 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d26:	7139                	addi	sp,sp,-64
    80003d28:	fc06                	sd	ra,56(sp)
    80003d2a:	f822                	sd	s0,48(sp)
    80003d2c:	f426                	sd	s1,40(sp)
    80003d2e:	f04a                	sd	s2,32(sp)
    80003d30:	ec4e                	sd	s3,24(sp)
    80003d32:	e852                	sd	s4,16(sp)
    80003d34:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d36:	04451703          	lh	a4,68(a0)
    80003d3a:	4785                	li	a5,1
    80003d3c:	00f71a63          	bne	a4,a5,80003d50 <dirlookup+0x2a>
    80003d40:	892a                	mv	s2,a0
    80003d42:	89ae                	mv	s3,a1
    80003d44:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d46:	457c                	lw	a5,76(a0)
    80003d48:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d4a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4c:	e79d                	bnez	a5,80003d7a <dirlookup+0x54>
    80003d4e:	a8a5                	j	80003dc6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d50:	00005517          	auipc	a0,0x5
    80003d54:	99850513          	addi	a0,a0,-1640 # 800086e8 <syscalls+0x1a8>
    80003d58:	ffffc097          	auipc	ra,0xffffc
    80003d5c:	7e6080e7          	jalr	2022(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d60:	00005517          	auipc	a0,0x5
    80003d64:	9a050513          	addi	a0,a0,-1632 # 80008700 <syscalls+0x1c0>
    80003d68:	ffffc097          	auipc	ra,0xffffc
    80003d6c:	7d6080e7          	jalr	2006(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d70:	24c1                	addiw	s1,s1,16
    80003d72:	04c92783          	lw	a5,76(s2)
    80003d76:	04f4f763          	bgeu	s1,a5,80003dc4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d7a:	4741                	li	a4,16
    80003d7c:	86a6                	mv	a3,s1
    80003d7e:	fc040613          	addi	a2,s0,-64
    80003d82:	4581                	li	a1,0
    80003d84:	854a                	mv	a0,s2
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	d70080e7          	jalr	-656(ra) # 80003af6 <readi>
    80003d8e:	47c1                	li	a5,16
    80003d90:	fcf518e3          	bne	a0,a5,80003d60 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d94:	fc045783          	lhu	a5,-64(s0)
    80003d98:	dfe1                	beqz	a5,80003d70 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d9a:	fc240593          	addi	a1,s0,-62
    80003d9e:	854e                	mv	a0,s3
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	f6c080e7          	jalr	-148(ra) # 80003d0c <namecmp>
    80003da8:	f561                	bnez	a0,80003d70 <dirlookup+0x4a>
      if(poff)
    80003daa:	000a0463          	beqz	s4,80003db2 <dirlookup+0x8c>
        *poff = off;
    80003dae:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003db2:	fc045583          	lhu	a1,-64(s0)
    80003db6:	00092503          	lw	a0,0(s2)
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	754080e7          	jalr	1876(ra) # 8000350e <iget>
    80003dc2:	a011                	j	80003dc6 <dirlookup+0xa0>
  return 0;
    80003dc4:	4501                	li	a0,0
}
    80003dc6:	70e2                	ld	ra,56(sp)
    80003dc8:	7442                	ld	s0,48(sp)
    80003dca:	74a2                	ld	s1,40(sp)
    80003dcc:	7902                	ld	s2,32(sp)
    80003dce:	69e2                	ld	s3,24(sp)
    80003dd0:	6a42                	ld	s4,16(sp)
    80003dd2:	6121                	addi	sp,sp,64
    80003dd4:	8082                	ret

0000000080003dd6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dd6:	711d                	addi	sp,sp,-96
    80003dd8:	ec86                	sd	ra,88(sp)
    80003dda:	e8a2                	sd	s0,80(sp)
    80003ddc:	e4a6                	sd	s1,72(sp)
    80003dde:	e0ca                	sd	s2,64(sp)
    80003de0:	fc4e                	sd	s3,56(sp)
    80003de2:	f852                	sd	s4,48(sp)
    80003de4:	f456                	sd	s5,40(sp)
    80003de6:	f05a                	sd	s6,32(sp)
    80003de8:	ec5e                	sd	s7,24(sp)
    80003dea:	e862                	sd	s8,16(sp)
    80003dec:	e466                	sd	s9,8(sp)
    80003dee:	1080                	addi	s0,sp,96
    80003df0:	84aa                	mv	s1,a0
    80003df2:	8b2e                	mv	s6,a1
    80003df4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003df6:	00054703          	lbu	a4,0(a0)
    80003dfa:	02f00793          	li	a5,47
    80003dfe:	02f70363          	beq	a4,a5,80003e24 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e02:	ffffe097          	auipc	ra,0xffffe
    80003e06:	bae080e7          	jalr	-1106(ra) # 800019b0 <myproc>
    80003e0a:	15053503          	ld	a0,336(a0)
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	9f6080e7          	jalr	-1546(ra) # 80003804 <idup>
    80003e16:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e18:	02f00913          	li	s2,47
  len = path - s;
    80003e1c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e1e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e20:	4c05                	li	s8,1
    80003e22:	a865                	j	80003eda <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e24:	4585                	li	a1,1
    80003e26:	4505                	li	a0,1
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	6e6080e7          	jalr	1766(ra) # 8000350e <iget>
    80003e30:	89aa                	mv	s3,a0
    80003e32:	b7dd                	j	80003e18 <namex+0x42>
      iunlockput(ip);
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	c6e080e7          	jalr	-914(ra) # 80003aa4 <iunlockput>
      return 0;
    80003e3e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e40:	854e                	mv	a0,s3
    80003e42:	60e6                	ld	ra,88(sp)
    80003e44:	6446                	ld	s0,80(sp)
    80003e46:	64a6                	ld	s1,72(sp)
    80003e48:	6906                	ld	s2,64(sp)
    80003e4a:	79e2                	ld	s3,56(sp)
    80003e4c:	7a42                	ld	s4,48(sp)
    80003e4e:	7aa2                	ld	s5,40(sp)
    80003e50:	7b02                	ld	s6,32(sp)
    80003e52:	6be2                	ld	s7,24(sp)
    80003e54:	6c42                	ld	s8,16(sp)
    80003e56:	6ca2                	ld	s9,8(sp)
    80003e58:	6125                	addi	sp,sp,96
    80003e5a:	8082                	ret
      iunlock(ip);
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	aa6080e7          	jalr	-1370(ra) # 80003904 <iunlock>
      return ip;
    80003e66:	bfe9                	j	80003e40 <namex+0x6a>
      iunlockput(ip);
    80003e68:	854e                	mv	a0,s3
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	c3a080e7          	jalr	-966(ra) # 80003aa4 <iunlockput>
      return 0;
    80003e72:	89d2                	mv	s3,s4
    80003e74:	b7f1                	j	80003e40 <namex+0x6a>
  len = path - s;
    80003e76:	40b48633          	sub	a2,s1,a1
    80003e7a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e7e:	094cd463          	bge	s9,s4,80003f06 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e82:	4639                	li	a2,14
    80003e84:	8556                	mv	a0,s5
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	eba080e7          	jalr	-326(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e8e:	0004c783          	lbu	a5,0(s1)
    80003e92:	01279763          	bne	a5,s2,80003ea0 <namex+0xca>
    path++;
    80003e96:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e98:	0004c783          	lbu	a5,0(s1)
    80003e9c:	ff278de3          	beq	a5,s2,80003e96 <namex+0xc0>
    ilock(ip);
    80003ea0:	854e                	mv	a0,s3
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	9a0080e7          	jalr	-1632(ra) # 80003842 <ilock>
    if(ip->type != T_DIR){
    80003eaa:	04499783          	lh	a5,68(s3)
    80003eae:	f98793e3          	bne	a5,s8,80003e34 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eb2:	000b0563          	beqz	s6,80003ebc <namex+0xe6>
    80003eb6:	0004c783          	lbu	a5,0(s1)
    80003eba:	d3cd                	beqz	a5,80003e5c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ebc:	865e                	mv	a2,s7
    80003ebe:	85d6                	mv	a1,s5
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	e64080e7          	jalr	-412(ra) # 80003d26 <dirlookup>
    80003eca:	8a2a                	mv	s4,a0
    80003ecc:	dd51                	beqz	a0,80003e68 <namex+0x92>
    iunlockput(ip);
    80003ece:	854e                	mv	a0,s3
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	bd4080e7          	jalr	-1068(ra) # 80003aa4 <iunlockput>
    ip = next;
    80003ed8:	89d2                	mv	s3,s4
  while(*path == '/')
    80003eda:	0004c783          	lbu	a5,0(s1)
    80003ede:	05279763          	bne	a5,s2,80003f2c <namex+0x156>
    path++;
    80003ee2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ee4:	0004c783          	lbu	a5,0(s1)
    80003ee8:	ff278de3          	beq	a5,s2,80003ee2 <namex+0x10c>
  if(*path == 0)
    80003eec:	c79d                	beqz	a5,80003f1a <namex+0x144>
    path++;
    80003eee:	85a6                	mv	a1,s1
  len = path - s;
    80003ef0:	8a5e                	mv	s4,s7
    80003ef2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ef4:	01278963          	beq	a5,s2,80003f06 <namex+0x130>
    80003ef8:	dfbd                	beqz	a5,80003e76 <namex+0xa0>
    path++;
    80003efa:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003efc:	0004c783          	lbu	a5,0(s1)
    80003f00:	ff279ce3          	bne	a5,s2,80003ef8 <namex+0x122>
    80003f04:	bf8d                	j	80003e76 <namex+0xa0>
    memmove(name, s, len);
    80003f06:	2601                	sext.w	a2,a2
    80003f08:	8556                	mv	a0,s5
    80003f0a:	ffffd097          	auipc	ra,0xffffd
    80003f0e:	e36080e7          	jalr	-458(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f12:	9a56                	add	s4,s4,s5
    80003f14:	000a0023          	sb	zero,0(s4)
    80003f18:	bf9d                	j	80003e8e <namex+0xb8>
  if(nameiparent){
    80003f1a:	f20b03e3          	beqz	s6,80003e40 <namex+0x6a>
    iput(ip);
    80003f1e:	854e                	mv	a0,s3
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	adc080e7          	jalr	-1316(ra) # 800039fc <iput>
    return 0;
    80003f28:	4981                	li	s3,0
    80003f2a:	bf19                	j	80003e40 <namex+0x6a>
  if(*path == 0)
    80003f2c:	d7fd                	beqz	a5,80003f1a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f2e:	0004c783          	lbu	a5,0(s1)
    80003f32:	85a6                	mv	a1,s1
    80003f34:	b7d1                	j	80003ef8 <namex+0x122>

0000000080003f36 <dirlink>:
{
    80003f36:	7139                	addi	sp,sp,-64
    80003f38:	fc06                	sd	ra,56(sp)
    80003f3a:	f822                	sd	s0,48(sp)
    80003f3c:	f426                	sd	s1,40(sp)
    80003f3e:	f04a                	sd	s2,32(sp)
    80003f40:	ec4e                	sd	s3,24(sp)
    80003f42:	e852                	sd	s4,16(sp)
    80003f44:	0080                	addi	s0,sp,64
    80003f46:	892a                	mv	s2,a0
    80003f48:	8a2e                	mv	s4,a1
    80003f4a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f4c:	4601                	li	a2,0
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	dd8080e7          	jalr	-552(ra) # 80003d26 <dirlookup>
    80003f56:	e93d                	bnez	a0,80003fcc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f58:	04c92483          	lw	s1,76(s2)
    80003f5c:	c49d                	beqz	s1,80003f8a <dirlink+0x54>
    80003f5e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f60:	4741                	li	a4,16
    80003f62:	86a6                	mv	a3,s1
    80003f64:	fc040613          	addi	a2,s0,-64
    80003f68:	4581                	li	a1,0
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	b8a080e7          	jalr	-1142(ra) # 80003af6 <readi>
    80003f74:	47c1                	li	a5,16
    80003f76:	06f51163          	bne	a0,a5,80003fd8 <dirlink+0xa2>
    if(de.inum == 0)
    80003f7a:	fc045783          	lhu	a5,-64(s0)
    80003f7e:	c791                	beqz	a5,80003f8a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f80:	24c1                	addiw	s1,s1,16
    80003f82:	04c92783          	lw	a5,76(s2)
    80003f86:	fcf4ede3          	bltu	s1,a5,80003f60 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f8a:	4639                	li	a2,14
    80003f8c:	85d2                	mv	a1,s4
    80003f8e:	fc240513          	addi	a0,s0,-62
    80003f92:	ffffd097          	auipc	ra,0xffffd
    80003f96:	e62080e7          	jalr	-414(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003f9a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f9e:	4741                	li	a4,16
    80003fa0:	86a6                	mv	a3,s1
    80003fa2:	fc040613          	addi	a2,s0,-64
    80003fa6:	4581                	li	a1,0
    80003fa8:	854a                	mv	a0,s2
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	c44080e7          	jalr	-956(ra) # 80003bee <writei>
    80003fb2:	872a                	mv	a4,a0
    80003fb4:	47c1                	li	a5,16
  return 0;
    80003fb6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb8:	02f71863          	bne	a4,a5,80003fe8 <dirlink+0xb2>
}
    80003fbc:	70e2                	ld	ra,56(sp)
    80003fbe:	7442                	ld	s0,48(sp)
    80003fc0:	74a2                	ld	s1,40(sp)
    80003fc2:	7902                	ld	s2,32(sp)
    80003fc4:	69e2                	ld	s3,24(sp)
    80003fc6:	6a42                	ld	s4,16(sp)
    80003fc8:	6121                	addi	sp,sp,64
    80003fca:	8082                	ret
    iput(ip);
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	a30080e7          	jalr	-1488(ra) # 800039fc <iput>
    return -1;
    80003fd4:	557d                	li	a0,-1
    80003fd6:	b7dd                	j	80003fbc <dirlink+0x86>
      panic("dirlink read");
    80003fd8:	00004517          	auipc	a0,0x4
    80003fdc:	73850513          	addi	a0,a0,1848 # 80008710 <syscalls+0x1d0>
    80003fe0:	ffffc097          	auipc	ra,0xffffc
    80003fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>
    panic("dirlink");
    80003fe8:	00005517          	auipc	a0,0x5
    80003fec:	83050513          	addi	a0,a0,-2000 # 80008818 <syscalls+0x2d8>
    80003ff0:	ffffc097          	auipc	ra,0xffffc
    80003ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>

0000000080003ff8 <namei>:

struct inode*
namei(char *path)
{
    80003ff8:	1101                	addi	sp,sp,-32
    80003ffa:	ec06                	sd	ra,24(sp)
    80003ffc:	e822                	sd	s0,16(sp)
    80003ffe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004000:	fe040613          	addi	a2,s0,-32
    80004004:	4581                	li	a1,0
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	dd0080e7          	jalr	-560(ra) # 80003dd6 <namex>
}
    8000400e:	60e2                	ld	ra,24(sp)
    80004010:	6442                	ld	s0,16(sp)
    80004012:	6105                	addi	sp,sp,32
    80004014:	8082                	ret

0000000080004016 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004016:	1141                	addi	sp,sp,-16
    80004018:	e406                	sd	ra,8(sp)
    8000401a:	e022                	sd	s0,0(sp)
    8000401c:	0800                	addi	s0,sp,16
    8000401e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004020:	4585                	li	a1,1
    80004022:	00000097          	auipc	ra,0x0
    80004026:	db4080e7          	jalr	-588(ra) # 80003dd6 <namex>
}
    8000402a:	60a2                	ld	ra,8(sp)
    8000402c:	6402                	ld	s0,0(sp)
    8000402e:	0141                	addi	sp,sp,16
    80004030:	8082                	ret

0000000080004032 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004032:	1101                	addi	sp,sp,-32
    80004034:	ec06                	sd	ra,24(sp)
    80004036:	e822                	sd	s0,16(sp)
    80004038:	e426                	sd	s1,8(sp)
    8000403a:	e04a                	sd	s2,0(sp)
    8000403c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000403e:	0001e917          	auipc	s2,0x1e
    80004042:	03290913          	addi	s2,s2,50 # 80022070 <log>
    80004046:	01892583          	lw	a1,24(s2)
    8000404a:	02892503          	lw	a0,40(s2)
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	ff2080e7          	jalr	-14(ra) # 80003040 <bread>
    80004056:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004058:	02c92683          	lw	a3,44(s2)
    8000405c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000405e:	02d05763          	blez	a3,8000408c <write_head+0x5a>
    80004062:	0001e797          	auipc	a5,0x1e
    80004066:	03e78793          	addi	a5,a5,62 # 800220a0 <log+0x30>
    8000406a:	05c50713          	addi	a4,a0,92
    8000406e:	36fd                	addiw	a3,a3,-1
    80004070:	1682                	slli	a3,a3,0x20
    80004072:	9281                	srli	a3,a3,0x20
    80004074:	068a                	slli	a3,a3,0x2
    80004076:	0001e617          	auipc	a2,0x1e
    8000407a:	02e60613          	addi	a2,a2,46 # 800220a4 <log+0x34>
    8000407e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004080:	4390                	lw	a2,0(a5)
    80004082:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004084:	0791                	addi	a5,a5,4
    80004086:	0711                	addi	a4,a4,4
    80004088:	fed79ce3          	bne	a5,a3,80004080 <write_head+0x4e>
  }
  bwrite(buf);
    8000408c:	8526                	mv	a0,s1
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	0a4080e7          	jalr	164(ra) # 80003132 <bwrite>
  brelse(buf);
    80004096:	8526                	mv	a0,s1
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	0d8080e7          	jalr	216(ra) # 80003170 <brelse>
}
    800040a0:	60e2                	ld	ra,24(sp)
    800040a2:	6442                	ld	s0,16(sp)
    800040a4:	64a2                	ld	s1,8(sp)
    800040a6:	6902                	ld	s2,0(sp)
    800040a8:	6105                	addi	sp,sp,32
    800040aa:	8082                	ret

00000000800040ac <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ac:	0001e797          	auipc	a5,0x1e
    800040b0:	ff07a783          	lw	a5,-16(a5) # 8002209c <log+0x2c>
    800040b4:	0af05d63          	blez	a5,8000416e <install_trans+0xc2>
{
    800040b8:	7139                	addi	sp,sp,-64
    800040ba:	fc06                	sd	ra,56(sp)
    800040bc:	f822                	sd	s0,48(sp)
    800040be:	f426                	sd	s1,40(sp)
    800040c0:	f04a                	sd	s2,32(sp)
    800040c2:	ec4e                	sd	s3,24(sp)
    800040c4:	e852                	sd	s4,16(sp)
    800040c6:	e456                	sd	s5,8(sp)
    800040c8:	e05a                	sd	s6,0(sp)
    800040ca:	0080                	addi	s0,sp,64
    800040cc:	8b2a                	mv	s6,a0
    800040ce:	0001ea97          	auipc	s5,0x1e
    800040d2:	fd2a8a93          	addi	s5,s5,-46 # 800220a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040d8:	0001e997          	auipc	s3,0x1e
    800040dc:	f9898993          	addi	s3,s3,-104 # 80022070 <log>
    800040e0:	a035                	j	8000410c <install_trans+0x60>
      bunpin(dbuf);
    800040e2:	8526                	mv	a0,s1
    800040e4:	fffff097          	auipc	ra,0xfffff
    800040e8:	166080e7          	jalr	358(ra) # 8000324a <bunpin>
    brelse(lbuf);
    800040ec:	854a                	mv	a0,s2
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	082080e7          	jalr	130(ra) # 80003170 <brelse>
    brelse(dbuf);
    800040f6:	8526                	mv	a0,s1
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	078080e7          	jalr	120(ra) # 80003170 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004100:	2a05                	addiw	s4,s4,1
    80004102:	0a91                	addi	s5,s5,4
    80004104:	02c9a783          	lw	a5,44(s3)
    80004108:	04fa5963          	bge	s4,a5,8000415a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000410c:	0189a583          	lw	a1,24(s3)
    80004110:	014585bb          	addw	a1,a1,s4
    80004114:	2585                	addiw	a1,a1,1
    80004116:	0289a503          	lw	a0,40(s3)
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	f26080e7          	jalr	-218(ra) # 80003040 <bread>
    80004122:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004124:	000aa583          	lw	a1,0(s5)
    80004128:	0289a503          	lw	a0,40(s3)
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	f14080e7          	jalr	-236(ra) # 80003040 <bread>
    80004134:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004136:	40000613          	li	a2,1024
    8000413a:	05890593          	addi	a1,s2,88
    8000413e:	05850513          	addi	a0,a0,88
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	bfe080e7          	jalr	-1026(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	fe6080e7          	jalr	-26(ra) # 80003132 <bwrite>
    if(recovering == 0)
    80004154:	f80b1ce3          	bnez	s6,800040ec <install_trans+0x40>
    80004158:	b769                	j	800040e2 <install_trans+0x36>
}
    8000415a:	70e2                	ld	ra,56(sp)
    8000415c:	7442                	ld	s0,48(sp)
    8000415e:	74a2                	ld	s1,40(sp)
    80004160:	7902                	ld	s2,32(sp)
    80004162:	69e2                	ld	s3,24(sp)
    80004164:	6a42                	ld	s4,16(sp)
    80004166:	6aa2                	ld	s5,8(sp)
    80004168:	6b02                	ld	s6,0(sp)
    8000416a:	6121                	addi	sp,sp,64
    8000416c:	8082                	ret
    8000416e:	8082                	ret

0000000080004170 <initlog>:
{
    80004170:	7179                	addi	sp,sp,-48
    80004172:	f406                	sd	ra,40(sp)
    80004174:	f022                	sd	s0,32(sp)
    80004176:	ec26                	sd	s1,24(sp)
    80004178:	e84a                	sd	s2,16(sp)
    8000417a:	e44e                	sd	s3,8(sp)
    8000417c:	1800                	addi	s0,sp,48
    8000417e:	892a                	mv	s2,a0
    80004180:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004182:	0001e497          	auipc	s1,0x1e
    80004186:	eee48493          	addi	s1,s1,-274 # 80022070 <log>
    8000418a:	00004597          	auipc	a1,0x4
    8000418e:	59658593          	addi	a1,a1,1430 # 80008720 <syscalls+0x1e0>
    80004192:	8526                	mv	a0,s1
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	9c0080e7          	jalr	-1600(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000419c:	0149a583          	lw	a1,20(s3)
    800041a0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041a2:	0109a783          	lw	a5,16(s3)
    800041a6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041a8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041ac:	854a                	mv	a0,s2
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	e92080e7          	jalr	-366(ra) # 80003040 <bread>
  log.lh.n = lh->n;
    800041b6:	4d3c                	lw	a5,88(a0)
    800041b8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041ba:	02f05563          	blez	a5,800041e4 <initlog+0x74>
    800041be:	05c50713          	addi	a4,a0,92
    800041c2:	0001e697          	auipc	a3,0x1e
    800041c6:	ede68693          	addi	a3,a3,-290 # 800220a0 <log+0x30>
    800041ca:	37fd                	addiw	a5,a5,-1
    800041cc:	1782                	slli	a5,a5,0x20
    800041ce:	9381                	srli	a5,a5,0x20
    800041d0:	078a                	slli	a5,a5,0x2
    800041d2:	06050613          	addi	a2,a0,96
    800041d6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041d8:	4310                	lw	a2,0(a4)
    800041da:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041dc:	0711                	addi	a4,a4,4
    800041de:	0691                	addi	a3,a3,4
    800041e0:	fef71ce3          	bne	a4,a5,800041d8 <initlog+0x68>
  brelse(buf);
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	f8c080e7          	jalr	-116(ra) # 80003170 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041ec:	4505                	li	a0,1
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	ebe080e7          	jalr	-322(ra) # 800040ac <install_trans>
  log.lh.n = 0;
    800041f6:	0001e797          	auipc	a5,0x1e
    800041fa:	ea07a323          	sw	zero,-346(a5) # 8002209c <log+0x2c>
  write_head(); // clear the log
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	e34080e7          	jalr	-460(ra) # 80004032 <write_head>
}
    80004206:	70a2                	ld	ra,40(sp)
    80004208:	7402                	ld	s0,32(sp)
    8000420a:	64e2                	ld	s1,24(sp)
    8000420c:	6942                	ld	s2,16(sp)
    8000420e:	69a2                	ld	s3,8(sp)
    80004210:	6145                	addi	sp,sp,48
    80004212:	8082                	ret

0000000080004214 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004214:	1101                	addi	sp,sp,-32
    80004216:	ec06                	sd	ra,24(sp)
    80004218:	e822                	sd	s0,16(sp)
    8000421a:	e426                	sd	s1,8(sp)
    8000421c:	e04a                	sd	s2,0(sp)
    8000421e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004220:	0001e517          	auipc	a0,0x1e
    80004224:	e5050513          	addi	a0,a0,-432 # 80022070 <log>
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	9bc080e7          	jalr	-1604(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004230:	0001e497          	auipc	s1,0x1e
    80004234:	e4048493          	addi	s1,s1,-448 # 80022070 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004238:	4979                	li	s2,30
    8000423a:	a039                	j	80004248 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000423c:	85a6                	mv	a1,s1
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffe097          	auipc	ra,0xffffe
    80004244:	e88080e7          	jalr	-376(ra) # 800020c8 <sleep>
    if(log.committing){
    80004248:	50dc                	lw	a5,36(s1)
    8000424a:	fbed                	bnez	a5,8000423c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424c:	509c                	lw	a5,32(s1)
    8000424e:	0017871b          	addiw	a4,a5,1
    80004252:	0007069b          	sext.w	a3,a4
    80004256:	0027179b          	slliw	a5,a4,0x2
    8000425a:	9fb9                	addw	a5,a5,a4
    8000425c:	0017979b          	slliw	a5,a5,0x1
    80004260:	54d8                	lw	a4,44(s1)
    80004262:	9fb9                	addw	a5,a5,a4
    80004264:	00f95963          	bge	s2,a5,80004276 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004268:	85a6                	mv	a1,s1
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffe097          	auipc	ra,0xffffe
    80004270:	e5c080e7          	jalr	-420(ra) # 800020c8 <sleep>
    80004274:	bfd1                	j	80004248 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004276:	0001e517          	auipc	a0,0x1e
    8000427a:	dfa50513          	addi	a0,a0,-518 # 80022070 <log>
    8000427e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004280:	ffffd097          	auipc	ra,0xffffd
    80004284:	a18080e7          	jalr	-1512(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004288:	60e2                	ld	ra,24(sp)
    8000428a:	6442                	ld	s0,16(sp)
    8000428c:	64a2                	ld	s1,8(sp)
    8000428e:	6902                	ld	s2,0(sp)
    80004290:	6105                	addi	sp,sp,32
    80004292:	8082                	ret

0000000080004294 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004294:	7139                	addi	sp,sp,-64
    80004296:	fc06                	sd	ra,56(sp)
    80004298:	f822                	sd	s0,48(sp)
    8000429a:	f426                	sd	s1,40(sp)
    8000429c:	f04a                	sd	s2,32(sp)
    8000429e:	ec4e                	sd	s3,24(sp)
    800042a0:	e852                	sd	s4,16(sp)
    800042a2:	e456                	sd	s5,8(sp)
    800042a4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042a6:	0001e497          	auipc	s1,0x1e
    800042aa:	dca48493          	addi	s1,s1,-566 # 80022070 <log>
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	934080e7          	jalr	-1740(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042b8:	509c                	lw	a5,32(s1)
    800042ba:	37fd                	addiw	a5,a5,-1
    800042bc:	0007891b          	sext.w	s2,a5
    800042c0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042c2:	50dc                	lw	a5,36(s1)
    800042c4:	efb9                	bnez	a5,80004322 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042c6:	06091663          	bnez	s2,80004332 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042ca:	0001e497          	auipc	s1,0x1e
    800042ce:	da648493          	addi	s1,s1,-602 # 80022070 <log>
    800042d2:	4785                	li	a5,1
    800042d4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042d6:	8526                	mv	a0,s1
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	9c0080e7          	jalr	-1600(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042e0:	54dc                	lw	a5,44(s1)
    800042e2:	06f04763          	bgtz	a5,80004350 <end_op+0xbc>
    acquire(&log.lock);
    800042e6:	0001e497          	auipc	s1,0x1e
    800042ea:	d8a48493          	addi	s1,s1,-630 # 80022070 <log>
    800042ee:	8526                	mv	a0,s1
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	8f4080e7          	jalr	-1804(ra) # 80000be4 <acquire>
    log.committing = 0;
    800042f8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffe097          	auipc	ra,0xffffe
    80004302:	f56080e7          	jalr	-170(ra) # 80002254 <wakeup>
    release(&log.lock);
    80004306:	8526                	mv	a0,s1
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	990080e7          	jalr	-1648(ra) # 80000c98 <release>
}
    80004310:	70e2                	ld	ra,56(sp)
    80004312:	7442                	ld	s0,48(sp)
    80004314:	74a2                	ld	s1,40(sp)
    80004316:	7902                	ld	s2,32(sp)
    80004318:	69e2                	ld	s3,24(sp)
    8000431a:	6a42                	ld	s4,16(sp)
    8000431c:	6aa2                	ld	s5,8(sp)
    8000431e:	6121                	addi	sp,sp,64
    80004320:	8082                	ret
    panic("log.committing");
    80004322:	00004517          	auipc	a0,0x4
    80004326:	40650513          	addi	a0,a0,1030 # 80008728 <syscalls+0x1e8>
    8000432a:	ffffc097          	auipc	ra,0xffffc
    8000432e:	214080e7          	jalr	532(ra) # 8000053e <panic>
    wakeup(&log);
    80004332:	0001e497          	auipc	s1,0x1e
    80004336:	d3e48493          	addi	s1,s1,-706 # 80022070 <log>
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffe097          	auipc	ra,0xffffe
    80004340:	f18080e7          	jalr	-232(ra) # 80002254 <wakeup>
  release(&log.lock);
    80004344:	8526                	mv	a0,s1
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	952080e7          	jalr	-1710(ra) # 80000c98 <release>
  if(do_commit){
    8000434e:	b7c9                	j	80004310 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004350:	0001ea97          	auipc	s5,0x1e
    80004354:	d50a8a93          	addi	s5,s5,-688 # 800220a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004358:	0001ea17          	auipc	s4,0x1e
    8000435c:	d18a0a13          	addi	s4,s4,-744 # 80022070 <log>
    80004360:	018a2583          	lw	a1,24(s4)
    80004364:	012585bb          	addw	a1,a1,s2
    80004368:	2585                	addiw	a1,a1,1
    8000436a:	028a2503          	lw	a0,40(s4)
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	cd2080e7          	jalr	-814(ra) # 80003040 <bread>
    80004376:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004378:	000aa583          	lw	a1,0(s5)
    8000437c:	028a2503          	lw	a0,40(s4)
    80004380:	fffff097          	auipc	ra,0xfffff
    80004384:	cc0080e7          	jalr	-832(ra) # 80003040 <bread>
    80004388:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000438a:	40000613          	li	a2,1024
    8000438e:	05850593          	addi	a1,a0,88
    80004392:	05848513          	addi	a0,s1,88
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	9aa080e7          	jalr	-1622(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000439e:	8526                	mv	a0,s1
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	d92080e7          	jalr	-622(ra) # 80003132 <bwrite>
    brelse(from);
    800043a8:	854e                	mv	a0,s3
    800043aa:	fffff097          	auipc	ra,0xfffff
    800043ae:	dc6080e7          	jalr	-570(ra) # 80003170 <brelse>
    brelse(to);
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	dbc080e7          	jalr	-580(ra) # 80003170 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043bc:	2905                	addiw	s2,s2,1
    800043be:	0a91                	addi	s5,s5,4
    800043c0:	02ca2783          	lw	a5,44(s4)
    800043c4:	f8f94ee3          	blt	s2,a5,80004360 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	c6a080e7          	jalr	-918(ra) # 80004032 <write_head>
    install_trans(0); // Now install writes to home locations
    800043d0:	4501                	li	a0,0
    800043d2:	00000097          	auipc	ra,0x0
    800043d6:	cda080e7          	jalr	-806(ra) # 800040ac <install_trans>
    log.lh.n = 0;
    800043da:	0001e797          	auipc	a5,0x1e
    800043de:	cc07a123          	sw	zero,-830(a5) # 8002209c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043e2:	00000097          	auipc	ra,0x0
    800043e6:	c50080e7          	jalr	-944(ra) # 80004032 <write_head>
    800043ea:	bdf5                	j	800042e6 <end_op+0x52>

00000000800043ec <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ec:	1101                	addi	sp,sp,-32
    800043ee:	ec06                	sd	ra,24(sp)
    800043f0:	e822                	sd	s0,16(sp)
    800043f2:	e426                	sd	s1,8(sp)
    800043f4:	e04a                	sd	s2,0(sp)
    800043f6:	1000                	addi	s0,sp,32
    800043f8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043fa:	0001e917          	auipc	s2,0x1e
    800043fe:	c7690913          	addi	s2,s2,-906 # 80022070 <log>
    80004402:	854a                	mv	a0,s2
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	7e0080e7          	jalr	2016(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000440c:	02c92603          	lw	a2,44(s2)
    80004410:	47f5                	li	a5,29
    80004412:	06c7c563          	blt	a5,a2,8000447c <log_write+0x90>
    80004416:	0001e797          	auipc	a5,0x1e
    8000441a:	c767a783          	lw	a5,-906(a5) # 8002208c <log+0x1c>
    8000441e:	37fd                	addiw	a5,a5,-1
    80004420:	04f65e63          	bge	a2,a5,8000447c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004424:	0001e797          	auipc	a5,0x1e
    80004428:	c6c7a783          	lw	a5,-916(a5) # 80022090 <log+0x20>
    8000442c:	06f05063          	blez	a5,8000448c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004430:	4781                	li	a5,0
    80004432:	06c05563          	blez	a2,8000449c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004436:	44cc                	lw	a1,12(s1)
    80004438:	0001e717          	auipc	a4,0x1e
    8000443c:	c6870713          	addi	a4,a4,-920 # 800220a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004440:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004442:	4314                	lw	a3,0(a4)
    80004444:	04b68c63          	beq	a3,a1,8000449c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004448:	2785                	addiw	a5,a5,1
    8000444a:	0711                	addi	a4,a4,4
    8000444c:	fef61be3          	bne	a2,a5,80004442 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004450:	0621                	addi	a2,a2,8
    80004452:	060a                	slli	a2,a2,0x2
    80004454:	0001e797          	auipc	a5,0x1e
    80004458:	c1c78793          	addi	a5,a5,-996 # 80022070 <log>
    8000445c:	963e                	add	a2,a2,a5
    8000445e:	44dc                	lw	a5,12(s1)
    80004460:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004462:	8526                	mv	a0,s1
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	daa080e7          	jalr	-598(ra) # 8000320e <bpin>
    log.lh.n++;
    8000446c:	0001e717          	auipc	a4,0x1e
    80004470:	c0470713          	addi	a4,a4,-1020 # 80022070 <log>
    80004474:	575c                	lw	a5,44(a4)
    80004476:	2785                	addiw	a5,a5,1
    80004478:	d75c                	sw	a5,44(a4)
    8000447a:	a835                	j	800044b6 <log_write+0xca>
    panic("too big a transaction");
    8000447c:	00004517          	auipc	a0,0x4
    80004480:	2bc50513          	addi	a0,a0,700 # 80008738 <syscalls+0x1f8>
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	0ba080e7          	jalr	186(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000448c:	00004517          	auipc	a0,0x4
    80004490:	2c450513          	addi	a0,a0,708 # 80008750 <syscalls+0x210>
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	0aa080e7          	jalr	170(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000449c:	00878713          	addi	a4,a5,8
    800044a0:	00271693          	slli	a3,a4,0x2
    800044a4:	0001e717          	auipc	a4,0x1e
    800044a8:	bcc70713          	addi	a4,a4,-1076 # 80022070 <log>
    800044ac:	9736                	add	a4,a4,a3
    800044ae:	44d4                	lw	a3,12(s1)
    800044b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044b2:	faf608e3          	beq	a2,a5,80004462 <log_write+0x76>
  }
  release(&log.lock);
    800044b6:	0001e517          	auipc	a0,0x1e
    800044ba:	bba50513          	addi	a0,a0,-1094 # 80022070 <log>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7da080e7          	jalr	2010(ra) # 80000c98 <release>
}
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6902                	ld	s2,0(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret

00000000800044d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	e04a                	sd	s2,0(sp)
    800044dc:	1000                	addi	s0,sp,32
    800044de:	84aa                	mv	s1,a0
    800044e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044e2:	00004597          	auipc	a1,0x4
    800044e6:	28e58593          	addi	a1,a1,654 # 80008770 <syscalls+0x230>
    800044ea:	0521                	addi	a0,a0,8
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	668080e7          	jalr	1640(ra) # 80000b54 <initlock>
  lk->name = name;
    800044f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fc:	0204a423          	sw	zero,40(s1)
}
    80004500:	60e2                	ld	ra,24(sp)
    80004502:	6442                	ld	s0,16(sp)
    80004504:	64a2                	ld	s1,8(sp)
    80004506:	6902                	ld	s2,0(sp)
    80004508:	6105                	addi	sp,sp,32
    8000450a:	8082                	ret

000000008000450c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000450c:	1101                	addi	sp,sp,-32
    8000450e:	ec06                	sd	ra,24(sp)
    80004510:	e822                	sd	s0,16(sp)
    80004512:	e426                	sd	s1,8(sp)
    80004514:	e04a                	sd	s2,0(sp)
    80004516:	1000                	addi	s0,sp,32
    80004518:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000451a:	00850913          	addi	s2,a0,8
    8000451e:	854a                	mv	a0,s2
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	6c4080e7          	jalr	1732(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004528:	409c                	lw	a5,0(s1)
    8000452a:	cb89                	beqz	a5,8000453c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000452c:	85ca                	mv	a1,s2
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffe097          	auipc	ra,0xffffe
    80004534:	b98080e7          	jalr	-1128(ra) # 800020c8 <sleep>
  while (lk->locked) {
    80004538:	409c                	lw	a5,0(s1)
    8000453a:	fbed                	bnez	a5,8000452c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000453c:	4785                	li	a5,1
    8000453e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004540:	ffffd097          	auipc	ra,0xffffd
    80004544:	470080e7          	jalr	1136(ra) # 800019b0 <myproc>
    80004548:	591c                	lw	a5,48(a0)
    8000454a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	74a080e7          	jalr	1866(ra) # 80000c98 <release>
}
    80004556:	60e2                	ld	ra,24(sp)
    80004558:	6442                	ld	s0,16(sp)
    8000455a:	64a2                	ld	s1,8(sp)
    8000455c:	6902                	ld	s2,0(sp)
    8000455e:	6105                	addi	sp,sp,32
    80004560:	8082                	ret

0000000080004562 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004562:	1101                	addi	sp,sp,-32
    80004564:	ec06                	sd	ra,24(sp)
    80004566:	e822                	sd	s0,16(sp)
    80004568:	e426                	sd	s1,8(sp)
    8000456a:	e04a                	sd	s2,0(sp)
    8000456c:	1000                	addi	s0,sp,32
    8000456e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004570:	00850913          	addi	s2,a0,8
    80004574:	854a                	mv	a0,s2
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	66e080e7          	jalr	1646(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000457e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004582:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004586:	8526                	mv	a0,s1
    80004588:	ffffe097          	auipc	ra,0xffffe
    8000458c:	ccc080e7          	jalr	-820(ra) # 80002254 <wakeup>
  release(&lk->lk);
    80004590:	854a                	mv	a0,s2
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	706080e7          	jalr	1798(ra) # 80000c98 <release>
}
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6902                	ld	s2,0(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret

00000000800045a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045a6:	7179                	addi	sp,sp,-48
    800045a8:	f406                	sd	ra,40(sp)
    800045aa:	f022                	sd	s0,32(sp)
    800045ac:	ec26                	sd	s1,24(sp)
    800045ae:	e84a                	sd	s2,16(sp)
    800045b0:	e44e                	sd	s3,8(sp)
    800045b2:	1800                	addi	s0,sp,48
    800045b4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045b6:	00850913          	addi	s2,a0,8
    800045ba:	854a                	mv	a0,s2
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	628080e7          	jalr	1576(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c4:	409c                	lw	a5,0(s1)
    800045c6:	ef99                	bnez	a5,800045e4 <holdingsleep+0x3e>
    800045c8:	4481                	li	s1,0
  release(&lk->lk);
    800045ca:	854a                	mv	a0,s2
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	6cc080e7          	jalr	1740(ra) # 80000c98 <release>
  return r;
}
    800045d4:	8526                	mv	a0,s1
    800045d6:	70a2                	ld	ra,40(sp)
    800045d8:	7402                	ld	s0,32(sp)
    800045da:	64e2                	ld	s1,24(sp)
    800045dc:	6942                	ld	s2,16(sp)
    800045de:	69a2                	ld	s3,8(sp)
    800045e0:	6145                	addi	sp,sp,48
    800045e2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e4:	0284a983          	lw	s3,40(s1)
    800045e8:	ffffd097          	auipc	ra,0xffffd
    800045ec:	3c8080e7          	jalr	968(ra) # 800019b0 <myproc>
    800045f0:	5904                	lw	s1,48(a0)
    800045f2:	413484b3          	sub	s1,s1,s3
    800045f6:	0014b493          	seqz	s1,s1
    800045fa:	bfc1                	j	800045ca <holdingsleep+0x24>

00000000800045fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045fc:	1141                	addi	sp,sp,-16
    800045fe:	e406                	sd	ra,8(sp)
    80004600:	e022                	sd	s0,0(sp)
    80004602:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004604:	00004597          	auipc	a1,0x4
    80004608:	17c58593          	addi	a1,a1,380 # 80008780 <syscalls+0x240>
    8000460c:	0001e517          	auipc	a0,0x1e
    80004610:	bac50513          	addi	a0,a0,-1108 # 800221b8 <ftable>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	540080e7          	jalr	1344(ra) # 80000b54 <initlock>
}
    8000461c:	60a2                	ld	ra,8(sp)
    8000461e:	6402                	ld	s0,0(sp)
    80004620:	0141                	addi	sp,sp,16
    80004622:	8082                	ret

0000000080004624 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000462e:	0001e517          	auipc	a0,0x1e
    80004632:	b8a50513          	addi	a0,a0,-1142 # 800221b8 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	5ae080e7          	jalr	1454(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463e:	0001e497          	auipc	s1,0x1e
    80004642:	b9248493          	addi	s1,s1,-1134 # 800221d0 <ftable+0x18>
    80004646:	0001f717          	auipc	a4,0x1f
    8000464a:	b2a70713          	addi	a4,a4,-1238 # 80023170 <ftable+0xfb8>
    if(f->ref == 0){
    8000464e:	40dc                	lw	a5,4(s1)
    80004650:	cf99                	beqz	a5,8000466e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004652:	02848493          	addi	s1,s1,40
    80004656:	fee49ce3          	bne	s1,a4,8000464e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000465a:	0001e517          	auipc	a0,0x1e
    8000465e:	b5e50513          	addi	a0,a0,-1186 # 800221b8 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	636080e7          	jalr	1590(ra) # 80000c98 <release>
  return 0;
    8000466a:	4481                	li	s1,0
    8000466c:	a819                	j	80004682 <filealloc+0x5e>
      f->ref = 1;
    8000466e:	4785                	li	a5,1
    80004670:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004672:	0001e517          	auipc	a0,0x1e
    80004676:	b4650513          	addi	a0,a0,-1210 # 800221b8 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	61e080e7          	jalr	1566(ra) # 80000c98 <release>
}
    80004682:	8526                	mv	a0,s1
    80004684:	60e2                	ld	ra,24(sp)
    80004686:	6442                	ld	s0,16(sp)
    80004688:	64a2                	ld	s1,8(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	1000                	addi	s0,sp,32
    80004698:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000469a:	0001e517          	auipc	a0,0x1e
    8000469e:	b1e50513          	addi	a0,a0,-1250 # 800221b8 <ftable>
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	542080e7          	jalr	1346(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046aa:	40dc                	lw	a5,4(s1)
    800046ac:	02f05263          	blez	a5,800046d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046b0:	2785                	addiw	a5,a5,1
    800046b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b4:	0001e517          	auipc	a0,0x1e
    800046b8:	b0450513          	addi	a0,a0,-1276 # 800221b8 <ftable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	5dc080e7          	jalr	1500(ra) # 80000c98 <release>
  return f;
}
    800046c4:	8526                	mv	a0,s1
    800046c6:	60e2                	ld	ra,24(sp)
    800046c8:	6442                	ld	s0,16(sp)
    800046ca:	64a2                	ld	s1,8(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret
    panic("filedup");
    800046d0:	00004517          	auipc	a0,0x4
    800046d4:	0b850513          	addi	a0,a0,184 # 80008788 <syscalls+0x248>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	e66080e7          	jalr	-410(ra) # 8000053e <panic>

00000000800046e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046e0:	7139                	addi	sp,sp,-64
    800046e2:	fc06                	sd	ra,56(sp)
    800046e4:	f822                	sd	s0,48(sp)
    800046e6:	f426                	sd	s1,40(sp)
    800046e8:	f04a                	sd	s2,32(sp)
    800046ea:	ec4e                	sd	s3,24(sp)
    800046ec:	e852                	sd	s4,16(sp)
    800046ee:	e456                	sd	s5,8(sp)
    800046f0:	0080                	addi	s0,sp,64
    800046f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046f4:	0001e517          	auipc	a0,0x1e
    800046f8:	ac450513          	addi	a0,a0,-1340 # 800221b8 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	4e8080e7          	jalr	1256(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004704:	40dc                	lw	a5,4(s1)
    80004706:	06f05163          	blez	a5,80004768 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000470a:	37fd                	addiw	a5,a5,-1
    8000470c:	0007871b          	sext.w	a4,a5
    80004710:	c0dc                	sw	a5,4(s1)
    80004712:	06e04363          	bgtz	a4,80004778 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004716:	0004a903          	lw	s2,0(s1)
    8000471a:	0094ca83          	lbu	s5,9(s1)
    8000471e:	0104ba03          	ld	s4,16(s1)
    80004722:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004726:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000472a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000472e:	0001e517          	auipc	a0,0x1e
    80004732:	a8a50513          	addi	a0,a0,-1398 # 800221b8 <ftable>
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	562080e7          	jalr	1378(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000473e:	4785                	li	a5,1
    80004740:	04f90d63          	beq	s2,a5,8000479a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004744:	3979                	addiw	s2,s2,-2
    80004746:	4785                	li	a5,1
    80004748:	0527e063          	bltu	a5,s2,80004788 <fileclose+0xa8>
    begin_op();
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	ac8080e7          	jalr	-1336(ra) # 80004214 <begin_op>
    iput(ff.ip);
    80004754:	854e                	mv	a0,s3
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	2a6080e7          	jalr	678(ra) # 800039fc <iput>
    end_op();
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	b36080e7          	jalr	-1226(ra) # 80004294 <end_op>
    80004766:	a00d                	j	80004788 <fileclose+0xa8>
    panic("fileclose");
    80004768:	00004517          	auipc	a0,0x4
    8000476c:	02850513          	addi	a0,a0,40 # 80008790 <syscalls+0x250>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	dce080e7          	jalr	-562(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004778:	0001e517          	auipc	a0,0x1e
    8000477c:	a4050513          	addi	a0,a0,-1472 # 800221b8 <ftable>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	518080e7          	jalr	1304(ra) # 80000c98 <release>
  }
}
    80004788:	70e2                	ld	ra,56(sp)
    8000478a:	7442                	ld	s0,48(sp)
    8000478c:	74a2                	ld	s1,40(sp)
    8000478e:	7902                	ld	s2,32(sp)
    80004790:	69e2                	ld	s3,24(sp)
    80004792:	6a42                	ld	s4,16(sp)
    80004794:	6aa2                	ld	s5,8(sp)
    80004796:	6121                	addi	sp,sp,64
    80004798:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000479a:	85d6                	mv	a1,s5
    8000479c:	8552                	mv	a0,s4
    8000479e:	00000097          	auipc	ra,0x0
    800047a2:	34c080e7          	jalr	844(ra) # 80004aea <pipeclose>
    800047a6:	b7cd                	j	80004788 <fileclose+0xa8>

00000000800047a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047a8:	715d                	addi	sp,sp,-80
    800047aa:	e486                	sd	ra,72(sp)
    800047ac:	e0a2                	sd	s0,64(sp)
    800047ae:	fc26                	sd	s1,56(sp)
    800047b0:	f84a                	sd	s2,48(sp)
    800047b2:	f44e                	sd	s3,40(sp)
    800047b4:	0880                	addi	s0,sp,80
    800047b6:	84aa                	mv	s1,a0
    800047b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ba:	ffffd097          	auipc	ra,0xffffd
    800047be:	1f6080e7          	jalr	502(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047c2:	409c                	lw	a5,0(s1)
    800047c4:	37f9                	addiw	a5,a5,-2
    800047c6:	4705                	li	a4,1
    800047c8:	04f76763          	bltu	a4,a5,80004816 <filestat+0x6e>
    800047cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800047ce:	6c88                	ld	a0,24(s1)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	072080e7          	jalr	114(ra) # 80003842 <ilock>
    stati(f->ip, &st);
    800047d8:	fb840593          	addi	a1,s0,-72
    800047dc:	6c88                	ld	a0,24(s1)
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	2ee080e7          	jalr	750(ra) # 80003acc <stati>
    iunlock(f->ip);
    800047e6:	6c88                	ld	a0,24(s1)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	11c080e7          	jalr	284(ra) # 80003904 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047f0:	46e1                	li	a3,24
    800047f2:	fb840613          	addi	a2,s0,-72
    800047f6:	85ce                	mv	a1,s3
    800047f8:	05093503          	ld	a0,80(s2)
    800047fc:	ffffd097          	auipc	ra,0xffffd
    80004800:	e76080e7          	jalr	-394(ra) # 80001672 <copyout>
    80004804:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004808:	60a6                	ld	ra,72(sp)
    8000480a:	6406                	ld	s0,64(sp)
    8000480c:	74e2                	ld	s1,56(sp)
    8000480e:	7942                	ld	s2,48(sp)
    80004810:	79a2                	ld	s3,40(sp)
    80004812:	6161                	addi	sp,sp,80
    80004814:	8082                	ret
  return -1;
    80004816:	557d                	li	a0,-1
    80004818:	bfc5                	j	80004808 <filestat+0x60>

000000008000481a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000481a:	7179                	addi	sp,sp,-48
    8000481c:	f406                	sd	ra,40(sp)
    8000481e:	f022                	sd	s0,32(sp)
    80004820:	ec26                	sd	s1,24(sp)
    80004822:	e84a                	sd	s2,16(sp)
    80004824:	e44e                	sd	s3,8(sp)
    80004826:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004828:	00854783          	lbu	a5,8(a0)
    8000482c:	c3d5                	beqz	a5,800048d0 <fileread+0xb6>
    8000482e:	84aa                	mv	s1,a0
    80004830:	89ae                	mv	s3,a1
    80004832:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004834:	411c                	lw	a5,0(a0)
    80004836:	4705                	li	a4,1
    80004838:	04e78963          	beq	a5,a4,8000488a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000483c:	470d                	li	a4,3
    8000483e:	04e78d63          	beq	a5,a4,80004898 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004842:	4709                	li	a4,2
    80004844:	06e79e63          	bne	a5,a4,800048c0 <fileread+0xa6>
    ilock(f->ip);
    80004848:	6d08                	ld	a0,24(a0)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	ff8080e7          	jalr	-8(ra) # 80003842 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004852:	874a                	mv	a4,s2
    80004854:	5094                	lw	a3,32(s1)
    80004856:	864e                	mv	a2,s3
    80004858:	4585                	li	a1,1
    8000485a:	6c88                	ld	a0,24(s1)
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	29a080e7          	jalr	666(ra) # 80003af6 <readi>
    80004864:	892a                	mv	s2,a0
    80004866:	00a05563          	blez	a0,80004870 <fileread+0x56>
      f->off += r;
    8000486a:	509c                	lw	a5,32(s1)
    8000486c:	9fa9                	addw	a5,a5,a0
    8000486e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004870:	6c88                	ld	a0,24(s1)
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	092080e7          	jalr	146(ra) # 80003904 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000487a:	854a                	mv	a0,s2
    8000487c:	70a2                	ld	ra,40(sp)
    8000487e:	7402                	ld	s0,32(sp)
    80004880:	64e2                	ld	s1,24(sp)
    80004882:	6942                	ld	s2,16(sp)
    80004884:	69a2                	ld	s3,8(sp)
    80004886:	6145                	addi	sp,sp,48
    80004888:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000488a:	6908                	ld	a0,16(a0)
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	3c8080e7          	jalr	968(ra) # 80004c54 <piperead>
    80004894:	892a                	mv	s2,a0
    80004896:	b7d5                	j	8000487a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004898:	02451783          	lh	a5,36(a0)
    8000489c:	03079693          	slli	a3,a5,0x30
    800048a0:	92c1                	srli	a3,a3,0x30
    800048a2:	4725                	li	a4,9
    800048a4:	02d76863          	bltu	a4,a3,800048d4 <fileread+0xba>
    800048a8:	0792                	slli	a5,a5,0x4
    800048aa:	0001e717          	auipc	a4,0x1e
    800048ae:	86e70713          	addi	a4,a4,-1938 # 80022118 <devsw>
    800048b2:	97ba                	add	a5,a5,a4
    800048b4:	639c                	ld	a5,0(a5)
    800048b6:	c38d                	beqz	a5,800048d8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048b8:	4505                	li	a0,1
    800048ba:	9782                	jalr	a5
    800048bc:	892a                	mv	s2,a0
    800048be:	bf75                	j	8000487a <fileread+0x60>
    panic("fileread");
    800048c0:	00004517          	auipc	a0,0x4
    800048c4:	ee050513          	addi	a0,a0,-288 # 800087a0 <syscalls+0x260>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	c76080e7          	jalr	-906(ra) # 8000053e <panic>
    return -1;
    800048d0:	597d                	li	s2,-1
    800048d2:	b765                	j	8000487a <fileread+0x60>
      return -1;
    800048d4:	597d                	li	s2,-1
    800048d6:	b755                	j	8000487a <fileread+0x60>
    800048d8:	597d                	li	s2,-1
    800048da:	b745                	j	8000487a <fileread+0x60>

00000000800048dc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048dc:	715d                	addi	sp,sp,-80
    800048de:	e486                	sd	ra,72(sp)
    800048e0:	e0a2                	sd	s0,64(sp)
    800048e2:	fc26                	sd	s1,56(sp)
    800048e4:	f84a                	sd	s2,48(sp)
    800048e6:	f44e                	sd	s3,40(sp)
    800048e8:	f052                	sd	s4,32(sp)
    800048ea:	ec56                	sd	s5,24(sp)
    800048ec:	e85a                	sd	s6,16(sp)
    800048ee:	e45e                	sd	s7,8(sp)
    800048f0:	e062                	sd	s8,0(sp)
    800048f2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048f4:	00954783          	lbu	a5,9(a0)
    800048f8:	10078663          	beqz	a5,80004a04 <filewrite+0x128>
    800048fc:	892a                	mv	s2,a0
    800048fe:	8aae                	mv	s5,a1
    80004900:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004902:	411c                	lw	a5,0(a0)
    80004904:	4705                	li	a4,1
    80004906:	02e78263          	beq	a5,a4,8000492a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000490a:	470d                	li	a4,3
    8000490c:	02e78663          	beq	a5,a4,80004938 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004910:	4709                	li	a4,2
    80004912:	0ee79163          	bne	a5,a4,800049f4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004916:	0ac05d63          	blez	a2,800049d0 <filewrite+0xf4>
    int i = 0;
    8000491a:	4981                	li	s3,0
    8000491c:	6b05                	lui	s6,0x1
    8000491e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004922:	6b85                	lui	s7,0x1
    80004924:	c00b8b9b          	addiw	s7,s7,-1024
    80004928:	a861                	j	800049c0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000492a:	6908                	ld	a0,16(a0)
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	22e080e7          	jalr	558(ra) # 80004b5a <pipewrite>
    80004934:	8a2a                	mv	s4,a0
    80004936:	a045                	j	800049d6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004938:	02451783          	lh	a5,36(a0)
    8000493c:	03079693          	slli	a3,a5,0x30
    80004940:	92c1                	srli	a3,a3,0x30
    80004942:	4725                	li	a4,9
    80004944:	0cd76263          	bltu	a4,a3,80004a08 <filewrite+0x12c>
    80004948:	0792                	slli	a5,a5,0x4
    8000494a:	0001d717          	auipc	a4,0x1d
    8000494e:	7ce70713          	addi	a4,a4,1998 # 80022118 <devsw>
    80004952:	97ba                	add	a5,a5,a4
    80004954:	679c                	ld	a5,8(a5)
    80004956:	cbdd                	beqz	a5,80004a0c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004958:	4505                	li	a0,1
    8000495a:	9782                	jalr	a5
    8000495c:	8a2a                	mv	s4,a0
    8000495e:	a8a5                	j	800049d6 <filewrite+0xfa>
    80004960:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004964:	00000097          	auipc	ra,0x0
    80004968:	8b0080e7          	jalr	-1872(ra) # 80004214 <begin_op>
      ilock(f->ip);
    8000496c:	01893503          	ld	a0,24(s2)
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	ed2080e7          	jalr	-302(ra) # 80003842 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004978:	8762                	mv	a4,s8
    8000497a:	02092683          	lw	a3,32(s2)
    8000497e:	01598633          	add	a2,s3,s5
    80004982:	4585                	li	a1,1
    80004984:	01893503          	ld	a0,24(s2)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	266080e7          	jalr	614(ra) # 80003bee <writei>
    80004990:	84aa                	mv	s1,a0
    80004992:	00a05763          	blez	a0,800049a0 <filewrite+0xc4>
        f->off += r;
    80004996:	02092783          	lw	a5,32(s2)
    8000499a:	9fa9                	addw	a5,a5,a0
    8000499c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049a0:	01893503          	ld	a0,24(s2)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	f60080e7          	jalr	-160(ra) # 80003904 <iunlock>
      end_op();
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	8e8080e7          	jalr	-1816(ra) # 80004294 <end_op>

      if(r != n1){
    800049b4:	009c1f63          	bne	s8,s1,800049d2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049b8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049bc:	0149db63          	bge	s3,s4,800049d2 <filewrite+0xf6>
      int n1 = n - i;
    800049c0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049c4:	84be                	mv	s1,a5
    800049c6:	2781                	sext.w	a5,a5
    800049c8:	f8fb5ce3          	bge	s6,a5,80004960 <filewrite+0x84>
    800049cc:	84de                	mv	s1,s7
    800049ce:	bf49                	j	80004960 <filewrite+0x84>
    int i = 0;
    800049d0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049d2:	013a1f63          	bne	s4,s3,800049f0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049d6:	8552                	mv	a0,s4
    800049d8:	60a6                	ld	ra,72(sp)
    800049da:	6406                	ld	s0,64(sp)
    800049dc:	74e2                	ld	s1,56(sp)
    800049de:	7942                	ld	s2,48(sp)
    800049e0:	79a2                	ld	s3,40(sp)
    800049e2:	7a02                	ld	s4,32(sp)
    800049e4:	6ae2                	ld	s5,24(sp)
    800049e6:	6b42                	ld	s6,16(sp)
    800049e8:	6ba2                	ld	s7,8(sp)
    800049ea:	6c02                	ld	s8,0(sp)
    800049ec:	6161                	addi	sp,sp,80
    800049ee:	8082                	ret
    ret = (i == n ? n : -1);
    800049f0:	5a7d                	li	s4,-1
    800049f2:	b7d5                	j	800049d6 <filewrite+0xfa>
    panic("filewrite");
    800049f4:	00004517          	auipc	a0,0x4
    800049f8:	dbc50513          	addi	a0,a0,-580 # 800087b0 <syscalls+0x270>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	b42080e7          	jalr	-1214(ra) # 8000053e <panic>
    return -1;
    80004a04:	5a7d                	li	s4,-1
    80004a06:	bfc1                	j	800049d6 <filewrite+0xfa>
      return -1;
    80004a08:	5a7d                	li	s4,-1
    80004a0a:	b7f1                	j	800049d6 <filewrite+0xfa>
    80004a0c:	5a7d                	li	s4,-1
    80004a0e:	b7e1                	j	800049d6 <filewrite+0xfa>

0000000080004a10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a10:	7179                	addi	sp,sp,-48
    80004a12:	f406                	sd	ra,40(sp)
    80004a14:	f022                	sd	s0,32(sp)
    80004a16:	ec26                	sd	s1,24(sp)
    80004a18:	e84a                	sd	s2,16(sp)
    80004a1a:	e44e                	sd	s3,8(sp)
    80004a1c:	e052                	sd	s4,0(sp)
    80004a1e:	1800                	addi	s0,sp,48
    80004a20:	84aa                	mv	s1,a0
    80004a22:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a24:	0005b023          	sd	zero,0(a1)
    80004a28:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	bf8080e7          	jalr	-1032(ra) # 80004624 <filealloc>
    80004a34:	e088                	sd	a0,0(s1)
    80004a36:	c551                	beqz	a0,80004ac2 <pipealloc+0xb2>
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	bec080e7          	jalr	-1044(ra) # 80004624 <filealloc>
    80004a40:	00aa3023          	sd	a0,0(s4)
    80004a44:	c92d                	beqz	a0,80004ab6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	0ae080e7          	jalr	174(ra) # 80000af4 <kalloc>
    80004a4e:	892a                	mv	s2,a0
    80004a50:	c125                	beqz	a0,80004ab0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a52:	4985                	li	s3,1
    80004a54:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a58:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a5c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a60:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a64:	00004597          	auipc	a1,0x4
    80004a68:	9c458593          	addi	a1,a1,-1596 # 80008428 <states.2432+0x168>
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	0e8080e7          	jalr	232(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a74:	609c                	ld	a5,0(s1)
    80004a76:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a7a:	609c                	ld	a5,0(s1)
    80004a7c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a80:	609c                	ld	a5,0(s1)
    80004a82:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a86:	609c                	ld	a5,0(s1)
    80004a88:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a8c:	000a3783          	ld	a5,0(s4)
    80004a90:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a94:	000a3783          	ld	a5,0(s4)
    80004a98:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a9c:	000a3783          	ld	a5,0(s4)
    80004aa0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aa4:	000a3783          	ld	a5,0(s4)
    80004aa8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aac:	4501                	li	a0,0
    80004aae:	a025                	j	80004ad6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ab0:	6088                	ld	a0,0(s1)
    80004ab2:	e501                	bnez	a0,80004aba <pipealloc+0xaa>
    80004ab4:	a039                	j	80004ac2 <pipealloc+0xb2>
    80004ab6:	6088                	ld	a0,0(s1)
    80004ab8:	c51d                	beqz	a0,80004ae6 <pipealloc+0xd6>
    fileclose(*f0);
    80004aba:	00000097          	auipc	ra,0x0
    80004abe:	c26080e7          	jalr	-986(ra) # 800046e0 <fileclose>
  if(*f1)
    80004ac2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ac6:	557d                	li	a0,-1
  if(*f1)
    80004ac8:	c799                	beqz	a5,80004ad6 <pipealloc+0xc6>
    fileclose(*f1);
    80004aca:	853e                	mv	a0,a5
    80004acc:	00000097          	auipc	ra,0x0
    80004ad0:	c14080e7          	jalr	-1004(ra) # 800046e0 <fileclose>
  return -1;
    80004ad4:	557d                	li	a0,-1
}
    80004ad6:	70a2                	ld	ra,40(sp)
    80004ad8:	7402                	ld	s0,32(sp)
    80004ada:	64e2                	ld	s1,24(sp)
    80004adc:	6942                	ld	s2,16(sp)
    80004ade:	69a2                	ld	s3,8(sp)
    80004ae0:	6a02                	ld	s4,0(sp)
    80004ae2:	6145                	addi	sp,sp,48
    80004ae4:	8082                	ret
  return -1;
    80004ae6:	557d                	li	a0,-1
    80004ae8:	b7fd                	j	80004ad6 <pipealloc+0xc6>

0000000080004aea <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aea:	1101                	addi	sp,sp,-32
    80004aec:	ec06                	sd	ra,24(sp)
    80004aee:	e822                	sd	s0,16(sp)
    80004af0:	e426                	sd	s1,8(sp)
    80004af2:	e04a                	sd	s2,0(sp)
    80004af4:	1000                	addi	s0,sp,32
    80004af6:	84aa                	mv	s1,a0
    80004af8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	0ea080e7          	jalr	234(ra) # 80000be4 <acquire>
  if(writable){
    80004b02:	02090d63          	beqz	s2,80004b3c <pipeclose+0x52>
    pi->writeopen = 0;
    80004b06:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b0a:	21848513          	addi	a0,s1,536
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	746080e7          	jalr	1862(ra) # 80002254 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b16:	2204b783          	ld	a5,544(s1)
    80004b1a:	eb95                	bnez	a5,80004b4e <pipeclose+0x64>
    release(&pi->lock);
    80004b1c:	8526                	mv	a0,s1
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	17a080e7          	jalr	378(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b26:	8526                	mv	a0,s1
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	ed0080e7          	jalr	-304(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b30:	60e2                	ld	ra,24(sp)
    80004b32:	6442                	ld	s0,16(sp)
    80004b34:	64a2                	ld	s1,8(sp)
    80004b36:	6902                	ld	s2,0(sp)
    80004b38:	6105                	addi	sp,sp,32
    80004b3a:	8082                	ret
    pi->readopen = 0;
    80004b3c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b40:	21c48513          	addi	a0,s1,540
    80004b44:	ffffd097          	auipc	ra,0xffffd
    80004b48:	710080e7          	jalr	1808(ra) # 80002254 <wakeup>
    80004b4c:	b7e9                	j	80004b16 <pipeclose+0x2c>
    release(&pi->lock);
    80004b4e:	8526                	mv	a0,s1
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	148080e7          	jalr	328(ra) # 80000c98 <release>
}
    80004b58:	bfe1                	j	80004b30 <pipeclose+0x46>

0000000080004b5a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b5a:	7159                	addi	sp,sp,-112
    80004b5c:	f486                	sd	ra,104(sp)
    80004b5e:	f0a2                	sd	s0,96(sp)
    80004b60:	eca6                	sd	s1,88(sp)
    80004b62:	e8ca                	sd	s2,80(sp)
    80004b64:	e4ce                	sd	s3,72(sp)
    80004b66:	e0d2                	sd	s4,64(sp)
    80004b68:	fc56                	sd	s5,56(sp)
    80004b6a:	f85a                	sd	s6,48(sp)
    80004b6c:	f45e                	sd	s7,40(sp)
    80004b6e:	f062                	sd	s8,32(sp)
    80004b70:	ec66                	sd	s9,24(sp)
    80004b72:	1880                	addi	s0,sp,112
    80004b74:	84aa                	mv	s1,a0
    80004b76:	8aae                	mv	s5,a1
    80004b78:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	e36080e7          	jalr	-458(ra) # 800019b0 <myproc>
    80004b82:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	05e080e7          	jalr	94(ra) # 80000be4 <acquire>
  while(i < n){
    80004b8e:	0d405163          	blez	s4,80004c50 <pipewrite+0xf6>
    80004b92:	8ba6                	mv	s7,s1
  int i = 0;
    80004b94:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b96:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b98:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b9c:	21c48c13          	addi	s8,s1,540
    80004ba0:	a08d                	j	80004c02 <pipewrite+0xa8>
      release(&pi->lock);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	0f4080e7          	jalr	244(ra) # 80000c98 <release>
      return -1;
    80004bac:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bae:	854a                	mv	a0,s2
    80004bb0:	70a6                	ld	ra,104(sp)
    80004bb2:	7406                	ld	s0,96(sp)
    80004bb4:	64e6                	ld	s1,88(sp)
    80004bb6:	6946                	ld	s2,80(sp)
    80004bb8:	69a6                	ld	s3,72(sp)
    80004bba:	6a06                	ld	s4,64(sp)
    80004bbc:	7ae2                	ld	s5,56(sp)
    80004bbe:	7b42                	ld	s6,48(sp)
    80004bc0:	7ba2                	ld	s7,40(sp)
    80004bc2:	7c02                	ld	s8,32(sp)
    80004bc4:	6ce2                	ld	s9,24(sp)
    80004bc6:	6165                	addi	sp,sp,112
    80004bc8:	8082                	ret
      wakeup(&pi->nread);
    80004bca:	8566                	mv	a0,s9
    80004bcc:	ffffd097          	auipc	ra,0xffffd
    80004bd0:	688080e7          	jalr	1672(ra) # 80002254 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bd4:	85de                	mv	a1,s7
    80004bd6:	8562                	mv	a0,s8
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	4f0080e7          	jalr	1264(ra) # 800020c8 <sleep>
    80004be0:	a839                	j	80004bfe <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004be2:	21c4a783          	lw	a5,540(s1)
    80004be6:	0017871b          	addiw	a4,a5,1
    80004bea:	20e4ae23          	sw	a4,540(s1)
    80004bee:	1ff7f793          	andi	a5,a5,511
    80004bf2:	97a6                	add	a5,a5,s1
    80004bf4:	f9f44703          	lbu	a4,-97(s0)
    80004bf8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bfc:	2905                	addiw	s2,s2,1
  while(i < n){
    80004bfe:	03495d63          	bge	s2,s4,80004c38 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c02:	2204a783          	lw	a5,544(s1)
    80004c06:	dfd1                	beqz	a5,80004ba2 <pipewrite+0x48>
    80004c08:	0289a783          	lw	a5,40(s3)
    80004c0c:	fbd9                	bnez	a5,80004ba2 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c0e:	2184a783          	lw	a5,536(s1)
    80004c12:	21c4a703          	lw	a4,540(s1)
    80004c16:	2007879b          	addiw	a5,a5,512
    80004c1a:	faf708e3          	beq	a4,a5,80004bca <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c1e:	4685                	li	a3,1
    80004c20:	01590633          	add	a2,s2,s5
    80004c24:	f9f40593          	addi	a1,s0,-97
    80004c28:	0509b503          	ld	a0,80(s3)
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	ad2080e7          	jalr	-1326(ra) # 800016fe <copyin>
    80004c34:	fb6517e3          	bne	a0,s6,80004be2 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c38:	21848513          	addi	a0,s1,536
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	618080e7          	jalr	1560(ra) # 80002254 <wakeup>
  release(&pi->lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	052080e7          	jalr	82(ra) # 80000c98 <release>
  return i;
    80004c4e:	b785                	j	80004bae <pipewrite+0x54>
  int i = 0;
    80004c50:	4901                	li	s2,0
    80004c52:	b7dd                	j	80004c38 <pipewrite+0xde>

0000000080004c54 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c54:	715d                	addi	sp,sp,-80
    80004c56:	e486                	sd	ra,72(sp)
    80004c58:	e0a2                	sd	s0,64(sp)
    80004c5a:	fc26                	sd	s1,56(sp)
    80004c5c:	f84a                	sd	s2,48(sp)
    80004c5e:	f44e                	sd	s3,40(sp)
    80004c60:	f052                	sd	s4,32(sp)
    80004c62:	ec56                	sd	s5,24(sp)
    80004c64:	e85a                	sd	s6,16(sp)
    80004c66:	0880                	addi	s0,sp,80
    80004c68:	84aa                	mv	s1,a0
    80004c6a:	892e                	mv	s2,a1
    80004c6c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c6e:	ffffd097          	auipc	ra,0xffffd
    80004c72:	d42080e7          	jalr	-702(ra) # 800019b0 <myproc>
    80004c76:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c78:	8b26                	mv	s6,s1
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	f68080e7          	jalr	-152(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c84:	2184a703          	lw	a4,536(s1)
    80004c88:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c8c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c90:	02f71463          	bne	a4,a5,80004cb8 <piperead+0x64>
    80004c94:	2244a783          	lw	a5,548(s1)
    80004c98:	c385                	beqz	a5,80004cb8 <piperead+0x64>
    if(pr->killed){
    80004c9a:	028a2783          	lw	a5,40(s4)
    80004c9e:	ebc1                	bnez	a5,80004d2e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ca0:	85da                	mv	a1,s6
    80004ca2:	854e                	mv	a0,s3
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	424080e7          	jalr	1060(ra) # 800020c8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cac:	2184a703          	lw	a4,536(s1)
    80004cb0:	21c4a783          	lw	a5,540(s1)
    80004cb4:	fef700e3          	beq	a4,a5,80004c94 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb8:	09505263          	blez	s5,80004d3c <piperead+0xe8>
    80004cbc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cbe:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cc0:	2184a783          	lw	a5,536(s1)
    80004cc4:	21c4a703          	lw	a4,540(s1)
    80004cc8:	02f70d63          	beq	a4,a5,80004d02 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ccc:	0017871b          	addiw	a4,a5,1
    80004cd0:	20e4ac23          	sw	a4,536(s1)
    80004cd4:	1ff7f793          	andi	a5,a5,511
    80004cd8:	97a6                	add	a5,a5,s1
    80004cda:	0187c783          	lbu	a5,24(a5)
    80004cde:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce2:	4685                	li	a3,1
    80004ce4:	fbf40613          	addi	a2,s0,-65
    80004ce8:	85ca                	mv	a1,s2
    80004cea:	050a3503          	ld	a0,80(s4)
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	984080e7          	jalr	-1660(ra) # 80001672 <copyout>
    80004cf6:	01650663          	beq	a0,s6,80004d02 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfa:	2985                	addiw	s3,s3,1
    80004cfc:	0905                	addi	s2,s2,1
    80004cfe:	fd3a91e3          	bne	s5,s3,80004cc0 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d02:	21c48513          	addi	a0,s1,540
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	54e080e7          	jalr	1358(ra) # 80002254 <wakeup>
  release(&pi->lock);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	f88080e7          	jalr	-120(ra) # 80000c98 <release>
  return i;
}
    80004d18:	854e                	mv	a0,s3
    80004d1a:	60a6                	ld	ra,72(sp)
    80004d1c:	6406                	ld	s0,64(sp)
    80004d1e:	74e2                	ld	s1,56(sp)
    80004d20:	7942                	ld	s2,48(sp)
    80004d22:	79a2                	ld	s3,40(sp)
    80004d24:	7a02                	ld	s4,32(sp)
    80004d26:	6ae2                	ld	s5,24(sp)
    80004d28:	6b42                	ld	s6,16(sp)
    80004d2a:	6161                	addi	sp,sp,80
    80004d2c:	8082                	ret
      release(&pi->lock);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	f68080e7          	jalr	-152(ra) # 80000c98 <release>
      return -1;
    80004d38:	59fd                	li	s3,-1
    80004d3a:	bff9                	j	80004d18 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3c:	4981                	li	s3,0
    80004d3e:	b7d1                	j	80004d02 <piperead+0xae>

0000000080004d40 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d40:	df010113          	addi	sp,sp,-528
    80004d44:	20113423          	sd	ra,520(sp)
    80004d48:	20813023          	sd	s0,512(sp)
    80004d4c:	ffa6                	sd	s1,504(sp)
    80004d4e:	fbca                	sd	s2,496(sp)
    80004d50:	f7ce                	sd	s3,488(sp)
    80004d52:	f3d2                	sd	s4,480(sp)
    80004d54:	efd6                	sd	s5,472(sp)
    80004d56:	ebda                	sd	s6,464(sp)
    80004d58:	e7de                	sd	s7,456(sp)
    80004d5a:	e3e2                	sd	s8,448(sp)
    80004d5c:	ff66                	sd	s9,440(sp)
    80004d5e:	fb6a                	sd	s10,432(sp)
    80004d60:	f76e                	sd	s11,424(sp)
    80004d62:	0c00                	addi	s0,sp,528
    80004d64:	84aa                	mv	s1,a0
    80004d66:	dea43c23          	sd	a0,-520(s0)
    80004d6a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	c42080e7          	jalr	-958(ra) # 800019b0 <myproc>
    80004d76:	892a                	mv	s2,a0

  begin_op();
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	49c080e7          	jalr	1180(ra) # 80004214 <begin_op>

  if((ip = namei(path)) == 0){
    80004d80:	8526                	mv	a0,s1
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	276080e7          	jalr	630(ra) # 80003ff8 <namei>
    80004d8a:	c92d                	beqz	a0,80004dfc <exec+0xbc>
    80004d8c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	ab4080e7          	jalr	-1356(ra) # 80003842 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d96:	04000713          	li	a4,64
    80004d9a:	4681                	li	a3,0
    80004d9c:	e5040613          	addi	a2,s0,-432
    80004da0:	4581                	li	a1,0
    80004da2:	8526                	mv	a0,s1
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	d52080e7          	jalr	-686(ra) # 80003af6 <readi>
    80004dac:	04000793          	li	a5,64
    80004db0:	00f51a63          	bne	a0,a5,80004dc4 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004db4:	e5042703          	lw	a4,-432(s0)
    80004db8:	464c47b7          	lui	a5,0x464c4
    80004dbc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dc0:	04f70463          	beq	a4,a5,80004e08 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	cde080e7          	jalr	-802(ra) # 80003aa4 <iunlockput>
    end_op();
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	4c6080e7          	jalr	1222(ra) # 80004294 <end_op>
  }
  return -1;
    80004dd6:	557d                	li	a0,-1
}
    80004dd8:	20813083          	ld	ra,520(sp)
    80004ddc:	20013403          	ld	s0,512(sp)
    80004de0:	74fe                	ld	s1,504(sp)
    80004de2:	795e                	ld	s2,496(sp)
    80004de4:	79be                	ld	s3,488(sp)
    80004de6:	7a1e                	ld	s4,480(sp)
    80004de8:	6afe                	ld	s5,472(sp)
    80004dea:	6b5e                	ld	s6,464(sp)
    80004dec:	6bbe                	ld	s7,456(sp)
    80004dee:	6c1e                	ld	s8,448(sp)
    80004df0:	7cfa                	ld	s9,440(sp)
    80004df2:	7d5a                	ld	s10,432(sp)
    80004df4:	7dba                	ld	s11,424(sp)
    80004df6:	21010113          	addi	sp,sp,528
    80004dfa:	8082                	ret
    end_op();
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	498080e7          	jalr	1176(ra) # 80004294 <end_op>
    return -1;
    80004e04:	557d                	li	a0,-1
    80004e06:	bfc9                	j	80004dd8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e08:	854a                	mv	a0,s2
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	c6a080e7          	jalr	-918(ra) # 80001a74 <proc_pagetable>
    80004e12:	8baa                	mv	s7,a0
    80004e14:	d945                	beqz	a0,80004dc4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e16:	e7042983          	lw	s3,-400(s0)
    80004e1a:	e8845783          	lhu	a5,-376(s0)
    80004e1e:	c7ad                	beqz	a5,80004e88 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e20:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e22:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e24:	6c85                	lui	s9,0x1
    80004e26:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e2a:	def43823          	sd	a5,-528(s0)
    80004e2e:	a42d                	j	80005058 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e30:	00004517          	auipc	a0,0x4
    80004e34:	99050513          	addi	a0,a0,-1648 # 800087c0 <syscalls+0x280>
    80004e38:	ffffb097          	auipc	ra,0xffffb
    80004e3c:	706080e7          	jalr	1798(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e40:	8756                	mv	a4,s5
    80004e42:	012d86bb          	addw	a3,s11,s2
    80004e46:	4581                	li	a1,0
    80004e48:	8526                	mv	a0,s1
    80004e4a:	fffff097          	auipc	ra,0xfffff
    80004e4e:	cac080e7          	jalr	-852(ra) # 80003af6 <readi>
    80004e52:	2501                	sext.w	a0,a0
    80004e54:	1aaa9963          	bne	s5,a0,80005006 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e58:	6785                	lui	a5,0x1
    80004e5a:	0127893b          	addw	s2,a5,s2
    80004e5e:	77fd                	lui	a5,0xfffff
    80004e60:	01478a3b          	addw	s4,a5,s4
    80004e64:	1f897163          	bgeu	s2,s8,80005046 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e68:	02091593          	slli	a1,s2,0x20
    80004e6c:	9181                	srli	a1,a1,0x20
    80004e6e:	95ea                	add	a1,a1,s10
    80004e70:	855e                	mv	a0,s7
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	1fc080e7          	jalr	508(ra) # 8000106e <walkaddr>
    80004e7a:	862a                	mv	a2,a0
    if(pa == 0)
    80004e7c:	d955                	beqz	a0,80004e30 <exec+0xf0>
      n = PGSIZE;
    80004e7e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e80:	fd9a70e3          	bgeu	s4,s9,80004e40 <exec+0x100>
      n = sz - i;
    80004e84:	8ad2                	mv	s5,s4
    80004e86:	bf6d                	j	80004e40 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e88:	4901                	li	s2,0
  iunlockput(ip);
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	c18080e7          	jalr	-1000(ra) # 80003aa4 <iunlockput>
  end_op();
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	400080e7          	jalr	1024(ra) # 80004294 <end_op>
  p = myproc();
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	b14080e7          	jalr	-1260(ra) # 800019b0 <myproc>
    80004ea4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ea6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eaa:	6785                	lui	a5,0x1
    80004eac:	17fd                	addi	a5,a5,-1
    80004eae:	993e                	add	s2,s2,a5
    80004eb0:	757d                	lui	a0,0xfffff
    80004eb2:	00a977b3          	and	a5,s2,a0
    80004eb6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eba:	6609                	lui	a2,0x2
    80004ebc:	963e                	add	a2,a2,a5
    80004ebe:	85be                	mv	a1,a5
    80004ec0:	855e                	mv	a0,s7
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	560080e7          	jalr	1376(ra) # 80001422 <uvmalloc>
    80004eca:	8b2a                	mv	s6,a0
  ip = 0;
    80004ecc:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ece:	12050c63          	beqz	a0,80005006 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ed2:	75f9                	lui	a1,0xffffe
    80004ed4:	95aa                	add	a1,a1,a0
    80004ed6:	855e                	mv	a0,s7
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	768080e7          	jalr	1896(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ee0:	7c7d                	lui	s8,0xfffff
    80004ee2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee4:	e0043783          	ld	a5,-512(s0)
    80004ee8:	6388                	ld	a0,0(a5)
    80004eea:	c535                	beqz	a0,80004f56 <exec+0x216>
    80004eec:	e9040993          	addi	s3,s0,-368
    80004ef0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ef4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	f6e080e7          	jalr	-146(ra) # 80000e64 <strlen>
    80004efe:	2505                	addiw	a0,a0,1
    80004f00:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f04:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f08:	13896363          	bltu	s2,s8,8000502e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f0c:	e0043d83          	ld	s11,-512(s0)
    80004f10:	000dba03          	ld	s4,0(s11)
    80004f14:	8552                	mv	a0,s4
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	f4e080e7          	jalr	-178(ra) # 80000e64 <strlen>
    80004f1e:	0015069b          	addiw	a3,a0,1
    80004f22:	8652                	mv	a2,s4
    80004f24:	85ca                	mv	a1,s2
    80004f26:	855e                	mv	a0,s7
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	74a080e7          	jalr	1866(ra) # 80001672 <copyout>
    80004f30:	10054363          	bltz	a0,80005036 <exec+0x2f6>
    ustack[argc] = sp;
    80004f34:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f38:	0485                	addi	s1,s1,1
    80004f3a:	008d8793          	addi	a5,s11,8
    80004f3e:	e0f43023          	sd	a5,-512(s0)
    80004f42:	008db503          	ld	a0,8(s11)
    80004f46:	c911                	beqz	a0,80004f5a <exec+0x21a>
    if(argc >= MAXARG)
    80004f48:	09a1                	addi	s3,s3,8
    80004f4a:	fb3c96e3          	bne	s9,s3,80004ef6 <exec+0x1b6>
  sz = sz1;
    80004f4e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f52:	4481                	li	s1,0
    80004f54:	a84d                	j	80005006 <exec+0x2c6>
  sp = sz;
    80004f56:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f58:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f5a:	00349793          	slli	a5,s1,0x3
    80004f5e:	f9040713          	addi	a4,s0,-112
    80004f62:	97ba                	add	a5,a5,a4
    80004f64:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f68:	00148693          	addi	a3,s1,1
    80004f6c:	068e                	slli	a3,a3,0x3
    80004f6e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f72:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f76:	01897663          	bgeu	s2,s8,80004f82 <exec+0x242>
  sz = sz1;
    80004f7a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f7e:	4481                	li	s1,0
    80004f80:	a059                	j	80005006 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f82:	e9040613          	addi	a2,s0,-368
    80004f86:	85ca                	mv	a1,s2
    80004f88:	855e                	mv	a0,s7
    80004f8a:	ffffc097          	auipc	ra,0xffffc
    80004f8e:	6e8080e7          	jalr	1768(ra) # 80001672 <copyout>
    80004f92:	0a054663          	bltz	a0,8000503e <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f96:	058ab783          	ld	a5,88(s5)
    80004f9a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f9e:	df843783          	ld	a5,-520(s0)
    80004fa2:	0007c703          	lbu	a4,0(a5)
    80004fa6:	cf11                	beqz	a4,80004fc2 <exec+0x282>
    80004fa8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004faa:	02f00693          	li	a3,47
    80004fae:	a039                	j	80004fbc <exec+0x27c>
      last = s+1;
    80004fb0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fb4:	0785                	addi	a5,a5,1
    80004fb6:	fff7c703          	lbu	a4,-1(a5)
    80004fba:	c701                	beqz	a4,80004fc2 <exec+0x282>
    if(*s == '/')
    80004fbc:	fed71ce3          	bne	a4,a3,80004fb4 <exec+0x274>
    80004fc0:	bfc5                	j	80004fb0 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fc2:	4641                	li	a2,16
    80004fc4:	df843583          	ld	a1,-520(s0)
    80004fc8:	158a8513          	addi	a0,s5,344
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	e66080e7          	jalr	-410(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fd4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fd8:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fdc:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fe0:	058ab783          	ld	a5,88(s5)
    80004fe4:	e6843703          	ld	a4,-408(s0)
    80004fe8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fea:	058ab783          	ld	a5,88(s5)
    80004fee:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ff2:	85ea                	mv	a1,s10
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	b1c080e7          	jalr	-1252(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ffc:	0004851b          	sext.w	a0,s1
    80005000:	bbe1                	j	80004dd8 <exec+0x98>
    80005002:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005006:	e0843583          	ld	a1,-504(s0)
    8000500a:	855e                	mv	a0,s7
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	b04080e7          	jalr	-1276(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005014:	da0498e3          	bnez	s1,80004dc4 <exec+0x84>
  return -1;
    80005018:	557d                	li	a0,-1
    8000501a:	bb7d                	j	80004dd8 <exec+0x98>
    8000501c:	e1243423          	sd	s2,-504(s0)
    80005020:	b7dd                	j	80005006 <exec+0x2c6>
    80005022:	e1243423          	sd	s2,-504(s0)
    80005026:	b7c5                	j	80005006 <exec+0x2c6>
    80005028:	e1243423          	sd	s2,-504(s0)
    8000502c:	bfe9                	j	80005006 <exec+0x2c6>
  sz = sz1;
    8000502e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005032:	4481                	li	s1,0
    80005034:	bfc9                	j	80005006 <exec+0x2c6>
  sz = sz1;
    80005036:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000503a:	4481                	li	s1,0
    8000503c:	b7e9                	j	80005006 <exec+0x2c6>
  sz = sz1;
    8000503e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005042:	4481                	li	s1,0
    80005044:	b7c9                	j	80005006 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005046:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000504a:	2b05                	addiw	s6,s6,1
    8000504c:	0389899b          	addiw	s3,s3,56
    80005050:	e8845783          	lhu	a5,-376(s0)
    80005054:	e2fb5be3          	bge	s6,a5,80004e8a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005058:	2981                	sext.w	s3,s3
    8000505a:	03800713          	li	a4,56
    8000505e:	86ce                	mv	a3,s3
    80005060:	e1840613          	addi	a2,s0,-488
    80005064:	4581                	li	a1,0
    80005066:	8526                	mv	a0,s1
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	a8e080e7          	jalr	-1394(ra) # 80003af6 <readi>
    80005070:	03800793          	li	a5,56
    80005074:	f8f517e3          	bne	a0,a5,80005002 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005078:	e1842783          	lw	a5,-488(s0)
    8000507c:	4705                	li	a4,1
    8000507e:	fce796e3          	bne	a5,a4,8000504a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005082:	e4043603          	ld	a2,-448(s0)
    80005086:	e3843783          	ld	a5,-456(s0)
    8000508a:	f8f669e3          	bltu	a2,a5,8000501c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000508e:	e2843783          	ld	a5,-472(s0)
    80005092:	963e                	add	a2,a2,a5
    80005094:	f8f667e3          	bltu	a2,a5,80005022 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005098:	85ca                	mv	a1,s2
    8000509a:	855e                	mv	a0,s7
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	386080e7          	jalr	902(ra) # 80001422 <uvmalloc>
    800050a4:	e0a43423          	sd	a0,-504(s0)
    800050a8:	d141                	beqz	a0,80005028 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050aa:	e2843d03          	ld	s10,-472(s0)
    800050ae:	df043783          	ld	a5,-528(s0)
    800050b2:	00fd77b3          	and	a5,s10,a5
    800050b6:	fba1                	bnez	a5,80005006 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050b8:	e2042d83          	lw	s11,-480(s0)
    800050bc:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050c0:	f80c03e3          	beqz	s8,80005046 <exec+0x306>
    800050c4:	8a62                	mv	s4,s8
    800050c6:	4901                	li	s2,0
    800050c8:	b345                	j	80004e68 <exec+0x128>

00000000800050ca <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050ca:	7179                	addi	sp,sp,-48
    800050cc:	f406                	sd	ra,40(sp)
    800050ce:	f022                	sd	s0,32(sp)
    800050d0:	ec26                	sd	s1,24(sp)
    800050d2:	e84a                	sd	s2,16(sp)
    800050d4:	1800                	addi	s0,sp,48
    800050d6:	892e                	mv	s2,a1
    800050d8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050da:	fdc40593          	addi	a1,s0,-36
    800050de:	ffffe097          	auipc	ra,0xffffe
    800050e2:	992080e7          	jalr	-1646(ra) # 80002a70 <argint>
    800050e6:	04054063          	bltz	a0,80005126 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050ea:	fdc42703          	lw	a4,-36(s0)
    800050ee:	47bd                	li	a5,15
    800050f0:	02e7ed63          	bltu	a5,a4,8000512a <argfd+0x60>
    800050f4:	ffffd097          	auipc	ra,0xffffd
    800050f8:	8bc080e7          	jalr	-1860(ra) # 800019b0 <myproc>
    800050fc:	fdc42703          	lw	a4,-36(s0)
    80005100:	01a70793          	addi	a5,a4,26
    80005104:	078e                	slli	a5,a5,0x3
    80005106:	953e                	add	a0,a0,a5
    80005108:	611c                	ld	a5,0(a0)
    8000510a:	c395                	beqz	a5,8000512e <argfd+0x64>
    return -1;
  if(pfd)
    8000510c:	00090463          	beqz	s2,80005114 <argfd+0x4a>
    *pfd = fd;
    80005110:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005114:	4501                	li	a0,0
  if(pf)
    80005116:	c091                	beqz	s1,8000511a <argfd+0x50>
    *pf = f;
    80005118:	e09c                	sd	a5,0(s1)
}
    8000511a:	70a2                	ld	ra,40(sp)
    8000511c:	7402                	ld	s0,32(sp)
    8000511e:	64e2                	ld	s1,24(sp)
    80005120:	6942                	ld	s2,16(sp)
    80005122:	6145                	addi	sp,sp,48
    80005124:	8082                	ret
    return -1;
    80005126:	557d                	li	a0,-1
    80005128:	bfcd                	j	8000511a <argfd+0x50>
    return -1;
    8000512a:	557d                	li	a0,-1
    8000512c:	b7fd                	j	8000511a <argfd+0x50>
    8000512e:	557d                	li	a0,-1
    80005130:	b7ed                	j	8000511a <argfd+0x50>

0000000080005132 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005132:	1101                	addi	sp,sp,-32
    80005134:	ec06                	sd	ra,24(sp)
    80005136:	e822                	sd	s0,16(sp)
    80005138:	e426                	sd	s1,8(sp)
    8000513a:	1000                	addi	s0,sp,32
    8000513c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	872080e7          	jalr	-1934(ra) # 800019b0 <myproc>
    80005146:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005148:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    8000514c:	4501                	li	a0,0
    8000514e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005150:	6398                	ld	a4,0(a5)
    80005152:	cb19                	beqz	a4,80005168 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005154:	2505                	addiw	a0,a0,1
    80005156:	07a1                	addi	a5,a5,8
    80005158:	fed51ce3          	bne	a0,a3,80005150 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000515c:	557d                	li	a0,-1
}
    8000515e:	60e2                	ld	ra,24(sp)
    80005160:	6442                	ld	s0,16(sp)
    80005162:	64a2                	ld	s1,8(sp)
    80005164:	6105                	addi	sp,sp,32
    80005166:	8082                	ret
      p->ofile[fd] = f;
    80005168:	01a50793          	addi	a5,a0,26
    8000516c:	078e                	slli	a5,a5,0x3
    8000516e:	963e                	add	a2,a2,a5
    80005170:	e204                	sd	s1,0(a2)
      return fd;
    80005172:	b7f5                	j	8000515e <fdalloc+0x2c>

0000000080005174 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005174:	715d                	addi	sp,sp,-80
    80005176:	e486                	sd	ra,72(sp)
    80005178:	e0a2                	sd	s0,64(sp)
    8000517a:	fc26                	sd	s1,56(sp)
    8000517c:	f84a                	sd	s2,48(sp)
    8000517e:	f44e                	sd	s3,40(sp)
    80005180:	f052                	sd	s4,32(sp)
    80005182:	ec56                	sd	s5,24(sp)
    80005184:	0880                	addi	s0,sp,80
    80005186:	89ae                	mv	s3,a1
    80005188:	8ab2                	mv	s5,a2
    8000518a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000518c:	fb040593          	addi	a1,s0,-80
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	e86080e7          	jalr	-378(ra) # 80004016 <nameiparent>
    80005198:	892a                	mv	s2,a0
    8000519a:	12050f63          	beqz	a0,800052d8 <create+0x164>
    return 0;

  ilock(dp);
    8000519e:	ffffe097          	auipc	ra,0xffffe
    800051a2:	6a4080e7          	jalr	1700(ra) # 80003842 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051a6:	4601                	li	a2,0
    800051a8:	fb040593          	addi	a1,s0,-80
    800051ac:	854a                	mv	a0,s2
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	b78080e7          	jalr	-1160(ra) # 80003d26 <dirlookup>
    800051b6:	84aa                	mv	s1,a0
    800051b8:	c921                	beqz	a0,80005208 <create+0x94>
    iunlockput(dp);
    800051ba:	854a                	mv	a0,s2
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	8e8080e7          	jalr	-1816(ra) # 80003aa4 <iunlockput>
    ilock(ip);
    800051c4:	8526                	mv	a0,s1
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	67c080e7          	jalr	1660(ra) # 80003842 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051ce:	2981                	sext.w	s3,s3
    800051d0:	4789                	li	a5,2
    800051d2:	02f99463          	bne	s3,a5,800051fa <create+0x86>
    800051d6:	0444d783          	lhu	a5,68(s1)
    800051da:	37f9                	addiw	a5,a5,-2
    800051dc:	17c2                	slli	a5,a5,0x30
    800051de:	93c1                	srli	a5,a5,0x30
    800051e0:	4705                	li	a4,1
    800051e2:	00f76c63          	bltu	a4,a5,800051fa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051e6:	8526                	mv	a0,s1
    800051e8:	60a6                	ld	ra,72(sp)
    800051ea:	6406                	ld	s0,64(sp)
    800051ec:	74e2                	ld	s1,56(sp)
    800051ee:	7942                	ld	s2,48(sp)
    800051f0:	79a2                	ld	s3,40(sp)
    800051f2:	7a02                	ld	s4,32(sp)
    800051f4:	6ae2                	ld	s5,24(sp)
    800051f6:	6161                	addi	sp,sp,80
    800051f8:	8082                	ret
    iunlockput(ip);
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	8a8080e7          	jalr	-1880(ra) # 80003aa4 <iunlockput>
    return 0;
    80005204:	4481                	li	s1,0
    80005206:	b7c5                	j	800051e6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005208:	85ce                	mv	a1,s3
    8000520a:	00092503          	lw	a0,0(s2)
    8000520e:	ffffe097          	auipc	ra,0xffffe
    80005212:	49c080e7          	jalr	1180(ra) # 800036aa <ialloc>
    80005216:	84aa                	mv	s1,a0
    80005218:	c529                	beqz	a0,80005262 <create+0xee>
  ilock(ip);
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	628080e7          	jalr	1576(ra) # 80003842 <ilock>
  ip->major = major;
    80005222:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005226:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000522a:	4785                	li	a5,1
    8000522c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005230:	8526                	mv	a0,s1
    80005232:	ffffe097          	auipc	ra,0xffffe
    80005236:	546080e7          	jalr	1350(ra) # 80003778 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000523a:	2981                	sext.w	s3,s3
    8000523c:	4785                	li	a5,1
    8000523e:	02f98a63          	beq	s3,a5,80005272 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005242:	40d0                	lw	a2,4(s1)
    80005244:	fb040593          	addi	a1,s0,-80
    80005248:	854a                	mv	a0,s2
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	cec080e7          	jalr	-788(ra) # 80003f36 <dirlink>
    80005252:	06054b63          	bltz	a0,800052c8 <create+0x154>
  iunlockput(dp);
    80005256:	854a                	mv	a0,s2
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	84c080e7          	jalr	-1972(ra) # 80003aa4 <iunlockput>
  return ip;
    80005260:	b759                	j	800051e6 <create+0x72>
    panic("create: ialloc");
    80005262:	00003517          	auipc	a0,0x3
    80005266:	57e50513          	addi	a0,a0,1406 # 800087e0 <syscalls+0x2a0>
    8000526a:	ffffb097          	auipc	ra,0xffffb
    8000526e:	2d4080e7          	jalr	724(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005272:	04a95783          	lhu	a5,74(s2)
    80005276:	2785                	addiw	a5,a5,1
    80005278:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000527c:	854a                	mv	a0,s2
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	4fa080e7          	jalr	1274(ra) # 80003778 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005286:	40d0                	lw	a2,4(s1)
    80005288:	00003597          	auipc	a1,0x3
    8000528c:	56858593          	addi	a1,a1,1384 # 800087f0 <syscalls+0x2b0>
    80005290:	8526                	mv	a0,s1
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	ca4080e7          	jalr	-860(ra) # 80003f36 <dirlink>
    8000529a:	00054f63          	bltz	a0,800052b8 <create+0x144>
    8000529e:	00492603          	lw	a2,4(s2)
    800052a2:	00003597          	auipc	a1,0x3
    800052a6:	55658593          	addi	a1,a1,1366 # 800087f8 <syscalls+0x2b8>
    800052aa:	8526                	mv	a0,s1
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	c8a080e7          	jalr	-886(ra) # 80003f36 <dirlink>
    800052b4:	f80557e3          	bgez	a0,80005242 <create+0xce>
      panic("create dots");
    800052b8:	00003517          	auipc	a0,0x3
    800052bc:	54850513          	addi	a0,a0,1352 # 80008800 <syscalls+0x2c0>
    800052c0:	ffffb097          	auipc	ra,0xffffb
    800052c4:	27e080e7          	jalr	638(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052c8:	00003517          	auipc	a0,0x3
    800052cc:	54850513          	addi	a0,a0,1352 # 80008810 <syscalls+0x2d0>
    800052d0:	ffffb097          	auipc	ra,0xffffb
    800052d4:	26e080e7          	jalr	622(ra) # 8000053e <panic>
    return 0;
    800052d8:	84aa                	mv	s1,a0
    800052da:	b731                	j	800051e6 <create+0x72>

00000000800052dc <sys_dup>:
{
    800052dc:	7179                	addi	sp,sp,-48
    800052de:	f406                	sd	ra,40(sp)
    800052e0:	f022                	sd	s0,32(sp)
    800052e2:	ec26                	sd	s1,24(sp)
    800052e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052e6:	fd840613          	addi	a2,s0,-40
    800052ea:	4581                	li	a1,0
    800052ec:	4501                	li	a0,0
    800052ee:	00000097          	auipc	ra,0x0
    800052f2:	ddc080e7          	jalr	-548(ra) # 800050ca <argfd>
    return -1;
    800052f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052f8:	02054363          	bltz	a0,8000531e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052fc:	fd843503          	ld	a0,-40(s0)
    80005300:	00000097          	auipc	ra,0x0
    80005304:	e32080e7          	jalr	-462(ra) # 80005132 <fdalloc>
    80005308:	84aa                	mv	s1,a0
    return -1;
    8000530a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000530c:	00054963          	bltz	a0,8000531e <sys_dup+0x42>
  filedup(f);
    80005310:	fd843503          	ld	a0,-40(s0)
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	37a080e7          	jalr	890(ra) # 8000468e <filedup>
  return fd;
    8000531c:	87a6                	mv	a5,s1
}
    8000531e:	853e                	mv	a0,a5
    80005320:	70a2                	ld	ra,40(sp)
    80005322:	7402                	ld	s0,32(sp)
    80005324:	64e2                	ld	s1,24(sp)
    80005326:	6145                	addi	sp,sp,48
    80005328:	8082                	ret

000000008000532a <sys_read>:
{
    8000532a:	7179                	addi	sp,sp,-48
    8000532c:	f406                	sd	ra,40(sp)
    8000532e:	f022                	sd	s0,32(sp)
    80005330:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005332:	fe840613          	addi	a2,s0,-24
    80005336:	4581                	li	a1,0
    80005338:	4501                	li	a0,0
    8000533a:	00000097          	auipc	ra,0x0
    8000533e:	d90080e7          	jalr	-624(ra) # 800050ca <argfd>
    return -1;
    80005342:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005344:	04054163          	bltz	a0,80005386 <sys_read+0x5c>
    80005348:	fe440593          	addi	a1,s0,-28
    8000534c:	4509                	li	a0,2
    8000534e:	ffffd097          	auipc	ra,0xffffd
    80005352:	722080e7          	jalr	1826(ra) # 80002a70 <argint>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005358:	02054763          	bltz	a0,80005386 <sys_read+0x5c>
    8000535c:	fd840593          	addi	a1,s0,-40
    80005360:	4505                	li	a0,1
    80005362:	ffffd097          	auipc	ra,0xffffd
    80005366:	730080e7          	jalr	1840(ra) # 80002a92 <argaddr>
    return -1;
    8000536a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536c:	00054d63          	bltz	a0,80005386 <sys_read+0x5c>
  return fileread(f, p, n);
    80005370:	fe442603          	lw	a2,-28(s0)
    80005374:	fd843583          	ld	a1,-40(s0)
    80005378:	fe843503          	ld	a0,-24(s0)
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	49e080e7          	jalr	1182(ra) # 8000481a <fileread>
    80005384:	87aa                	mv	a5,a0
}
    80005386:	853e                	mv	a0,a5
    80005388:	70a2                	ld	ra,40(sp)
    8000538a:	7402                	ld	s0,32(sp)
    8000538c:	6145                	addi	sp,sp,48
    8000538e:	8082                	ret

0000000080005390 <sys_write>:
{
    80005390:	7179                	addi	sp,sp,-48
    80005392:	f406                	sd	ra,40(sp)
    80005394:	f022                	sd	s0,32(sp)
    80005396:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005398:	fe840613          	addi	a2,s0,-24
    8000539c:	4581                	li	a1,0
    8000539e:	4501                	li	a0,0
    800053a0:	00000097          	auipc	ra,0x0
    800053a4:	d2a080e7          	jalr	-726(ra) # 800050ca <argfd>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053aa:	04054163          	bltz	a0,800053ec <sys_write+0x5c>
    800053ae:	fe440593          	addi	a1,s0,-28
    800053b2:	4509                	li	a0,2
    800053b4:	ffffd097          	auipc	ra,0xffffd
    800053b8:	6bc080e7          	jalr	1724(ra) # 80002a70 <argint>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053be:	02054763          	bltz	a0,800053ec <sys_write+0x5c>
    800053c2:	fd840593          	addi	a1,s0,-40
    800053c6:	4505                	li	a0,1
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	6ca080e7          	jalr	1738(ra) # 80002a92 <argaddr>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	00054d63          	bltz	a0,800053ec <sys_write+0x5c>
  return filewrite(f, p, n);
    800053d6:	fe442603          	lw	a2,-28(s0)
    800053da:	fd843583          	ld	a1,-40(s0)
    800053de:	fe843503          	ld	a0,-24(s0)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	4fa080e7          	jalr	1274(ra) # 800048dc <filewrite>
    800053ea:	87aa                	mv	a5,a0
}
    800053ec:	853e                	mv	a0,a5
    800053ee:	70a2                	ld	ra,40(sp)
    800053f0:	7402                	ld	s0,32(sp)
    800053f2:	6145                	addi	sp,sp,48
    800053f4:	8082                	ret

00000000800053f6 <sys_close>:
{
    800053f6:	1101                	addi	sp,sp,-32
    800053f8:	ec06                	sd	ra,24(sp)
    800053fa:	e822                	sd	s0,16(sp)
    800053fc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053fe:	fe040613          	addi	a2,s0,-32
    80005402:	fec40593          	addi	a1,s0,-20
    80005406:	4501                	li	a0,0
    80005408:	00000097          	auipc	ra,0x0
    8000540c:	cc2080e7          	jalr	-830(ra) # 800050ca <argfd>
    return -1;
    80005410:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005412:	02054463          	bltz	a0,8000543a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	59a080e7          	jalr	1434(ra) # 800019b0 <myproc>
    8000541e:	fec42783          	lw	a5,-20(s0)
    80005422:	07e9                	addi	a5,a5,26
    80005424:	078e                	slli	a5,a5,0x3
    80005426:	97aa                	add	a5,a5,a0
    80005428:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000542c:	fe043503          	ld	a0,-32(s0)
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	2b0080e7          	jalr	688(ra) # 800046e0 <fileclose>
  return 0;
    80005438:	4781                	li	a5,0
}
    8000543a:	853e                	mv	a0,a5
    8000543c:	60e2                	ld	ra,24(sp)
    8000543e:	6442                	ld	s0,16(sp)
    80005440:	6105                	addi	sp,sp,32
    80005442:	8082                	ret

0000000080005444 <sys_fstat>:
{
    80005444:	1101                	addi	sp,sp,-32
    80005446:	ec06                	sd	ra,24(sp)
    80005448:	e822                	sd	s0,16(sp)
    8000544a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000544c:	fe840613          	addi	a2,s0,-24
    80005450:	4581                	li	a1,0
    80005452:	4501                	li	a0,0
    80005454:	00000097          	auipc	ra,0x0
    80005458:	c76080e7          	jalr	-906(ra) # 800050ca <argfd>
    return -1;
    8000545c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545e:	02054563          	bltz	a0,80005488 <sys_fstat+0x44>
    80005462:	fe040593          	addi	a1,s0,-32
    80005466:	4505                	li	a0,1
    80005468:	ffffd097          	auipc	ra,0xffffd
    8000546c:	62a080e7          	jalr	1578(ra) # 80002a92 <argaddr>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005472:	00054b63          	bltz	a0,80005488 <sys_fstat+0x44>
  return filestat(f, st);
    80005476:	fe043583          	ld	a1,-32(s0)
    8000547a:	fe843503          	ld	a0,-24(s0)
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	32a080e7          	jalr	810(ra) # 800047a8 <filestat>
    80005486:	87aa                	mv	a5,a0
}
    80005488:	853e                	mv	a0,a5
    8000548a:	60e2                	ld	ra,24(sp)
    8000548c:	6442                	ld	s0,16(sp)
    8000548e:	6105                	addi	sp,sp,32
    80005490:	8082                	ret

0000000080005492 <sys_link>:
{
    80005492:	7169                	addi	sp,sp,-304
    80005494:	f606                	sd	ra,296(sp)
    80005496:	f222                	sd	s0,288(sp)
    80005498:	ee26                	sd	s1,280(sp)
    8000549a:	ea4a                	sd	s2,272(sp)
    8000549c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549e:	08000613          	li	a2,128
    800054a2:	ed040593          	addi	a1,s0,-304
    800054a6:	4501                	li	a0,0
    800054a8:	ffffd097          	auipc	ra,0xffffd
    800054ac:	60c080e7          	jalr	1548(ra) # 80002ab4 <argstr>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b2:	10054e63          	bltz	a0,800055ce <sys_link+0x13c>
    800054b6:	08000613          	li	a2,128
    800054ba:	f5040593          	addi	a1,s0,-176
    800054be:	4505                	li	a0,1
    800054c0:	ffffd097          	auipc	ra,0xffffd
    800054c4:	5f4080e7          	jalr	1524(ra) # 80002ab4 <argstr>
    return -1;
    800054c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ca:	10054263          	bltz	a0,800055ce <sys_link+0x13c>
  begin_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	d46080e7          	jalr	-698(ra) # 80004214 <begin_op>
  if((ip = namei(old)) == 0){
    800054d6:	ed040513          	addi	a0,s0,-304
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	b1e080e7          	jalr	-1250(ra) # 80003ff8 <namei>
    800054e2:	84aa                	mv	s1,a0
    800054e4:	c551                	beqz	a0,80005570 <sys_link+0xde>
  ilock(ip);
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	35c080e7          	jalr	860(ra) # 80003842 <ilock>
  if(ip->type == T_DIR){
    800054ee:	04449703          	lh	a4,68(s1)
    800054f2:	4785                	li	a5,1
    800054f4:	08f70463          	beq	a4,a5,8000557c <sys_link+0xea>
  ip->nlink++;
    800054f8:	04a4d783          	lhu	a5,74(s1)
    800054fc:	2785                	addiw	a5,a5,1
    800054fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	274080e7          	jalr	628(ra) # 80003778 <iupdate>
  iunlock(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	3f6080e7          	jalr	1014(ra) # 80003904 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005516:	fd040593          	addi	a1,s0,-48
    8000551a:	f5040513          	addi	a0,s0,-176
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	af8080e7          	jalr	-1288(ra) # 80004016 <nameiparent>
    80005526:	892a                	mv	s2,a0
    80005528:	c935                	beqz	a0,8000559c <sys_link+0x10a>
  ilock(dp);
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	318080e7          	jalr	792(ra) # 80003842 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005532:	00092703          	lw	a4,0(s2)
    80005536:	409c                	lw	a5,0(s1)
    80005538:	04f71d63          	bne	a4,a5,80005592 <sys_link+0x100>
    8000553c:	40d0                	lw	a2,4(s1)
    8000553e:	fd040593          	addi	a1,s0,-48
    80005542:	854a                	mv	a0,s2
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	9f2080e7          	jalr	-1550(ra) # 80003f36 <dirlink>
    8000554c:	04054363          	bltz	a0,80005592 <sys_link+0x100>
  iunlockput(dp);
    80005550:	854a                	mv	a0,s2
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	552080e7          	jalr	1362(ra) # 80003aa4 <iunlockput>
  iput(ip);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	4a0080e7          	jalr	1184(ra) # 800039fc <iput>
  end_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	d30080e7          	jalr	-720(ra) # 80004294 <end_op>
  return 0;
    8000556c:	4781                	li	a5,0
    8000556e:	a085                	j	800055ce <sys_link+0x13c>
    end_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	d24080e7          	jalr	-732(ra) # 80004294 <end_op>
    return -1;
    80005578:	57fd                	li	a5,-1
    8000557a:	a891                	j	800055ce <sys_link+0x13c>
    iunlockput(ip);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	526080e7          	jalr	1318(ra) # 80003aa4 <iunlockput>
    end_op();
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	d0e080e7          	jalr	-754(ra) # 80004294 <end_op>
    return -1;
    8000558e:	57fd                	li	a5,-1
    80005590:	a83d                	j	800055ce <sys_link+0x13c>
    iunlockput(dp);
    80005592:	854a                	mv	a0,s2
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	510080e7          	jalr	1296(ra) # 80003aa4 <iunlockput>
  ilock(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	2a4080e7          	jalr	676(ra) # 80003842 <ilock>
  ip->nlink--;
    800055a6:	04a4d783          	lhu	a5,74(s1)
    800055aa:	37fd                	addiw	a5,a5,-1
    800055ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	1c6080e7          	jalr	454(ra) # 80003778 <iupdate>
  iunlockput(ip);
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	4e8080e7          	jalr	1256(ra) # 80003aa4 <iunlockput>
  end_op();
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	cd0080e7          	jalr	-816(ra) # 80004294 <end_op>
  return -1;
    800055cc:	57fd                	li	a5,-1
}
    800055ce:	853e                	mv	a0,a5
    800055d0:	70b2                	ld	ra,296(sp)
    800055d2:	7412                	ld	s0,288(sp)
    800055d4:	64f2                	ld	s1,280(sp)
    800055d6:	6952                	ld	s2,272(sp)
    800055d8:	6155                	addi	sp,sp,304
    800055da:	8082                	ret

00000000800055dc <sys_unlink>:
{
    800055dc:	7151                	addi	sp,sp,-240
    800055de:	f586                	sd	ra,232(sp)
    800055e0:	f1a2                	sd	s0,224(sp)
    800055e2:	eda6                	sd	s1,216(sp)
    800055e4:	e9ca                	sd	s2,208(sp)
    800055e6:	e5ce                	sd	s3,200(sp)
    800055e8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055ea:	08000613          	li	a2,128
    800055ee:	f3040593          	addi	a1,s0,-208
    800055f2:	4501                	li	a0,0
    800055f4:	ffffd097          	auipc	ra,0xffffd
    800055f8:	4c0080e7          	jalr	1216(ra) # 80002ab4 <argstr>
    800055fc:	18054163          	bltz	a0,8000577e <sys_unlink+0x1a2>
  begin_op();
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	c14080e7          	jalr	-1004(ra) # 80004214 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005608:	fb040593          	addi	a1,s0,-80
    8000560c:	f3040513          	addi	a0,s0,-208
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	a06080e7          	jalr	-1530(ra) # 80004016 <nameiparent>
    80005618:	84aa                	mv	s1,a0
    8000561a:	c979                	beqz	a0,800056f0 <sys_unlink+0x114>
  ilock(dp);
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	226080e7          	jalr	550(ra) # 80003842 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005624:	00003597          	auipc	a1,0x3
    80005628:	1cc58593          	addi	a1,a1,460 # 800087f0 <syscalls+0x2b0>
    8000562c:	fb040513          	addi	a0,s0,-80
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	6dc080e7          	jalr	1756(ra) # 80003d0c <namecmp>
    80005638:	14050a63          	beqz	a0,8000578c <sys_unlink+0x1b0>
    8000563c:	00003597          	auipc	a1,0x3
    80005640:	1bc58593          	addi	a1,a1,444 # 800087f8 <syscalls+0x2b8>
    80005644:	fb040513          	addi	a0,s0,-80
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	6c4080e7          	jalr	1732(ra) # 80003d0c <namecmp>
    80005650:	12050e63          	beqz	a0,8000578c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005654:	f2c40613          	addi	a2,s0,-212
    80005658:	fb040593          	addi	a1,s0,-80
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	6c8080e7          	jalr	1736(ra) # 80003d26 <dirlookup>
    80005666:	892a                	mv	s2,a0
    80005668:	12050263          	beqz	a0,8000578c <sys_unlink+0x1b0>
  ilock(ip);
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	1d6080e7          	jalr	470(ra) # 80003842 <ilock>
  if(ip->nlink < 1)
    80005674:	04a91783          	lh	a5,74(s2)
    80005678:	08f05263          	blez	a5,800056fc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000567c:	04491703          	lh	a4,68(s2)
    80005680:	4785                	li	a5,1
    80005682:	08f70563          	beq	a4,a5,8000570c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005686:	4641                	li	a2,16
    80005688:	4581                	li	a1,0
    8000568a:	fc040513          	addi	a0,s0,-64
    8000568e:	ffffb097          	auipc	ra,0xffffb
    80005692:	652080e7          	jalr	1618(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005696:	4741                	li	a4,16
    80005698:	f2c42683          	lw	a3,-212(s0)
    8000569c:	fc040613          	addi	a2,s0,-64
    800056a0:	4581                	li	a1,0
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	54a080e7          	jalr	1354(ra) # 80003bee <writei>
    800056ac:	47c1                	li	a5,16
    800056ae:	0af51563          	bne	a0,a5,80005758 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056b2:	04491703          	lh	a4,68(s2)
    800056b6:	4785                	li	a5,1
    800056b8:	0af70863          	beq	a4,a5,80005768 <sys_unlink+0x18c>
  iunlockput(dp);
    800056bc:	8526                	mv	a0,s1
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	3e6080e7          	jalr	998(ra) # 80003aa4 <iunlockput>
  ip->nlink--;
    800056c6:	04a95783          	lhu	a5,74(s2)
    800056ca:	37fd                	addiw	a5,a5,-1
    800056cc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056d0:	854a                	mv	a0,s2
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	0a6080e7          	jalr	166(ra) # 80003778 <iupdate>
  iunlockput(ip);
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	3c8080e7          	jalr	968(ra) # 80003aa4 <iunlockput>
  end_op();
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	bb0080e7          	jalr	-1104(ra) # 80004294 <end_op>
  return 0;
    800056ec:	4501                	li	a0,0
    800056ee:	a84d                	j	800057a0 <sys_unlink+0x1c4>
    end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	ba4080e7          	jalr	-1116(ra) # 80004294 <end_op>
    return -1;
    800056f8:	557d                	li	a0,-1
    800056fa:	a05d                	j	800057a0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056fc:	00003517          	auipc	a0,0x3
    80005700:	12450513          	addi	a0,a0,292 # 80008820 <syscalls+0x2e0>
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	e3a080e7          	jalr	-454(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000570c:	04c92703          	lw	a4,76(s2)
    80005710:	02000793          	li	a5,32
    80005714:	f6e7f9e3          	bgeu	a5,a4,80005686 <sys_unlink+0xaa>
    80005718:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000571c:	4741                	li	a4,16
    8000571e:	86ce                	mv	a3,s3
    80005720:	f1840613          	addi	a2,s0,-232
    80005724:	4581                	li	a1,0
    80005726:	854a                	mv	a0,s2
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	3ce080e7          	jalr	974(ra) # 80003af6 <readi>
    80005730:	47c1                	li	a5,16
    80005732:	00f51b63          	bne	a0,a5,80005748 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005736:	f1845783          	lhu	a5,-232(s0)
    8000573a:	e7a1                	bnez	a5,80005782 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000573c:	29c1                	addiw	s3,s3,16
    8000573e:	04c92783          	lw	a5,76(s2)
    80005742:	fcf9ede3          	bltu	s3,a5,8000571c <sys_unlink+0x140>
    80005746:	b781                	j	80005686 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005748:	00003517          	auipc	a0,0x3
    8000574c:	0f050513          	addi	a0,a0,240 # 80008838 <syscalls+0x2f8>
    80005750:	ffffb097          	auipc	ra,0xffffb
    80005754:	dee080e7          	jalr	-530(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005758:	00003517          	auipc	a0,0x3
    8000575c:	0f850513          	addi	a0,a0,248 # 80008850 <syscalls+0x310>
    80005760:	ffffb097          	auipc	ra,0xffffb
    80005764:	dde080e7          	jalr	-546(ra) # 8000053e <panic>
    dp->nlink--;
    80005768:	04a4d783          	lhu	a5,74(s1)
    8000576c:	37fd                	addiw	a5,a5,-1
    8000576e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	004080e7          	jalr	4(ra) # 80003778 <iupdate>
    8000577c:	b781                	j	800056bc <sys_unlink+0xe0>
    return -1;
    8000577e:	557d                	li	a0,-1
    80005780:	a005                	j	800057a0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005782:	854a                	mv	a0,s2
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	320080e7          	jalr	800(ra) # 80003aa4 <iunlockput>
  iunlockput(dp);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	316080e7          	jalr	790(ra) # 80003aa4 <iunlockput>
  end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	afe080e7          	jalr	-1282(ra) # 80004294 <end_op>
  return -1;
    8000579e:	557d                	li	a0,-1
}
    800057a0:	70ae                	ld	ra,232(sp)
    800057a2:	740e                	ld	s0,224(sp)
    800057a4:	64ee                	ld	s1,216(sp)
    800057a6:	694e                	ld	s2,208(sp)
    800057a8:	69ae                	ld	s3,200(sp)
    800057aa:	616d                	addi	sp,sp,240
    800057ac:	8082                	ret

00000000800057ae <sys_open>:

uint64
sys_open(void)
{
    800057ae:	7131                	addi	sp,sp,-192
    800057b0:	fd06                	sd	ra,184(sp)
    800057b2:	f922                	sd	s0,176(sp)
    800057b4:	f526                	sd	s1,168(sp)
    800057b6:	f14a                	sd	s2,160(sp)
    800057b8:	ed4e                	sd	s3,152(sp)
    800057ba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057bc:	08000613          	li	a2,128
    800057c0:	f5040593          	addi	a1,s0,-176
    800057c4:	4501                	li	a0,0
    800057c6:	ffffd097          	auipc	ra,0xffffd
    800057ca:	2ee080e7          	jalr	750(ra) # 80002ab4 <argstr>
    return -1;
    800057ce:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057d0:	0c054163          	bltz	a0,80005892 <sys_open+0xe4>
    800057d4:	f4c40593          	addi	a1,s0,-180
    800057d8:	4505                	li	a0,1
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	296080e7          	jalr	662(ra) # 80002a70 <argint>
    800057e2:	0a054863          	bltz	a0,80005892 <sys_open+0xe4>

  begin_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	a2e080e7          	jalr	-1490(ra) # 80004214 <begin_op>

  if(omode & O_CREATE){
    800057ee:	f4c42783          	lw	a5,-180(s0)
    800057f2:	2007f793          	andi	a5,a5,512
    800057f6:	cbdd                	beqz	a5,800058ac <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057f8:	4681                	li	a3,0
    800057fa:	4601                	li	a2,0
    800057fc:	4589                	li	a1,2
    800057fe:	f5040513          	addi	a0,s0,-176
    80005802:	00000097          	auipc	ra,0x0
    80005806:	972080e7          	jalr	-1678(ra) # 80005174 <create>
    8000580a:	892a                	mv	s2,a0
    if(ip == 0){
    8000580c:	c959                	beqz	a0,800058a2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000580e:	04491703          	lh	a4,68(s2)
    80005812:	478d                	li	a5,3
    80005814:	00f71763          	bne	a4,a5,80005822 <sys_open+0x74>
    80005818:	04695703          	lhu	a4,70(s2)
    8000581c:	47a5                	li	a5,9
    8000581e:	0ce7ec63          	bltu	a5,a4,800058f6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	e02080e7          	jalr	-510(ra) # 80004624 <filealloc>
    8000582a:	89aa                	mv	s3,a0
    8000582c:	10050263          	beqz	a0,80005930 <sys_open+0x182>
    80005830:	00000097          	auipc	ra,0x0
    80005834:	902080e7          	jalr	-1790(ra) # 80005132 <fdalloc>
    80005838:	84aa                	mv	s1,a0
    8000583a:	0e054663          	bltz	a0,80005926 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000583e:	04491703          	lh	a4,68(s2)
    80005842:	478d                	li	a5,3
    80005844:	0cf70463          	beq	a4,a5,8000590c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005848:	4789                	li	a5,2
    8000584a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000584e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005852:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005856:	f4c42783          	lw	a5,-180(s0)
    8000585a:	0017c713          	xori	a4,a5,1
    8000585e:	8b05                	andi	a4,a4,1
    80005860:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005864:	0037f713          	andi	a4,a5,3
    80005868:	00e03733          	snez	a4,a4
    8000586c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005870:	4007f793          	andi	a5,a5,1024
    80005874:	c791                	beqz	a5,80005880 <sys_open+0xd2>
    80005876:	04491703          	lh	a4,68(s2)
    8000587a:	4789                	li	a5,2
    8000587c:	08f70f63          	beq	a4,a5,8000591a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	082080e7          	jalr	130(ra) # 80003904 <iunlock>
  end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	a0a080e7          	jalr	-1526(ra) # 80004294 <end_op>

  return fd;
}
    80005892:	8526                	mv	a0,s1
    80005894:	70ea                	ld	ra,184(sp)
    80005896:	744a                	ld	s0,176(sp)
    80005898:	74aa                	ld	s1,168(sp)
    8000589a:	790a                	ld	s2,160(sp)
    8000589c:	69ea                	ld	s3,152(sp)
    8000589e:	6129                	addi	sp,sp,192
    800058a0:	8082                	ret
      end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	9f2080e7          	jalr	-1550(ra) # 80004294 <end_op>
      return -1;
    800058aa:	b7e5                	j	80005892 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058ac:	f5040513          	addi	a0,s0,-176
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	748080e7          	jalr	1864(ra) # 80003ff8 <namei>
    800058b8:	892a                	mv	s2,a0
    800058ba:	c905                	beqz	a0,800058ea <sys_open+0x13c>
    ilock(ip);
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	f86080e7          	jalr	-122(ra) # 80003842 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058c4:	04491703          	lh	a4,68(s2)
    800058c8:	4785                	li	a5,1
    800058ca:	f4f712e3          	bne	a4,a5,8000580e <sys_open+0x60>
    800058ce:	f4c42783          	lw	a5,-180(s0)
    800058d2:	dba1                	beqz	a5,80005822 <sys_open+0x74>
      iunlockput(ip);
    800058d4:	854a                	mv	a0,s2
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	1ce080e7          	jalr	462(ra) # 80003aa4 <iunlockput>
      end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	9b6080e7          	jalr	-1610(ra) # 80004294 <end_op>
      return -1;
    800058e6:	54fd                	li	s1,-1
    800058e8:	b76d                	j	80005892 <sys_open+0xe4>
      end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	9aa080e7          	jalr	-1622(ra) # 80004294 <end_op>
      return -1;
    800058f2:	54fd                	li	s1,-1
    800058f4:	bf79                	j	80005892 <sys_open+0xe4>
    iunlockput(ip);
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	1ac080e7          	jalr	428(ra) # 80003aa4 <iunlockput>
    end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	994080e7          	jalr	-1644(ra) # 80004294 <end_op>
    return -1;
    80005908:	54fd                	li	s1,-1
    8000590a:	b761                	j	80005892 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000590c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005910:	04691783          	lh	a5,70(s2)
    80005914:	02f99223          	sh	a5,36(s3)
    80005918:	bf2d                	j	80005852 <sys_open+0xa4>
    itrunc(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	034080e7          	jalr	52(ra) # 80003950 <itrunc>
    80005924:	bfb1                	j	80005880 <sys_open+0xd2>
      fileclose(f);
    80005926:	854e                	mv	a0,s3
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	db8080e7          	jalr	-584(ra) # 800046e0 <fileclose>
    iunlockput(ip);
    80005930:	854a                	mv	a0,s2
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	172080e7          	jalr	370(ra) # 80003aa4 <iunlockput>
    end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	95a080e7          	jalr	-1702(ra) # 80004294 <end_op>
    return -1;
    80005942:	54fd                	li	s1,-1
    80005944:	b7b9                	j	80005892 <sys_open+0xe4>

0000000080005946 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005946:	7175                	addi	sp,sp,-144
    80005948:	e506                	sd	ra,136(sp)
    8000594a:	e122                	sd	s0,128(sp)
    8000594c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	8c6080e7          	jalr	-1850(ra) # 80004214 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005956:	08000613          	li	a2,128
    8000595a:	f7040593          	addi	a1,s0,-144
    8000595e:	4501                	li	a0,0
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	154080e7          	jalr	340(ra) # 80002ab4 <argstr>
    80005968:	02054963          	bltz	a0,8000599a <sys_mkdir+0x54>
    8000596c:	4681                	li	a3,0
    8000596e:	4601                	li	a2,0
    80005970:	4585                	li	a1,1
    80005972:	f7040513          	addi	a0,s0,-144
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	7fe080e7          	jalr	2046(ra) # 80005174 <create>
    8000597e:	cd11                	beqz	a0,8000599a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	124080e7          	jalr	292(ra) # 80003aa4 <iunlockput>
  end_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	90c080e7          	jalr	-1780(ra) # 80004294 <end_op>
  return 0;
    80005990:	4501                	li	a0,0
}
    80005992:	60aa                	ld	ra,136(sp)
    80005994:	640a                	ld	s0,128(sp)
    80005996:	6149                	addi	sp,sp,144
    80005998:	8082                	ret
    end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	8fa080e7          	jalr	-1798(ra) # 80004294 <end_op>
    return -1;
    800059a2:	557d                	li	a0,-1
    800059a4:	b7fd                	j	80005992 <sys_mkdir+0x4c>

00000000800059a6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059a6:	7135                	addi	sp,sp,-160
    800059a8:	ed06                	sd	ra,152(sp)
    800059aa:	e922                	sd	s0,144(sp)
    800059ac:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	866080e7          	jalr	-1946(ra) # 80004214 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b6:	08000613          	li	a2,128
    800059ba:	f7040593          	addi	a1,s0,-144
    800059be:	4501                	li	a0,0
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	0f4080e7          	jalr	244(ra) # 80002ab4 <argstr>
    800059c8:	04054a63          	bltz	a0,80005a1c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059cc:	f6c40593          	addi	a1,s0,-148
    800059d0:	4505                	li	a0,1
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	09e080e7          	jalr	158(ra) # 80002a70 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059da:	04054163          	bltz	a0,80005a1c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059de:	f6840593          	addi	a1,s0,-152
    800059e2:	4509                	li	a0,2
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	08c080e7          	jalr	140(ra) # 80002a70 <argint>
     argint(1, &major) < 0 ||
    800059ec:	02054863          	bltz	a0,80005a1c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059f0:	f6841683          	lh	a3,-152(s0)
    800059f4:	f6c41603          	lh	a2,-148(s0)
    800059f8:	458d                	li	a1,3
    800059fa:	f7040513          	addi	a0,s0,-144
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	776080e7          	jalr	1910(ra) # 80005174 <create>
     argint(2, &minor) < 0 ||
    80005a06:	c919                	beqz	a0,80005a1c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	09c080e7          	jalr	156(ra) # 80003aa4 <iunlockput>
  end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	884080e7          	jalr	-1916(ra) # 80004294 <end_op>
  return 0;
    80005a18:	4501                	li	a0,0
    80005a1a:	a031                	j	80005a26 <sys_mknod+0x80>
    end_op();
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	878080e7          	jalr	-1928(ra) # 80004294 <end_op>
    return -1;
    80005a24:	557d                	li	a0,-1
}
    80005a26:	60ea                	ld	ra,152(sp)
    80005a28:	644a                	ld	s0,144(sp)
    80005a2a:	610d                	addi	sp,sp,160
    80005a2c:	8082                	ret

0000000080005a2e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a2e:	7135                	addi	sp,sp,-160
    80005a30:	ed06                	sd	ra,152(sp)
    80005a32:	e922                	sd	s0,144(sp)
    80005a34:	e526                	sd	s1,136(sp)
    80005a36:	e14a                	sd	s2,128(sp)
    80005a38:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a3a:	ffffc097          	auipc	ra,0xffffc
    80005a3e:	f76080e7          	jalr	-138(ra) # 800019b0 <myproc>
    80005a42:	892a                	mv	s2,a0
  
  begin_op();
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	7d0080e7          	jalr	2000(ra) # 80004214 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a4c:	08000613          	li	a2,128
    80005a50:	f6040593          	addi	a1,s0,-160
    80005a54:	4501                	li	a0,0
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	05e080e7          	jalr	94(ra) # 80002ab4 <argstr>
    80005a5e:	04054b63          	bltz	a0,80005ab4 <sys_chdir+0x86>
    80005a62:	f6040513          	addi	a0,s0,-160
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	592080e7          	jalr	1426(ra) # 80003ff8 <namei>
    80005a6e:	84aa                	mv	s1,a0
    80005a70:	c131                	beqz	a0,80005ab4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	dd0080e7          	jalr	-560(ra) # 80003842 <ilock>
  if(ip->type != T_DIR){
    80005a7a:	04449703          	lh	a4,68(s1)
    80005a7e:	4785                	li	a5,1
    80005a80:	04f71063          	bne	a4,a5,80005ac0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a84:	8526                	mv	a0,s1
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	e7e080e7          	jalr	-386(ra) # 80003904 <iunlock>
  iput(p->cwd);
    80005a8e:	15093503          	ld	a0,336(s2)
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	f6a080e7          	jalr	-150(ra) # 800039fc <iput>
  end_op();
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	7fa080e7          	jalr	2042(ra) # 80004294 <end_op>
  p->cwd = ip;
    80005aa2:	14993823          	sd	s1,336(s2)
  return 0;
    80005aa6:	4501                	li	a0,0
}
    80005aa8:	60ea                	ld	ra,152(sp)
    80005aaa:	644a                	ld	s0,144(sp)
    80005aac:	64aa                	ld	s1,136(sp)
    80005aae:	690a                	ld	s2,128(sp)
    80005ab0:	610d                	addi	sp,sp,160
    80005ab2:	8082                	ret
    end_op();
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	7e0080e7          	jalr	2016(ra) # 80004294 <end_op>
    return -1;
    80005abc:	557d                	li	a0,-1
    80005abe:	b7ed                	j	80005aa8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ac0:	8526                	mv	a0,s1
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	fe2080e7          	jalr	-30(ra) # 80003aa4 <iunlockput>
    end_op();
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	7ca080e7          	jalr	1994(ra) # 80004294 <end_op>
    return -1;
    80005ad2:	557d                	li	a0,-1
    80005ad4:	bfd1                	j	80005aa8 <sys_chdir+0x7a>

0000000080005ad6 <sys_exec>:

uint64
sys_exec(void)
{
    80005ad6:	7145                	addi	sp,sp,-464
    80005ad8:	e786                	sd	ra,456(sp)
    80005ada:	e3a2                	sd	s0,448(sp)
    80005adc:	ff26                	sd	s1,440(sp)
    80005ade:	fb4a                	sd	s2,432(sp)
    80005ae0:	f74e                	sd	s3,424(sp)
    80005ae2:	f352                	sd	s4,416(sp)
    80005ae4:	ef56                	sd	s5,408(sp)
    80005ae6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ae8:	08000613          	li	a2,128
    80005aec:	f4040593          	addi	a1,s0,-192
    80005af0:	4501                	li	a0,0
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	fc2080e7          	jalr	-62(ra) # 80002ab4 <argstr>
    return -1;
    80005afa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005afc:	0c054a63          	bltz	a0,80005bd0 <sys_exec+0xfa>
    80005b00:	e3840593          	addi	a1,s0,-456
    80005b04:	4505                	li	a0,1
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	f8c080e7          	jalr	-116(ra) # 80002a92 <argaddr>
    80005b0e:	0c054163          	bltz	a0,80005bd0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b12:	10000613          	li	a2,256
    80005b16:	4581                	li	a1,0
    80005b18:	e4040513          	addi	a0,s0,-448
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	1c4080e7          	jalr	452(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b24:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b28:	89a6                	mv	s3,s1
    80005b2a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b2c:	02000a13          	li	s4,32
    80005b30:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b34:	00391513          	slli	a0,s2,0x3
    80005b38:	e3040593          	addi	a1,s0,-464
    80005b3c:	e3843783          	ld	a5,-456(s0)
    80005b40:	953e                	add	a0,a0,a5
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	e94080e7          	jalr	-364(ra) # 800029d6 <fetchaddr>
    80005b4a:	02054a63          	bltz	a0,80005b7e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b4e:	e3043783          	ld	a5,-464(s0)
    80005b52:	c3b9                	beqz	a5,80005b98 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b54:	ffffb097          	auipc	ra,0xffffb
    80005b58:	fa0080e7          	jalr	-96(ra) # 80000af4 <kalloc>
    80005b5c:	85aa                	mv	a1,a0
    80005b5e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b62:	cd11                	beqz	a0,80005b7e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b64:	6605                	lui	a2,0x1
    80005b66:	e3043503          	ld	a0,-464(s0)
    80005b6a:	ffffd097          	auipc	ra,0xffffd
    80005b6e:	ebe080e7          	jalr	-322(ra) # 80002a28 <fetchstr>
    80005b72:	00054663          	bltz	a0,80005b7e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b76:	0905                	addi	s2,s2,1
    80005b78:	09a1                	addi	s3,s3,8
    80005b7a:	fb491be3          	bne	s2,s4,80005b30 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b7e:	10048913          	addi	s2,s1,256
    80005b82:	6088                	ld	a0,0(s1)
    80005b84:	c529                	beqz	a0,80005bce <sys_exec+0xf8>
    kfree(argv[i]);
    80005b86:	ffffb097          	auipc	ra,0xffffb
    80005b8a:	e72080e7          	jalr	-398(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8e:	04a1                	addi	s1,s1,8
    80005b90:	ff2499e3          	bne	s1,s2,80005b82 <sys_exec+0xac>
  return -1;
    80005b94:	597d                	li	s2,-1
    80005b96:	a82d                	j	80005bd0 <sys_exec+0xfa>
      argv[i] = 0;
    80005b98:	0a8e                	slli	s5,s5,0x3
    80005b9a:	fc040793          	addi	a5,s0,-64
    80005b9e:	9abe                	add	s5,s5,a5
    80005ba0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ba4:	e4040593          	addi	a1,s0,-448
    80005ba8:	f4040513          	addi	a0,s0,-192
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	194080e7          	jalr	404(ra) # 80004d40 <exec>
    80005bb4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb6:	10048993          	addi	s3,s1,256
    80005bba:	6088                	ld	a0,0(s1)
    80005bbc:	c911                	beqz	a0,80005bd0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	e3a080e7          	jalr	-454(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc6:	04a1                	addi	s1,s1,8
    80005bc8:	ff3499e3          	bne	s1,s3,80005bba <sys_exec+0xe4>
    80005bcc:	a011                	j	80005bd0 <sys_exec+0xfa>
  return -1;
    80005bce:	597d                	li	s2,-1
}
    80005bd0:	854a                	mv	a0,s2
    80005bd2:	60be                	ld	ra,456(sp)
    80005bd4:	641e                	ld	s0,448(sp)
    80005bd6:	74fa                	ld	s1,440(sp)
    80005bd8:	795a                	ld	s2,432(sp)
    80005bda:	79ba                	ld	s3,424(sp)
    80005bdc:	7a1a                	ld	s4,416(sp)
    80005bde:	6afa                	ld	s5,408(sp)
    80005be0:	6179                	addi	sp,sp,464
    80005be2:	8082                	ret

0000000080005be4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005be4:	7139                	addi	sp,sp,-64
    80005be6:	fc06                	sd	ra,56(sp)
    80005be8:	f822                	sd	s0,48(sp)
    80005bea:	f426                	sd	s1,40(sp)
    80005bec:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bee:	ffffc097          	auipc	ra,0xffffc
    80005bf2:	dc2080e7          	jalr	-574(ra) # 800019b0 <myproc>
    80005bf6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bf8:	fd840593          	addi	a1,s0,-40
    80005bfc:	4501                	li	a0,0
    80005bfe:	ffffd097          	auipc	ra,0xffffd
    80005c02:	e94080e7          	jalr	-364(ra) # 80002a92 <argaddr>
    return -1;
    80005c06:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c08:	0e054063          	bltz	a0,80005ce8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c0c:	fc840593          	addi	a1,s0,-56
    80005c10:	fd040513          	addi	a0,s0,-48
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	dfc080e7          	jalr	-516(ra) # 80004a10 <pipealloc>
    return -1;
    80005c1c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c1e:	0c054563          	bltz	a0,80005ce8 <sys_pipe+0x104>
  fd0 = -1;
    80005c22:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c26:	fd043503          	ld	a0,-48(s0)
    80005c2a:	fffff097          	auipc	ra,0xfffff
    80005c2e:	508080e7          	jalr	1288(ra) # 80005132 <fdalloc>
    80005c32:	fca42223          	sw	a0,-60(s0)
    80005c36:	08054c63          	bltz	a0,80005cce <sys_pipe+0xea>
    80005c3a:	fc843503          	ld	a0,-56(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	4f4080e7          	jalr	1268(ra) # 80005132 <fdalloc>
    80005c46:	fca42023          	sw	a0,-64(s0)
    80005c4a:	06054863          	bltz	a0,80005cba <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c4e:	4691                	li	a3,4
    80005c50:	fc440613          	addi	a2,s0,-60
    80005c54:	fd843583          	ld	a1,-40(s0)
    80005c58:	68a8                	ld	a0,80(s1)
    80005c5a:	ffffc097          	auipc	ra,0xffffc
    80005c5e:	a18080e7          	jalr	-1512(ra) # 80001672 <copyout>
    80005c62:	02054063          	bltz	a0,80005c82 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c66:	4691                	li	a3,4
    80005c68:	fc040613          	addi	a2,s0,-64
    80005c6c:	fd843583          	ld	a1,-40(s0)
    80005c70:	0591                	addi	a1,a1,4
    80005c72:	68a8                	ld	a0,80(s1)
    80005c74:	ffffc097          	auipc	ra,0xffffc
    80005c78:	9fe080e7          	jalr	-1538(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c7c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c7e:	06055563          	bgez	a0,80005ce8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c82:	fc442783          	lw	a5,-60(s0)
    80005c86:	07e9                	addi	a5,a5,26
    80005c88:	078e                	slli	a5,a5,0x3
    80005c8a:	97a6                	add	a5,a5,s1
    80005c8c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c90:	fc042503          	lw	a0,-64(s0)
    80005c94:	0569                	addi	a0,a0,26
    80005c96:	050e                	slli	a0,a0,0x3
    80005c98:	9526                	add	a0,a0,s1
    80005c9a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c9e:	fd043503          	ld	a0,-48(s0)
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	a3e080e7          	jalr	-1474(ra) # 800046e0 <fileclose>
    fileclose(wf);
    80005caa:	fc843503          	ld	a0,-56(s0)
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	a32080e7          	jalr	-1486(ra) # 800046e0 <fileclose>
    return -1;
    80005cb6:	57fd                	li	a5,-1
    80005cb8:	a805                	j	80005ce8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cba:	fc442783          	lw	a5,-60(s0)
    80005cbe:	0007c863          	bltz	a5,80005cce <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cc2:	01a78513          	addi	a0,a5,26
    80005cc6:	050e                	slli	a0,a0,0x3
    80005cc8:	9526                	add	a0,a0,s1
    80005cca:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cce:	fd043503          	ld	a0,-48(s0)
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	a0e080e7          	jalr	-1522(ra) # 800046e0 <fileclose>
    fileclose(wf);
    80005cda:	fc843503          	ld	a0,-56(s0)
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	a02080e7          	jalr	-1534(ra) # 800046e0 <fileclose>
    return -1;
    80005ce6:	57fd                	li	a5,-1
}
    80005ce8:	853e                	mv	a0,a5
    80005cea:	70e2                	ld	ra,56(sp)
    80005cec:	7442                	ld	s0,48(sp)
    80005cee:	74a2                	ld	s1,40(sp)
    80005cf0:	6121                	addi	sp,sp,64
    80005cf2:	8082                	ret
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	b8dfc0ef          	jal	ra,800028cc <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bac080e7          	jalr	-1108(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	b74080e7          	jalr	-1164(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5179b          	slliw	a5,a0,0xd
    80005e1c:	0c201537          	lui	a0,0xc201
    80005e20:	953e                	add	a0,a0,a5
  return irq;
}
    80005e22:	4148                	lw	a0,4(a0)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b4c080e7          	jalr	-1204(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	06a7c963          	blt	a5,a0,80005ed2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	0001e797          	auipc	a5,0x1e
    80005e68:	19c78793          	addi	a5,a5,412 # 80024000 <disk>
    80005e6c:	00a78733          	add	a4,a5,a0
    80005e70:	6789                	lui	a5,0x2
    80005e72:	97ba                	add	a5,a5,a4
    80005e74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e78:	e7ad                	bnez	a5,80005ee2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e7a:	00451793          	slli	a5,a0,0x4
    80005e7e:	00020717          	auipc	a4,0x20
    80005e82:	18270713          	addi	a4,a4,386 # 80026000 <disk+0x2000>
    80005e86:	6314                	ld	a3,0(a4)
    80005e88:	96be                	add	a3,a3,a5
    80005e8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e8e:	6314                	ld	a3,0(a4)
    80005e90:	96be                	add	a3,a3,a5
    80005e92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e96:	6314                	ld	a3,0(a4)
    80005e98:	96be                	add	a3,a3,a5
    80005e9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e9e:	6318                	ld	a4,0(a4)
    80005ea0:	97ba                	add	a5,a5,a4
    80005ea2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ea6:	0001e797          	auipc	a5,0x1e
    80005eaa:	15a78793          	addi	a5,a5,346 # 80024000 <disk>
    80005eae:	97aa                	add	a5,a5,a0
    80005eb0:	6509                	lui	a0,0x2
    80005eb2:	953e                	add	a0,a0,a5
    80005eb4:	4785                	li	a5,1
    80005eb6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eba:	00020517          	auipc	a0,0x20
    80005ebe:	15e50513          	addi	a0,a0,350 # 80026018 <disk+0x2018>
    80005ec2:	ffffc097          	auipc	ra,0xffffc
    80005ec6:	392080e7          	jalr	914(ra) # 80002254 <wakeup>
}
    80005eca:	60a2                	ld	ra,8(sp)
    80005ecc:	6402                	ld	s0,0(sp)
    80005ece:	0141                	addi	sp,sp,16
    80005ed0:	8082                	ret
    panic("free_desc 1");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	98e50513          	addi	a0,a0,-1650 # 80008860 <syscalls+0x320>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	98e50513          	addi	a0,a0,-1650 # 80008870 <syscalls+0x330>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>

0000000080005ef2 <virtio_disk_init>:
{
    80005ef2:	1101                	addi	sp,sp,-32
    80005ef4:	ec06                	sd	ra,24(sp)
    80005ef6:	e822                	sd	s0,16(sp)
    80005ef8:	e426                	sd	s1,8(sp)
    80005efa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005efc:	00003597          	auipc	a1,0x3
    80005f00:	98458593          	addi	a1,a1,-1660 # 80008880 <syscalls+0x340>
    80005f04:	00020517          	auipc	a0,0x20
    80005f08:	22450513          	addi	a0,a0,548 # 80026128 <disk+0x2128>
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	c48080e7          	jalr	-952(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f14:	100017b7          	lui	a5,0x10001
    80005f18:	4398                	lw	a4,0(a5)
    80005f1a:	2701                	sext.w	a4,a4
    80005f1c:	747277b7          	lui	a5,0x74727
    80005f20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f24:	0ef71163          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	43dc                	lw	a5,4(a5)
    80005f2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f30:	4705                	li	a4,1
    80005f32:	0ce79a63          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f36:	100017b7          	lui	a5,0x10001
    80005f3a:	479c                	lw	a5,8(a5)
    80005f3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f3e:	4709                	li	a4,2
    80005f40:	0ce79363          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	47d8                	lw	a4,12(a5)
    80005f4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f4c:	554d47b7          	lui	a5,0x554d4
    80005f50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f54:	0af71963          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	4705                	li	a4,1
    80005f5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f60:	470d                	li	a4,3
    80005f62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f66:	c7ffe737          	lui	a4,0xc7ffe
    80005f6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005f6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f70:	2701                	sext.w	a4,a4
    80005f72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f74:	472d                	li	a4,11
    80005f76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f78:	473d                	li	a4,15
    80005f7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f7c:	6705                	lui	a4,0x1
    80005f7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f84:	5bdc                	lw	a5,52(a5)
    80005f86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f88:	c7d9                	beqz	a5,80006016 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f8a:	471d                	li	a4,7
    80005f8c:	08f77d63          	bgeu	a4,a5,80006026 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f90:	100014b7          	lui	s1,0x10001
    80005f94:	47a1                	li	a5,8
    80005f96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f98:	6609                	lui	a2,0x2
    80005f9a:	4581                	li	a1,0
    80005f9c:	0001e517          	auipc	a0,0x1e
    80005fa0:	06450513          	addi	a0,a0,100 # 80024000 <disk>
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	d3c080e7          	jalr	-708(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fac:	0001e717          	auipc	a4,0x1e
    80005fb0:	05470713          	addi	a4,a4,84 # 80024000 <disk>
    80005fb4:	00c75793          	srli	a5,a4,0xc
    80005fb8:	2781                	sext.w	a5,a5
    80005fba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fbc:	00020797          	auipc	a5,0x20
    80005fc0:	04478793          	addi	a5,a5,68 # 80026000 <disk+0x2000>
    80005fc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fc6:	0001e717          	auipc	a4,0x1e
    80005fca:	0ba70713          	addi	a4,a4,186 # 80024080 <disk+0x80>
    80005fce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fd0:	0001f717          	auipc	a4,0x1f
    80005fd4:	03070713          	addi	a4,a4,48 # 80025000 <disk+0x1000>
    80005fd8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fda:	4705                	li	a4,1
    80005fdc:	00e78c23          	sb	a4,24(a5)
    80005fe0:	00e78ca3          	sb	a4,25(a5)
    80005fe4:	00e78d23          	sb	a4,26(a5)
    80005fe8:	00e78da3          	sb	a4,27(a5)
    80005fec:	00e78e23          	sb	a4,28(a5)
    80005ff0:	00e78ea3          	sb	a4,29(a5)
    80005ff4:	00e78f23          	sb	a4,30(a5)
    80005ff8:	00e78fa3          	sb	a4,31(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6105                	addi	sp,sp,32
    80006004:	8082                	ret
    panic("could not find virtio disk");
    80006006:	00003517          	auipc	a0,0x3
    8000600a:	88a50513          	addi	a0,a0,-1910 # 80008890 <syscalls+0x350>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006016:	00003517          	auipc	a0,0x3
    8000601a:	89a50513          	addi	a0,a0,-1894 # 800088b0 <syscalls+0x370>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006026:	00003517          	auipc	a0,0x3
    8000602a:	8aa50513          	addi	a0,a0,-1878 # 800088d0 <syscalls+0x390>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	510080e7          	jalr	1296(ra) # 8000053e <panic>

0000000080006036 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006036:	7159                	addi	sp,sp,-112
    80006038:	f486                	sd	ra,104(sp)
    8000603a:	f0a2                	sd	s0,96(sp)
    8000603c:	eca6                	sd	s1,88(sp)
    8000603e:	e8ca                	sd	s2,80(sp)
    80006040:	e4ce                	sd	s3,72(sp)
    80006042:	e0d2                	sd	s4,64(sp)
    80006044:	fc56                	sd	s5,56(sp)
    80006046:	f85a                	sd	s6,48(sp)
    80006048:	f45e                	sd	s7,40(sp)
    8000604a:	f062                	sd	s8,32(sp)
    8000604c:	ec66                	sd	s9,24(sp)
    8000604e:	e86a                	sd	s10,16(sp)
    80006050:	1880                	addi	s0,sp,112
    80006052:	892a                	mv	s2,a0
    80006054:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006056:	00c52c83          	lw	s9,12(a0)
    8000605a:	001c9c9b          	slliw	s9,s9,0x1
    8000605e:	1c82                	slli	s9,s9,0x20
    80006060:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006064:	00020517          	auipc	a0,0x20
    80006068:	0c450513          	addi	a0,a0,196 # 80026128 <disk+0x2128>
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	b78080e7          	jalr	-1160(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006074:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006076:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006078:	0001eb97          	auipc	s7,0x1e
    8000607c:	f88b8b93          	addi	s7,s7,-120 # 80024000 <disk>
    80006080:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006082:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006084:	8a4e                	mv	s4,s3
    80006086:	a051                	j	8000610a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006088:	00fb86b3          	add	a3,s7,a5
    8000608c:	96da                	add	a3,a3,s6
    8000608e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006092:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006094:	0207c563          	bltz	a5,800060be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006098:	2485                	addiw	s1,s1,1
    8000609a:	0711                	addi	a4,a4,4
    8000609c:	25548063          	beq	s1,s5,800062dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060a2:	00020697          	auipc	a3,0x20
    800060a6:	f7668693          	addi	a3,a3,-138 # 80026018 <disk+0x2018>
    800060aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060ac:	0006c583          	lbu	a1,0(a3)
    800060b0:	fde1                	bnez	a1,80006088 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060b2:	2785                	addiw	a5,a5,1
    800060b4:	0685                	addi	a3,a3,1
    800060b6:	ff879be3          	bne	a5,s8,800060ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ba:	57fd                	li	a5,-1
    800060bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060be:	02905a63          	blez	s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060c2:	f9042503          	lw	a0,-112(s0)
    800060c6:	00000097          	auipc	ra,0x0
    800060ca:	d90080e7          	jalr	-624(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060ce:	4785                	li	a5,1
    800060d0:	0297d163          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060d4:	f9442503          	lw	a0,-108(s0)
    800060d8:	00000097          	auipc	ra,0x0
    800060dc:	d7e080e7          	jalr	-642(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060e0:	4789                	li	a5,2
    800060e2:	0097d863          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060e6:	f9842503          	lw	a0,-104(s0)
    800060ea:	00000097          	auipc	ra,0x0
    800060ee:	d6c080e7          	jalr	-660(ra) # 80005e56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f2:	00020597          	auipc	a1,0x20
    800060f6:	03658593          	addi	a1,a1,54 # 80026128 <disk+0x2128>
    800060fa:	00020517          	auipc	a0,0x20
    800060fe:	f1e50513          	addi	a0,a0,-226 # 80026018 <disk+0x2018>
    80006102:	ffffc097          	auipc	ra,0xffffc
    80006106:	fc6080e7          	jalr	-58(ra) # 800020c8 <sleep>
  for(int i = 0; i < 3; i++){
    8000610a:	f9040713          	addi	a4,s0,-112
    8000610e:	84ce                	mv	s1,s3
    80006110:	bf41                	j	800060a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006112:	20058713          	addi	a4,a1,512
    80006116:	00471693          	slli	a3,a4,0x4
    8000611a:	0001e717          	auipc	a4,0x1e
    8000611e:	ee670713          	addi	a4,a4,-282 # 80024000 <disk>
    80006122:	9736                	add	a4,a4,a3
    80006124:	4685                	li	a3,1
    80006126:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000612a:	20058713          	addi	a4,a1,512
    8000612e:	00471693          	slli	a3,a4,0x4
    80006132:	0001e717          	auipc	a4,0x1e
    80006136:	ece70713          	addi	a4,a4,-306 # 80024000 <disk>
    8000613a:	9736                	add	a4,a4,a3
    8000613c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006140:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006144:	7679                	lui	a2,0xffffe
    80006146:	963e                	add	a2,a2,a5
    80006148:	00020697          	auipc	a3,0x20
    8000614c:	eb868693          	addi	a3,a3,-328 # 80026000 <disk+0x2000>
    80006150:	6298                	ld	a4,0(a3)
    80006152:	9732                	add	a4,a4,a2
    80006154:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006156:	6298                	ld	a4,0(a3)
    80006158:	9732                	add	a4,a4,a2
    8000615a:	4541                	li	a0,16
    8000615c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000615e:	6298                	ld	a4,0(a3)
    80006160:	9732                	add	a4,a4,a2
    80006162:	4505                	li	a0,1
    80006164:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006168:	f9442703          	lw	a4,-108(s0)
    8000616c:	6288                	ld	a0,0(a3)
    8000616e:	962a                	add	a2,a2,a0
    80006170:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006174:	0712                	slli	a4,a4,0x4
    80006176:	6290                	ld	a2,0(a3)
    80006178:	963a                	add	a2,a2,a4
    8000617a:	05890513          	addi	a0,s2,88
    8000617e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006180:	6294                	ld	a3,0(a3)
    80006182:	96ba                	add	a3,a3,a4
    80006184:	40000613          	li	a2,1024
    80006188:	c690                	sw	a2,8(a3)
  if(write)
    8000618a:	140d0063          	beqz	s10,800062ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000618e:	00020697          	auipc	a3,0x20
    80006192:	e726b683          	ld	a3,-398(a3) # 80026000 <disk+0x2000>
    80006196:	96ba                	add	a3,a3,a4
    80006198:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000619c:	0001e817          	auipc	a6,0x1e
    800061a0:	e6480813          	addi	a6,a6,-412 # 80024000 <disk>
    800061a4:	00020517          	auipc	a0,0x20
    800061a8:	e5c50513          	addi	a0,a0,-420 # 80026000 <disk+0x2000>
    800061ac:	6114                	ld	a3,0(a0)
    800061ae:	96ba                	add	a3,a3,a4
    800061b0:	00c6d603          	lhu	a2,12(a3)
    800061b4:	00166613          	ori	a2,a2,1
    800061b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061bc:	f9842683          	lw	a3,-104(s0)
    800061c0:	6110                	ld	a2,0(a0)
    800061c2:	9732                	add	a4,a4,a2
    800061c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c8:	20058613          	addi	a2,a1,512
    800061cc:	0612                	slli	a2,a2,0x4
    800061ce:	9642                	add	a2,a2,a6
    800061d0:	577d                	li	a4,-1
    800061d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d6:	00469713          	slli	a4,a3,0x4
    800061da:	6114                	ld	a3,0(a0)
    800061dc:	96ba                	add	a3,a3,a4
    800061de:	03078793          	addi	a5,a5,48
    800061e2:	97c2                	add	a5,a5,a6
    800061e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061e6:	611c                	ld	a5,0(a0)
    800061e8:	97ba                	add	a5,a5,a4
    800061ea:	4685                	li	a3,1
    800061ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ee:	611c                	ld	a5,0(a0)
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	4809                	li	a6,2
    800061f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061f8:	611c                	ld	a5,0(a0)
    800061fa:	973e                	add	a4,a4,a5
    800061fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006200:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006204:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006208:	6518                	ld	a4,8(a0)
    8000620a:	00275783          	lhu	a5,2(a4)
    8000620e:	8b9d                	andi	a5,a5,7
    80006210:	0786                	slli	a5,a5,0x1
    80006212:	97ba                	add	a5,a5,a4
    80006214:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006218:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000621c:	6518                	ld	a4,8(a0)
    8000621e:	00275783          	lhu	a5,2(a4)
    80006222:	2785                	addiw	a5,a5,1
    80006224:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006228:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006234:	00492703          	lw	a4,4(s2)
    80006238:	4785                	li	a5,1
    8000623a:	02f71163          	bne	a4,a5,8000625c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000623e:	00020997          	auipc	s3,0x20
    80006242:	eea98993          	addi	s3,s3,-278 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006246:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006248:	85ce                	mv	a1,s3
    8000624a:	854a                	mv	a0,s2
    8000624c:	ffffc097          	auipc	ra,0xffffc
    80006250:	e7c080e7          	jalr	-388(ra) # 800020c8 <sleep>
  while(b->disk == 1) {
    80006254:	00492783          	lw	a5,4(s2)
    80006258:	fe9788e3          	beq	a5,s1,80006248 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000625c:	f9042903          	lw	s2,-112(s0)
    80006260:	20090793          	addi	a5,s2,512
    80006264:	00479713          	slli	a4,a5,0x4
    80006268:	0001e797          	auipc	a5,0x1e
    8000626c:	d9878793          	addi	a5,a5,-616 # 80024000 <disk>
    80006270:	97ba                	add	a5,a5,a4
    80006272:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006276:	00020997          	auipc	s3,0x20
    8000627a:	d8a98993          	addi	s3,s3,-630 # 80026000 <disk+0x2000>
    8000627e:	00491713          	slli	a4,s2,0x4
    80006282:	0009b783          	ld	a5,0(s3)
    80006286:	97ba                	add	a5,a5,a4
    80006288:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000628c:	854a                	mv	a0,s2
    8000628e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006292:	00000097          	auipc	ra,0x0
    80006296:	bc4080e7          	jalr	-1084(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000629a:	8885                	andi	s1,s1,1
    8000629c:	f0ed                	bnez	s1,8000627e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000629e:	00020517          	auipc	a0,0x20
    800062a2:	e8a50513          	addi	a0,a0,-374 # 80026128 <disk+0x2128>
    800062a6:	ffffb097          	auipc	ra,0xffffb
    800062aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
}
    800062ae:	70a6                	ld	ra,104(sp)
    800062b0:	7406                	ld	s0,96(sp)
    800062b2:	64e6                	ld	s1,88(sp)
    800062b4:	6946                	ld	s2,80(sp)
    800062b6:	69a6                	ld	s3,72(sp)
    800062b8:	6a06                	ld	s4,64(sp)
    800062ba:	7ae2                	ld	s5,56(sp)
    800062bc:	7b42                	ld	s6,48(sp)
    800062be:	7ba2                	ld	s7,40(sp)
    800062c0:	7c02                	ld	s8,32(sp)
    800062c2:	6ce2                	ld	s9,24(sp)
    800062c4:	6d42                	ld	s10,16(sp)
    800062c6:	6165                	addi	sp,sp,112
    800062c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062ca:	00020697          	auipc	a3,0x20
    800062ce:	d366b683          	ld	a3,-714(a3) # 80026000 <disk+0x2000>
    800062d2:	96ba                	add	a3,a3,a4
    800062d4:	4609                	li	a2,2
    800062d6:	00c69623          	sh	a2,12(a3)
    800062da:	b5c9                	j	8000619c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062dc:	f9042583          	lw	a1,-112(s0)
    800062e0:	20058793          	addi	a5,a1,512
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	0001e517          	auipc	a0,0x1e
    800062ea:	dc250513          	addi	a0,a0,-574 # 800240a8 <disk+0xa8>
    800062ee:	953e                	add	a0,a0,a5
  if(write)
    800062f0:	e20d11e3          	bnez	s10,80006112 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062f4:	20058713          	addi	a4,a1,512
    800062f8:	00471693          	slli	a3,a4,0x4
    800062fc:	0001e717          	auipc	a4,0x1e
    80006300:	d0470713          	addi	a4,a4,-764 # 80024000 <disk>
    80006304:	9736                	add	a4,a4,a3
    80006306:	0a072423          	sw	zero,168(a4)
    8000630a:	b505                	j	8000612a <virtio_disk_rw+0xf4>

000000008000630c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000630c:	1101                	addi	sp,sp,-32
    8000630e:	ec06                	sd	ra,24(sp)
    80006310:	e822                	sd	s0,16(sp)
    80006312:	e426                	sd	s1,8(sp)
    80006314:	e04a                	sd	s2,0(sp)
    80006316:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006318:	00020517          	auipc	a0,0x20
    8000631c:	e1050513          	addi	a0,a0,-496 # 80026128 <disk+0x2128>
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	8c4080e7          	jalr	-1852(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006328:	10001737          	lui	a4,0x10001
    8000632c:	533c                	lw	a5,96(a4)
    8000632e:	8b8d                	andi	a5,a5,3
    80006330:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006332:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006336:	00020797          	auipc	a5,0x20
    8000633a:	cca78793          	addi	a5,a5,-822 # 80026000 <disk+0x2000>
    8000633e:	6b94                	ld	a3,16(a5)
    80006340:	0207d703          	lhu	a4,32(a5)
    80006344:	0026d783          	lhu	a5,2(a3)
    80006348:	06f70163          	beq	a4,a5,800063aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000634c:	0001e917          	auipc	s2,0x1e
    80006350:	cb490913          	addi	s2,s2,-844 # 80024000 <disk>
    80006354:	00020497          	auipc	s1,0x20
    80006358:	cac48493          	addi	s1,s1,-852 # 80026000 <disk+0x2000>
    __sync_synchronize();
    8000635c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006360:	6898                	ld	a4,16(s1)
    80006362:	0204d783          	lhu	a5,32(s1)
    80006366:	8b9d                	andi	a5,a5,7
    80006368:	078e                	slli	a5,a5,0x3
    8000636a:	97ba                	add	a5,a5,a4
    8000636c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000636e:	20078713          	addi	a4,a5,512
    80006372:	0712                	slli	a4,a4,0x4
    80006374:	974a                	add	a4,a4,s2
    80006376:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000637a:	e731                	bnez	a4,800063c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000637c:	20078793          	addi	a5,a5,512
    80006380:	0792                	slli	a5,a5,0x4
    80006382:	97ca                	add	a5,a5,s2
    80006384:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006386:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000638a:	ffffc097          	auipc	ra,0xffffc
    8000638e:	eca080e7          	jalr	-310(ra) # 80002254 <wakeup>

    disk.used_idx += 1;
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	17c2                	slli	a5,a5,0x30
    8000639a:	93c1                	srli	a5,a5,0x30
    8000639c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063a0:	6898                	ld	a4,16(s1)
    800063a2:	00275703          	lhu	a4,2(a4)
    800063a6:	faf71be3          	bne	a4,a5,8000635c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063aa:	00020517          	auipc	a0,0x20
    800063ae:	d7e50513          	addi	a0,a0,-642 # 80026128 <disk+0x2128>
    800063b2:	ffffb097          	auipc	ra,0xffffb
    800063b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
}
    800063ba:	60e2                	ld	ra,24(sp)
    800063bc:	6442                	ld	s0,16(sp)
    800063be:	64a2                	ld	s1,8(sp)
    800063c0:	6902                	ld	s2,0(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret
      panic("virtio_disk_intr status");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	52a50513          	addi	a0,a0,1322 # 800088f0 <syscalls+0x3b0>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
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
