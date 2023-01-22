// ���������� ���� �������������
.include "m8535def.inc"

// ������������� ��������
.equ max_sec = 60
.equ LED = 3
.equ TX = 1
.equ Bitrate = 9600 // 9600 ��� ����� 0.00768 �������/���
//����� Asynchronous Normal Mode
.equ BAUD = 8000000 / (16 * Bitrate) - 1 // 51! ������� � ��������, 8000000 - �������� ������� 8���
.equ AsciiCode = 48

// ������������� ��������� 
.def Acc0 = R16
.def Acc1 = R17
.def TactCount = R18
.def LineCount = R19
.def SymbolCount = R20
.def Razr1 = R21 // �����
.def Razr2 = R22 // �������
.def Razr3 = R23 // �������
.def Number = R25 // ����� �������
.def NumDecCount = R24 // ���������� ��������



// PROGRAMM

//interrupt vectors (������� ����������)
.org 0x0 /// ��������� �������� ������ � ������ ��������.
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
.org 0x00D
	rjmp USART_TXC ; USART TX Complete Handler
.org 0x00E
	rjmp ADC_CON ; ADC Conversion Complete Handler
//	rjmp EE_RDY ; EEPROM Ready Handler
//	rjmp ANA_COMP ; Analog Comparator Handler
//	rjmp TWSI ; Two-wire Serial Interface Handler
//	rjmp EXT_INT2 ; IRQ2 Handler
//	rjmp TIM0_COMP ; Timer0 Compare Handler
//	rjmp SPM_RDY ; Store Program Memory Ready Handler
.org 0x15 /// ������ ������� ���������

RESET:
	// ������������� �����
	ldi Acc0, LOW(RAMEND) /// RAMEND - ���� ����� ���
	out SPL, Acc0
	ldi Acc0, HIGH(RAMEND)
	out SPH, Acc0

	//init SFR (special function reg)
	sbi DDRB, LED

	// ��������� �������
	ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00) // CS00 - �������/1024 (��� 84)
	out TCCR0, Acc0 // ������ � ������� ���� ���������� ��� ��������� �������
	ldi Acc0, 0xFF // 255 - ������������ ������ �����
	out OCR0, Acc0 // OCR0 - ������� ���������
	ldi Acc0, (1<<TOIE0) // ��������� ���������� �� ������������
	out TIMSK, Acc0 // �������� � ������� ���������� ����������

	// ��������� usart
	ldi Acc0, HIGH(BAUD)
	out UBRRH,Acc0 
	ldi Acc0, LOW(BAUD) 
	out UBRRL,Acc0
	ldi Acc0, (1<<TXEN) | (1<<RXEN) | (1<<RXCIE) | (1<<TXCIE) // ��� ���� ��������� ����������
	out UCSRB, Acc0 
	ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1)

	// ��������� ��� adc
	// ADLAR - ������������ �� ������ ���� (����� ������� ����), 
	// MUX0 - ���������� ���������� ������ 00000, ����� ������ ������������ �����
	// REFS0 - ���������� ������� ����������
	ldi Acc0, (0x0<<REFS0) | (1<<ADLAR) | (0x0<<MUX0) 
	out ADMUX, Acc0

	// ADEN - �������� ���
	// ADSC - ������ ��������������
	// ADATE - �������������� ������ ��������������
	// ADIE - ��������� ����������
	// ADPS0 - �������� ���������, ������ 128 (�������� � ���������: ����. ������� ����./��� � ���� �������)
	ldi Acc0, (1<<ADEN) | (0<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0) // 0x7 - 111 � ������� ��������
	out ADCSRA, Acc0
	
	// ������ / ����������� / ������
	//���������� ��� �����, �� ��������
	//in Acc0, SFIOR
	//andi Acc0, ~(0x3<<ADTS0) // andi - ��������� � � ����������, ���������� ������ ������� 3 ���� (������������ �� ������� �������� 100)
	//ori Acc0, (0x0<<ADTS0) // ori - ���������� ���
	ldi Acc0, (0x4<<ADTS0)
	out SFIOR, Acc0

	ldi Acc0, (1<<ADEN) | (1<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0)
	out ADCSRA, Acc0

	ldi TactCount, 0
	ldi LineCount, 0
	ldi Razr1, 0
	ldi Razr2, 0
	ldi Razr3, 0
	ldi Number, 0
	ldi NumDecCount, 0


