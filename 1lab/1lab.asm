// подключаем файл инициализации
.include "m8535def.inc"

// инициализация констант
.equ max_sec = 60
.equ LED = 3;PORTB.3
.equ BTN1 = 2;PORTD.2
.equ BTN2 = 3;PORTD.3

// инициализация регистров 
.def Acc0 = R16
.def Acc1 = R17

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
//	rjmp ADC ; ADC Conversion Complete Handler
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
	cbi DDRD, BTN1 // настройка регистра на вход (можно было не писать)

// Interrupt Enable
// sei
// Main programm
loop:
	// 1 вариант
	sbis PIND, BTN1
	rjmp loop
//	rjmp Check_two_btn
	sbis PIND, BTN2
	rjmp loop
	// LED ON
	sbi PORTB, LED
	// Delay
	rcall Delay // вызов подпрограммы
	// LED OFF
	cbi PORTB, LED
	// Delay
	rcall Delay
	rjmp loop
	// 2 вариант
	// 1 BTN
	//in Acc0, PIND // Считать с пина
	//andi Acc0, 1<<BTN1 // Маскирование, побитовое И

	// 2 BTN
	//in Acc1, PIND
	//andi Acc1, 1<<BTN2

	// Исключающее ИЛИ
	//eor Acc0, Acc1
	//breq loop
	//rjmp Control_led
	

// Subprogramm
Delay:
	nop
	nop
	
	ret // выход из подпрограммы

Check_two_btn:
	sbis PIND, BTN2
	rjmp loop
	rjmp Control_led

Control_led:
	// LED ON
	sbi PORTB, LED
	// Delay
	rcall Delay // вызов подпрограммы
	// LED OFF
	cbi PORTB, LED
	// Delay
	rcall Delay
	rjmp loop

// Обработка прерываний
EXT_INTO:
	push Acc0 // Положить в регистр
	push Acc1
	pop Acc1 // Восстановить из регистра
	pop Acc0
	reti // Возврат из прерывания


// Data
DataByte:
.DB 0x1f, 0x1C // Сохранение данных (адресов)
DataWord:
.DW 0x1234, 0x5678 // Сохранение слов
