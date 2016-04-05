; Lab 1 Part E - Array Sort

.cseg
arrOne: .db 7, 4, 5, 1, 6, 3, 2 ; The array to be sorted.
.equ arrLength = 7

.dseg
arrTwo: .byte arrLength ; The array to sort into.

.cseg
.def highestIndex = r16 ; The highest index to swap (this will be 1 under the max).
.def currentIndex = r17 ; The current index looked at.
.def tempVarOne = r18 ; A temporary variable to utilise.
.def tempVarTwo = r19 ; Another one.
.def length = r20 ; The length of the array.

start:
	ldi length, arrLength
	ldi highestIndex, arrLength - 2
	ldi currentIndex, 0
	ldi YH, high(arrTwo)
	ldi YL, low(arrTwo)
	ldi ZH, high(arrOne)
	ldi ZL, low(arrOne)
	jmp copyToData

copyToData: ; Copy the program array into the space allocated in the data.
	lpm tempVarOne, Z+
	st Y+, tempVarOne
	inc currentIndex
	cp currentIndex, length
	breq resetPointers
	jmp copyToData

resetPointers: ; Reset the current index and set the pointers to [0] and [1].
	ldi currentIndex, 0
	ldi YH, high(arrTwo)
	ldi YL, low(arrTwo)
	ldi ZH, high(arrTwo + 1)
	ldi ZL, low(arrTwo + 1)
	jmp mainLoop

mainLoop: ; Compare the two values pointed, and swap if the latter is less.
	ld tempVarOne, Y
	ld tempVarTwo, Z
	cp tempVarTwo, tempVarOne
	brlo swapNums
	jmp evaluateNextStep

evaluateNextStep: ; Check whether the last step is done.
	cpi highestIndex, 0
	breq halt
	cp currentIndex, highestIndex
	breq reduceIndex
	ld tempVarOne, Y+
	ld tempVarTwo, Z+
	inc currentIndex
	jmp mainLoop

reduceIndex: ; Lock in the highest value by lowering the max index.
	dec highestIndex
	jmp resetPointers

swapNums: ; Swap two numbers by storing the opposite pointers.
	st Y, tempVarTwo
	st Z, tempVarOne
	jmp evaluateNextStep
	

halt:
	jmp halt