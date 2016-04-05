; Lab 2 Part A - String Reverse
.include "m2560def.inc"

.cseg
strOne: .db "abc" ; The string to be reversed.
.equ terminatingChar = 0

.dseg
strTwo: .byte arrLength ; The string to reverse into.

.cseg
.def currentChar = r16 ; The current register.

start:
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL, r16
	ldi ZH, high(strOne)
	ldi ZL, low(strOne)
	ldi YH, high(strTwo)
	ldi YL, low(strTwo)
	ldi currentChar, terminatingChar
	push currentChar
	rjmp loadOriginalStr

loadOriginalStr:
	lpm currentChar, Z+
	cpi currentChar, terminatingChar
	breq reverseStr
	push currentChar
	rjmp loadOriginalStr

reverseStr:
	pop currentChar
	cpi currentChar, terminatingChar
	breq end
	st Y+, currentChar
	rjmp reverseStr

end:
	ldi currentChar, terminatingChar
	st Z, currentChar
	rjmp halt

halt:
	rjmp halt