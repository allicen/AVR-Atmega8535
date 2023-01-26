// SPI

//include init file
.include "m8535def.inc"

.dseg
MEMO:
.byte 7

//init constant
.equ max_sec = 60
.equ LED = 3
.equ TX = 1
.equ SS = 4
.equ MOSI = 5
.equ MISO = 6
.equ SCK = 7

//init registers
.def Acc0 = R16
.def Acc1 = R17
.def Second = R18
.def min = R19
.def SPIacc = R20


//PROGRAMM
//interrupt vectors
.cseg
.org 0x0
rjmp RESET ; Reset Handler
reti ;rjmp EXT_INT0 ; IRQ0 Handler
reti ;rjmp EXT_INT1 ; IRQ1 Handler
reti ;rjmp TIM2_COMP ; Timer2 Compare Handler
reti ;rjmp TIM2_OVF ; Timer2 Overflow Handler
reti ;rjmp TIM1_CAPT ; Timer1 Capture Handler
reti ;rjmp TIM1_COMPA ; Timer1 Compare A Handler
reti ;rjmp TIM1_COMPB ; Timer1 Compare B Handler
reti ;rjmp TIM1_OVF ; Timer1 Overflow Handler
reti ;rjmp TIM0_OVF ; T SPI_STC ; SPI Timer0 Overflow Handler
rjmp SPI_STC; ansfer Complete Handler
reti ;rjmp USART_RXC ; USART RX Complete Handler
reti ;rjmp USART_UDRE ; UDR Empty Handler
reti ;rjmp USART_TXC ; USART TX Complete Handler
reti ;rjmp ADC ; ADC Conversion Complete Handler
reti ;rjmp EE_RDY ; EEPROM Ready Handler
reti ;rjmp ANA_COMP ; Analog Comparator Handler
reti ;rjmp TWSI ; Two-wire Serial Interface Handler
reti ;rjmp EXT_INT2 ; IRQ2 Handler
reti ;rjmp TIM0_COMP ; Timer0 Compare Handler
reti ;rjmp SPM_RDY*/
.org 0x15
RESET:
//init stack pointer
ldi Acc0, HIGH(RAMEND)
out SPH, Acc0
ldi Acc0, LOW(RAMEND)
out SPL, Acc0

//init SFR (special function reg)
ldi Acc0, (1<<SS)|(1<<MOSI)|(0<<MISO)|(1<<SCK)|(1<<LED)
out DDRB, Acc0

ldi Acc0, (1<<SPIE)|(1<<SPE)|(1<<DORD)|(1<<MSTR)|(0<<CPOL)|(0<<CPHA)|(0b00<<SPR0)
out SPCR, Acc0

ldi Acc0, (1<<SPI2X)
out SPSR, Acc0

ldi Acc1, 0
out SPDR, Acc1

sei
loop:
rjmp loop


SPI_STC:

in SPIacc, SPDR
CP SPIacc, Acc1

BREQ ledON

ledOFF:
sbi PORTB, LED
rjmp END

ledON:
cbi PORTB, LED

END:
Inc Acc1
out SPDR, Acc1

reti
