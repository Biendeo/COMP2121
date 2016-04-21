; Lab 3 Part B - Moving Pattern
.include "m2560def.inc"

.dseg
timerCounter: .byte 2

.cseg
.equ timerLimit = 1 ; Change this to suit the physical board.

.def patternRegisterHigh = r16
.def patternRegisterLow = r17
.equ lightPattern = 0xE00E

.def timerCounterHigh = r18
.def timerCounterLow = r19
.def tempRegOne = r20
.def tempRegTwo = r21

.org 0x0000
	jmp start

.org OVF0addr
	jmp timer0Interrupt

start:
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL, r16

	ldi r16, 0
	ldi ZL, low(timerCounter)
	ldi ZH, high(timerCounter)
	st Z, r16
	adiw Z, 1
	st Z, r16
	sbiw z, 1

	ldi tempRegOne, 0b00000000
	out TCCR0A, tempRegOne
	ldi tempRegOne, 0b00000010
	out TCCR0B, tempRegOne ; Prescaling value=8
	ldi tempRegOne,  1<<TOIE0 ; = 128 microseconds   
	sts TIMSK0, tempRegOne ; T/C0 interrupt enable 

	ldi patternRegisterHigh, high(lightPattern)
	ldi patternRegisterLow, low(lightPattern)

	out DDRC, patternRegisterLow
	out PORTC, patternRegisterLow

	sei

    rjmp halt

; Will change the values in r16 and r17.
timer0Interrupt:
	push timerCounterHigh
	push timerCounterLow
	push tempRegOne
	push tempRegTwo
	push ZH
	push ZL

	timer0InterruptIncrementTimer:
		ldi ZH, high(timerCounter)
		ldi ZL, low(timerCounter)

		lds timerCounterHigh, timerCounter
		lds timerCounterLow, timerCounter + 1

		ldi tempRegOne, 1
		add timerCounterLow, tempRegOne
		ldi tempRegOne, 0
		adc timerCounterHigh, tempRegOne

		st Z, timerCounterHigh
		adiw Z, 1
		st Z, timerCounterLow
		sbiw Z, 1

		rjmp timer0InterruptCheckTime

	timer0InterruptCheckTime:
		cpi timerCounterLow, low(timerLimit)
		brne timer0InterruptFin
		cpi timerCounterHigh, high(timerLimit)
		brne timer0InterruptFin
		rjmp timer0InterruptChangeLights

	timer0InterruptChangeLights:
		ldi tempRegOne, 1
		ldi tempRegTwo, 1
		and tempRegOne, patternRegisterHigh
		and tempRegTwo, patternRegisterLow
		lsr patternRegisterHigh
		lsr patternRegisterLow
		; Have to bit-shift left 7 times.
		lsl tempRegOne
		lsl tempRegOne
		lsl tempRegOne
		lsl tempRegOne
		lsl tempRegOne
		lsl tempRegOne
		lsl tempRegOne
		lsl tempRegTwo
		lsl tempRegTwo
		lsl tempRegTwo
		lsl tempRegTwo
		lsl tempRegTwo
		lsl tempRegTwo
		lsl tempRegTwo
		add patternRegisterHigh, tempRegOne
		add patternRegisterLow, tempRegTwo
		out DDRC, patternRegisterLow
		out PORTC, patternRegisterLow
		ldi tempRegOne, 0
		st Z, tempRegOne
		adiw Z, 1
		st Z, tempRegOne
		sbiw Z, 1
		rjmp timer0InterruptFin

	timer0InterruptFin:
		pop ZL
		pop ZH
		pop tempRegTwo
		pop tempRegOne
		pop timerCounterLow
		pop timerCounterHigh
		reti

halt:
	rjmp halt
