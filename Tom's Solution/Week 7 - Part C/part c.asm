;
; part c.asm
;
; Created: 23/04/2016 16:59:28
; Author : Julian Blacket
; Replace with your application code
.include "m2560def.inc"

.equ patternlength = 8
.equ timerinterval = 7812
.equ debounceinterval = 500 ; 10 milliseconds, may need to change
.equ maxflashes = 6
.def temp1 = r20
.def temp2 = r21
.def patterntemp = r22
.def patternlengthtemp = r23
.def flashcountertemp = r24
.def activepatternstemp = r16
.def debouncetemp = r17

.dseg
pattern: .byte 1
currentpattern: .byte 1
patternindex: .byte 1
activepatterns: .byte 1
ispatterndisplayed: .byte 1
flashcounter: .byte 1
timercounter: .byte 2
debouncecounter: .byte 2
debounceflag0: .byte 1
debounceflag1: .byte 1

.cseg
.org 0x0000
	jmp reset
.org INT0addr
	jmp setZero
.org INT1addr
	jmp setOne
.org OVF0addr
	jmp timer0Interrupt

	jmp DEFAULT
DEFAULT: reti

reset:
	ldi yl, low(ramend)
	ldi yh, high(ramend)
	out spl, yl
	out sph, yh

	; set port b as input 
	clr temp1
	out DDRB, temp1

	; set port c as output
	ser temp1
	out DDRC, temp1

	jmp main
	
setOne:
	push temp1
	in temp1, SREG	
	push temp1
	push patterntemp
	push patternlengthtemp

	; if debounce is set, return, else set debounce
	lds debouncetemp, debounceflag1
	cpi debouncetemp, 1
	breq returnSetOne
	ldi debouncetemp, 1
	sts debounceflag1, debouncetemp
	
	; return if activepatterns == 2
	lds activepatternstemp, activepatterns
	cpi activepatternstemp, 2
	breq returnSetOne

	; increment current pattern length
	lds patternlengthtemp, patternindex
	inc patternlengthtemp
	sts patternindex, patternlengthtemp

	addOneToPattern:
		ldi temp1, 0b00000001
		;rcall rightRotN			; temp1 = number to rotate, temp2 = number of times to rotate
		lds patterntemp, currentpattern
		lsl patterntemp
		or patterntemp, temp1
		sts currentpattern, patterntemp
	; if length of current word is pattern length
	; increment stored patterns
	; if no current active pattern, store pattern as current
	cpi patternlengthtemp, patternlength
	brlt returnSetOne
	cpi activepatternstemp, 0
	brne setOne_incActivePatterns
	sts pattern, patterntemp
	setOne_incActivePatterns:
		inc activepatternstemp
		sts activepatterns, activepatternstemp
	returnSetOne:
		pop patternlengthtemp
		pop patterntemp
		pop temp1
		out SREG, temp1
		pop temp1
		reti

setZero:
	push temp1
	in temp1, SREG	
	push temp1
	push patterntemp
	push patternlengthtemp

	; handle debounce
	lds debouncetemp, debounceflag0
	cpi debouncetemp, 1
	breq returnSetZero
	ldi debouncetemp, 1
	sts debounceflag0, debouncetemp
	
	; handle active patterns
	lds activepatternstemp, activepatterns
	cpi activepatternstemp, 2
	breq returnSetZero

	; handle pattern length
	lds patternlengthtemp, patternindex
	inc patternlengthtemp
	sts patternindex, patternlengthtemp

	addZeroToPattern:
		lds patterntemp, currentpattern
		lsl patterntemp
		ldi temp1, 0b11111110
		; rcall rightRotN			; temp1 = number to shift, temp2 = number of times to shift
		and patterntemp, temp1
		sts currentpattern, patterntemp
	; if length of current word is pattern length
	; increment stored patterns
	; if no current active pattern, store pattern as current
	cpi patternlengthtemp, patternlength
	brlt returnSetZero
	cpi activepatternstemp, 0
	brne setZero_incActivePatterns
	sts pattern, patterntemp
	setZero_incActivePatterns:
		inc activepatternstemp
		sts activepatterns, activepatternstemp
	
	returnSetZero:
		pop patternlengthtemp
		pop patterntemp
		pop temp1
		out SREG, temp1
		pop temp1
		reti

