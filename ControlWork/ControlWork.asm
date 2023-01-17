//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3
.equ DATA = 1
.equ CLK = 0

//init registers 
.def Acc0 = R16
.def Acc1 = R17
.def Acc2 = R18
.def TactCount = R20
.def DBCount = R22

//PROGRAMM
//interrupt vectors
.org 0x0
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
//	rjmp ADC ; ADC Conversion Complete Handler
//	rjmp EE_RDY ; EEPROM Ready Handler
//	rjmp ANA_COMP ; Analog Comparator Handler
//	rjmp TWSI ; Two-wire Serial Interface Handler
//	rjmp EXT_INT2 ; IRQ2 Handler
//	rjmp TIM0_COMP ; Timer0 Compare Handler
//	rjmp SPM_RDY ; Store Program Memory Ready Handler
.org 0x15
RESET:
//init stack pointer
	ldi Acc0, LOW(RAMEND)
	out SPL, Acc0
	ldi Acc0, HIGH(RAMEND)	
	out SPH, Acc0
//init SFR (special function reg)
	sbi DDRC, CLK // установить бит в 0 регистр, настроено на выход
	sbi DDRC, DATA // установить бит в 1 регистр, настроено на выход
	sbi DDRB, LED 
	// настроить на выход для всех устройств
	// WGM01 - настройка ctc в 1
	// WGM00 - настройка ctc в 0
	ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00) // CS00 - частота/1024 (стр 84)
	out TCCR0, Acc0 // запись в регистр спец назначения для настройки таймера
	ldi Acc0, 0xFF // 255 - максимальный период счета
	out OCR0, Acc0 // OCR0 - Регистр сравнения

	ldi Acc0, (1<<TOIE0) // разрешить прерывание по переполнению
	out TIMSK, Acc0 // записать в регистр разрешения прерываний
	ldi TactCount, 0 
	sbi PORTB, LED // на линию светодиода установить 1
	ldi DBCount, 0

//Interrupt Enable 
	sei // разрешить прерывания
//Main programm
loop:
	rjmp loop
	
//SubProgamm

// Семисегментный индикатор
SevSeg:
	ldi Acc1, 8

SS0:
	lsl Acc0
	brcc SS1
	sbi PORTC, DATA
	rjmp SS2

SS1:
	cbi PORTC, DATA

SS2:
	// taсt
	nop
	nop
	sbi PORTC, CLK // установить бит
	nop
	nop
	cbi PORTC, CLK // сбросить бит
	// dec CNT
	dec Acc1 // декремент
	// test CNT
	brne SS0 // переходить в SS0, пока флаг 0 не будет установлен

ret

// запись значений на индикаторы
CountSevSeg:
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	cpi DBCount, 10
	brne C0 // переходить в C0, пока флаг 0 не будет установлен
	ldi DBCount, 0
C0:
	ldi ZL, LOW(DataByte*2)
	ldi ZH, HIGH(DataByte*2)
	add ZL, DBCount
	lpm Acc0, Z
	rcall SevSeg
	inc DBCount
ret


//Interrupt Routines
TIM0_OVF: // название берется из вектора прерывания
	push Acc0
	push Acc1
	in Acc0, SREG // сохраняем статусный регистр
	push Acc0

	rjmp TO0_0
	
TO0_0:
	inc TactCount
	cpi TactCount, 4 // сравниваем регистр с 4 (т.к. 1 такт = 1/сек.)
	brne TO0_1
	ldi TactCount, 0
	rcall CountSevSeg // записать значения на индикаторы

TO0_1:
	pop Acc0
	out SREG, Acc0
	pop Acc1
	pop Acc0
	reti // окончание прерывания

//Data
DataByte:
.DB 0x90, 0x80, 0xf8, 0x82, 0x92, 0x99, 0xb0, 0xa4, 0xf9, 0xC0
DataWord:
.DW 0x1234, 0x5678
