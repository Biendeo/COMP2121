; Lab 1 Part A - 16-bit Add

; Part one adding 40960 and 2730.
.equ numOne = 40960 ; Store the given numbers.
.equ numTwo = 2730

; Part two adding 640 and 511.
;.equ numOne = 640
;.equ numTwo = 511

.def numOne_low = r16 ; Store what registers will be used.
.def numOne_high = r17
.def numTwo_low = r18
.def numTwo_high = r19
.def numResult_low = r20
.def numResult_high = r21

start:
	ldi numOne_low, low(numOne) ; Load the values into the registers.
	ldi numOne_high, high(numOne)
	ldi numTwo_low, low(numTwo)
	ldi numTwo_high, high(numTwo)

	movw numResult_high:numResult_low, numTwo_high:numTwo_low ; Store numTwo at the result register.
	add numResult_low, numOne_low ; Add the lower byte of numOne to it.
	adc numResult_high, numOne_high ; Add the higher byte of numOne to it (with carry if set).



halt:
	jmp halt