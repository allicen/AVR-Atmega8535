// ���������� ���� �������������
.include "m8535def.inc"

// ������������� ��������
.equ max_sec = 60
.equ LED = 3;PORTB.3
.equ BTN1 = 2;PORTD.2
.equ BTN2 = 3;PORTD.3

// ������������� ��������� 
.def Acc0 = R16
.def Acc1 = R17

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
.org 0x15 /// ������ ������� ���������

RESET:
// ������������� �����
	ldi Acc0, LOW(RAMEND) /// RAMEND - ���� ����� ���
	out SPL, Acc0
	ldi Acc0, HIGH(RAMEND)
	out SPH, Acc0

// ������������� ��������� ������������ ����������
	sbi DDRB, LED
	cbi DDRD, BTN1 // ��������� �������� �� ���� (����� ���� �� ������)

// Interrupt Enable
// sei
// Main programm
loop:
	// 1 �������
	sbis PIND, BTN1
	rjmp loop
//	rjmp Check_two_btn
	sbis PIND, BTN2
	rjmp loop
	// LED ON
	sbi PORTB, LED
	// Delay
	rcall Delay // ����� ������������
	// LED OFF
	cbi PORTB, LED
	// Delay
	rcall Delay
	rjmp loop
	// 2 �������
	// 1 BTN
	//in Acc0, PIND // ������� � ����
	//andi Acc0, 1<<BTN1 // ������������, ��������� �

	// 2 BTN
	//in Acc1, PIND
	//andi Acc1, 1<<BTN2

	// ����������� ���
	//eor Acc0, Acc1
	//breq loop
	//rjmp Control_led
	

// Subprogramm
Delay:
	nop
	nop
	
	ret // ����� �� ������������

Check_two_btn:
	sbis PIND, BTN2
	rjmp loop
	rjmp Control_led

Control_led:
	// LED ON
	sbi PORTB, LED
	// Delay
	rcall Delay // ����� ������������
	// LED OFF
	cbi PORTB, LED
	// Delay
	rcall Delay
	rjmp loop

// ��������� ����������
EXT_INTO:
	push Acc0 // �������� � �������
	push Acc1
	pop Acc1 // ������������ �� ��������
	pop Acc0
	reti // ������� �� ����������


// Data
DataByte:
.DB 0x1f, 0x1C // ���������� ������ (�������)
DataWord:
.DW 0x1234, 0x5678 // ���������� ����
