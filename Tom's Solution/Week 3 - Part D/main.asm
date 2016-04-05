; Lab 1 Part D - String Search

.cseg
originalString: .db "20 Character String" ; Storing the string into program memory.
.def index = r16
.def workingChar = r17
.def specificCharReg = r18
.equ specificChar = 97 ; Set the char to find here.

start:
	ldi ZH, high(2 * originalString)
	ldi ZL, low(2 * originalString)
	ldi index, 0
	ldi specificCharReg, specificChar

scanLoop:
	lpm workingChar, Z+ ; Load the current character into workingChar
	cpi workingChar, 0
	brlo end ; Jump if workingChar is 0, which is the end of the string.
	cp workingChar, specificCharReg
	breq halt ; Halt if the workingChar is equal to the specificChar (index should be correct then).

	inc index ; Add 1 to the index
	jmp scanLoop


end:
	ldi index, 0xFF ; If it can't find the char, it just uses this value.
	jmp halt

halt:
	jmp halt