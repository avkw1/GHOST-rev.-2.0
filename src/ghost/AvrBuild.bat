@ECHO OFF
"C:\Program Files\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\ghost\src\ghost\labels.tmp" -fI -W+ie -C V2 -o "C:\ghost\src\ghost\ghost.hex" -d "C:\ghost\src\ghost\ghost.obj" -e "C:\ghost\src\ghost\ghost.eep" -m "C:\ghost\src\ghost\ghost.map" -l "C:\ghost\src\ghost\ghost.lst" "C:\ghost\src\ghost\ghost.asm"
