; Lab 5 Part B - LED Brightness

.include "m2560def.inc"

.def temp1 = r24
.def temp2 = r25
.equ seconds = 7000
.equ maxBrightness = 0b1111111111111111

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

.dseg
counter: .byte 2

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
	clr temp1
	sts counter, temp1
	sts counter+1, temp1

	; leds
	ser temp1
	out DDRC, temp1

	; setup timer 3 for interrupts
	ldi temp1, 1<<TOIE3
	sts TIMSK3, temp1


	ldi temp1, (1<<CS30)	; no prescaler for timer3
	sts TCCR3B, temp1		; TCCRNB handles prescaling
	ldi temp1, (1<<WGM32)|(1<<WGM30)|(1<<COM3B1) ; wgm30: pwm, phase correct. com3b1, compare output channel b used 
	sts TCCR3A, temp1 ; TCCRNA handles copmare output mode

	ldi temp1, 	1<<DDE2 ;pe2 is oc3b
	ser temp1
	out DDRE, temp1	; lab says pin pe2 but manual says pe4

	; configure duty cycle
	ser temp1
	sts OCR3BL, temp1
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
	push r20
	incStack 2
	ser temp1

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
	brlt decDutyCycle
	
	second:
		;rcall resetDutyCycle
		clr temp1
		std Y+1, temp1
		std Y+2, temp1
		rjmp storeTimer
	
	decDutyCycle:
		lds temp1, OCR3BL
		lds temp2, OCR3BH
		sbiw temp2:temp1, 63
		sts OCR3BL, temp1
		sts OCR3BH, temp2

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
	ldi temp1, low(maxBrightness)
	ldi temp2, high(maxBrightness)
	sts OCR3BL, temp1
	sts OCR3BH, temp2
	pop temp1
	ret

