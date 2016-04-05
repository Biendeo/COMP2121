; Lab 1 Part C - Upper Case

.cseg
originalString: .db "20 Character String" ; Storing the string into program memory.

.dseg
.equ maxLength = 20
returnString: .byte maxLength ; Storing the resulting string.

.cseg

.def workingChar = r16 ; The value of the character being worked on.
.def length = r17
.def lowerToUpper = r18

start:
	ldi YH, high(2 * returnString)
	ldi YL, low(2 * returnString)
	ldi ZH, high(2 * originalString)
	ldi ZL, low(2 * originalString)
	ldi length, 0
	ldi lowerToUpper, 32

scanLoop:
	lpm workingChar, Z+ ; Load the current character into workingChar
	cpi workingChar, 0
	breq halt
	cpi workingChar, 97
	brlo putBack ; Jump if workingChar < 'a'
	cpi workingChar, 123
	brsh putBack ; Jump if workingChar > 'z'
	sub workingChar, lowerToUpper ; Subtract 32 to convert it to uppercase then.
	jmp putBack

putBack:
	st Y+, workingChar
	inc length
	cpi length, maxLength
	breq halt
	jmp scanLoop

halt:
	jmp halt