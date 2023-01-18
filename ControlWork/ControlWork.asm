//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3
.equ DATA = 1
.equ CLK = 0
.equ Zero = 0xC0

//init registers 
.def Acc0 = R16
.def Acc1 = R17
.def Acc2 = R18
.def numkey = R19 // номер клавиши
.def numkeyTmp = R25 // сохранить номер клавиши для обратного отсчета
.def MASK = R24 // маска для поиска нажатой кнопки
.def TactCount = R20
.def DBCount = R22
.def Start = R23

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
	ldi Acc0, 0b11110000|(1<<LED) // настроить на выход для всех устройств (включая светодиод)
	out DDRB, Acc0 // ddr направление порта

	sbi DDRC, CLK // установить бит в 0 регистр, настроено на выход
	sbi DDRC, DATA // установить бит в 1 регистр, настроено на выход
	// настроить на выход для всех устройств
	// WGM01 - настройка ctc в 1
	// WGM00 - настройка ctc в 0
	ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00) // CS00 - частота/1024 (стр 84)
	out TCCR0, Acc0 // запись в регистр спец назначения для настройки таймера


	ldi Acc0, 0xFF // 255 - максимальный период счета
	out OCR0, Acc0 // OCR0 - Регистр сравнения

	ldi Acc0, (1<<TOIE0) // разрешить прерывание по переполнению
	out TIMSK, Acc0 // записать в регистр разрешения прерываний
	clr numkey

	//clr numkeyTmp
	// ломается, если раскомментировать
	//ldi TactCount, 0 
	//ldi DBCount, 0
	//ldi Start, 0 // Счет вниз 1 - разрешен, 0 - запрещен

//Interrupt Enable 
	sei // разрешить прерывания
//Main programm

rcall Init
rcall Init
rcall Init
rcall SetZero


loop:

	rcall Key 	
	cpi numkey, 0 // если кнопка не нажата	
	breq loop // если не нажата, уйти в loop

L1:
	rcall Init
	rcall Init
	rcall Init
	ldi Acc2,20 
	ldi ZL, LOW(DataByte*2-1) // LOW - взять младший байт слова, 2 - 2 байта в памяти, кажд адрес содержит 2 байта (0x100 * 2 = 0x200)
	ldi ZH, HIGH(DataByte*2) // HIGH - взять старший байт слова
	
	// Перебор массива с конца
	ldi Acc1, 10
	sub Acc1, numkey
	mov numkeyTmp, Acc1
	add ZL, Acc1 // сложение
	lpm Acc0, Z	// загрузить в память программы
	rcall SevSeg

E1:	
	dec Acc2
	rcall Delay // задержка
	cpi Acc2,0 // если Acc2=0, зауиклить E1
	brne E1



//SubProgamm
//Delay

Delay:
	ldi R21, 255
delay1: ldi R20, 255
delay2: dec R20
	brne delay2
	dec R21
	brne delay1
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
	ldi Start, 1 // Разрешить счет вниз
	add numkey, Acc1 // кладем номер нажатой кнопки
	sbi PORTB, LED // выключить светодиод
	ldi DBCount, 10

endkey:
	ret




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

CountSevSegInit:
	rcall Init
	rcall Init
	rcall Init
	cpi Start, 0
	brne CountSevSeg
	rcall SetZero
	ret

CountSevSeg:
	rcall Init
	rcall Init
	rcall Init
	cpi DBCount, 10
	brne C0 // переходить в C0, пока флаг 0 не будет установлен
	ldi DBCount, 0

C0:
	//add Acc1, DataByte*2

	ldi ZL, LOW(DataByte*2)
	ldi ZH, HIGH(DataByte*2)
	add ZL, DBCount
	add ZL, numkeyTmp
	lpm Acc0, Z
	mov Acc2, Acc0
	rcall SevSeg
	cpi Acc2, Zero
	brne C1_cont

	cbi PORTB, LED
	ldi Acc2, 0
	ldi Start, 0

C1_cont:
	cpi Start, 1
	brne C2_stop
	inc DBCount

C2_stop:
		
ret

Init:
	ldi Acc0, 0xff
	rcall SevSeg
ret

SetZero:
	cpi Start, 0
	brne SZ_end 
	ldi Acc0, Zero
	rcall SevSeg
SZ_end:
	//ldi ZL, LOW(DataByte*2)
	//ldi ZH, HIGH(DataByte*2)
	//add ZL, DBCount
	//add ZL, numkeyTmp
	//lpm Acc0, Z
	//rcall SevSeg
ret
	


//Interrupt Routines
TIM0_OVF: // название берется из вектора прерывания
	//rcall Delay
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
	rcall CountSevSegInit // записать значения на индикаторы

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
