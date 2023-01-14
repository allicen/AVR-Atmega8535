////////// 2 lab

//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3

//init registers
.def Acc0 = R16
.def Acc1 = R17

//PROGRAMM
//interrupt vectors
.org 0x0
rjmp RESET ; Reset Handler
// rjmp EXT_INT0 ; IRQ0 Handler
// rjmp EXT_INT1 ; IRQ1 Handler
// rjmp TIM2_COMP ; Timer2 Compare Handler
// rjmp TIM2_OVF ; Timer2 Overflow Handler
// rjmp TIM1_CAPT ; Timer1 Capture Handler
// rjmp TIM1_COMPA ; Timer1 Compare A Handler
// rjmp TIM1_COMPB ; Timer1 Compare B Handler
// rjmp TIM1_OVF ; Timer1 Overflow Handler
// rjmp TIM0_OVF ; Timer0 Overflow Handler
// rjmp SPI_STC ; SPI Transfer Complete Handler
// rjmp USART_RXC ; USART RX Complete Handler
// rjmp USART_UDRE ; UDR Empty Handler
// rjmp USART_TXC ; USART TX Complete Handler
// rjmp ADC ; ADC Conversion Complete Handler
// rjmp EE_RDY ; EEPROM Ready Handler
// rjmp ANA_COMP ; Analog Comparator Handler
// rjmp TWSI ; Two-wire Serial Interface Handler
// rjmp EXT_INT2 ; IRQ2 Handler
// rjmp TIM0_COMP ; Timer0 Compare Handler
// rjmp SPM_RDY ; Store Program Memory Ready Handler
.org 0x15
RESET:
//init stack pointer
ldi Acc0, LOW(RAMEND) // RAMEND = 0x25F
out SPL, Acc0 // SPL - ���� ������� ��� �����
ldi Acc0, HIGH(RAMEND)
out SPH, Acc0 // SPH - ���� ������� ��� �����
//init SFR (special function reg)

//Interrupt Enable
// sei

//Main programm

ldi r18, 0x00 // �������� ��������� � �������
// X, Z - ��������� ��������, �������� ���������� - ��������� ���������
ldi ZL, LOW(DataByte*2) // LOW - ����� ������� ���� �����, 2 - 2 ����� � ������, ���� ����� �������� 2 ����� (0x100 * 2 = 0x200)
ldi ZH, HIGH(DataByte*2) // HIGH - ����� ������� ���� �����
// (1) ������ �� ������ 100
ldi XL, LOW(0x100)
ldi XH, HIGH(0x100)

///SRAM
// (1) ���������� ��� ����� �� ������� �� ������ 100
Write_SRAM:
	lpm R2,Z
	st X,R2 // ��������� ���������, R2 � X
	inc XL // ���������
	inc R18
	inc ZL
	cpi R18,10 // ��������� ��������
	brne Write_SRAM // Branch if Not Equal

///Flash Programm
ldi ZL, LOW(DataByte*2)
ldi ZH, HIGH(DataByte*2)

// (2) �������� � ������ 0x50
ldi R17, LOW(0x50)
ldi R18, HIGH(0x50)
ldi R20, 0x00
lpm // ��� ���������� - ����� �� Z � ������ � R0
	
// (2) �������� � ������ EEPROM
Write_EEpr:
	lpm R2,Z // ������ ��������, � ������� �������� �������� ������ Z
	mov R16,R2 // ����������� �� �������� � �������
	rcall EEPROM_write // ����� ������������
	inc R17 // ���������
	inc ZL
	inc R20
	cpi R20,10 // ��������� �������� � 10
	brne Write_EEpr
	ret

lpm // ��� ���������� - ����� �� Z � ������ � R0
///EEPROM DATA - ����������������� ������
lpm R2,Z // �������� ����������� ������
ldi R17, LOW(0x50)
ldi R18, HIGH(0x50)

rcall EEPROM_write // ����� ������������

//SubProgamm
// ��� �� ������������ 
EEPROM_write:
	; Wait for completion of previous write
	sbic EECR,EEWE // ���� ��������� ������, ������ ����� EEWE � �������� EECR
	rjmp EEPROM_write
	; Set up address (r18:r17) in address register
	out EEARH, r18
	out EEARL, r17
	; Write data (r16) to Data Register
	out EEDR,r16
	; Write logical one to EEMWE
	sbi EECR,EEMWE // ���������� � ������� �����-������ 1
	; Start eeprom write by setting EEWE
	sbi EECR,EEWE
	ret

// ��� �� ������������ 
EEPROM_read:
	; Wait for completion of previous write
	sbic EECR,EEWE
	rjmp EEPROM_read
	; Set up address (r18:r17) in Address Register
	out EEARH, r18
	out EEARL, r17
	; Start eeprom read by writing EERE
	sbi EECR,EERE
	; Read data from Data Register
	in r16,EEDR
	ret

Delay:
	nop
	nop
	ret // ����� �� ������������

//Interrupt Routines
EXT_INT0:
	push Acc0 // �������� � ����
	push Acc1

	pop Acc1 // ����� �� �����
	pop Acc0

	reti // ����� �� ����������

//Dat
.org 0x100 // DataByte ���������� �� ������ 0x100
DataByte:
.DB 0x1f, 0x1C, 0x6a, 0xe9, 0xbb, 0xc6, 0x11, 0xa5, 0x9d,0xee
DataWord:
.DW 0x1234, 0x5678
