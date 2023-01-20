// подключаем файл инициализации
.include "m8535def.inc"

// инициализация констант
.equ max_sec = 60
.equ LED = 3
.equ TX = 1 

// инициализация регистров 
.def Acc0 = R16
.def Acc1 = R17
.def TactCount = R18


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
//	rjmp USART_TXC ; USART TX Complete Handler
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

	// Настройка usart
	ldi Acc0, (1<<U2X) 
	out UCSRA, Acc0 
	ldi Acc0, (1<<TXEN) | (1<<RXEN) //| (1<<UDRIE) -- прерывание
	out UCSRB, Acc0 
	ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1)
	out UCSRC,Acc0 
	ldi Acc0, 0 
	out UBRRH,Acc0 
	ldi Acc0, 12 
	out UBRRL,Acc0 
	sbi DDRD, TX

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
	//in Acc0, SFIOR
	//andi Acc0, ~(0x3<<ADTS0) // andi - побитовое И с константой, обработать только старшие 3 бита (переполнение по таймеру счетчика 100)
	//ori Acc0, (0x0<<ADTS0) // ori - логическое ИЛИ
	ldi Acc0, (0x4<<ADTS0)
	out SFIOR, Acc0

	ldi Acc0, (1<<ADEN) | (1<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0)
	out ADCSRA, Acc0

	ldi TactCount, 0


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
	in Acc0, ADCH
	out UDR, Acc0 // UDR - регистр отвечает за данные uart

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
	cpi TactCount, 4 // сравниваем регистр с 4 (т.к. 1 такт = 1/сек.)
	brne TO0_1

TO0_clear:
	ldi TactCount, 0

TO0_1:
	pop Acc0
	out SREG, Acc0
	pop Acc1
	pop Acc0
	reti // окончание прерывания


// Data
DataByte:
.DB 0x1f, 0x1C // Сохранение данных (адресов)
DataWord:
.DW 0x1234, 0x5678 // Сохранение слов
