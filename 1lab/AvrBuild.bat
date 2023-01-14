@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\helen\Assembler\1lab\labels.tmp" -fI -W+ie -C V2E -o "C:\helen\Assembler\1lab\1lab.hex" -d "C:\helen\Assembler\1lab\1lab.obj" -e "C:\helen\Assembler\1lab\1lab.eep" -m "C:\helen\Assembler\1lab\1lab.map" "C:\helen\Assembler\1lab\1lab.asm"
