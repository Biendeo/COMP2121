; main.asm
; The main entry point of the program.

.org 0x0000
	jmp Reset
.org INT0addr
	jmp PushRightButton
.org INT1addr
	jmp PushLeftButton
.org OVF0addr
	jmp Timer0Interrupt

.dseg
currentMode: .byte 1

.equ MODE_TITLESCREEN = 0
.equ MODE_TITLEWAIT = 1
.equ MODE_RESETPOTENT = 2
.equ MODE_FINDPOTENT = 3
.equ MODE_FINDCODE = 4
.equ MODE_ENTERCODE = 5
.equ MODE_GAMEWIN = 6
.equ MODE_GAMELOSE = 7

difficultyLevel: .byte 1

.equ DIFFICULTY_EASY = 0
.equ DIFFICULTY_MEDIUM = 1
.equ DIFFICULTY_HARD = 2
.equ DIFFICULTY_REALLYHARD = 3

currentRandomPotent: .byte 1 ; Or should this be two bytes?
currentRandomCode: .byte 1
randomCode1: .byte 1
randomCode2: .byte 1
randomCode3: .byte 1

.cseg
.include "m2560def.inc"
.include "button.asm"
.include "keypad.asm"
.include "lcd.asm"
.include "led.asm"
.include "motor.asm"
.include "potentiometer.asm"
.include "random.asm"
.include "speaker.asm"
.include "strobe.asm"
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
	call SetupStrobe
	call SetupKeyPad
	call SetupMotor
	call SetupPotent
	call SetupSpeaker
	call SetupMainVariables

	sei

	rjmp Start

; Initialises the main variables.
SetupMainVariables:
	ldi r16, MODE_TITLESCREEN
	ldi ZL, low(currentMode)
	ldi ZH, high(currentMode)
	st Z, r16

	ldi r16, DIFFICULTY_EASY
	ldi ZL, low(difficultyLevel)
	ldi ZH, high(difficultyLevel)
	st Z, r16

	; currentRandomPotent, currentRandomCode and the randomCode variables are set
	; when a button is pushed so that randomness can be decided.
	ret

; The start of the program after all setup has been done.
Start:
	rcall TitleScreen
	
	; This is just to test that GetKeyPadInput works by outputting the result to
	; the LEDs. Ideally this function waits until we press a key. The only time
	; we ever need to interrupt this input is on the title screen when picking
	; a difficulty (which we can make a "bail" function for).
	call GetKeyPadInput
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