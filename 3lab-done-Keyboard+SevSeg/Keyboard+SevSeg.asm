//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3
.equ CLK = 0
.equ DATA = 1
//init registers 
.def Acc0 = R16
.def Acc1 = R17
.def Acc2 = R18
.def numkey = R19
.def MASK = R20


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
.org 0x15
RESET:
//init stack pointer
	ldi Acc0, LOW(RAMEND)
	out SPL, Acc0
	ldi Acc0, HIGH(RAMEND)	
	out SPH, Acc0
//init SFR (special function reg)
	ldi Acc0, 0b11110000|(1<<LED)
	out DDRB, Acc0 // ddr направление порта
	
	sbi DDRC, CLK // установить бит в 0 регистр, настроено на выход
	sbi DDRC, DATA // установить бит в 1 регистр, настроено на выход
//Interrupt Enable
//	sei
//Main programm

rjmp loop
L1:
	ldi r18,20 
	ldi ZL, low(DataByte*2-1)
	ldi ZH, high(DataByte*2)
	add ZL, numkey
	lpm Acc0, Z	
	rcall SevSeg
E1:	dec r18
	rcall Delay
	cpi r18,0
	brne E1


loop:
	rcall Key 	
	cpi numkey, 0	
	breq loop 	
	rjmp L1
	
//SubProgamm
//Keyboard
//OUT: numkey - number of push key, if keyboard free -> numkey = 0 
Key:
//reg mask
	ldi MASK, 0b11101111 // маска для бегущего нуля
	clr numkey
	ldi Acc2, 0x3
//set portB
//считать, модифицировать и записать
K1:
	ORI MASK, 0x1
	in Acc0, PORTB
	ORI Acc0, 0b11110000 // ori - логичнское И с константой
	AND Acc0, MASK
	out PORTB, Acc0
	//read column portD
	nop
	nop
	in Acc0, PIND
	//analys in data
	ldi Acc1, 0x3
ankey:
//if key push to ret
//else <<mask and rjmp K1	
	LSL Acc0
	BRCC pushkey
	dec Acc1
	BRNE ankey
	//numkey+3
	add numkey, Acc2

	LSL MASK
	BRCS K1
	clr numkey
	rjmp endkey
pushkey:
	ADD numkey, Acc1
endkey:
	ret



//Seven Segment
//IN: Acc0 <- Data for Segment
SevSeg:
ldi Acc1, 8 // нужно вывести 8 битов для каждлого числа
SS0:
// set data
lsl Acc0 // сдвиг слево, в бит С
brcc SS1 // если флаг 0, то перейти на метку SS1
sbi PORTC, DATA // на линию данных установить 1
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


//Delay
Delay:
         ldi r21, 255
 delay1: ldi r20, 255
 delay2: dec r20
         brne delay2
         dec r21
         brne delay1
 ret


//Interrupt Routines
EXT_INT0:
	push Acc0
	push Acc1
	in Acc0, SREG
	push Acc0


	pop Acc0
	out SREG, Acc0
	pop Acc1
	pop Acc0

	reti

//Data Записал коды для цифр семисегментного индикатора
DataByte:
.DB 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8, 0x80, 0x90
DataWord:
.DW 0x1234, 0x5678
