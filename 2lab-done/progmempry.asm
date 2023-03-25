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
out SPL, Acc0 // SPL - special register for the stack
ldi Acc0, HIGH(RAMEND)
out SPH, Acc0 // SPH - special register for the stack
//init SFR (special function reg)

//Interrupt Enable
// sei

//Main programm

ldi r18, 0x00 // loading a constant into a register
// X, Z - dual registers, the main purpose is indirect addressing
ldi ZL, LOW(DataByte*2) // LOW - take the lowest byte of the word, 2 - 2 bytes in memory, each address contains 2 bytes (0x100 * 2 = 0x200)
ldi ZH, HIGH(DataByte*2) // HIGH - take the highest byte of the word
// (1) Write at address 100
ldi XL, LOW(0x100)
ldi XH, HIGH(0x100)

///SRAM
// (1) Add all the words from the dictionary to the address 100
Write_SRAM:
    lpm R2,Z
    st X,R2 // indirect addressing, R2 in X
    inc XL // increment
    inc R18
    inc ZL
    cpi R18,10 // case comparison
    brne Write_SRAM // Branch if Not Equal

///Flash Programm
ldi ZL, LOW(DataByte*2)
ldi ZH, HIGH(DataByte*2)

// (2) Write to memory 0x50
ldi R17, LOW(0x50)
ldi R18, HIGH(0x50)
ldi R20, 0x00
lpm // without arguments - takes from Z and puts in R0
    
// (2) Write to EEPROM memory
Write_EEpr:
    lpm R2,Z // program memory, only Z works with program memory
    mov R16,R2 // moving from register to register
    rcall EEPROM_write // calling a subroutine
    inc R17 // increment
    inc ZL
    inc R20
    cpi R20,10 // comparing the register with 10
    brne Write_EEpr
    ret

lpm // without arguments - takes from Z and puts in R0
///EEPROM DATA - non-volatile memory
lpm R2,Z // loading program memory
ldi R17, LOW(0x50)
ldi R18, HIGH(0x50)

rcall EEPROM_write // calling a subroutine

//SubProgamm
// Code from the documentation
EEPROM_write:
    ; Wait for completion of previous write
    sbic EECR,EEWE // waiting for the end of the recording, analyzing the EEWE flag in the EECR register
    rjmp EEPROM_write
    ; Set up address (r18:r17) in address register
    out EEARH, r18
    out EEARL, r17
    ; Write data (r16) to Data Register
    out EEDR,r16
    ; Write logical one to EEMWE
    sbi EECR,EEMWE // set to I/O register 1
    ; Start eeprom write by setting EEWE
    sbi EECR,EEWE
    ret

// Code from the documentation
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
    ret // exit from the subroutine

//Interrupt Routines
EXT_INT0:
    push Acc0 // put it on the stack
    push Acc1

    pop Acc1 // take from the stack
    pop Acc0

    reti // exiting the interrupt

//Dat
.org 0x100 // DataByte складываем по адресу 0x100
DataByte:
.DB 0x1f, 0x1C, 0x6a, 0xe9, 0xbb, 0xc6, 0x11, 0xa5, 0x9d,0xee
DataWord:
.DW 0x1234, 0x5678
