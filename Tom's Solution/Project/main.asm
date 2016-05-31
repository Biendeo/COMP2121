; main.asm
; The main entry point of the program.

.macro incStack
	in yl, SPL
	in yh, SPH
	sbiw yl, @0
	out SPL, yl
	out SPH, yh
.endmacro
.macro decStack
	in yl, SPL
	in yh, SPH
	adiw yl, @0
	out SPL, yl
	out SPH, yh
.endmacro

.org 0x0000
	jmp Reset
.org INT0addr
	jmp PushRightButton
.org INT1addr
	jmp PushLeftButton
.org OVF0addr ; DEBOUNCING
	jmp Timer0Interrupt 
.org ADCCaddr
	jmp ADCCint

.dseg
currentMode: .byte 1

.equ MODE_TITLESCREEN = 0
.equ MODE_TITLEWAIT = 1
.equ MODE_RESETPOTENT = 2
.equ MODE_FINDPOTENT = 3
.equ MODE_FINDCODE = 4
.equ MODE_ENTERCODE = 5
.equ MODE_END_ROUND = 8
.equ MODE_GAMEWIN = 6
.equ MODE_GAMELOSE = 7

difficultyLevel: .byte 1

.equ DIFFICULTY_EASY = 0
.equ DIFFICULTY_MEDIUM = 1
.equ DIFFICULTY_HARD = 2
.equ DIFFICULTY_REALLYHARD = 3

currentStage: .byte 1

.equ FLAG_SET = 1
.equ FLAG_UNSET = 0

; POT
potFlag: .byte 1
potTimer: .byte 2
currentDesiredPot: .byte 2 ; Or should this be two bytes?
currentRandomCode: .byte 1

; timer 0
; used as game timer and countdown timer
timer0Counter: .byte 2
timer0Seconds: .byte 2

; DEBOUNCING PB
PB0dbFlag: .byte 1
PB0dbTimer: .byte 2
PB1dbFlag: .byte 1
PB1dbTimer: .byte 2

; keypad
keypadFlag: .byte 1
keypadHoldFlag: .byte 1

; codes
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

.def temp1 = r24
.def temp2 = r25

; The main process of resetting the program.
Reset:
	; The stack is set up first so rcalls can be made from here on out.
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL, r16

	rcall SetupTimer0
	rcall SetupLCD ; This somehow takes 750ms to do. Maybe investigate.
	rcall SetupLED
	rcall SetupStrobe
	rcall SetupButtons
	rcall SetupKeyPad
	rcall SetupMotor
	rcall SetupPotent
	rcall SetupSpeaker

	sei
	rjmp SetupMainVariables

; Initialises the main variables.
SetupMainVariables:
	ldi r16, MODE_TITLESCREEN
	sts currentMode, r16

	ldi r16, DIFFICULTY_EASY
	sts difficultyLevel, r16

	ldi r16, 0
	sts currentStage, r16

	rcall DisableAllFlags

	; currentRandomPotent, currentRandomCode and the randomCode variables are set
	; when a button is pushed so that randomness can be decided.
	rjmp Start

DisableAllFlags:
	push r16
	ldi r16, FLAG_UNSET
	sts potFlag, r16
	sts keypadFlag, r16
	pop r16
	ret
; The start of the program after all setup has been done.
Start:
	rcall TitleScreen
	
	; This is just to test that GetKeyPadInput works by outputting the result to
	; the LEDs. Ideally this function waits until we press a key. The only time
	; we ever need to interrupt this input is on the title screen when picking
	; a difficulty (which we can make a "bail" function for).
	;call GetKeyPadInput
	;ser r16
	;out PORTC, r16
	rjmp Halt

; Displays the title screen of the game.
; Called from Start
; Polls the keypad for difficulty
;	polling can be interrupted by PB1
;   which cancells polling and starts the game.
TitleScreen:
	push temp1
	do_lcd_command LCD_CLEARDISPLAY

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

	ldi temp1, FLAG_SET
	sts keypadFlag, temp1
	rcall PollForDifficulty

	ldi temp1, FLAG_UNSET
	sts keypadFlag, temp1 ; turn off the keypad polling

	pop temp1
	ret