timer0Interrupt:
	push temp1
	in temp1, SREG
	push temp1
	push yh
	push yl
	push temp2
	push patterntemp

	; start debounce timers if either debounce is set
	; otherwise set debounce timer and do nothing
	lds debouncetemp, debounceflag0
	cpi debouncetemp, 1
	breq debounceHandle
	lds debouncetemp, debounceflag1
	cpi debouncetemp, 1
	breq debounceHandle
	rjmp testActivePatterns
	debounceHandle:
		rcall handleDebounceTimer
	
	testActivePatterns:
		lds activepatternstemp, activepatterns
		cpi activepatternstemp, 0
		breq returntimer0Interrupt

	incrementMili:
		; increment the milisecond timer
		lds yl, timercounter
		lds yh, timercounter+1
		adiw yh:yl, 1
		; return if a second has not passed
		cpi yl, low(timerinterval)
		ldi temp1, high(timerinterval)
		cpc yh, temp1
		brlt storeTimer

	; a second has passed
	resetTimerCounter:
		clr temp1
		sts timercounter, temp1
		sts timercounter+1, temp1
	; test the pattern

	; toggle display
	lds temp1, ispatterndisplayed
	cpi temp1, 0
	breq displayPattern
	undisplayPattern:
		ldi patterntemp, 0b00000000
		out PORTC, patterntemp
		ldi temp1, 0
		sts ispatterndisplayed, temp1
		rjmp incrementFlashesCounter
	displayPattern:
		lds patterntemp, pattern
		out PORTC, patterntemp
		ldi temp1, 1
		sts ispatterndisplayed, temp1
		
	incrementFlashesCounter:
		;lds flashcountertemp, flashcounter
		;inc flashcountertemp
		;cpi flashcountertemp, maxflashes
		;brlt storeFlashesCounter
		; if max flashes reached:
		; set flashes to zero
		; decrement the activepatterns
		; load the next pattern, if needed
		;lds temp1, activepatterns
		;subi temp1, 1
		;sts activepatterns, temp1
		;cpi temp1, 0
		;breq storeFlashesCounter
		; load next pattern
	changePattern:
		clr flashcountertemp
		clr temp1
		lds patterntemp, currentpattern
		sts pattern, patterntemp
		sts currentpattern, temp1
		sts patternindex, temp1
		lds activepatternstemp, activepatterns
		dec activepatternstemp
		sts activepatterns, activepatternstemp
		
	storeFlashesCounter:
		sts flashcounter, flashcountertemp

	storeTimer:
		sts timercounter, yl
		sts timercounter+1, yh

	returntimer0Interrupt:
		pop patterntemp
		pop temp2
		pop yl
		pop yh
		pop temp1
		out SREG, temp1
		pop temp1
		reti

handleDebounceTimer:
	push yl
	push yh
	push debouncetemp

	lds yl, debouncecounter
	lds yh, debouncecounter+1
	adiw yh:yl, 1
	; if less than debounce timer, do nothing
	; else unset the debounce timer and clear the flags
	cpi yl, low(debounceinterval)
	ldi debouncetemp, high(debounceinterval)
	cpc yh, debouncetemp
	brlt storeDebounceTimer
	clr yl
	clr yh
	sts debounceflag0, yl
	sts debounceflag1, yl
	storeDebounceTimer:
		sts debouncecounter, yl
		sts debouncecounter+1, yh

	returnHandleDebounceTimer:
		pop debouncetemp
		pop yh
		pop yl
		ret

main:
	; clear all data variables
	clr temp1
	sts pattern, temp1
	sts currentpattern, temp1
	sts ispatterndisplayed, temp1
	sts flashcounter, temp1
	sts timercounter, temp1
	sts debouncecounter, temp1
	sts debounceflag0, temp1
	sts debounceflag1, temp1

	; set prescaling value of the timer
	clr temp1
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1
	ldi temp1, 1<<TOIE0
	sts TIMSK0, temp1

	; set as falling edge for int1 and int0
	ldi yh, high(EICRA)
	ldi yl, low(EICRA)		
	ldi temp1, ISC01
	ori temp1, ISC11
	st y, temp1 
	; enable the interrupts
	in temp1, EIMSK
	ori temp1, (1<<INT0)
	ori temp1, (1<<INT1)
	out EIMSK, temp1
	
	sei
	rjmp loop

loop:
	rjmp loop