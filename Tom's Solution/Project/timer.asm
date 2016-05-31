; timer.asm
; Handles the timer stuff.

.ifndef TIMER_ASM
.equ TIMER_ASM = 1
.equ DEBOUNCE_INTERVAL = 700
.equ SECOND_INTERVAL = 7812
.equ HALF_SECOND_INTERVAL = 3906
.def temp1 = r24
.def temp2 = r25
.def temp3 = r16
.def temp4 = r17

; PUSH BUTTON DEBOUNCE TIMER
Timer0Interrupt:
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	push r16
	;lds r16, difficultyLevel
	;out portc, r16
	testPB1:
		lds temp1, PB1dbFlag
		cpi temp1, flagSet
		brne testPB0
		rcall handlePB1
	testPB0:
		lds temp1, PB0dbFlag
		cpi temp1, flagSet
		brne testForSecond
		rcall handlePB0
		
	testForSecond: ; use for countdown and game counter
		lds temp1, timer0Counter
		lds temp2, timer0Counter+1
		adiw temp2:temp1, 1
		ldi r16, high(SECOND_INTERVAL)
		cpi temp1, low(SECOND_INTERVAL)
		cpc temp2, r16
		brlt storeTimer0Counter
		clr temp1
		clr temp2
	
	rcall Timer0GameTimer

	storeTimer0Counter:
		sts timer0Counter, temp1
		sts timer0Counter+1, temp2

	testPotTimer:
		; if mode == ResetPot or FindPot
		lds r16, currentMode
		cpi r16, MODE_RESETPOTENT
		breq GotoPotTimerHandler
		cpi r16, MODE_FINDPOTENT
		breq GotoPotTimerHandler
		; else: skip
		rjmp testKeyPadTimer
	
	GotoPotTimerHandler:
		rcall Timer0PotTimer

	testKeyPadTimer:
		lds r16, currentMode
		cpi r16, MODE_FINDCODE
		breq gotoKeyPadTimerHandler
		rjmp return_Timer0Interrupt
	gotoKeyPadTimerHandler:
		rcall Timer0KeypadTimer

	return_Timer0Interrupt:
		pop r16
		pop temp2
		pop temp1
		out SREG, temp1
		pop temp1
		reti

handlePB1:
	push temp1
	push temp2
	push r20

	lds temp1, PB1dbTimer
	lds temp2, PB1dbTimer+1
	adiw temp2:temp1, 1
	ldi r20, high(DEBOUNCE_INTERVAL)
	cpi temp1, low(DEBOUNCE_INTERVAL)
	cpc temp2, r20
	brlt storePB1dbTimer

	ldi temp1, flagUnSet
	sts PB1dbFlag, temp1
	clr temp1
	clr temp2

	storePB1dbTimer:
		sts PB1dbTimer, temp1
		sts PB1dbTimer+1, temp2
	
	pop r20
	pop temp1
	pop temp2
	ret

handlePB0:
	push temp1
	push temp2
	push r20

	lds temp1, PB0dbTimer
	lds temp2, PB0dbTimer+1
	adiw temp2:temp1, 1
	ldi r20, high(DEBOUNCE_INTERVAL)
	cpi temp1, low(DEBOUNCE_INTERVAL)
	cpc temp2, r20
	brlt storePB0dbTimer

	ldi temp1, flagUnSet
	sts PB0dbFlag, temp1
	clr temp1
	clr temp2

	storePB0dbTimer:
		sts PB0dbTimer, temp1
		sts PB0dbTimer+1, temp2
	
	pop r20
	pop temp1
	pop temp2
	ret

; Sets up timer0 with the right stuff (from the lecture sides).
; USED AS DEBOUNCE TIMER
SetupTimer0:
	push temp1
	ldi temp1, 0b00000000
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1
	ldi temp1, 1 << TOIE0
	sts TIMSK0, temp1
	pop temp1
	ret

.undef temp1
.undef temp2
.undef temp3
.undef temp4
.endif