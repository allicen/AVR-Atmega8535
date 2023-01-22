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
reti ; rjmp EXT_INT0 ; IRQ0 Handler
reti ; rjmp EXT_INT1 ; IRQ1 Handler
reti ; rjmp TIM2_COMP ; Timer2 Compare Handler
reti ; rjmp TIM2_OVF ;Timer2 Overflow Handler
 rjmp TIM1_CAPT ; Timer1 Capture Handler
reti ; rjmp TIM1_COMPA ; Timer1 Compare A Handler
reti ; rjmp TIM1_COMPB ; Timer1 Compare B Handler
reti ; rjmp TIM1_OVF ; Timer1 Overflow Handler
reti ; rjmp TIM0_OVF ; Timer0 Overflow Handler
reti ; rjmp SPI_STC ; SPI Transfer Complete Handler
reti ; rjmp USART_RXC ; USART RX Complete Handler
reti ; rjmp USART_UDRE ; UDR Empty Handler
reti ; rjmp USART_TXC ; USART TX Complete Handler
reti ; rjmp ADC ; ADC Conversion Complete Handler
reti ; rjmp EE_RDY ; EEPROM Ready Handler
reti ; rjmp ANA_COMP ; Analog Comparator Handler
reti ; rjmp TWSI ; Two-wire Serial Interface Handler
reti ; rjmp EXT_INT2 ; IRQ2 Handler
reti ; rjmp TIM0_COMP ; Timer0 Compare Handler
reti ; rjmp SPM_RDY
.org 0x15
RESET:
//init stack pointer
ldi Acc0, 0x5f
out SPL, Acc0
ldi Acc0, HIGH(RAMEND)
out SPH, Acc0
//init SFR (special function reg)
in Acc0, SFIOR
SBR Acc0, ACME
//ORI Acc0, (1�ACME)
out SFIOR, Acc0
Ldi Acc0, (0<<ACBG) | (1<<ACIC) | (0b10<<ACIS0)| (1<<ACD)
out ACSR, Acc0
Ldi Acc0, (0<<ACBG) | (1<<ACIC) | (0b10<<ACIS0)| (0<<ACD)
out ACSR, Acc0
LDI Acc0, (0b00000<<MUX0)
out ADMUX, Acc0
LDi Acc0, (0b001<<CS10)| (1<<ICES1)
out TCCR1B, Acc0
in Acc0, TIMSK
ORI Acc0, (1<<TICIE1)//| (1�OCIE1A)| (1�OCIE1B)| (1�TOIE1)
out TIMSK, Acc0

LdI Acc0, (1<<U2X)
out UCSRA, Acc0
LDI Acc0, (1<<TXEN) | (1<<RXEN)
out UCSRB, Acc0
LDI Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1)
out UCSRC,Acc0
LDI Acc0, 0
out UBRRH,Acc0
LDI Acc0, 12
out UBRRL,Acc0 
sbi DDRD, TX
sbi DDRB, LED

sbi DDRB, LED
//Interrupt Enable

 sei

//Main programm
loop:

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

TIM1_CAPT:
push Acc0
push Acc1
in Acc0,SREG
push Acc0

TC1:
in Acc0,UCSRA
//ANDI Acc0, (1<<UDRE)
//breq TC1 
SBRS Acc0, UDRE
rjmp TC1
in Acc0, ICR1L
//LDI Acc0, 0x31
//in Acc0, TCNT1L
out UDR, Acc0

pop Acc0
out SREG,Acc0
pop Acc1
pop Acc0

reti

//Data
DataByte:
.DB 0x1f, 0x1C
DataWord:
.DW 0x1234, 0x5678
