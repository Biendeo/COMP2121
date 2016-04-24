;
; part c.asm
;
; Created: 23/04/2016 16:59:28
; Author : Julian Blacket
; Replace with your application code
.include "m2560def.inc"

.equ patternlength = 8
.equ timerinterval = 7812
.equ maxflashes = 6
.def temp1 = r20
.def temp2 = r21
.def patterntemp = r22
.def patternlengthtemp = r23
.def flashcountertemp = r24
.def activepatternstemp = r16

.dseg
pattern: .byte 1
currentpattern: .byte 1
patternindex: .byte 1
activepatterns: .byte 1
ispatterndisplayed: .byte 1
flashcounter: .byte 1
timercounter: .byte 2

.cseg
.org 0x0000
	jmp reset
.org INT0addr
	jmp setZero
.org INT1addr
	jmp setOne
.org OVF0addr
	jmp timer0Interrupt


reset:
	ldi yl, low(ramend)
	ldi yh, high(ramend)
	out spl, yl
	out sph, yh

	; write 0 to counter and pattern
	ldi yh, high(patternindex<<1)
	ldi yl, low(patternindex<<1)
	clr temp1
	st y, temp1
	ldi yh, high(pattern<<1)
	ldi yl, low(pattern<<1)
	st y, temp1
	ldi yh, high(flashcounter<<1)
	ldi yl, low(flashcounter<<1)
	st y, temp1

	; set prescaling value of the timer
	ldi temp1, 0
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1
	ldi temp1, 1<<TOIE0
	sts TIMSK0, temp1

	; set port b as input 
	clr temp1
	out DDRB, temp1
	out PORTB, temp1
	out PORTC, temp1
	; set port c as output
	ser temp1
	out DDRC, temp1

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
	rjmp wait
	
setOne:
	push temp1
	in temp1, SREG	
	push temp1
	push temp2
	push patterntemp
	push patternlengthtemp

	ldi temp1, 0xff
	delay: ; need to find a better way to handle buttons
		dec temp1
		cpi temp1, 0
		brne delay
	ldi temp1, 0xff
	delay1: 
		dec temp1
		cpi temp1, 0
		brne delay1
	
	;getPatternLength:
	lds patternlengthtemp, patternindex

	addOneToPattern:
		ldi temp1, 0b10000000
		mov temp2, patternlengthtemp
		rcall rightRotN			; temp1 = number to rotate, temp2 = number of times to rotate
		lds patterntemp, currentpattern
		or patterntemp, temp1

	rcall storeNewPattern

	pop patternlengthtemp
	pop patterntemp
	pop temp2
	pop temp1
	out SREG, temp1
	pop temp1
	reti

setZero:
	push temp1
	in temp1, SREG	
	push temp1
	push temp2
	push patterntemp
	push patternlengthtemp

	ldi temp1, 0xff
	delayPB0: ; need to find a better way to handle buttons
		dec temp1
		cpi temp1, 0
		brne delayPB0
	ldi temp1, 0xff
	delay1PB0: 
		dec temp1
		cpi temp1, 0
		brne delay1PB0
	
	getPatternLength:
		lds patternlengthtemp, patternindex

	addZeroToPattern:
		ldi temp1, 0b01111111
		mov temp2, patternlengthtemp
		rcall rightRotN			; temp1 = number to shift, temp2 = number of times to shift
		lds patterntemp, currentpattern
		and patterntemp, temp1
		
	rcall storeNewPattern
		
	pop patternlengthtemp
	pop patterntemp
	pop temp2
	pop temp1
	out SREG, temp1
	pop temp1
	reti

; assume patterntemp, patternlengthtemp has been set
storeNewPattern:
	sts currentpattern, patterntemp
	;out PORTC, patterntemp ; debug - display the pattern
	inc patternlengthtemp
	cpi patternlengthtemp, patternlength
	brlt storePatternLength
	; reached a full new pattern
	; if active patterns == 0, set pattern to currentpattern, clear currentpattern
	; else leave as currentpattern
	; inc active patterns
	clr patternlengthtemp
	lds activepatternstemp, activepatterns
	cpi activepatternstemp, 0
	brne incrementActivePatterns
	sts pattern, patterntemp
	ldi temp1, 0
	sts currentpattern, temp1
	incrementActivePatterns:
		inc activepatternstemp
		sts activepatterns, activepatternstemp
	storePatternLength:
		sts patternindex, patternlengthtemp
	ret

timer0Interrupt:
	push temp1
	in temp1, SREG
	push temp1
	push yh
	push yl
	push temp2
	push patterntemp
	; return if no active patterns are ready to be displayed
	lds temp1, activepatterns
	cpi temp1, 0
	breq returntimer0Interrupt
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
	; toggle the pattern

	;lds temp1, pattern ; debug
	;neg temp1
	;sts pattern, temp1
	;out portc, temp1
	;jmp returntimer0Interrupt



	; if numflashes == 0: turn on display
	lds temp1, ispatterndisplayed
	cpi temp1, 1
	breq undisplayPattern
	displayPattern:
		lds patterntemp, pattern
		out PORTC, patterntemp
		ldi temp1, 1
		sts ispatterndisplayed, temp1
		rjmp incrementFlashesCounter
	undisplayPattern:
		lds patterntemp, 0b00000000
		out PORTC, patterntemp
		ldi temp1, 0
		sts ispatterndisplayed, temp1
		
	incrementFlashesCounter:
		lds flashcountertemp, flashcounter
		inc flashcountertemp
		cpi flashcountertemp, maxflashes
		brlt storeFlashesCounter
		; if max flashes reached:
		; set flashes to zero
		; decrement the activepatterns
		; load the next pattern, if needed
		clr flashcountertemp
		lds temp1, activepatterns
		subi temp1, 1
		sts activepatterns, temp1
		cpi temp1, 0
		breq storeFlashesCounter
		; load next pattern
		lds patterntemp, currentpattern
		sts pattern, patterntemp
		clr temp1
		sts currentpattern, temp1
		
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
	
; Left rotates a number N times
; params: number to shift, number of times to rotate: r20, r21
; return r20
rightRotN:
	push r21
	push r22 ; counter
	clr r22
	loop:
		cp r22, r21
		brge returnRightRotN
		clc
		ror r20
		inc r22
		rjmp loop
	returnRightRotN:
		pop r22
		pop r21
		ret

wait:
	rjmp wait
