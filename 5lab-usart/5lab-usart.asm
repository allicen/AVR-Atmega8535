//include init file 
.include "m8535def.inc" 
 
//init constant 
.equ Bitrate = 9600 // 9600 under is equal to 0.00768 megabits/sec
//Режим Asynchronous Normal Mode
.equ BAUD = 8000000 / (16 * Bitrate) - 1 // 51! the formula in datasheet, 8000000 - clock frequency 8MHz
.equ numCode = 0x31 // 1 code
 
//init registers 
.def Acc0 = R16 
.def Acc1 = R17
.def Acc2 = R20
.def count = R18
.def print = R19
 
//PROGRAMM 
//interrupt vectors 
.org 0x0 
rjmp RESET ; Reset Handler 
//rjmp EXT_INT0 ; IRQ0 Handler 
//rjmp EXT_INT1 ; IRQ1 Handler 
//rjmp TIM2_COMP ; Timer2 Compare Handler 
//rjmp TIM2_OVF ; Timer2 Overflow Handler 
//rjmp TIM1_CAPT ; Timer1 Capture Handler 
//rjmp TIM1_COMPA ; Timer1 Compare A Handler 
//rjmp TIM1_COMPB ; Timer1 Compare B Handler 
//rjmp TIM1_OVF ; Timer1 Overflow Handler 
//rjmp TIM0_OVF ; Timer0 Overflow Handler 
//rjmp SPI_STC ; SPI Transfer Complete Handler 
.org 0x00B
  rjmp USART_RXC ; USART RX Complete Handler 
//rjmp USART_UDRE ; UDR Empty Handler 
.org 0x00D
  rjmp USART_TXC ; USART TX Complete Handler 
//rjmp ADC ; ADC Conversion Complete Handler 
//rjmp EE_RDY ; EEPROM Ready Handler 
//rjmp ANA_COMP ; Analog Comparator Handler 
//rjmp TWSI ; Two-wire Serial Interface Handler 
//rjmp EXT_INT2 ; IRQ2 Handler 
//rjmp TIM0_COMP ; Timer0 Compare Handler 
//rjmp SPM_RDY
.org 0x15

RESET: 
//init stack pointer 
ldi Acc0, LOW(RAMEND) 
out SPL, Acc0 
ldi Acc0, HIGH(RAMEND) 
out SPH, Acc0

//init SFR (special function reg)
ldi Acc0, HIGH(BAUD)
out UBRRH,Acc0 
ldi Acc0, LOW(BAUD) 
out UBRRL,Acc0

ldi Acc0, (1<<TXEN) | (1<<RXEN) | (1<<RXCIE) | (1<<TXCIE) // these bits allow interrupts
out UCSRB, Acc0 
ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1) // UCSZ0 и UCSZ1 because 8 bits
out UCSRC,Acc0

ldi print, 0

//Interrupt Enable 
    sei


//Main programm 
loop:
    rjmp loop


//SubProgramm

Delay:
    nop
    nop
    nop
    nop
ret

//Inerrupt Routines 
USART_RXC: // interruption when receiving data
    sbis UCSRA, RXC // RXC - USART interrupt entry bit
    rjmp USART_RXC
    in Acc1, UDR // get data from the terminal
    cpi print, 1
    breq UR_print_stop
    cpi Acc1, numCode
    brne UR_stop
    rjmp UR_print_start
UR_print_stop:
    ldi print, 0
UR_stop:
    out UDR, Acc1 // send the data back to the terminal
    rjmp stop
UR_print_start:
    ldi Acc2, 0x1
    out UDR, Acc2
stop:
reti


USART_TXC: // transfer completed
    sbis UCSRA, UDRE // UDRE - interrupt entry bit
    rjmp USART_TXC
    cpi Acc1, numCode // if 1 came, then repeat 1
    breq UT_print
    rjmp UT_stop
UT_print:
    ldi print, 1
    ldi Acc2, 0x1
    out UDR, Acc2
    rcall Delay
UT_stop:
reti

Clear:
    rjmp UT_stop


//Data
DataByte: 
.DB 0x1f, 0x1C 
DataWord: 
.DW 0x1234, 0x5678