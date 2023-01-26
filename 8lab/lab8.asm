// SPI

//include init file
.include "m8535def.inc"

.dseg
MEMO:
.byte 7

//init constant
.equ max_sec = 60
.equ LED = 3
.equ TX = 1
.equ SS = 4
.equ MOSI = 5
.equ MISO = 6
.equ SCK = 7

//init registers
.def Acc0 = r16
.def Acc1 = r20
.def Acc2 = r21
.def delay1 = r17
.def delay2 = r18
.def delay3 = r19
.def count = r22


//PROGRAMM
//interrupt vectors
.cseg
.org 0x0
rjmp RESET ; Reset Handler
reti ;rjmp EXT_INT0 ; IRQ0 Handler
reti ;rjmp EXT_INT1 ; IRQ1 Handler
reti ;rjmp TIM2_COMP ; Timer2 Compare Handler
reti ;rjmp TIM2_OVF ; Timer2 Overflow Handler
reti ;rjmp TIM1_CAPT ; Timer1 Capture Handler
reti ;rjmp TIM1_COMPA ; Timer1 Compare A Handler
reti ;rjmp TIM1_COMPB ; Timer1 Compare B Handler
reti ;rjmp TIM1_OVF ; Timer1 Overflow Handler
reti ;rjmp TIM0_OVF ; T SPI_STC ; SPI Timer0 Overflow Handler
rjmp SPI_STC; ansfer Complete Handler
reti ;rjmp USART_RXC ; USART RX Complete Handler
reti ;rjmp USART_UDRE ; UDR Empty Handler
reti ;rjmp USART_TXC ; USART TX Complete Handler
reti ;rjmp ADC ; ADC Conversion Complete Handler
reti ;rjmp EE_RDY ; EEPROM Ready Handler
reti ;rjmp ANA_COMP ; Analog Comparator Handler
reti ;rjmp TWSI ; Two-wire Serial Interface Handler
reti ;rjmp EXT_INT2 ; IRQ2 Handler
reti ;rjmp TIM0_COMP ; Timer0 Compare Handler
reti ;rjmp SPM_RDY
.org 0x15
RESET:

//init stack pointer
ldi Acc0, HIGH(RAMEND)
out SPH, Acc0
ldi Acc0, LOW(RAMEND)
out SPL, Acc0

//init SFR (special function reg)

ldi Acc0, (1<<SS)|(1<<MOSI)|(0<<MISO)|(1<<SCK) // 0 - вход, 1 - выход
out DDRB, Acc0
sbi PORTB, 4 // Вывод SS на +5
sbi PORTB, 6 // На MISO подключаем подтягивающий резистор 

ldi Acc0, 0b11010001 //(1<<SPIE)|(1<<SPE)|(0<<DORD)|(1<<DORD)|(1<<MSTR)|(0<<CPOL)|(0<<CPHA)|(0b00<<SPR0) // Разрешить прерывания и протокол;
out SPCR, Acc0 // MSTR = 1 говорит что мы руководим посылкой, SPR = 01 предделитель SPI

ldi Acc0, (1<<SPI2X)
out SPSR, Acc0
ldi Acc0, 0
out SPDR, Acc0


// Разрешить прерывания
sei

loop:
	// Свперва запишем набор данных во внешнюю микросхему. Операция записи 
	ldi Acc1, 0 // sys = 0 это счетчик для прерывания
	ldi Acc2, 0 // try = 0 это для того, чтобы узнать, что сейчас операция записи
	sbi PORTB, 4 // Поднять SS на +5
	cbi PORTB, 4 // Опрокинуть SS на землю, т.е. начинаем работать с микросхемой
	ldi Acc0, 0b00000110 // Записываем разрешение на запись для начала(тех.док на микросхему)
	out SPDR, Acc0 // Отправляем в регистр отвечающий за прием/передачу данных
	rcall delay // Вызываем задержку в пару секунд

	// А тут почитаем из микросхемы в ОЗУ чипа. Операция чтения
	ldi Acc1, 0 // счетчик для прерывания
	ldi Acc2, 1 // 1 - это операция чтения
	ldi XH, HIGH(MEMO) // Запишем указатель на 1 ячейку MEMO через регистр косвенной адресации
	ldi XL, LOW(MEMO)
	sbi PORTB, 4 // Поднять SS на +5
	cbi PORTB, 4 // Опрокинуть SS на землю, т.е. начинаем работать с микросхемой
	ldi Acc0, 0b00000011 // Операция о том, что будем сейчас читать(тех.док на микросхему)
	out SPDR, Acc0 // Отправляем в регистр отвечающий за прием/передачу данных
	rcall delay
rjmp loop


SPI_STC:
	sbis SPSR, SPIF
	rjmp SPI_STC

	cpi Acc2, 0
	breq WriteSPI // 0 - операция записи
	cpi Acc2, 1
	breq ReadSPI // 1 - операция чтения
	SS_stop: 
reti


// Операции записи
WriteSPI: 
	inc Acc1 // Повышаем sys на 1
	cpi Acc1, 1
	breq WriteSPIWR // переход, если разрешена запись в микросхему
	cpi Acc1, 2
	breq WriteSPIADR // переход, для указания адреса для записи в микросхему
	cpi Acc1, 10
	breq STOP
	inc count // count - произвольные данные, для записи в память
	out SPDR, count // отправка на SPI
rjmp SS_stop


WriteSPIWR:
	sbi PORTB, 4 // перезагрузим вывод SS, подняв его на +5 и опрокинув на землю (только для операции записи)
	cbi PORTB, 4
	ldi Acc0, 0b00000010 
	out SPDR, Acc0 // команду записи отправить на SPI
rjmp SS_stop


WriteSPIADR:
	ldi Acc0, 0x00
	out SPDR, Acc0
rjmp SS_stop


STOP:
	sbi PORTB, 4 // SS на +5
rjmp SS_stop


// Операции чтения
ReadSPI: 
	inc Acc1
	cpi Acc1, 1
	breq ReadSPIADR // переход, когда отослали команду на чтение
	cpi Acc1, 2
	breq ReadSPI2 // переход, когда отправили на SPI адрес чтения
	cpi Acc1, 10
	breq STOP // конец передачи
	in Acc0, SPDR // считать пришедшие данные
	st X+, Acc0 // запись в ОЗУ чипа через косвенную адресацию
	ldi Acc0, 0xFF // для начала обмена отправить любой байт
	out SPDR,Acc0
rjmp SS_stop


ReadSPIADR:
	ldi Acc0, 0x00 // какой адрес считываем
	out SPDR, Acc0 // отправка на SPI
rjmp SS_stop


ReadSPI2:
	ldi Acc0, 0xFF // отправить любой байт
	out SPDR,Acc0 // в ответ будем получать с микросхемы нужные байты
rjmp SS_stop


Delay: // задержка ~2 сек
	ldi delay1, 255
	ldi delay2, 255
	ldi delay3, 100

	PDelay:
	dec delay1
	brne PDelay
	dec delay2
	brne PDelay
	dec delay3
	brne PDelay
ret
