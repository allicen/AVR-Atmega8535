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
// ldi Acc0, LOW(RAMEND)
// out SPL, Acc0
// ldi Acc0, HIGH(RAMEND)
// out SPH, Acc0
//init SFR (special function reg)
// sbi DDRB, LED

//Interrupt Enable
// sei

//Main programm


ldi r18, 0x00
// X, Z - сдвоенные регистры, основное назначение - косвенная адресация
LDI ZL, LOW(DataByte*2) // LOW - взять младший байт слова, 2 - 2 байта в памяти, кажд адрес содержит 2 байта (0x100 * 2 = 0x200)
LDI ZH, HIGH(DataByte*2) // HIGH - взять старший байт слова
ldi XL, LOW(0x0100)
ldi XH, HIGH(0x0100)

///SRAM
Write_SRAM:
LPM r2,Z
st X,r2 // косвенная адресация
inc XL
inc r18
inc ZL
cpi r18,10 // сравнение регистра
brne Write_SRAM

///Flash Programm
LDI ZL, LOW(DataByte*2)
LDI ZH, HIGH(DataByte*2)


LDI R17, LOW(0x50)
LDI R18, HIGH(0x50)
ldi r20, 0x00
LPM
Write_EEpr:
LPM r2,Z
MOV r16,r2
rcall EEPROM_write
INC R17
inc ZL
inc r20
cpi r20,10
brne Write_EEpr


LPM // без аргументов - берет из Z и кладет в R0
///EEPROM DATA - энергонезависимая память
LPM r2,Z // Загрузка программной памяти
LDI R17, LOW(0x50)
LDI R18, HIGH(0x50)

rcall EEPROM_write


//SubProgamm
Delay:
nop
nop

ret

// Код из документации 
EEPROM_write:
; Wait for completion of previous write
sbic EECR,EEWE // ждет окончания записи, анализ флага EEWE в регистре EECR
rjmp EEPROM_write
; Set up address (r18:r17) in address register
out EEARH, r18
out EEARL, r17
; Write data (r16) to Data Register
out EEDR,r16
; Write logical one to EEMWE
sbi EECR,EEMWE
; Start eeprom write by setting EEWE
sbi EECR,EEWE
ret

// Код из документации 
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

//Interrupt Routines
EXT_INT0:
push Acc0
push Acc1

pop Acc0
pop Acc1

reti

//Dat
.org 0x100 // DataByte складываем по адресу 0x100
DataByte:
.DB 0x1f, 0x1C, 0x6a, 0xe9, 0xbb, 0xc6, 0x11, 0xa5, 0x9d,0xee
DataWord:
.DW 0x1234, 0x5678
