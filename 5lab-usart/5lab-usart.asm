//include init file 
.include "m8535def.inc" 
 
//init constant 
.equ max_sec = 60 
.equ LED = 3 
.equ TX = 1
.equ Bitrate = 9600
// Режим Asynchronous Normal Mode
.equ BAUD = 16000000 / (16 * Bitrate) - 1 // формула в даташите, 16000000 - тактовая частота 16 МГц
 
//init registers 
.def Acc0 = R16 
.def Acc1 = R17
.def count = R18
 
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

ldi Acc0, (1<<U2X) 
out UCSRA, Acc0 
ldi Acc0, (1<<TXEN) | (1<<RXEN) | (1<<RXCIE) | (1<<TXCIE) // эти биты разрешают прерывания
out UCSRB, Acc0 
ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1) // UCSZ0 и UCSZ1 т.к.8 бит
out UCSRC,Acc0


//Interrupt Enable 
	sei


//Main programm 
loop:
	rjmp loop


//SubProgramm


//Inerrupt Routines 
USART_RXC: // прерывание при получении данных
	sbis UCSRA, RXC // RXC - бит входа в прерывание по USART
	rjmp USART_RXC
	in Acc1, UDR // получить данные из терминала
	inc Acc1
	out UDR, Acc1 // отослать обратно данные в терминал
	ldi count, 0
UR_stop:
reti

USART_TXC: // передача выполнена
	sbis UCSRA, UDRE // UDRE - бит входа в прерывание
	rjmp USART_TXC
	inc count
	cpi count, 5
	breq Clear
	inc Acc1
	out UDR, Acc1
UT_stop:
reti

Clear:
	ldi count, 0
	rjmp UT_stop


//Data
DataByte: 
.DB 0x1f, 0x1C 
DataWord: 
.DW 0x1234, 0x5678
