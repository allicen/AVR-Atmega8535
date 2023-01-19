//include init file 
.include "m8535def.inc" 
 
//init constant 
.equ max_sec = 60 
.equ LED = 3 
.equ TX = 1 
 
//init registers 
.def Acc0 = R16 
.def Acc1 = R17 
.def Second = R18 
.def min = R19 
 
//PROGRAMM 
//interrupt vectors 
.org 0x0 
rjmp RESET ; Reset Handler 
/* rjmp EXT_INT0 ; IRQ0 Handler 
rjmp EXT_INT1 ; IRQ1 Handler 
rjmp TIM2_COMP ; Timer2 Compare Handler 
rjmp TIM2_OVF ; Timer2 Overflow Handler 
rjmp TIM1_CAPT ; Timer1 Capture Handler 
rjmp TIM1_COMPA ; Timer1 Compare A Handler 
rjmp TIM1_COMPB ; Timer1 Compare B Handler 
rjmp TIM1_OVF ; Timer1 Overflow Handler 
rjmp TIM0_OVF ; Timer0 Overflow Handler 
rjmp SPI_STC ; SPI Transfer Complete Handler 
rjmp USART_RXC ; USART RX Complete Handler 
rjmp USART_UDRE ; UDR Empty Handler 
rjmp USART_TXC ; USART TX Complete Handler 
rjmp ADC ; ADC Conversion Complete Handler 
rjmp EE_RDY ; EEPROM Ready Handler 
rjmp ANA_COMP ; Analog Comparator Handler 
rjmp TWSI ; Two-wire Serial Interface Handler 
rjmp EXT_INT2 ; IRQ2 Handler 
rjmp TIM0_COMP ; Timer0 Compare Handler 
rjmp SPM_RDY*/ 
.org 0x15 
RESET: 
//init stack pointer 
ldi Acc0, 0x5f 
out SPL, Acc0 
ldi Acc0, HIGH(RAMEND) 
out SPH, Acc0

//init SFR (special function reg) 
ldi Acc0, (1<<U2X) 
out UCSRA, Acc0 
ldi Acc0, (1<<TXEN) | (1<<RXEN) 
out UCSRB, Acc0 
ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1) 
out UCSRC,Acc0 
ldi Acc0, 0 
out UBRRH,Acc0 
ldi Acc0, 12 
out UBRRL,Acc0 
 
 
 
sbi DDRD, TX 
sbi DDRB, LED 
 
//Interrupt Enable 
// sei 
//Main programm 
 
loop: 
in Acc0, UCSRA 
sbrs Acc0, RXC 
rjmp loop 
//LDI Acc0, 0x31 
in Acc0, UDR 
out UDR, Acc0 
 
//LED ON 
sbi PORTB, LED 
//DELAY 
rcall Delay 
//LED OFF 
cbi PORTB, LED 
//DELAY 
rcall Delay 
rjmp loop 
//SubProgramm 
 
Delay: 
nop 
nop 
 
ret 
//Inerrupt Routines 
EXT_INT0: 
push Acc0 
push Acc1 
 
pop Acc1 
pop Acc0 
 
reti 
//Data 
DataByte: 
.DB 0x1f, 0x1C 
DataWord: 
.DW 0x1234, 0x5678
