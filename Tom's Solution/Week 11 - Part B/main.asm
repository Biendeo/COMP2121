; Lab 5 Part B - LED Brightness

.include "m2560def.inc"

.def temp1 = r24
.def temp2 = r25
.equ pwmCycle = 0xFF

.cseg
.org 0x0000
	rjmp RESET
.org OVF3addr
	jmp TIMER3ovf
	jmp DEFAULT
DEFAULT: reti

RESET:
	ldi yh, high(ramend)
	ldi yl, low(ramend)
	out sph, yh
	out spl, yl

	; leds
	ser temp1
	out DDRC, temp1

	; setup timer 3
	ldi temp1, 1<<TOIE3
	sts TIMSK3, temp1

	ldi temp1, (1<<CS30)	; no prescaler for timer3
	sts TCCR3B, temp1		; TCCRNB handles prescaling
	ldi temp1, (1<<WGM30)|(1<<COM3B1) ; wgm30: pwm, phase correct. com3b1, compare output channel b used 
	sts TCCR3A, temp1 ; TCCRNA handles copmare output mode

	ldi temp1, 	1<<DDE2; oc3b as output
	out DDRE, temp1	; lab says pin pe2 but manual says pe4

	; configure output compare match
	ser temp1
	sts OCR3BL, temp1
	clr temp1
	sts OCR3BH, temp1

	sei

main:
	rjmp main

TIMER3ovf:
	push yh
	push yl
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	

	;in temp1, portE
	;out portc, temp1

	pop temp2
	pop temp1
	out SREG, temp1
	pop temp1
	pop yl
	pop yh
	reti