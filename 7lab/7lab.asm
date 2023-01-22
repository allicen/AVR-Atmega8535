//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3
.equ TX = 1

.equ Bitrate = 9600 // 9600 бод равно 0.00768 мегабит/сек
//Режим Asynchronous Normal Mode
.equ BAUD = 8000000 / (16 * Bitrate) - 1 // 51! формула в даташите, 8000000 - тактовая частота 8МГц
.equ AsciiCode = 48

//init registers
.def Acc0 = R16
.def Acc1 = R17
.def Start = R18
.def SymbolCount = R19

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
	rjmp USART_RXC ; USART RX Complete Handler
reti ; rjmp USART_UDRE ; UDR Empty Handler
	rjmp USART_TXC ; USART TX Complete Handler
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
sbr Acc0, ACME // sbr - установить бит в регистр, включить аналоговый компаратор

out SFIOR, Acc0
ldi Acc0, (0<<ACBG) | (1<<ACIC) | (0b10<<ACIS0)| (1<<ACD) // ACIC - включить захват, ACIS0 - включить прерывания
out ACSR, Acc0 // ACSR - регистр аналогового компаратора
ldi Acc0, (0<<ACBG) | (1<<ACIC) | (0b10<<ACIS0)| (0<<ACD) // ACBG - сигнал берем со входа
out ACSR, Acc0
ldi Acc0, (0b00000<<MUX0) // нулевой канал
out ADMUX, Acc0
ldi Acc0, (0b001<<CS10)| (1<<ICES1) // ICES1 - нарастающий/спадающий фронт, CS10 - делитель частоты
out TCCR1B, Acc0 // таймер
in Acc0, TIMSK
ori Acc0, (1<<TICIE1)//| (1«OCIE1A)| (1«OCIE1B)| (1«TOIE1) // TICIE1 - прерывание по захвату
out TIMSK, Acc0

// Настройка usart
ldi Acc0, HIGH(BAUD)
out UBRRH,Acc0 
ldi Acc0, LOW(BAUD) 
out UBRRL,Acc0

ldi Acc0, (1<<TXEN) | (1<<RXEN) | (1<<RXCIE) | (1<<TXCIE) // эти биты разрешают прерывания
out UCSRB, Acc0 
ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1) // UCSZ0 и UCSZ1 т.к.8 бит
out UCSRC,Acc0

sbi DDRD, TX
sbi DDRB, LED

ldi Start, 1 // Начало программы
ldi SymbolCount, 0

// Печать инструкции
ldi r30, LOW(StartNote*2)
ldi r31, HIGH(StartNote*2)
rcall PrintLine

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


PrintUSART:
	sbis UCSRA, UDRE
	rjmp PrintUSART
	out UDR, Acc1
ret


PrintLine:
	lpm Acc1, Z+
	cpi Acc1, $00 // проверка на 0
	breq LC_end
	rcall PrintUSART
	rjmp PrintLine

LC_end:
	rjmp LC_end

ret




//Inerrupt Routines

TIM1_CAPT:
	push Acc0
	push Acc1
	in Acc0,SREG
	push Acc0

	TC1:
	in Acc0,UCSRA
	sbrs Acc0, UDRE // пропустить следующую строку, если UDRE=1
	rjmp TC1
	in Acc0, ICR1L
	//out UDR, Acc0

	pop Acc0
	out SREG,Acc0
	pop Acc1
	pop Acc0

reti



USART_RXC: // прерывание при получении данных
	sbis UCSRA, RXC // RXC - бит входа в прерывание по USART
	rjmp USART_RXC
reti


USART_TXC: // передача выполнена
	sbis UCSRA, UDRE
	rjmp USART_TXC

reti



//Data
StartNote:
.DB "Key Values: 1 - start timer, 2 - stop timer and print data, 3 - clear data. Please, enter key: ", 0
