@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\helen\Assembler\2lab-done\labels.tmp" -fI -W+ie -C V2E -o "C:\helen\Assembler\2lab-done\progmempry.hex" -d "C:\helen\Assembler\2lab-done\progmempry.obj" -e "C:\helen\Assembler\2lab-done\progmempry.eep" -m "C:\helen\Assembler\2lab-done\progmempry.map" "C:\helen\Assembler\2lab-done\progmempry.asm"
