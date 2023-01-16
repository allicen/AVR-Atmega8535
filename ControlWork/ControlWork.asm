//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3
.equ CLK = 0
.equ DATA = 1
.equ Num = 0 // Нажатое число

//init registers 
.def Acc0 = R16
.def Acc1 = R17
.def Acc2 = R18
.def numkey = R19 // номер клавиши
.def MASK = R20 // маска для поиска нажатой кнопки
.def AccNum = R22 // Регистр для числа


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
	ldi Acc0, 0b11110000|(1<<LED) // настроить на выход для всех устройств (включая светодиод)
	out DDRB, Acc0 // ddr направление порта
	
	sbi DDRC, CLK // установить бит в 0 регистр, настроено на выход
	sbi DDRC, DATA // установить бит в 1 регистр, настроено на выход
//Interrupt Enable
//	sei
//Main programm
rcall Init

rjmp loop
L1:
    ldi Acc0, 0xff // залить поля слева от числа
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	ldi Acc2,20
	ldi ZL, LOW(DataByte*2-1) // LOW - взять младший байт слова, 2 - 2 байта в памяти, кажд адрес содержит 2 байта (0x100 * 2 = 0x200)
	ldi ZH, HIGH(DataByte*2) // HIGH - взять старший байт слова
	add ZL, numkey // сложение
	lpm Acc0, Z	// загрузить в память программы
	rcall SevSeg

E1:	dec Acc2
	rcall Delay // задержка
	cpi Acc2,0 // если Acc2=0, зауиклить E1
	brne E1

loop:
	rcall Key 	
	cpi numkey, 0 // если кнопка не нажата	
	breq loop // если не нажата, уйти в loop
	rjmp L1 // если нажата, установить значение
	
//SubProgamm
Init:
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xff
	rcall SevSeg
	ldi Acc0, 0xC0 // инициализировать только 0 справа
	rcall SevSeg
	ret

//Keyboard
//OUT: numkey - number of push key, if keyboard free -> numkey = 0
Key:
//reg mask
	ldi MASK, 0b11101111 // маска для бегущего нуля
	clr numkey // проинициализировать numkey 0
	ldi Acc2, 0x3 // инициализирует Acc2 3

//set portB
//считать, модифицировать и записать

K1: // Блок для считывания/записи с/в порт
	ori MASK, 0x1 // младший бит в 1
	in Acc0, PORTB // считать данные из PORTB
	ori Acc0, 0b11110000 // ori - логичнское побитовое И с константой, ставим 4 старших бита в 1 и накладываем маску
	and Acc0, MASK  // наложение маски
	out PORTB, Acc0 // записать результат в порт

	//read column portD
	nop // выставляем задержку, чтобы успеть считать установленные данные
	nop
	in Acc0, PIND // считать PIND
	//analys in data
	ldi Acc1, 0x3 // 3 раза будем сдвигать влево

ankey: // Блок анализирует нажатие кнопки
//if key push to ret
//else <<mask and rjmp K1	
	lsl Acc0 // сдвиг влево
	brcc pushkey // если 0, то уйти в pushkey, если 1 - идти дальше
	dec Acc1 // декремент
	brne ankey // если не 0, то уйти в ankey, иначе идти дальше
	//numkey+3
	add numkey, Acc2

	lsl MASK
	brcs K1 // если флаг С=1, уйти в K1
	clr numkey // ни одна клавиша не была нажата = обнулить numkey
	rjmp endkey

pushkey:
	add numkey, Acc1

endkey:
	ret

// 
SetNum:
	



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
	ldi R21, 255
delay1: ldi R20, 255
delay2: dec R20
	brne delay2
	dec R21
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

//Data Коды для цифр семисегментного индикатора
DataByte:
.DB 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8, 0x80, 0x90
DataWord:
.DW 0x1234, 0x5678
