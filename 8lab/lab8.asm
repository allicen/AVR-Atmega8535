// Serial Peripheral Interface � SPI

//include init file
.include "m8535def.inc"

.dseg // ���������� ������� � ������� ���������� ������ ������
MEMO:
.byte 8 // ������ 8 ���� ����������� ������

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
.cseg // ���������� ������� � ������� ������ ��������
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

ldi Acc0, (1<<SS)|(1<<MOSI)|(0<<MISO)|(1<<SCK) // 0 - ����, 1 - �����
out DDRB, Acc0
sbi PORTB, 4 // ����� SS �� +5 (���������� � ������ ��������, �������� ��������, ����� ��������� � 0)
sbi PORTB, 6

ldi Acc0, (1<<SPIE)|(1<<SPE)|(0<<DORD)|(1<<MSTR)|(0<<CPOL)|(0<<CPHA)|(0<<SPR1)|(1<<SPR0) // ��������� ���������� � ��������;
out SPCR, Acc0 // MSTR = 1 ������� ��� �� ��������� ��������, SPR = 01 ������������ SPI


// ��������� ����������
sei

// ���������� � ���������� �����
// ���������� ����� spi �� ����������
// ��������� ������� � ����������� ������ ����� spi
loop:
	// ������ �� ������� ����������
	ldi Acc1, 0 // ������� ��� ����������
	ldi Acc2, 0 // 0 - �������� ������, 1 - ������
	sbi PORTB, 4 // SS �� +5
	cbi PORTB, 4 // ����� = ������ ������ � �����������
	ldi Acc0, (1<<SPDR1)|(1<<SPDR2)// ���������� �� ������
	out SPDR, Acc0 // SPDR - ������� ������-�������� ������
	rcall delay

	// ������ �� ���������� � ��� ����
	ldi Acc1, 0 // ������� ��� ����������
	ldi Acc2, 1 // 1 - ��� �������� ������
	ldi XH, HIGH(MEMO) // ������ ��������� �� 1 ������ MEMO ����� ������� ��������� ���������
	ldi XL, LOW(MEMO)
	sbi PORTB, 4 // SS �� +5
	cbi PORTB, 4 // SS �� �����, ������ �������� � �����������
	ldi Acc0, (1<<SPDR0)|(1<<SPDR1) // ���������� �� ������
	out SPDR, Acc0
	rcall delay
rjmp loop


SPI_STC:
	sbis SPSR, SPIF
	rjmp SPI_STC

	cpi Acc2, 0
	breq SS_WriteSPI // 0 - �������� ������
	cpi Acc2, 1
	breq SS_ReadSPI // 1 - �������� ������
	
	rjmp SS_stop

// �������� ������
SS_WriteSPI: 
	inc Acc1
	cpi Acc1, 1
	breq SS_WriteSPIWR // �������, ���� ��������� ������ � ����������
	cpi Acc1, 2
	breq SS_WriteSPIADR // �������, ��� �������� ������ ��� ������ � ����������

	// ���������� ����� ��� ������ � ������ (10 ��)
	cpi Acc1, 10
	breq SS_RESET
	inc count // count - ������������ ������, ��� ������ � ������
	out SPDR, count // �������� �� SPI
	rjmp SS_stop


SS_WriteSPIWR:
	sbi PORTB, 4 // ������������ ����� SS, ������ ��� �� +5 � ��������� �� ����� (������ ��� �������� ������)
	cbi PORTB, 4
	ldi Acc0, (1<<SPDR1)
	out SPDR, Acc0 // ������� ������ ��������� �� SPI
	rjmp SS_stop


SS_WriteSPIADR:
	ldi Acc0, 0x00
	out SPDR, Acc0
	rjmp SS_stop


SS_RESET:
	sbi PORTB, 4 // SS �� +5
	rjmp SS_stop


// �������� ������
SS_ReadSPI: 
	inc Acc1
	cpi Acc1, 1
	breq SS_ReadSPIADR // �������, ����� �������� ������� �� ������
	cpi Acc1, 2
	breq SS_ReadSPI2 // �������, ����� ��������� �� SPI ����� ������
	cpi Acc1, 10
	breq SS_RESET // ����� ��������
	in Acc0, SPDR // ������� ��������� ������
	st X+, Acc0 // ������ � ��� ���� ����� ��������� ���������
	ldi Acc0, 0xFF // ��� ������ ������ ��������� ����� ����
	out SPDR,Acc0
	rjmp SS_stop


SS_ReadSPIADR:
	ldi Acc0, 0x00 // ����� ����� ���������
	out SPDR, Acc0 // �������� �� SPI
	rjmp SS_stop


SS_ReadSPI2:
	ldi Acc0, 0xFF // ��������� ����� ����
	out SPDR,Acc0 // � ����� ����� �������� � ���������� ������ �����
	rjmp SS_stop

SS_stop: 
reti


Delay: // �������� ~2 ���
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
