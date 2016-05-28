; random.asm
; Handles the current random number to get.

.ifndef RANDOM_ASM
.equ RANDOM_ASM = 1

.dseg
currentRandomValue: .byte 1 ; The random number generated. Use this to get a random value.
currentRandomIndex: .byte 1 ; The value used to create a random number. Don't use this, it just counts up.

.cseg
.def temp1 = r24
.def temp2 = r25

; Sets both currentRandomValue and currentRandomIndex to 0.
InitialiseRandomness:
	push temp1
	ldi temp1, 0
	sts currentRandomValue, temp1
	sts currentRandomIndex, temp1
	pop temp1
	ret

; Generates a new random value to sit in currentRandomValue.
CreateRandomValue:
	push temp1
	push temp2

	lds temp1, currentRandomIndex
	inc temp1
	sts currentRandomIndex, temp1
	ldi temp2, 171
	mul temp1, temp2
	ldi temp2, 29
	mul temp1, temp2
	sts currentRandomValue, r0

	pop temp2
	pop temp1
	ret

.undef temp1
.undef temp2
.endif