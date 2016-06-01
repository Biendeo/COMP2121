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

; handles strobe light
Timer2Interrupt:
	push temp1
	push temp2
	push r16
	rcall StrobeOn
	;lds temp1, currentMode
	;cpi temp1, MODE_GAMEWIN
	;brne Timer2Interrupt_return

	lds temp1, timer2Counter
	lds temp2, timer2Counter+1
	adiw temp2:temp1, 1

	ldi r16, high(SECOND_INTERVAL)
	cpi temp1, low(SECOND_INTERVAL)
	cpc temp2, r16
	brlt Timer2Interrupt_store

	; TODO: toggle strobe
	rcall StrobeOn

	Timer2Interrupt_store:
		sts timer2Counter, temp1
		sts timer2Counter, temp2
	Timer2Interrupt_return:
		pop r16
		pop temp2
		pop temp1
		reti

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

; Setup timer 2 for strobe light flashes.
SetupTimer2:
	push temp1

	ldi temp1, 0b00000000
	sts TCCR2A, temp1
	ldi temp1, 0b00000010
	sts TCCR2B, temp1
	ldi temp1, 1 << TOIE2
	sts TIMSK2, temp1

	clr temp1
	sts timer2Counter, temp1
	sts timer2Counter+1, temp1

	pop temp1
	ret

SetupTimer3:
	push temp1
	;ldi temp1, (1<<CS00)	; no prescaler for timer3
	;sts TCCR3B, temp1		; TCCRNB handles prescaling
	;ldi temp1, (1<<WGM30)|(1<<COM3B1) ; wgm30: pwm, phase correct. com3b1, compare output channel b used 
	;sts TCCR3A, temp1 ; TCCRNA handles copmare output mode
	
	; duty cycle = nothing
	;clr temp1
	;sts OCR3BL, temp1
	;sts OCR3BH, temp1
	pop temp1
	ret

TIMER3ovf:
	push yh
	push yl
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	push r20
	incStack 2

	; inc timer
	lds temp1, counter
	lds temp2, counter+1
	adiw temp2:temp1, 1
	std Y+1, temp1
	std Y+2, temp2

	; is second?
	cpi temp1, low(seconds)
	ldi r20, high(seconds)
	cpc temp2, r20
	brlt storeTimer

	lds temp1, pattern
	ldi temp2, 0b11111111
	eor temp1, temp2
	;out portc, temp1
	sts pattern, temp1
	decDutyCycle:
		lds temp1, OCR3BL
		lds temp2, OCR3BH
		
		sbiw temp2:temp1, 25
		sts OCR3BL, temp1
		sts OCR3BH, temp2
	
	second:
		;rcall resetDutyCycle
		clr temp1
		std Y+1, temp1
		std Y+2, temp1
		rjmp storeTimer

	storeTimer:
		ldd temp1, y+1
		ldd temp2, y+2
		sts counter, temp1
		sts counter+1, temp2
	
	returnTIMER3ovf:
		decStack 2
		pop r20
		pop temp2
		pop temp1
		out SREG, temp1
		pop temp1
		pop yl
		pop yh
		reti

resetDutyCycle:
	push temp1
	ser temp1
	ser temp2
	pop temp1
	ret 

.undef temp1
.undef temp2
.undef temp3
.undef temp4
.endif