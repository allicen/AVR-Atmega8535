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
.equ numCode = 0x31 // код единицы
.equ memAddr = 0x50

//init registers
.def Acc0 = R16
.def Acc1 = R17

// Статус печати в USART
// 0 - не печатать ничего
// 1 - запуск таймера
// 2 - остановка таймера и печать результата
// 3 - очистить данные
// 4 - неверная команда (ошибка)
.def PrintState = R18

// Статус печати строки
// 0 - ожидание ввода символа от пользователя
// 1 - печать идет
// 2 - строка закончена, печать переноса строки
.def LinePrintState = R19

.def CharIndex = R20 // индекс символа строки
.def Char = R21 // печатный символ

// Регистры для работы с памятью
.def AccMem1 = R22
.def AccMem2 = R23
.def PrintMemData = R24 // 1 - печатать, 0 - не печатать


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

ldi PrintState, 0 // Статус печати в USART
ldi CharIndex, 0 // Индекс символа строки
ldi Char, 0
ldi LinePrintState, 1 // При запуске программы печатаем строку
ldi PrintMemData, 0

ldi AccMem1, LOW(memAddr) //Адрес записи данных
ldi AccMem2, HIGH(memAddr)


// Печать инструкции
ldi ZL, LOW(StartNote*2)
ldi ZH, HIGH(StartNote*2)
rcall PrintStartLine

//Interrupt Enable
 sei

//Main programm
loop:

/*
//LED ON
sbi PORTB, LED
//DELAY
rcall Delay
//LED OFF
cbi PORTB, LED
//DELAY
rcall Delay
*/

rjmp loop



//SubProgramm
Delay:
nop
nop

ret


PrintUSART:
	sbis UCSRA, UDRE
	rjmp PrintUSART
	out UDR, Char
ret


PrintStartLine:
	lpm Char, Z+
	cpi Char, '$' // проверка на конец строки
	breq LC_end
	rcall PrintUSART
	rjmp PrintStartLine
LC_end:
	ldi CharIndex, 0
	ldi Char, 0
	ldi LinePrintState, 0
ret


PrintEndLine:
	cpi LinePrintState, 2
	brne PEL_stop
	ldi Char, 0x0D
	out UDR, Char
	ldi CharIndex, 0
	ldi Char, 0
	ldi LinePrintState, 0
PEL_stop:
ret


ClearAndEndLine:
	ldi LinePrintState, 2
	rcall PrintEndLine
	ldi CharIndex, 0
	ldi Char, 0
	ldi LinePrintState, 0
	ldi PrintState, 0
ret


PrintTimerStartNote:
	ldi ZL, LOW(TimerStartNote*2)
	ldi ZH, HIGH(TimerStartNote*2)
	add ZL, CharIndex
	lpm Char, Z
	cpi Char, '$'
	breq PTSN_clear
	out UDR, Char
	inc CharIndex
	rjmp PTSN_stop
PTSN_clear:
	rcall ClearAndEndLine
PTSN_stop:
ret


PrintTimerResultNote:
	ldi ZL, LOW(TimerResultNote*2)
	ldi ZH, HIGH(TimerResultNote*2)
	add ZL, CharIndex
	lpm Char, Z
	cpi Char, '$'
	breq PTRN_clear
	out UDR, Char
	inc CharIndex
	rjmp PTRN_stop
PTRN_clear:
	rcall ClearAndEndLine
	ldi PrintMemData, 1
	ldi CharIndex, 0
PTRN_stop:
ret


PrintTimerClearNote:
	ldi ZL, LOW(TimerClearNote*2)
	ldi ZH, HIGH(TimerClearNote*2)
	add ZL, CharIndex
	lpm Char, Z
	cpi Char, '$'
	breq PTCN_clear
	out UDR, Char
	inc CharIndex
	rjmp PTCN_stop
PTCN_clear:
	rcall ClearAndEndLine
PTCN_stop:
ret

PrintKeyErrorNote:
	ldi ZL, LOW(KeyErrorNote*2)
	ldi ZH, HIGH(KeyErrorNote*2)
	add ZL, CharIndex
	lpm Char, Z
	cpi Char, '$'
	breq PKEN_clear
	out UDR, Char
	inc CharIndex
	rjmp PKEN_stop
PKEN_clear:
	rcall ClearAndEndLine
PKEN_stop:
ret


EEPROM_write:
	; Wait for completion of previous write
	sbic EECR,EEWE // ждет окончания записи, анализ флага EEWE в регистре EECR
	rjmp EEPROM_write
	; Set up address (r18:r17) in address register
	out EEARH, AccMem2
	out EEARL, AccMem1
	; Write data (r16) to Data Register
	out EEDR, Char
	; Write logical one to EEMWE
	sbi EECR,EEMWE // установить в регистр ввода-вывода 1
	; Start eeprom write by setting EEWE
	sbi EECR,EEWE
ret


EEPROM_read:
	; Wait for completion of previous write
	sbic EECR,EEWE
	rjmp EEPROM_read
	; Set up address (r18:r17) in Address Register
	out EEARH, AccMem2
	out EEARL, AccMem1
	; Start eeprom read by writing EERE
	sbi EECR,EERE
	; Read data from Data Register
	in Char,EEDR
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
	
	mov Char, Acc0

	rcall EEPROM_write
	inc AccMem1

	pop Acc0
	out SREG,Acc0
	pop Acc1
	pop Acc0

reti



USART_RXC: // прерывание при получении данных
	sbis UCSRA, RXC // RXC - бит входа в прерывание по USART
	rjmp USART_RXC
	
	ldi Acc0, numCode
	in Char, UDR
	cp Char, Acc0 // 1 - запуск таймера
	breq UR_timer_start
	inc Acc0
	cp Char, Acc0 // 2 - остановить таймер и вывести результат
	breq UR_timer_res
	inc Acc0
	cp Char, Acc0 // 3 - очистить таймер
	breq UR_timer_clear

	rjmp UR_error


UR_timer_start:
	ldi PrintState, 1
	rjmp UR_stop

UR_timer_res:
	ldi PrintState, 2
	rjmp UR_stop

UR_timer_clear:
	ldi PrintState, 3
	rjmp UR_stop

UR_error:
	ldi PrintState, 4
	rjmp UR_stop
	
UR_stop:
	ldi CharIndex, 0 // Индекс символа в 0
	ldi LinePrintState, 2 // символ введен - строка закончена
	ldi PrintMemData, 0
	out UDR, Char
	sei
reti



USART_TXC: // передача выполнена
	sbis UCSRA, UDRE
	rjmp USART_TXC

	cpi LinePrintState, 2
	breq US_print_end

	cpi PrintState, 1
	breq US_print_start

	cpi PrintState, 2
	breq US_print_stop

	cpi PrintState, 3
	breq US_print_clear

	cpi PrintState, 4
	breq US_print_error

	cpi PrintMemData, 1
	breq US_ps_data

	rjmp US_stop

US_print_end:
	//cbi PORTB, LED
	rcall PrintEndLine
	rjmp US_stop

US_print_start:
	rcall PrintTimerStartNote
	rjmp US_stop

US_print_stop:
	rcall PrintTimerResultNote
	rjmp US_stop

US_ps_data:
	cpi AccMem1, LOW(memAddr)
	brlo USPD_stop

	cpi CharIndex, 0
	breq USPD_print
	rcall PrintEndLine

	SBRC CharIndex, 0 // пропустить, если бит 0 не установлен
	ldi CharIndex, 0
	
	rjmp US_stop

USPD_print:
	rcall EEPROM_read
	dec AccMem1
	ldi Char, 0x45
	out UDR, Char
	ldi CharIndex, 1
	ldi LinePrintState, 2 // конец строки
	rjmp US_stop

USPD_stop:
	cpi PrintMemData, 1
	breq USPD_clear
	rjmp US_stop

USPD_clear:
	ldi PrintMemData, 0
	ldi CharIndex, 0
	rcall ClearAndEndLine
	rjmp US_stop

US_print_clear:
	rcall PrintTimerClearNote
	rjmp US_stop

US_print_error:
	rcall PrintKeyErrorNote
	rjmp US_stop

US_stop:

reti



//Data
StartNote:
.DB "Values: 1 - start timer, 2 - stop timer and print data, 3 - clear data. Enter key: $"

KeyErrorNote:
.DB "Invalid key code.$"

TimerResultNote:
.DB "Timer stopped. Saved data: $"

TimerStartNote:
.DB "Timer started.$"

TimerClearNote:
.DB "Timer cleared.$"
