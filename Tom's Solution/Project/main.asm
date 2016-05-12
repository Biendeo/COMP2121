; main.asm
; The main entry point of the program.

.org 0x0000
	jmp Reset

.include "m2560def.inc"
.include "keypad.asm"
.include "lcd.asm"
.include "led.asm"
.include "potentiometer.asm"
.include "random.asm"
.include "speaker.asm"
.include "timer.asm"

; The main process of resetting the program.
Reset:
	; The stack is set up first so rcalls can be made from here on out.
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL, r16

	rcall SetupTimer0
	rcall SetupLCD

	rjmp Start

; The start of the program after all setup has been done.
Start:
	rjmp Halt

; Stops the program.
; Our program shouldn't really be in an ended state.
Halt:
	rjmp Halt