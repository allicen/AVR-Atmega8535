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

ldi Acc0, (1<<SS)|(1<<MOSI)|(0<<MISO)|(1<<SCK) // 0 - ����, 1 - �����
out DDRB, Acc0
sbi PORTB, 4 // ����� SS �� +5
sbi PORTB, 6 // �� MISO ���������� ������������� �������� 

ldi Acc0, 0b11010001 //(1<<SPIE)|(1<<SPE)|(0<<DORD)|(1<<DORD)|(1<<MSTR)|(0<<CPOL)|(0<<CPHA)|(0b00<<SPR0) // ��������� ���������� � ��������;
out SPCR, Acc0 // MSTR = 1 ������� ��� �� ��������� ��������, SPR = 01 ������������ SPI

ldi Acc0, (1<<SPI2X)
out SPSR, Acc0
ldi Acc0, 0
out SPDR, Acc0


// ��������� ����������
sei

loop:
	// ������� ������� ����� ������ �� ������� ����������. �������� ������ 
	ldi Acc1, 0 // sys = 0 ��� ������� ��� ����������
	ldi Acc2, 0 // try = 0 ��� ��� ����, ����� ������, ��� ������ �������� ������
	sbi PORTB, 4 // ������� SS �� +5
	cbi PORTB, 4 // ���������� SS �� �����, �.�. �������� �������� � �����������
	ldi Acc0, 0b00000110 // ���������� ���������� �� ������ ��� ������(���.��� �� ����������)
	out SPDR, Acc0 // ���������� � ������� ���������� �� �����/�������� ������
	rcall delay // �������� �������� � ���� ������

	// � ��� �������� �� ���������� � ��� ����. �������� ������
	ldi Acc1, 0 // ������� ��� ����������
	ldi Acc2, 1 // 1 - ��� �������� ������
	ldi XH, HIGH(MEMO) // ������� ��������� �� 1 ������ MEMO ����� ������� ��������� ���������
	ldi XL, LOW(MEMO)
	sbi PORTB, 4 // ������� SS �� +5
	cbi PORTB, 4 // ���������� SS �� �����, �.�. �������� �������� � �����������
	ldi Acc0, 0b00000011 // �������� � ���, ��� ����� ������ ������(���.��� �� ����������)
	out SPDR, Acc0 // ���������� � ������� ���������� �� �����/�������� ������
	rcall delay
rjmp loop


SPI_STC:
	sbis SPSR, SPIF
	rjmp SPI_STC

	cpi Acc2, 0
	breq WriteSPI // 0 - �������� ������
	cpi Acc2, 1
	breq ReadSPI // 1 - �������� ������
	SS_stop: 
reti


// �������� ������
WriteSPI: 
	inc Acc1 // �������� sys �� 1
	cpi Acc1, 1
	breq WriteSPIWR // �������, ���� ��������� ������ � ����������
	cpi Acc1, 2
	breq WriteSPIADR // �������, ��� �������� ������ ��� ������ � ����������
	cpi Acc1, 10
	breq STOP
	inc count // count - ������������ ������, ��� ������ � ������
	out SPDR, count // �������� �� SPI
rjmp SS_stop


WriteSPIWR:
	sbi PORTB, 4 // ������������ ����� SS, ������ ��� �� +5 � ��������� �� ����� (������ ��� �������� ������)
	cbi PORTB, 4
	ldi Acc0, 0b00000010 
	out SPDR, Acc0 // ������� ������ ��������� �� SPI
rjmp SS_stop


WriteSPIADR:
	ldi Acc0, 0x00
	out SPDR, Acc0
rjmp SS_stop


STOP:
	sbi PORTB, 4 // SS �� +5
rjmp SS_stop


// �������� ������
ReadSPI: 
	inc Acc1
	cpi Acc1, 1
	breq ReadSPIADR // �������, ����� �������� ������� �� ������
	cpi Acc1, 2
	breq ReadSPI2 // �������, ����� ��������� �� SPI ����� ������
	cpi Acc1, 10
	breq STOP // ����� ��������
	in Acc0, SPDR // ������� ��������� ������
	st X+, Acc0 // ������ � ��� ���� ����� ��������� ���������
	ldi Acc0, 0xFF // ��� ������ ������ ��������� ����� ����
	out SPDR,Acc0
rjmp SS_stop


ReadSPIADR:
	ldi Acc0, 0x00 // ����� ����� ���������
	out SPDR, Acc0 // �������� �� SPI
rjmp SS_stop


ReadSPI2:
	ldi Acc0, 0xFF // ��������� ����� ����
	out SPDR,Acc0 // � ����� ����� �������� � ���������� ������ �����
rjmp SS_stop


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
