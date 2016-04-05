; Lab 1 Part B - Array Addition

.dseg

arrResult: .byte 5 ; Allocate 5 bytes for the result array.

.cseg
.def arrOne_one = r16 ; Store what registers will be used.
.def arrOne_two = r17
.def arrOne_three = r18
.def arrOne_four = r19
.def arrOne_five = r20
.def arrTwo_one = r21
.def arrTwo_two = r22
.def arrTwo_three = r23
.def arrTwo_four = r24
.def arrTwo_five = r25

start:
	ldi arrOne_one, 1 ; Store all the values for both arrays.
	ldi arrOne_two, 2
	ldi arrOne_three, 3
	ldi arrOne_four, 4
	ldi arrOne_five, 5
	ldi arrTwo_one, 5
	ldi arrTwo_two, 4
	ldi arrTwo_three, 3
	ldi arrTwo_four, 2
	ldi arrTwo_five, 1

	add arrOne_one, arrTwo_one ; Add each element together (and stored in arrOne).
	add arrOne_two, arrTwo_two
	add arrOne_three, arrTwo_three
	add arrOne_four, arrTwo_four
	add arrOne_five, arrTwo_five

	sts arrResult, arrOne_one ; Copy each element to each byte of the allocated data memory (I found it at 0x0200).
	sts arrResult + 1, arrOne_two
	sts arrResult + 2, arrOne_three
	sts arrResult + 3, arrOne_four
	sts arrResult + 4, arrOne_five

halt:
	jmp halt