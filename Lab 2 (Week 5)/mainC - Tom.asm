; Lab 2 Part C - Min / Max
.include "m2560def.inc"

.cseg

.set NEXT_INT = 0x0000
.macro defint ; int
	.set T = PC ; save current position in program memory
	.dw NEXT_INT << 1 ;write out address of next list node
	.set NEXT_INT = T ; update NEXT_INT to point to this node
	; .if strlen(@0) & 1 ; odd length + null byte
	; 	.db @0, 0
	; .else ; even length + null byte, add padding byte
	; 	.db @0, 0, 0
	; .endif
	.dw @0
.endmacro

defint 2016
defint 65000
defint 1


.dseg

.cseg
.def largestIntH = r17
.def largestIntL = r18
.def smallestIntH = r19
.def smallestIntL = r20
.def tempCompare1 = r21
.def tempCompare2 = r22

start:
	
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL, r16
	
	ldi ZH, high(NEXT_INT)
	ldi ZL, low(NEXT_INT)
	ldi YH, 0
	ldi YL, 0
	ldi XH, 0
	ldi XL, 0
	rcall findMinMax
	rjmp halt

findMinMax:
	push largestIntH
	push largestIntL
	push smallestIntH
	push smallestIntL
	push tempCompare1
	push tempCompare2
	rcall findMinMaxStart
	pop tempCompare2
	pop tempCompare1
	pop smallestIntL
	pop smallestIntH
	pop largestIntL
	pop largestIntH
	ret
	
findMinMaxStart:
	push ZH
	push ZL
	rcall checkIfYIsNull
	breq findMinMaxNulls
	rcall isYGreaterThanZPlusTwo
	breq findMinMaxNewMin
	rcall isXLessThanZPlusTwo
	breq findMinMaxNewMax
	rjmp findMinMaxRecursiveCheck

	findMinMaxNulls:
		push ZH
		push ZL

		adiw Z, 2
		movw Y, Z
		movw X, Z
		lpm largestIntH, Z+
		lpm largestIntL, Z
		sbiw Z, 1
		lpm smallestIntH, Z+
		lpm smallestIntL, Z
		sbiw Z, 1

		pop ZL
		pop ZH
		rjmp findMinMaxRecursiveCheck
		
	findMinMaxNewMin:
		push ZH
		push ZL

		adiw Z, 2
		lpm smallestIntH, Z+
		lpm smallestIntL, Z
		sbiw Z, 1
		movw Y, Z

		pop ZL
		pop ZH
		rjmp findMinMaxRecursiveCheck

	findMinMaxNewMax:
		push ZH
		push ZL

		adiw Z, 2
		lpm largestIntH, Z+
		lpm largestIntL, Z
		sbiw Z, 1
		movw X, Z

		pop ZL
		pop ZH
		rjmp findMinMaxRecursiveCheck

	findMinMaxRecursiveCheck:
		lpm tempCompare1, Z
		lpm tempCompare2, Z + 1
		cpi tempCompare1, 0
		brne findMinMaxRecursive
		cpi tempCompare2, 0
		brne findMinMaxRecursive
		rjmp findMinMaxFinish

	findMinMaxRecursive:
		push ZH
		push ZL
		lpm tempCompare1, Z+
		lpm tempCompare2, Z
		sbiw Z, 1
		mov tempCompare1, ZH
		mov tempCompare2, ZL
		rcall findMinMaxStart
		pop ZL
		pop ZH
	
	findMinMaxFinish:
		pop ZL
		pop ZH
		ret

checkIfYIsNull:
	cpi YH, 0
	breq checkIfYIsNullTwo
	clz
	ret
	checkIfYIsNullTwo:
		cpi YL, 0
		breq checkIfYIsNullTrue
		clz
		ret
	checkIfYIsNullTrue:
		sez
		ret

isYGreaterThanZPlusTwo:
	push tempCompare1
	push tempCompare2
	push ZH
	push ZL
	adiw Z, 2
	lpm tempCompare1, Z
	lpm tempCompare2, Z+
	cp smallestIntH, tempCompare1
	brlt isYGreaterThanZPlusTwoFalse
	cp tempCompare1, smallestIntH
	brlt isYGreaterThanZPlusTwoTrue
	cp tempCompare2, smallestIntL
	brlt isYGreaterThanZPlusTwoTrue
	rjmp isYGreaterThanZPlusTwoFalse
	
	isYGreaterThanZPlusTwoFalse:
		clz
		rjmp isYGreaterThanZPlusTwoEnd

	isYGreaterThanZPlusTwoTrue:
		sez
		rjmp isYGreaterThanZPlusTwoEnd

	isYGreaterThanZPlusTwoEnd:
		pop ZL
		pop ZH
		pop tempCompare2
		pop tempCompare1
		ret

isXLessThanZPlusTwo:
	push tempCompare1
	push tempCompare2
	push ZH
	push ZL
	adiw Z, 2
	lpm tempCompare1, Z
	lpm tempCompare2, Z+
	cp tempCompare1, largestIntH
	brlt isXLessThanZPlusTwoFalse
	cp largestIntH, tempCompare1
	brlt isXLessThanZPlusTwoTrue
	cp largestIntL, tempCompare2
	brlt isXLessThanZPlusTwoTrue
	rjmp isXLessThanZPlusTwoFalse
	
	isXLessThanZPlusTwoFalse:
		clz
		rjmp isXLessThanZPlusTwoEnd

	isXLessThanZPlusTwoTrue:
		sez
		rjmp isXLessThanZPlusTwoEnd

	isXLessThanZPlusTwoEnd:
		pop ZL
		pop ZH
		pop tempCompare2
		pop tempCompare1
		ret

halt:
	rjmp halt