; Starts the 3 second countdown to start the game
; Called from pushButtonLeft in button.asm
; TODO: Cancel pb1 interrupts
StartTitleWait:
	push temp1
	rcall disablePB1
	ldi temp1, FLAG_UNSET
	sts keypadFlag, temp1 ; turn off the keypad polling
	ldi temp1, MODE_TITLEWAIT 
	sts currentMode, temp1 ; change mode
	clr temp1
	sts timer0Counter, temp1
	sts timer0Counter+1, temp1 ; reset the timer
	ldi temp1, 3
	sts timer0Seconds, temp1

	do_lcd_command LCD_CLEARDISPLAY
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
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data ' '
	rcall DisplayIAsAscii
	pop temp1
	ret

; Displays the title wait screen with the value in timer0Seconds
; Called from StartTitleWait and timer0GameTimer
; for the title wait (countdown), reset pot screen, and find pot screen
UpdateTitleWait:
	push temp1

	lds temp1, timer0Seconds
	do_lcd_command (16)
	do_lcd_command (16)
	do_lcd_command (16)
	rcall DisplayIAsAscii

	pop temp1
	ret

; Starts a new round with the Reset potent screen
; Increments the stage, sets the game timer to 0
InitialStartResetPotent:
	push temp1
	lds temp1, currentStage
	inc temp1					; increment the round counter
	sts currentStage, temp1

	clr temp1
	sts timer0Counter, temp1	; set the game length based on difficulty
	sts timer0Counter+1, temp1
	rcall StartResetPotent

	pop temp1
	ret
	
; Starts the game section involving finding the right potential setting.
; Called from InitialStartResetPotent and HandleFindPotMode in potentiometer.asm
; This creates a new random potential to find.
; Sets the mode to RESETPOTENT
StartResetPotent:
	push temp1

	do_lcd_command LCD_CLEARDISPLAY
	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'O'
	do_lcd_data 'T'
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_command LCD_SECONDLINE
	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 'm'
	do_lcd_data 'a'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ':'
	do_lcd_data ' '

	lds temp1, timer0Seconds
	rcall displayIAsAscii
	
	ldi temp1, MODE_RESETPOTENT
	sts currentMode, temp1		; change mode
	
	pop temp1
	ret

; Sets the GameSecondsBased on difficulty
; called by StartResetPotent and HandleFindPotMode in potentiometer.asm
SetGameSeconds:
	push temp1
	push temp2
	
	ldi temp2, 20 ; else timer = 20
	test_easy:
		lds temp1, difficultyLevel
		cpi temp1, DIFFICULTY_EASY
		brne test_med
		jmp storeDifficultySeconds
	test_med:
		cpi temp1, DIFFICULTY_MEDIUM
		brne test_hard
		ldi temp2, 15
		jmp storeDifficultySeconds
	test_hard:
		cpi temp1, DIFFICULTY_HARD
		brne test_rlyhard
		ldi temp2, 10
		jmp storeDifficultySeconds
	test_rlyhard:
		cpi temp1, DIFFICULTY_REALLYHARD
		brne storeDifficultySeconds
		ldi temp2, 6
	
	storeDifficultySeconds:	
		sts timer0Seconds, temp2
	
	return_SetGameSeconds:
		pop temp2
		pop temp1
		ret

; Arguments: gametimervalue in temp1
; Updates the last three digits displayed on the screen
; Called by timer0GameTimer
; For the title wait mode, pot reset and find pot screens
UpdateResetPotent:
	do_lcd_command (16)
	do_lcd_command (16)
	do_lcd_command (16)
	rcall DisplayIAsAscii
	ret

; Loads the Find Potent Mode screen to the LCD
; Generates a new random potent value for the user to find
; TODO: take the generation method out of this function,
;		so the user will try to find the same potent value if they go over.
; Changes the mode to MODE_FINDPOTENT
StartFindPotent:
	push temp1

	do_lcd_command LCD_CLEARDISPLAY
	do_lcd_data 'F'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'O'
	do_lcd_data 'T'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'o'
	do_lcd_data 's'
	do_lcd_command LCD_SECONDLINE
	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 'm'
	do_lcd_data 'a'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ':'
	do_lcd_data ' '
	lds temp1, timer0Seconds
	rcall displayIAsAscii

	call GenerateNewRandomPotent

	ldi temp1, MODE_FINDPOTENT
	sts currentMode, temp1

	pop temp1
	ret

