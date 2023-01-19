// подключаем файл инициализации
.include "m8535def.inc"

// инициализация констант
.equ max_sec = 60
.equ LED = 3
.equ TX = 1 

// инициализация регистров 
.def Acc0 = R16
.def Acc1 = R17
.def Second = R18
.def min = R19
.def hour = R20


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
//	rjmp TIM0_OVF ; Timer0 Overflow Handler
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

// инициализация регистров специального назначения
	sbi DDRB, LED

	// Настройка uart
	//init SFR (special function reg) 
	LdI Acc0, (1<<U2X) 
	out UCSRA, Acc0 
	LDI Acc0, (1<<TXEN) | (1<<RXEN) //| (1<<UDRIE) -- прерывание
	out UCSRB, Acc0 
	ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1)
	out UCSRC,Acc0 
	ldi Acc0, 0 
	out UBRRH,Acc0 
	ldi Acc0, 12 
	out UBRRL,Acc0 
	sbi DDRD, TX

	// настройка АЦП adc
	ldi Acc0, (0x0<<REFS0) | (1<<ADLAR) | (0x0<<MUX0)
	out ADMUX, Acc0
	ldi Acc0, (1<<ADEN) | (0<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0)
	out ADCSRA, Acc0
	
	in Acc0, SFIOR
	andi Acc0, ~(0x7<<ADTS0)
	ori Acc0, (0x0<<ADTS0)
	out SFIOR, Acc0


	ldi Acc0, (1<<ADEN) | (1<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0)
	out ADCSRA, Acc0


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
	sbrs Acc0, UDRE
	rjmp END_ADC
	in Acc0, ADCH
	out UDR, Acc0	

END_ADC:
	pop Acc0
	out SREG, Acc0
	pop Acc1 // Восстановить из регистра
	pop Acc0

		

	reti // Возврат из прерывания


// Data
DataByte:
.DB 0x1f, 0x1C // Сохранение данных (адресов)
DataWord:
.DW 0x1234, 0x5678 // Сохранение слов