// Interrupt Enable
sei


// Main programm
loop:
	// LED ON
	sbi PORTB, LED
	// Delay
	rcall Delay // ����� ������������
	// LED OFF
	cbi PORTB, LED
	// Delay
	rcall Delay
	rjmp loop


// Subprogramm
Delay:
	nop
	nop
	
	ret // ����� �� ������������

PrintEndLine:
	ldi ZL, LOW(DataByte*2) // LOW - ����� ������� ���� �����, 2 - 2 ����� � ������, ���� ����� �������� 2 ����� (0x100 * 2 = 0x200)
	ldi ZH, HIGH(DataByte*2) // HIGH - ����� ������� ���� �����
	add ZL, SymbolCount
	lpm Acc0, Z
	out UDR, Acc0
	inc SymbolCount

	ret

GetRazr: // ������� �������
	add Acc1, Acc0
	cp Acc1, Number
	brlo GR_continue // �������, ���� ������
	rjmp GR_razr3

GR_continue:
	inc NumDecCount
	rjmp GetRazr

GR_razr2: // ���������� ���������� ��������
	ldi Acc0, 10
	mov Acc1, NumDecCount
	mul  Acc1, Acc0
	cpi Acc1, 100
	brsh GR_razr1
	mov Razr2, NumDecCount
	ldi Acc0, AsciiCode
	add Razr2, Acc0
	add Razr1, Acc0
	rjmp GR_stop


GR_razr1: // ���������� ���������� �����
	

GR_razr3: // ���������� ���������� ������
	sub Acc1, Number
	ldi Acc0, 10
	sub Acc0, Acc1
	
	add Razr3, Acc0
	ldi Acc0, AsciiCode
	add Razr3, Acc0

	cpi NumDecCount, 1 // ������� ����
	brsh GR_razr2 // ����� �� ���� ������
	rjmp GR_stop

GR_stop:
	ret


// ��������� ����������
ADC_CON:
	push Acc0 // �������� � �������
	push Acc1
	in Acc0, SREG
	push Acc0
	in Acc0, UCSRA
	sbrs Acc0, UDRE // ����������� 5 ��� �������� UCSRA
	rjmp END_ADC

	in Acc1, ADCL // ������ ��������� ������, ���� �� �������
	in Number, ADCH
	
	ldi Acc0, 10 // ��� �������� ���������� ��������
	ldi Acc1, 0 // 1 ��� ���������

	ldi NumDecCount, 0
	ldi Razr1, 0
	ldi Razr2, 0
	ldi Razr3, 0

	rcall GetRazr
	out UDR, Razr1 // ������ 1 �������

END_ADC:
	pop Acc0
	out SREG, Acc0
	pop Acc1 // ������������ �� ��������
	pop Acc0

reti // ������� �� ����������


TIM0_OVF:
	push Acc0
	push Acc1
	in Acc0, SREG // ��������� ��������� �������
	push Acc0
	rjmp TO0_0
	
TO0_0:
	inc TactCount
	cpi TactCount, 2 // ���������� ������� � 4 (�.�. 1 ���� = 1/���.)
	brne TO0_1
	ldi TactCount, 0

TO0_1:
	pop Acc0
	out SREG, Acc0
	pop Acc1
	pop Acc0

reti // ��������� ����������


USART_TXC: // �������� ���������
	sbis UCSRA, UDRE // UDRE - ��� ����� � ����������
	rjmp USART_TXC
	inc LineCount
	cpi LineCount, 1
	breq UT_print2
	cpi LineCount, 2
	breq UT_print3

	cpi LineCount, 5
	breq UT_clear
	rcall PrintEndLine
	rjmp UT_stop

UT_print2:
	out UDR, Razr2 // ������ 2 �������
	rjmp UT_stop

UT_print3:
	out UDR, Razr3 // ������ 3 �������
	rjmp UT_stop

UT_clear:
	ldi LineCount, 0
	ldi SymbolCount, 0
UT_stop:
reti


// Data
DataByte:
.DB 0x0A, 0x0D // ������� ������ � ������� �������
DataWord:
.DW 0x1234, 0x5678 // ���������� ����
