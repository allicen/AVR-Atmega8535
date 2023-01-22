// подключаем файл инициализации
.include "m8535def.inc"

// инициализация констант
.equ max_sec = 60
.equ LED = 3
.equ TX = 1
.equ Bitrate = 9600 // 9600 бод равно 0.00768 мегабит/сек
//Режим Asynchronous Normal Mode
.equ BAUD = 8000000 / (16 * Bitrate) - 1 // 51! формула в даташите, 8000000 - тактовая частота 8МГц
.equ AsciiCode = 48

// инициализация регистров 
.def Acc0 = R16
.def Acc1 = R17
.def TactCount = R18
.def LineCount = R19
.def SymbolCount = R20
.def Razr1 = R21 // сотни
.def Razr2 = R22 // десятки
.def Razr3 = R23 // единицы
.def Number = R25 // число символа
.def NumDecCount = R24 // количество десятков



// PROGRAMM

//interrupt vectors (векторы прерываний)
.org 0x0 /// Установка счетчика адреса в нужное значение.
	rjmp RESET ; Reset Handler
//	rjmp EXT_INT0 ; IRQ0 Handler
//	rjmp EXT_INT1 ; IRQ1 Handler
//	rjmp TIM2_COMP ; Timer2 Compare Handler
//	rjmp TIM2_OVF ; Timer2 Overflow Handler
//	rjmp TIM1_CAPT ; Timer1 Capture Handler
//	rjmp TIM1_COMPA ; Timer1 Compare A Handler
//	rjmp TIM1_COMPB ; Timer1 Compare B Handler
//	rjmp TIM1_OVF ; Timer1 Overflow Handler
.org 0x009 // адрес для регистра TIM0_OVF из даташита
	rjmp TIM0_OVF ; Timer0 Overflow Handler
//	rjmp SPI_STC ; SPI Transfer Complete Handler
//	rjmp USART_RXC ; USART RX Complete Handler
//	rjmp USART_UDRE ; UDR Empty Handler
.org 0x00D
	rjmp USART_TXC ; USART TX Complete Handler
.org 0x00E
	rjmp ADC_CON ; ADC Conversion Complete Handler
//	rjmp EE_RDY ; EEPROM Ready Handler
//	rjmp ANA_COMP ; Analog Comparator Handler
//	rjmp TWSI ; Two-wire Serial Interface Handler
//	rjmp EXT_INT2 ; IRQ2 Handler
//	rjmp TIM0_COMP ; Timer0 Compare Handler
//	rjmp SPM_RDY ; Store Program Memory Ready Handler
.org 0x15 /// Начало главной программы

RESET:
	// инициализация стека
	ldi Acc0, LOW(RAMEND) /// RAMEND - макс адрес ОЗУ
	out SPL, Acc0
	ldi Acc0, HIGH(RAMEND)
	out SPH, Acc0

	//init SFR (special function reg)
	sbi DDRB, LED

	// Настройка таймера
	ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00) // CS00 - частота/1024 (стр 84)
	out TCCR0, Acc0 // запись в регистр спец назначения для настройки таймера
	ldi Acc0, 0xFF // 255 - максимальный период счета
	out OCR0, Acc0 // OCR0 - Регистр сравнения
	ldi Acc0, (1<<TOIE0) // разрешить прерывание по переполнению
	out TIMSK, Acc0 // записать в регистр разрешения прерываний

	// Настройка usart
	ldi Acc0, HIGH(BAUD)
	out UBRRH,Acc0 
	ldi Acc0, LOW(BAUD) 
	out UBRRL,Acc0
	ldi Acc0, (1<<TXEN) | (1<<RXEN) | (1<<RXCIE) | (1<<TXCIE) // эти биты разрешают прерывания
	out UCSRB, Acc0 
	ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1)

	// настройка АЦП adc
	// ADLAR - выравнивание по левому краю (важны старшие биты), 
	// MUX0 - комбинация аналоговых входов 00000, можно задать определенный канал
	// REFS0 - установить опорное напряжение
	ldi Acc0, (0x0<<REFS0) | (1<<ADLAR) | (0x0<<MUX0) 
	out ADMUX, Acc0

	// ADEN - включить АЦП
	// ADSC - начать преобразование
	// ADATE - автоматический запуск преобразования
	// ADIE - разрешить прерывания
	// ADPS0 - точность оцифровки, ставим 128 (выбирать в диапазоне: такт. частота проц./мин и макс частота)
	ldi Acc0, (1<<ADEN) | (0<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0) // 0x7 - 111 в младших разрядах
	out ADCSRA, Acc0
	
	// Чтение / модификация / запись
	//Переписать эту часть, не работает
	//in Acc0, SFIOR
	//andi Acc0, ~(0x3<<ADTS0) // andi - побитовое И с константой, обработать только старшие 3 бита (переполнение по таймеру счетчика 100)
	//ori Acc0, (0x0<<ADTS0) // ori - логическое ИЛИ
	ldi Acc0, (0x4<<ADTS0)
	out SFIOR, Acc0

	ldi Acc0, (1<<ADEN) | (1<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0)
	out ADCSRA, Acc0

	ldi TactCount, 0
	ldi LineCount, 0
	ldi Razr1, 0
	ldi Razr2, 0
	ldi Razr3, 0
	ldi Number, 0
	ldi NumDecCount, 0


