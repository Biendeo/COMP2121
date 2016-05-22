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

currentStage: .byte 1

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
	sts currentMode, r16

	ldi r16, DIFFICULTY_EASY
	sts difficultyLevel, r16

	ldi r16, 0
	sts currentStage, r16

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

; Displays the title screen of the game.
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

	do_lcd_command LCD_SECONDLINE

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

; Starts the game section involving finding the right potential setting.
; This creates a new random potential to find.
StartFindPotent:
	ldi r16, MODE_FINDPOTENT
	sts currentMode, r16

	lds r16, currentStage
	inc r16
	sts currentStage, r16

	rcall GenerateNewRandomPotent
	; TODO: Setup the timer.
	; TODO: Setup another timer when the potentiometer is in the right place.
	; TODO: Use some booleans to detect whether the user has entered or exited
	; the spot.
	ret

; Starts the section that involves finding a code character.
StartFindCode:
	ldi r16, MODE_FINDCODE
	sts currentMode, r16

	rcall GenerateNewRandomCodeDigit

	lds r16, currentStage
	lds r17, currentRandomCode

	cpi r16, 1
	breq StartFindCode_StoreCode1
	cpi r16, 2
	breq StartFindCode_StoreCode2
	rjmp StartFindCode_StoreCode3

	StartFindCode_StoreCode1:
		sts randomCode1, r17
		rjmp StartFindCode_Search

	StartFindCode_StoreCode2:
		sts randomCode2, r17
		rjmp StartFindCode_Search

	StartFindCode_StoreCode3:
		sts randomCode3, r17
	StartFindCode_Search:
		; TODO: Get the keypad input and confirm it's the key.
		; TODO: Use a timer and poll whether the key is down in a loop.
		; TODO: When the timer runs out and the key always was down, break.
		; TODO: Otherwise, keep looping.

	ret

; Creates a new random potential and stores it.
GenerateNewRandomPotent:
	push r16
	call CreateRandomValue
	lds r16, currentRandomValue
	; TODO: Figure out any refinements we need to make this work properly.
	; (restrict it to a range?)
	sts currentRandomPotent, r16
	pop r16
	ret
	
; Creates a new random digit and stores it.
GenerateNewRandomCodeDigit:
	push r16
	push r17
	push r18
	call CreateRandomValue
	lds r16, currentRandomValue
	ldi r17, 10
	rcall Divide
	sts currentRandomCode, r18
	pop r18
	pop r17
	pop r16.
	ret

.def argument = r16
.def divisor = r17
.def return = r18
; Divides r16 by r17 and returns the result in r18.
Divide:
	push argument
	push divisor
	ldi return, 0
	
	Divide_Loop:
		cp argument, divisor
		brlt Divide_End
		inc return
		sub argument, divisor
		rjmp Divide_Loop

	Divide_End:
		pop divisor
		pop argument
		ret

.undef argument
.undef divisor
.undef return

.def argument = r16
.def modulo = r17
.def return = r18
; Moduloes r16 by r17 and returns the result in r18.
Modulus:
	push argument
	push modulo

	Modulus_Loop:
	cp argument, modulo
	brlt Modulus_End
	sub argument, modulo
	rjmp Modulus_Loop

	Modulus_End:
		mov modulo, argument
		pop modulo
		pop argument
		ret

.undef argument
.undef modulo
.undef return

; Stops the program.
; This only ever needs to be called on screens waiting for a push button.
Halt:
	rjmp Halt