; Starts the section that involves finding the hidden code character.
; Called from Timer0PotTimer
; After return:
;		timer0 returns back to the Halt loop, which detects the change in mode 
;		and starts the FindCodeKeypadLoop routine.
;		This is done to save space on the stack. (As halt is basically the bottom of the stack)
; Displays the Start Find Code screen on the LCD
; Generates the hidden code to find for this round
StartFindCode:
	push temp1
	push temp2
	push r16
	push r17

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
		do_lcd_command LCD_CLEARDISPLAY
		do_lcd_data 'P'
		do_lcd_data 'o'
		do_lcd_data 's'
		do_lcd_data 'i'
		do_lcd_data 't'
		do_lcd_data 'i'
		do_lcd_data 'o'
		do_lcd_data 'n'
		do_lcd_data ' '
		do_lcd_data 'F'
		do_lcd_data 'o'
		do_lcd_data 'u'
		do_lcd_data 'n'
		do_lcd_data 'd'
		do_lcd_data '!'
		do_lcd_command LCD_SECONDLINE
		do_lcd_data 'S'
		do_lcd_data 'c'
		do_lcd_data 'a'
		do_lcd_data 'n'
		do_lcd_data ' '
		do_lcd_data 'f'
		do_lcd_data 'o'
		do_lcd_data 'r'
		do_lcd_data ' '
		do_lcd_data 'N'
		do_lcd_data 'u'
		do_lcd_data 'm'
		do_lcd_data 'b'
		do_lcd_data 'e'
		do_lcd_data 'r'
	
	ldi r16, MODE_FINDCODE
	sts currentMode, r16
	clr r16
	out portc, r16 ; clear the LEDS from find pot mode
	out portg, r16 ; clear the leds from find pot mode

	return_StartFindCode: ; returns back to calling function (pot timer)
		pop r17
		pop r16
		pop temp2
		pop temp1
		ret

