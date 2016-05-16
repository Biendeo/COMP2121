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
	rcall TitleScreen
	
	; This is just to test that GetKeyPadInput works by outputting the result to
	; the LEDs. Ideally this function waits until we press a key. The only time
	; we ever need to interrupt this input is on the title screen when picking
	; a difficulty (which we can make a "bail" function for).
	rcall GetKeyPadInput
	out LED_OUT, r16
	rjmp Halt

; Displays the title screen of the game and waits for input.
TitleScreen:
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data '6'
	do_lcd_data 's'
	do_lcd_data '1'

	do_lcd_command 0b11000000

	do_lcd_data 'S'
	do_lcd_data 'a'
	do_lcd_data 'f'
	do_lcd_data 'e'
	do_lcd_data ' '
	do_lcd_data 'C'
	do_lcd_data 'r'
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'k'
	do_lcd_data 'e'
	do_lcd_data 'r'

	ret

; Stops the program.
; Our program shouldn't really be in an ended state.
Halt:
	rjmp Halt