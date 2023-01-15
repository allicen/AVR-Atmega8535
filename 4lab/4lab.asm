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
.org 0x009
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
	sbi DDRB, LED
	ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00)
	out TCCR0, Acc0
	ldi Acc0, 0xFF
	out OCR0, Acc0

	ldi Acc0, (1<<TOIE0)
	out TIMSK, Acc0
	ldi R20, 0
	sbi PORTB, LED
	ldi R22, 0

//Interrupt Enable 
	sei
//Main programm
loop:
	//LED ON

	rjmp loop
	
//SubProgamm
Delay:
	nop
	nop

	ret

// Семисегментный индикатор
SevSeg:
	ldi Acc1, 0

SS0:
	lsl Acc0
	brcc SS1
	sbi PORTC, DATA

SS1:
	cbi PORTC, DATA

SS2:


CountSevSeg:
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	cpi R22, 10
	brne C0
	ldi R22, 0
C0:
	ldi ZL, LOW(DataByte*2)
	ldi ZH, HIGH(DataByte*2)
	add ZL, R22
	lpm Acc0, Z
	rcall SevSeg
	inc R22
ret



//Interrupt Routines
TIM0_OVF:
	push Acc0
	push Acc1
	
	sbis PORTB, LED
	rjmp TO0_0
	cbi PORTB, LED
	rjmp TO0_1
	
TO0_0:
	sbi PORTB, LED 

TO0_1:
	pop Acc1
	pop Acc0
	reti

//Data
DataByte:
.DB 0x1f, 0x1C
DataWord:
.DW 0x1234, 0x5678
