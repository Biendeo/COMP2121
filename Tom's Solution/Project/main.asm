; main.asm
; The main entry point of the program.

.org 0x0000
	jmp Reset

.include "m2560def.inc"

.org 0x2000
.include "keypad.asm"
.include "lcd.asm"
.include "led.asm"
.include "motor.asm"
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

	call SetupTimer0
	call SetupLCD ; This somehow takes 750ms to do. Maybe investigate.
	call SetupLED
	call SetupKeyPad
	call SetupMotor
	call SetupPotent
	call SetupSpeaker

	sei

	rjmp Start

; The start of the program after all setup has been done.
Start:
	rjmp Halt

; Stops the program.
; Our program shouldn't really be in an ended state.
Halt:
	rjmp Halt