// connecting the initialization file
.include "m8535def.inc"

// initializing constants
.equ max_sec = 60
.equ LED = 3
.equ TX = 1
.equ Bitrate = 9600 // 9600 under is equal to 0.00768 megabits/sec
//Режим Asynchronous Normal Mode
.equ BAUD = 8000000 / (16 * Bitrate) - 1 // 51! the formula in datasheet, 8000000 - clock frequency 8MHz
.equ AsciiCode = 48

// initializing registers
.def Acc0 = R16
.def Acc1 = R17
.def TactCount = R18
.def LineCount = R19
.def SymbolCount = R20
.def Razr1 = R21 // hundreds
.def Razr2 = R22 // dozens
.def Razr3 = R23 // units
.def Number = R25 // character number
.def NumDecCount = R24 // number of tens



// PROGRAMM

//interrupt vectors (interrupt vectors)
.org 0x0 /// Setting the address counter to the desired value.
	rjmp RESET ; Reset Handler
//	rjmp EXT_INT0 ; IRQ0 Handler
//	rjmp EXT_INT1 ; IRQ1 Handler
//	rjmp TIM2_COMP ; Timer2 Compare Handler
//	rjmp TIM2_OVF ; Timer2 Overflow Handler
//	rjmp TIM1_CAPT ; Timer1 Capture Handler
//	rjmp TIM1_COMPA ; Timer1 Compare A Handler
//	rjmp TIM1_COMPB ; Timer1 Compare B Handler
//	rjmp TIM1_OVF ; Timer1 Overflow Handler
.org 0x009 // the address for the TIM0_OVF register from the alphabet
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
.org 0x15 /// Start of the main program

RESET:
	// stack initialization
	ldi Acc0, LOW(RAMEND) /// RAMEND - max ram address
	out SPL, Acc0
	ldi Acc0, HIGH(RAMEND)
	out SPH, Acc0

	//init SFR (special function reg)
	sbi DDRB, LED

	// Setting up the timer
	ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00) // CS00 - frequency/1024 (стр 84)
	out TCCR0, Acc0 // writing to the special purpose register for setting the timer
	ldi Acc0, 0xFF // 255 - maximum account period
	out OCR0, Acc0 // OCR0 - comparison register
	ldi Acc0, (1<<TOIE0) // allow overflow interrupt
	out TIMSK, Acc0 // write to the interrupt resolution register

	// Setting up usart
	ldi Acc0, HIGH(BAUD)
	out UBRRH,Acc0 
	ldi Acc0, LOW(BAUD) 
	out UBRRL,Acc0
	ldi Acc0, (1<<TXEN) | (1<<RXEN) | (1<<RXCIE) | (1<<TXCIE) // these bits allow interrupts
	out UCSRB, Acc0 
	ldi Acc0, (1<<URSEL)| (1<<UCSZ0) |(1<<UCSZ1)

	// Setting up the ADC
	// ADLAR - left alignment (high-order bits are important),
	// MUX0 - combination of analog inputs 00000, you can set a specific channel
	// REFS0 - set the reference voltage
	ldi Acc0, (0x0<<REFS0) | (1<<ADLAR) | (0x0<<MUX0) 
	out ADMUX, Acc0

	// ADEN - enable ADC
	// ADSC - start conversion
	// ADATE - automatic start of conversion
	// ADIE - allow interrupts
	// ADPS0 - the accuracy of digitization, we set 128 (choose in the range: clock. frequency percent/min and max frequency)
	ldi Acc0, (1<<ADEN) | (0<<ADSC) | (1<<ADATE) | (1<<ADIE) | (0x7<<ADPS0) // 0x7 - 111 in the lower grades
	out ADCSRA, Acc0
	
	// Read / Modify / Write
	//Rewrite this part, does not work
	//in Acc0, SFIOR
	//andi Acc0, ~(0x3<<ADTS0) // andi - bitwise AND with a constant, process only the highest 3 bits (overflow by counter timer 100)
	//ori Acc0, (0x0<<ADTS0) // ori - logical OR
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
	rcall Delay // calling a subroutine
	// LED OFF
	cbi PORTB, LED
	// Delay
	rcall Delay
	rjmp loop


// Subprogramm
Delay:
	nop
	nop
ret // exit from the subroutine



//////////////////////////////////
//                              // 
// Printing the end of the line //
//                              //
//////////////////////////////////

PrintEndLine:
	ldi ZL, LOW(DataByte*2) // LOW - take the lowest byte of the word, 2 - 2 bytes in memory, each address contains 2 bytes (0x100 * 2 = 0x200)
	ldi ZH, HIGH(DataByte*2) // HIGH - take the highest byte of the word
	add ZL, SymbolCount
	lpm Acc0, Z
	out UDR, Acc0
	inc SymbolCount
ret



//////////////////////////////////
//                              // 
//  Calculation of discharges   //
//                              //
//////////////////////////////////

GetRazr: // counting tens
	add Acc1, Acc0
	cp Acc1, Number
	brlo GR_continue // go if less
	rjmp GR_razr3

GR_continue:
	inc NumDecCount
	rjmp GetRazr

GR_razr2: // determine the number of tens
	ldi Acc0, 10
	mov Acc1, NumDecCount
	mul  Acc1, Acc0
	cpi Number, 100
	brsh GR_razr1
	mov Razr2, NumDecCount
	ldi Acc0, AsciiCode
	add Razr2, Acc0
	add Razr1, Acc0
	rjmp GR_stop

GR_razr1: // determine the number of hundreds
	cpi Number, 200
	brsh GR_R0
	ldi Razr1, 1
	ldi Acc0, AsciiCode
	add Razr1, Acc0
	ldi Acc0, 10
	sub NumDecCount, Acc0
	mov Razr2, NumDecCount
	ldi Acc0, AsciiCode
	add Razr2, Acc0
	rjmp GR_stop

GR_R0:
	ldi Razr1, 2
	ldi Acc0, AsciiCode
	add Razr1, Acc0
	ldi Acc0, 20
	sub NumDecCount, Acc0
	mov Razr2, NumDecCount
	ldi Acc0, AsciiCode
	add Razr2, Acc0
	rjmp GR_stop

GR_razr3: // determine the number of units
	sub Acc1, Number
	ldi Acc0, 10
	sub Acc0, Acc1
	add Razr3, Acc0
	ldi Acc0, AsciiCode
	add Razr3, Acc0
	cpi NumDecCount, 1 // there are dozens
	brsh GR_razr2 // the same or more
	rjmp GR_stop

GR_stop:
ret



// Interrupt Handling

//////////////////////////////////
//                              // 
//        Getting data          //
//                              //
//////////////////////////////////

ADC_CON:
	push Acc0 // Put in the register
	push Acc1
	in Acc0, SREG
	push Acc0
	in Acc0, UCSRA
	sbrs Acc0, UDRE // analyzing 5 bits of the UCSRA register
	rjmp END_ADC

	in Acc1, ADCL // always read first
	in Number, ADCH
	
	ldi Acc0, 10 // to count the number of tens
	ldi Acc1, 0 // 1 for multiplication

	ldi NumDecCount, 0
	ldi Razr1, 0
	ldi Razr2, 0
	ldi Razr3, 0

	rcall GetRazr
	out UDR, Razr1 // Printing of the 1st category

END_ADC:
	pop Acc0
	out SREG, Acc0
	pop Acc1 // Restore from Register
	pop Acc0

reti // Returning from an interrupt



////////////////////////////////
//                            // 
//       Overflow timer       //
//                            //
////////////////////////////////

TIM0_OVF:
	push Acc0
	push Acc1
	in Acc0, SREG // saving the status register
	push Acc0
	rjmp TO0_0
	
TO0_0:
	inc TactCount
	cpi TactCount, 4
	brne TO0_1
	ldi TactCount, 0

TO0_1:
	pop Acc0
	out SREG, Acc0
	pop Acc1
	pop Acc0

reti // termination of the interrupt



////////////////////////////////
//                            // 
//     Printing in USART      //
//                            //
////////////////////////////////

USART_TXC: // transfer completed
	sbis UCSRA, UDRE // UDRE - interrupt entry bit
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
	out UDR, Razr2 // Print 2 digits
	rjmp UT_stop

UT_print3:
	out UDR, Razr3 // Print 3 digits
	rjmp UT_stop

UT_clear:
	ldi LineCount, 0
	ldi SymbolCount, 0
UT_stop:
reti


// Data
DataByte:
.DB 0x0A, 0x0D // line break and carriage return
DataWord:
.DW 0x1234, 0x5678 // saving words
