//include init file
.include "m8535def.inc"

//init constant
.equ max_sec = 60
.equ LED = 3
.equ CLK = 0
.equ DATA = 1
//init registers 
.def Acc0 = R16
.def Acc1 = R17
.def Acc2 = R18
.def numkey = R19 // key number
.def MASK = R20 // mask for searching for the pressed button


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
//    rjmp TIM0_OVF ; Timer0 Overflow Handler
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
    ldi Acc0, 0b11110000|(1<<LED) // set to output for all devices (including LED)
    out DDRB, Acc0 // ddr port direction
    
    sbi DDRC, CLK // set the bit to 0 register, set to output
    sbi DDRC, DATA // set the bit to 1 register, set to output
//Interrupt Enable
//    sei
//Main programm




loop:
    rcall Key     
    cpi numkey, 0 // if the button is not pressed
    breq loop // if not pressed, go to loop

L1:
    ldi Acc2,20 
    ldi ZL, LOW(DataByte*2-1) // LOW - take the lowest byte of the word, 2 - 2 bytes in memory, each address contains 2 bytes (0x100 * 2 = 0x200)
    ldi ZH, HIGH(DataByte*2) // HIGH - take the highest byte of the word
    add ZL, numkey // addition
    lpm Acc0, Z    // load the program into memory
    rcall SevSeg

E1:    dec Acc2
    rcall Delay // delay
    cpi Acc2,0 // if Acc2=0, loop E1
    brne E1

    rjmp loop    
//SubProgamm
//Keyboard
//OUT: numkey - number of push key, if keyboard free -> numkey = 0 
Key:
//reg mask
    ldi MASK, 0b11101111 // mask for running zero
    clr numkey // initialize numkey 0
    ldi Acc2, 0x3 // initializes Acc2 3

//set portB
//read, modify and write

K1: // Block for reading/writing from/to the port
    ori MASK, 0x1 // lowest bit in 1
    in Acc0, PORTB // read data from PORTB
    ori Acc0, 0b11110000 // ori - logical bitwise And with a constant, we put the 4 highest bits in 1 and apply a mask
    and Acc0, MASK  // applying a mask
    out PORTB, Acc0 // write the result to the port

    //read column portD
    nop // we set a delay in order to have time to read the set data
    nop
    in Acc0, PIND // count PIND
    //analys in data
    ldi Acc1, 0x3 // 3 times we will shift to the left

ankey: // The block analyzes the button press
//if key push to ret
//else <<mask and rjmp K1    
    lsl Acc0 // left shift
    brcc pushkey // if 0, then go to the push key, if 1 - go further
    dec Acc1 // decrement
    brne ankey // if not 0, then go to ankey, otherwise go further
    //numkey+3
    add numkey, Acc2

    lsl MASK
    brcs K1 // если флаг С=1, уйти в K1
    clr numkey // no key was pressed = reset numkey
    rjmp endkey

pushkey:
    add numkey, Acc1

endkey:
    ret


//Seven Segment
//IN: Acc0 <- Data for Segment
SevSeg:
ldi Acc1, 8 // you need to output 8 bits for each number
SS0:
    // set data
    lsl Acc0 // left shift, in bits С
    brcc SS1 // if the flag is 0, then go to the SS1 label
    sbi PORTC, DATA // set 1 on the data line
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

//Delay
Delay:
    ldi R21, 255
delay1: ldi R20, 255
delay2: dec R20
    brne delay2
    dec R21
    brne delay1
ret


//Interrupt Routines
EXT_INT0:
    push Acc0
    push Acc1
    in Acc0, SREG
    push Acc0


    pop Acc0
    out SREG, Acc0
    pop Acc1
    pop Acc0

    reti

// Codes for the digits of the seven-segment indicator
DataByte:
.DB 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8, 0x80, 0x90
DataWord:
.DW 0x1234, 0x5678
