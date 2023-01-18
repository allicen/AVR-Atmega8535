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
.def numkey = R19 // ����� �������
.def numkeyTmp = R25 // ��������� ����� ������� ��� ��������� �������
.def MASK = R24 // ����� ��� ������ ������� ������
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
.org 0x009 // ����� ��� �������� TIM0_OVF �� ��������
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
	ldi Acc0, 0b11110000|(1<<LED) // ��������� �� ����� ��� ���� ��������� (������� ���������)
	out DDRB, Acc0 // ddr ����������� �����

	sbi DDRC, CLK // ���������� ��� � 0 �������, ��������� �� �����
	sbi DDRC, DATA // ���������� ��� � 1 �������, ��������� �� �����
	// ��������� �� ����� ��� ���� ���������
	// WGM01 - ��������� ctc � 1
	// WGM00 - ��������� ctc � 0
	ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00) // CS00 - �������/1024 (��� 84)
	out TCCR0, Acc0 // ������ � ������� ���� ���������� ��� ��������� �������


	ldi Acc0, 0xFF // 255 - ������������ ������ �����
	out OCR0, Acc0 // OCR0 - ������� ���������

	ldi Acc0, (1<<TOIE0) // ��������� ���������� �� ������������
	out TIMSK, Acc0 // �������� � ������� ���������� ����������
	clr numkey

	//clr numkeyTmp
	// ��������, ���� �����������������
	//ldi TactCount, 0 
	//ldi DBCount, 0
	//ldi Start, 0 // ���� ���� 1 - ��������, 0 - ��������

//Interrupt Enable 
	sei // ��������� ����������
//Main programm

rcall Init
rcall Init
rcall Init
rcall SetZero


loop:

	rcall Key 	
	cpi numkey, 0 // ���� ������ �� ������	
	breq loop // ���� �� ������, ���� � loop

L1:
	rcall Init
	rcall Init
	rcall Init
	ldi Acc2,20 
	ldi ZL, LOW(DataByte*2-1) // LOW - ����� ������� ���� �����, 2 - 2 ����� � ������, ���� ����� �������� 2 ����� (0x100 * 2 = 0x200)
	ldi ZH, HIGH(DataByte*2) // HIGH - ����� ������� ���� �����
	
	// ������� ������� � �����
	ldi Acc1, 10
	sub Acc1, numkey
	mov numkeyTmp, Acc1
	add ZL, Acc1 // ��������
	lpm Acc0, Z	// ��������� � ������ ���������
	rcall SevSeg

E1:	
	dec Acc2
	rcall Delay // ��������
	cpi Acc2,0 // ���� Acc2=0, ��������� E1
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
	ldi MASK, 0b11101111 // ����� ��� �������� ����
	clr numkey // ������������������� numkey 0
	ldi Acc2, 0x3 // �������������� Acc2 3

//set portB
//�������, �������������� � ��������

K1: // ���� ��� ����������/������ �/� ����
	ori MASK, 0x1 // ������� ��� � 1
	in Acc0, PORTB // ������� ������ �� PORTB
	ori Acc0, 0b11110000 // ori - ���������� ��������� � � ����������, ������ 4 ������� ���� � 1 � ����������� �����
	and Acc0, MASK  // ��������� �����
	out PORTB, Acc0 // �������� ��������� � ����

	//read column portD
	nop // ���������� ��������, ����� ������ ������� ������������� ������
	nop
	in Acc0, PIND // ������� PIND
	//analys in data
	ldi Acc1, 0x3 // 3 ���� ����� �������� �����

ankey: // ���� ����������� ������� ������
//if key push to ret
//else <<mask and rjmp K1	
	lsl Acc0 // ����� �����
	brcc pushkey // ���� 0, �� ���� � pushkey, ���� 1 - ���� ������
	dec Acc1 // ���������
	brne ankey // ���� �� 0, �� ���� � ankey, ����� ���� ������
	//numkey+3
	add numkey, Acc2

	lsl MASK
	brcs K1 // ���� ���� �=1, ���� � K1
	clr numkey // �� ���� ������� �� ���� ������ = �������� numkey
	rjmp endkey

pushkey:
	ldi Start, 1 // ��������� ���� ����
	add numkey, Acc1 // ������ ����� ������� ������
	sbi PORTB, LED // ��������� ���������
	ldi DBCount, 10

endkey:
	ret




// �������������� ���������
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
	// ta�t
	nop
	nop
	sbi PORTC, CLK // ���������� ���
	nop
	nop
	cbi PORTC, CLK // �������� ���
	// dec CNT
	dec Acc1 // ���������
	// test CNT
	brne SS0 // ���������� � SS0, ���� ���� 0 �� ����� ����������

ret

// ������ �������� �� ����������

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
	brne C0 // ���������� � C0, ���� ���� 0 �� ����� ����������
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
TIM0_OVF: // �������� ������� �� ������� ����������
	//rcall Delay
	push Acc0
	push Acc1
	in Acc0, SREG // ��������� ��������� �������
	push Acc0

	rjmp TO0_0
	
TO0_0:
	inc TactCount
	cpi TactCount, 4 // ���������� ������� � 4 (�.�. 1 ���� = 1/���.)
	brne TO0_1
	ldi TactCount, 0
	rcall CountSevSegInit // �������� �������� �� ����������

TO0_1:
	pop Acc0
	out SREG, Acc0
	pop Acc1
	pop Acc0
	reti // ��������� ����������

//Data
DataByte:
.DB 0x90, 0x80, 0xf8, 0x82, 0x92, 0x99, 0xb0, 0xa4, 0xf9, 0xC0
DataWord:
.DW 0x1234, 0x5678
