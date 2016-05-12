; Lab 4 Part C - Calculator

start:
	rjmp halt


halt:
	jmp halt

ADDITION:
	push temp1
	push temp2

	lds temp1, CURRENT_VALUE
	lds temp2, INPUT_VALUE

	rcall ADDITION_FUNC

	sts CURRENT_VALUE, temp1
	ldi temp2, 0
	lds INPUT_VALUE, temp2

	pop temp2
	pop temp1
	ret

ADDITION_FUNC:
	add temp1, temp2
	ret


SUBTRACTION:
	push temp1
	push temp2

	lds temp1, CURRENT_VALUE
	lds temp2, INPUT_VALUE

	rcall SUBTRACTION_FUNC

	sts CURRENT_VALUE, temp1
	ldi temp2, 0
	lds INPUT_VALUE, temp2

	pop temp2
	pop temp1
	ret

SUBTRACTION_FUNC:
	sub temp1, temp2
	ret



MULTIPLICATION:
	push temp1
	push temp2

	lds temp1, CURRENT_VALUE
	lds temp2, INPUT_VALUE

	rcall MULTIPLICATION_FUNC

	sts CURRENT_VALUE, temp1
	ldi temp2, 0
	lds INPUT_VALUE, temp2

	pop temp2
	pop temp1
	ret

MULTIPLICATION_FUNC:
	mul temp1, temp2
	ret



DIVISION:
	push temp1
	push temp2
	push row

	lds temp1, CURRENT_VALUE
	lds temp2, INPUT_VALUE
	ldi row, 0

	rcall DIVISION_FUNC

	sts CURRENT_VALUE, row
	ldi temp2, 0
	lds INPUT_VALUE, temp2

	pop row
	pop temp2
	pop temp1
	ret

DIVISION_FUNC:
	DIVISION_LOOP:
		cp temp1, temp2
		brlt DIVISION_EXIT
		inc row
		sub temp1, temp2
		rjmp DIVISION_LOOP
	DIVISION_EXIT:
		ret