// Interrupt Enable
sei


// Main programm
loop:
	// LED ON
	sbi PORTB, LED
	// Delay
	rcall Delay // вызов подпрограммы
	// LED OFF
	cbi PORTB, LED
	// Delay
	rcall Delay
	rjmp loop


// Subprogramm
Delay:
	nop
	nop
	
	ret // выход из подпрограммы

PrintEndLine:
	ldi ZL, LOW(DataByte*2) // LOW - взять младший байт слова, 2 - 2 байта в памяти, кажд адрес содержит 2 байта (0x100 * 2 = 0x200)
	ldi ZH, HIGH(DataByte*2) // HIGH - взять старший байт слова
	add ZL, SymbolCount
	lpm Acc0, Z
	out UDR, Acc0
	inc SymbolCount

	ret

GetRazr: // считаем десятки
	add Acc1, Acc0
	cp Acc1, Number
	brlo GR_continue // перейти, если меньше
	rjmp GR_razr3

GR_continue:
	inc NumDecCount
	rjmp GetRazr

GR_razr2: // определить количество десятков
	ldi Acc0, 10
	mov Acc1, NumDecCount
	mul  Acc1, Acc0
	cpi Acc1, 100
	brsh GR_razr1
	mov Razr2, NumDecCount
	ldi Acc0, AsciiCode
	add Razr2, Acc0
	add Razr1, Acc0
	rjmp GR_stop


GR_razr1: // определить количество сотен
	

GR_razr3: // определить количество единиц
	sub Acc1, Number
	ldi Acc0, 10
	sub Acc0, Acc1
	
	add Razr3, Acc0
	ldi Acc0, AsciiCode
	add Razr3, Acc0

	cpi NumDecCount, 1 // десятки есть
	brsh GR_razr2 // такое же либо больше
	rjmp GR_stop

GR_stop:
	ret


// Обработка прерываний
ADC_CON:
	push Acc0 // Положить в регистр
	push Acc1
	in Acc0, SREG
	push Acc0
	in Acc0, UCSRA
	sbrs Acc0, UDRE // анализируем 5 бит регистра UCSRA
	rjmp END_ADC

	in Acc1, ADCL // всегда считываем первым, чтоб не глючило
	in Number, ADCH
	
	ldi Acc0, 10 // для подсчета количества десятков
	ldi Acc1, 0 // 1 для умножения

	ldi NumDecCount, 0
	ldi Razr1, 0
	ldi Razr2, 0
	ldi Razr3, 0

	rcall GetRazr
	out UDR, Razr1 // Печать 1 разряда

END_ADC:
	pop Acc0
	out SREG, Acc0
	pop Acc1 // Восстановить из регистра
	pop Acc0

reti // Возврат из прерывания


TIM0_OVF:
	push Acc0
	push Acc1
	in Acc0, SREG // сохраняем статусный регистр
	push Acc0
	rjmp TO0_0
	
TO0_0:
	inc TactCount
	cpi TactCount, 2 // сравниваем регистр с 4 (т.к. 1 такт = 1/сек.)
	brne TO0_1
	ldi TactCount, 0

TO0_1:
	pop Acc0
	out SREG, Acc0
	pop Acc1
	pop Acc0

reti // окончание прерывания


USART_TXC: // передача выполнена
	sbis UCSRA, UDRE // UDRE - бит входа в прерывание
	rjmp USART_TXC
	inc LineCount
	cpi LineCount, 1
	breq UT_print2
	cpi LineCount, 2
	breq UT_print3

	cpi LineCount, 5
	breq UT_clear
	rcall PrintEndLine
	rjmp UT_stop

UT_print2:
	out UDR, Razr2 // Печать 2 разряда
	rjmp UT_stop

UT_print3:
	out UDR, Razr3 // Печать 3 разряда
	rjmp UT_stop

UT_clear:
	ldi LineCount, 0
	ldi SymbolCount, 0
UT_stop:
reti


// Data
DataByte:
.DB 0x0A, 0x0D // перенос строки и возврат каретки
DataWord:
.DW 0x1234, 0x5678 // Сохранение слов