; Polls the keypad and waits for the correct input
; If the correct input is pressed, sets the keypadDownFlag
; Timer0 counts how long this flag is pressed,
; will progress to MODE_END_ROUND when complete.
FindCodeKeypadLoop:
	push temp1
	push temp2
	push r16

	ldi temp1, FLAG_SET
	sts keypadFlag, temp1 ; turn on keypad
	ldi r16, FLAG_UNSET		; unset keypad hold flag
	sts keypadHoldFlag, r16

	lds temp1, currentRandomCode ; get the random code
	FindCode_loop:
		rcall GetKeyPadInput
		; if code is correct: break to find code correct
		cp r16, temp1
		breq FindCode_correct
		; code incorrect
		ldi r16, FLAG_UNSET
		sts keypadHoldFlag, r16
		rjmp FindCode_loop

	FindCode_correct:
		; Correct Input Detected
		; if the keypadHoldFlag is set: continue
		; if keypadFlag is unset: return (second has passed)
		
		lds temp2, keypadFlag 
		cpi temp2, FLAG_UNSET		; test keypadFlag
		breq return_FindCodeKeypadLoop	; return if unset

		lds temp2, keypadHoldFlag	; test the hold flag
		cpi temp2, FLAG_SET			; no work needed if set: loop again
		breq FindCode_loop
		;	else: set keypadHoldFlag
		;		: set keypadHold Timer (using pot timer since it's not used in this section)
		clr temp2
		sts potTimer, temp2	; clear the timer
		sts potTimer+1, temp2	; clear the timer
		
		rcall MotorMaxPower		; start motor
		
		ldi temp2, FLAG_SET
		sts keypadHoldFlag, temp2 ; set the keypadHoldFlag
		rjmp FindCode_loop ; jump back to keypad loop
	
	; correct key is found, jump to change mode
	
	return_FindCodeKeypadLoop:
		pop r16
		pop temp2
		pop temp1
		ret

; Starts a new round or ends the game.
; If currentStage == 3: goes to StartGameOver
; If currentStage <= 3: goes to newound
; Note: This is not a function to save memory on the stack
; No need to push registers as 
; Called from Halt_changeToRoundEndMode (which isn't a function either)
StartNewRoundOrGameOver:
	lds temp1, currentStage
	cpi temp1, 3
	brlt StartNewRoundOrGameOver_nR
	; Game Over

	StartNewRoundOrGameOver_nR:
		rcall InitialStartResetPotent
		rjmp Halt
		
; Loads the timeout Screen
; Disables all flags
; Waits for input from keypad or interrupt from button
TimeoutScreen:
	do_lcd_command LCD_CLEARDISPLAY
	do_lcd_data 'G'
	do_lcd_data 'a'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data ' '
	do_lcd_data 'O'
	do_lcd_data 'v'
	do_lcd_data 'e'
	do_lcd_data 'r'
	do_lcd_command LCD_SECONDLINE
	do_lcd_data 'Y'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data ' '
	do_lcd_data 'L'
	do_lcd_data 'o'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data '!'

	rcall DisableAllFlags
	
	clr temp1
	out portc, temp1
	out portg, temp1

	ldi temp1, MODE_GAMELOSE
	sts currentMode, temp1

	ldi temp1, FLAG_SET
	sts keypadFlag, temp1
	rcall GetKeypadInput
	rjmp SetupMainVariables


; Creates a new random potential and stores it.
GenerateNewRandomPotent:
	push r16
	call CreateRandomValue
	lds r16, currentRandomValue
	; TODO: Figure out any refinements we need to make this work properly.
	; (restrict it to a range?)
	sts currentDesiredPot, r16
	pop r16
	ret
	
; Creates a new random digit and stores it.
GenerateNewRandomCodeDigit:
	push r16
	push r17
	push r18
	;call CreateRandomValue
	;lds r16, currentRandomValue
	;ldi r17, 10
	;rcall Divide
	;sts currentRandomCode, r18
	ldi r16, KEYPAD_1
	sts currentRandomCode, r16
	pop r18
	pop r17
	pop r16
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


.def remainder = R4
.def divisor  = R16
.def returnL  = R2
.def returnH  = R3
; tests the divide 2 byte function,
; TODO: Delete this before submission
testDivide2Byte:
	ldi divisor, 10
	ldi temp2, 0
	ldi temp1, 25
	rcall Divide2Byte

	loop: rjmp loop
; divides a 2 byte number with a 1 byte number and returns a 2 byte result with remainder
Divide2Byte:
	push temp1
	push temp2
	push divisor
	clr remainder
	clr returnH 
	clr returnL
	inc returnL 
	div8a:
		clc      ; clear carry-bit
		rol temp1 ; rotate the next-upper bit of the number
		rol temp2 ; to the interim register (multiply by 2)
		rol remainder
		brcs div8b ; a one has rolled left, so subtract
		cp remainder,divisor ; Division result 1 or 0?
		brcs div8c  ; jump over subtraction, if smaller
	div8b:
		sub remainder,divisor; subtract number to divide with
		sec      ; set carry-bit, result is a 1
		rjmp div8d  ; jump to shift of the result bit
	div8c:
		clc      ; clear carry-bit, resulting bit is a 0
	div8d:
		rol returnL  ; rotate carry-bit into result registers
		rol returnH
		brcc div8a  ; as long as zero rotate out of the result
					; registers: go on with the division loop
	pop divisor
	pop temp2
	pop temp1
	ret

.undef remainder
.undef divisor
.undef returnL
.undef returnH


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

; Polls the keypad and changes the difficulty based on the alphabetic key pressed.
; To enable polling the keypad set keypadFlag to FLAG_SET. 
; To break this loop externally (for a push button press for example)
; set keypadFlag to FLAG_UNSET
PollForDifficulty:
	push r16
	push temp1
	clr temp1
	clr r16
	loop_PollForDifficulty:
		rcall GetKeypadInput
		lds temp1, keypadFlag
		cpi temp1, FLAG_SET
		brne return_PollForDifficulty
		cpi r16, KEYPAD_A
		breq SetDifficultyEasy
		cpi r16, KEYPAD_B
		breq SetDifficultyMedium
		cpi r16, KEYPAD_C
		breq SetDifficultyHard
		cpi r16, KEYPAD_D
		breq SetDifficultyReallyHard
		rjmp loop_PollForDifficulty
	return_PollForDifficulty:
		pop temp1
		pop r16
		ret

SetDifficultyEasy:
	ldi r16, DIFFICULTY_EASY
	sts difficultyLevel, r16
	rjmp loop_PollForDifficulty

SetDifficultyMedium:
	ldi r16, DIFFICULTY_MEDIUM
	sts difficultyLevel, r16
	rjmp loop_PollForDifficulty

SetDifficultyHard:
	ldi r16, DIFFICULTY_HARD
	sts difficultyLevel, r16
	rjmp loop_PollForDifficulty

SetDifficultyReallyHard:
	ldi r16, DIFFICULTY_REALLYHARD
	sts difficultyLevel, r16
	rjmp loop_PollForDifficulty

Halt:
	lds r16, currentMode
	cpi r16, MODE_FINDCODE
	breq Halt_changeToFindCodeMode
	cpi r16, MODE_END_ROUND
	breq Halt_changeToRoundEndMode
	cpi r16, MODE_GAMELOSE
	breq Halt_changeToTimeoutMode
	rjmp Halt


Halt_changeToFindCodeMode:
	rcall FindCodeKeypadLoop
	rjmp Halt

Halt_changeToRoundEndMode:
	rjmp StartNewRoundOrGameOver

Halt_changeToTimeoutMode:
	rjmp TimeOutScreen
	

.def temp3 = r16
; Displays a one byte number given in temp1 to the lcd display.
; TODO: remove leading zeros
DisplayIAsASCII:
	push yh
	push yl
	push temp1
	push temp2
	push temp3
	incStack 6
	std Y+1, temp1 ; load starting number
	std Y+2, temp2
	clr temp3
	std Y+2, temp3 ; num Hundreds
	std Y+3, temp3 ; num tens
	std Y+4, temp3 ; num ones

	divOneHundred:
		cpi temp1, 100
		brlo pushHundreds
		subi temp1, 100
		inc temp3
		rjmp divOneHundred
	
	pushHundreds:
		std Y+2, temp3
		clr temp3

	divTen:
		cpi temp1, 10
		brlo pushTens
		subi temp1, 10
		inc temp3
		rjmp divTen

	pushTens:
		std Y+3, temp3
		clr temp3

	divOne:
		cpi temp1, 1
		brlo pushOnes
		subi temp1, 1
		inc temp3
		rjmp divOne

	pushOnes:
		std Y+4, temp3
	
	;printHundreds:
		ldd temp2, y+2
		;cpi temp2, 0
		;breq printTens
		subi temp2, -'0'
		do_lcd_data_reg temp2

	;printTens:
		ldd temp2, y+3
		;cpi temp2, 0
		;breq printOnes
		subi temp2, -'0'
		do_lcd_data_reg temp2

	;printOnes:
		ldd temp2, y+4
		subi temp2, -'0'
		do_lcd_data_reg temp2

	return_displayIAsASCII:
		decStack 6
		pop temp3
		pop temp2
		pop temp1
		pop yl
		pop yh
		ret

; Main routine for counting down the game timer
; called from timer0Interrupt in timer.asm
; Called in MODE_RESETPOTENT and MODE_FINDPOTENT
Timer0GameTimer:
	push temp1
	push temp2
	push r16
	
	; title wait 
	; count down from 3, 
	; when == 0: switch to reset potentmode
	; otherwise: update timer on screen
	;	return
	handleTitleWait:
		lds r16, currentMode
		cpi r16, MODE_TITLEWAIT
		brne handleGameTimer
		lds temp1, timer0Seconds
		dec temp1
		cpi temp1, 0
		breq switchToResetPotentMode

		sts timer0Seconds, temp1
		rcall UpdateTitleWait
		rjmp return_Timer0GameTimer

		switchToResetPotentMode:
			rcall SetGameSeconds
			rcall InitialStartResetPotent
			rjmp return_Timer0GameTimer
	; Game Timer
	; if mode == resetpotent or findpotent
	; count down from game length timer
	; update screen timer
	; when == 0: switch to timeout mode (Halt will detect this and jump to the screen)
	; otherwise: update timer on screen
	;	return	
	handleGameTimer:
		cpi r16, MODE_RESETPOTENT
		breq updateGameTimer
		cpi r16, MODE_FINDPOTENT
		breq updateGameTimer
		rjmp return_Timer0GameTimer
	updateGameTimer:
		lds temp1, timer0Seconds
		dec temp1
		sts timer0Seconds, temp1
		cpi temp1, 0
		breq timeout

		rcall UpdateResetPotent
		rjmp return_Timer0GameTimer

	timeout:
		;rcall TimeoutScreen
		ldi temp1, MODE_GAMELOSE
		sts currentMode, temp1
	
	; TODO: Game timer - > 250ms beep
	; todo: backlight timer
	; TODO: 500ms start game beep
	return_Timer0GameTimer:
		pop r16
		pop temp2
		pop temp1
		ret

; Main function for handling the pot counter
; Called from Timer0Interrupt in timer.asm
; Only called in MODE_RESETPOTENT and MODE_FINDPOTENT
; Handles changes from MODE_RESETPOTENT -> MODE_FINDPOTENT
;						and	MODE_FINDPOTENT -> MODE_FINDCODE
Timer0PotTimer:
	push temp1
	push temp2
	push r16

	; is flag set?
	lds r16, potFlag
	cpi r16, FLAG_SET
	brne return_Timer0PotTimer

	lds temp1, potTimer
	lds temp2, potTimer+1
	adiw temp2:temp1, 1
	sts potTimer, temp1
	sts potTimer+1, temp2
	lds r16, currentMode
	cpi r16, MODE_FINDPOTENT
	breq Timer0PotTimer_Second
	; If MODE_RESETPOTENT:	
	;	check if timer has run for a half second
	;	if true:
	;		change to MODE_FINDPOTENT
	Timer0PotTimer_halfSecond:
		ldi r16, high(HALF_SECOND_INTERVAL)
		cpi temp1, low(HALF_SECOND_INTERVAL)
		cpc temp2, r16
		breq switchToFindPotentMode
		rjmp return_Timer0PotTimer
	; If MODE_FINDPOTENT:	
	;	check if timer has run for a full second
	;	if true:
	;		change to MODE_FINDCODE
	Timer0PotTimer_Second:
		ldi r16, high(SECOND_INTERVAL)
		cpi temp1, low(SECOND_INTERVAL)
		cpc temp2, r16
		breq switchToFindCodeMode
		rjmp return_Timer0PotTimer
	; Changes to Find potent 
	switchToFindPotentMode:
		ldi r16, FLAG_UNSET
		sts potFlag, r16 ; turn off the pot input
		rcall StartFindPotent
		rjmp return_Timer0PotTimer
	; Changes to find code
	switchToFindCodeMode:
		; clear the leds after find pot mode
		ldi r16, FLAG_UNSET
		sts potFlag, r16 ; turn off pot input
		rcall StartFindCode
		rjmp return_Timer0PotTimer
		
	return_Timer0PotTimer:
		pop r16
		pop temp2
		pop temp1
		ret

; Main routine for timing how long the keypad has been pressed
; Called from Timer0Interrupt in timer.asm
; Called in MODE_FINDCODE
; Progresses game from MODE_FINDCODE -> MODE_END_ROUND
; 
Timer0KeypadTimer:
	push temp1
	push temp2
	push r16
	; if keypadHoldFlag is set: execute routine
	; else: 
	;		if motor is on:
	;			turn off motor
	;		return
	
	; if key pad is held down: execute routine
	; else: check motor and return
	Timer0KeypadTimer_testFlag:
		lds temp1, keypadHoldFlag
		cpi temp1, FLAG_SET
		breq Timer0KeypadTimer_main
	; if key is not held and motor is running: turn off the motor
	Timer0KeypadTimer_testMotor:
		lds  temp1, OCR3BL
		cpi temp1, 0
		brne Timer0KeypadTimer_motorOff
		rjmp return_Timer0KeypadTimer

	Timer0KeypadTimer_main:
	; increment timer
	lds temp1, potTimer
	lds temp2, potTimer+1
	adiw temp2:temp1, 1
	
	; store timer
	sts potTimer, temp1
	sts potTimer+1, temp2

	; turn on motor
	;rcall MotorMaxPower
	
	; if a second has passed: switch to round completion mode
	; else: return 
	ldi r16, high(SECOND_INTERVAL)
	cpi temp1, low(SECOND_INTERVAL)
	cpc temp2, r16
	breq switchToRoundCompletionMode

	rjmp return_Timer0KeypadTimer

	; End of round
	; turn off motor
	; turn off keypad
	; change mode
	switchToRoundCompletionMode:
		ldi r16, FLAG_UNSET
		sts keypadHoldFlag, r16
		sts keypadFlag, r16
		ldi temp1, MODE_END_ROUND
		sts currentMode, temp1
		rcall MotorOff

		rjmp return_Timer0KeypadTimer

	Timer0KeypadTimer_motorOff:
		rcall MotorOff

	return_Timer0KeypadTimer:
		pop r16
		pop temp2
		pop temp1
		ret