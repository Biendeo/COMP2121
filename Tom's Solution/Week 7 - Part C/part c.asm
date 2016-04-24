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

.dseg
pattern: .byte 1
currentpattern: .byte 1
counter: .byte 1
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
	ldi yh, high(counter<<1)
	ldi yl, low(counter<<1)
	clr temp1
	st y, temp1
	ldi yh, high(pattern<<1)
	ldi yl, low(pattern<<1)
	st y, temp1
	ldi yh, high(flashcounter<<1)
	ldi yl, low(flashcounter<<1)
	st y, temp1

	; set prescaling value of the timer
	ldi temp1, 0b00000000
	out TCCR0A, temp1 
	ldi temp1, 0b00000010
	out TCCR0B, temp1 ; Prescaling value=8 

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
	lds patternlengthtemp, counter

	addZeroToPattern:
		ldi temp1, 0b10000000
		mov temp2, patternlengthtemp
		rcall rightRotN			; temp1 = number to shift, temp2 = number of times to shift
		lds patterntemp, pattern
		or patterntemp, temp1
		sts pattern, patterntemp
		out PORTC, patterntemp
	;incrementPatternLength:
		inc patternlengthtemp
		cpi patternlengthtemp, patternlength
		brlt storePatternLength1
		clr patternlengthtemp	; clear pattern length
	;storeNewPattern:
		sts currentpattern, patterntemp	; store pattern in currentpattern
		;out PORTC, patterntemp
	storePatternLength1:
		sts counter, patternlengthtemp
	
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
		lds patternlengthtemp, counter

	updatePattern:
		ldi temp1, 0b01111111
		mov temp2, patternlengthtemp
		rcall rightRotN			; temp1 = number to shift, temp2 = number of times to shift
		lds patterntemp, pattern
		and patterntemp, temp1
		sts pattern, patterntemp
		out PORTC, patterntemp
	incPatternLength:
		inc patternlengthtemp
		cpi patternlengthtemp, patternlength
		brlt storePatternLength
		clr patternlengthtemp	; clear pattern length
	storeNewPattern:
		sts currentpattern, patterntemp	; store pattern in currentpattern
	storePatternLength:
		sts counter, patternlengthtemp
	
	pop patternlengthtemp
	pop patterntemp
	pop temp2
	pop temp1
	out SREG, temp1
	pop temp1
	reti

enableTimer0:
	push yh
	push yl
	push temp1
	ldi yh, high(TIMSK0<<1) ; preserve mask value
	ldi yl, low(TIMSK0<<1)
	ld temp1, y
	ori temp1,  1<<TOIE0
	sts TIMSK0, temp1 ; enable timer interrupt from timer0
	pop temp1
	pop yl
	pop yh
	ret
disableTimer0:
	push yh
	push yl
	push temp1
	ldi yh, high(TIMSK0<<1) ; preserve mask value
	ldi yl, low(TIMSK0<<1)
	ld temp1, y
	andi temp1, 0b11111110<<TOIE0
	sts TIMSK0, temp1 ; disable timer interrupt from timer0
	pop temp1
	pop yl
	pop yh
	ret

timer0Interrupt:
	push temp1
	in temp1, SREG
	push temp1
	push yh
	push yl
	push temp2
	push patterntemp

	lds yl, timercounter
	lds yh, timercounter+1
	adiw yh:yl, 1
	cpi yl, low(timerinterval)
	ldi temp1, high(timerinterval)
	cpc yh, temp1
	brlt storeTimer
	clr temp1
	resetTimerCounter:
		sts timercounter, temp1
		sts timercounter+1, temp1
	incrementFlashCounter:
		lds yl, flashcounter
		adiw yl, 1
		cpi yl, maxflashes			; flashed this pattern 3 times
		; ????
		sts flashcounter, yl

	storeTimer:
		sts timercounter, yl
		sts timercounter, yh

	pop patterntemp
	pop temp2
	pop yl
	pop yh
	pop temp1
	out SREG, temp1
	pop temp1
	reti
	

turnOnPattern:
	push yh
	push yl
	push patterntemp
	ldi yh, high(pattern<<1)
	ldi yl, high(pattern<<1)
	ld patterntemp, y
	out PORTC, patterntemp
	pop patterntemp
	pop yl
	pop yh

turnOffPattern:
	push yh
	push yl
	push patterntemp
	ldi yh, high(pattern<<1)
	ldi yl, high(pattern<<1)
	ldi patterntemp, 0
	out PORTC, patterntemp
	pop patterntemp
	pop yl
	pop yh

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
