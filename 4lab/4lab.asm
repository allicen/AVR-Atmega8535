//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3
.equ DATA = 1
.equ CLK = 0

//init registers 
.def Acc0 = R16
.def Acc1 = R17
.def Acc2 = R18
.def TactCount = R20
.def DBCount = R22

//PROGRAMM
//interrupt vectors
.org 0x0
    rjmp RESET ; Reset Handler
//    rjmp EXT_INT0 ; IRQ0 Handler
//    rjmp EXT_INT1 ; IRQ1 Handler
//    rjmp TIM2_COMP ; Timer2 Compare Handler
//    rjmp TIM2_OVF ; Timer2 Overflow Handler
//    rjmp TIM1_CAPT ; Timer1 Capture Handler
//    rjmp TIM1_COMPA ; Timer1 Compare A Handler
//    rjmp TIM1_COMPB ; Timer1 Compare B Handler
//    rjmp TIM1_OVF ; Timer1 Overflow Handler
.org 0x009 // the address for the TIM0_OVF register from datasheet
    rjmp TIM0_OVF ; Timer0 Overflow Handler
//    rjmp SPI_STC ; SPI Transfer Complete Handler
//    rjmp USART_RXC ; USART RX Complete Handler
//    rjmp USART_UDRE ; UDR Empty Handler
//    rjmp USART_TXC ; USART TX Complete Handler
//    rjmp ADC ; ADC Conversion Complete Handler
//    rjmp EE_RDY ; EEPROM Ready Handler
//    rjmp ANA_COMP ; Analog Comparator Handler
//    rjmp TWSI ; Two-wire Serial Interface Handler
//    rjmp EXT_INT2 ; IRQ2 Handler
//    rjmp TIM0_COMP ; Timer0 Compare Handler
//    rjmp SPM_RDY ; Store Program Memory Ready Handler
.org 0x15
RESET:
//init stack pointer
    ldi Acc0, LOW(RAMEND)
    out SPL, Acc0
    ldi Acc0, HIGH(RAMEND)    
    out SPH, Acc0
//init SFR (special function reg)
    sbi DDRC, CLK // set the bit to 0 register, set to output
    sbi DDRC, DATA // set the bit to 1 register, set to output
    sbi DDRB, LED 
    // set to output for all devices
    // WGM01 - настройка ctc в 1
    // WGM00 - настройка ctc в 0
    ldi Acc0, (1<<WGM01)|(0<<WGM00)|(0b101<<CS00) // CS00 - frequency/1024 (p. 84)
    out TCCR0, Acc0 // writing to the special purpose register for setting the timer
    ldi Acc0, 0xFF // 255 - maximum account period
    out OCR0, Acc0 // OCR0 - comparison register

    ldi Acc0, (1<<TOIE0) // allow overflow interrupt
    out TIMSK, Acc0 // write to the interrupt resolution register
    ldi TactCount, 0 
    sbi PORTB, LED // install 1 on the LED line
    ldi DBCount, 0

//Interrupt Enable 
    sei // allow interrupts
//Main programm
loop:
    rjmp loop
    
//SubProgamm

// seven-segment indicator
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
    sbi PORTC, CLK // set the bit
    nop
    nop
    cbi PORTC, CLK // reset the bit
    // dec CNT
    dec Acc1 // decrement
    // test CNT
    brne SS0 // switch to SS0 until the 0 flag is set

ret

// recording values on indicators
CountSevSeg:
    ldi Acc0, 0xff
    rcall SevSeg
    ldi Acc0, 0xff
    rcall SevSeg
    ldi Acc0, 0xff
    rcall SevSeg
    cpi DBCount, 2
    brne C0 // switch to C0 until the 0 flag is set
    ldi DBCount, 0
C0:
    ldi ZL, LOW(DataByte*2)
    ldi ZH, HIGH(DataByte*2)
    add ZL, DBCount
    lpm Acc0, Z
    rcall SevSeg
    inc DBCount
ret



//Interrupt Routines
TIM0_OVF: // the name is taken from the interrupt vector
    push Acc0
    push Acc1
    in Acc0, SREG // saving the status register
    push Acc0
    rcall CountSevSeg // write the values to the indicators
    inc TactCount
    sbic PORTB, LED // if the LED is on -> turn off
    rjmp TO0_0
    sbi PORTB, LED // set the bit for the LED
    rjmp TO0_1
    
TO0_0:
    cpi TactCount, 3 // compare the register with 3
    brne TO0_1 // we have reached 3 -> turn on the LED
    cbi PORTB, LED
    ldi TactCount, 0

TO0_1:
    pop Acc0
    out SREG, Acc0
    pop Acc1
    pop Acc0
    reti // termination of the interrupt

//Data
DataByte:
.DB 0xf9, 0xC0
DataWord:
.DW 0x1234, 0x5678