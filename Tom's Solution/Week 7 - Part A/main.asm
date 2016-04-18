; Lab 3 Part A - Static Pattern
.include "m2560def.inc"

.def patternRegister = r16
.equ lightPattern = 0xE5

start:
	ldi patternRegister, lightPattern
	out DDRC, patternRegister
	out PORTC, patternRegister
    rjmp halt

halt:
	rjmp halt
