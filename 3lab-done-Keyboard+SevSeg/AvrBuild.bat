@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\helen\Assembler\3lab-done-Keyboard+SevSeg\labels.tmp" -fI -W+ie -C V2E -o "C:\helen\Assembler\3lab-done-Keyboard+SevSeg\Keyboard+SevSeg.hex" -d "C:\helen\Assembler\3lab-done-Keyboard+SevSeg\Keyboard+SevSeg.obj" -e "C:\helen\Assembler\3lab-done-Keyboard+SevSeg\Keyboard+SevSeg.eep" -m "C:\helen\Assembler\3lab-done-Keyboard+SevSeg\Keyboard+SevSeg.map" "C:\helen\Assembler\3lab-done-Keyboard+SevSeg\Keyboard+SevSeg.asm"
