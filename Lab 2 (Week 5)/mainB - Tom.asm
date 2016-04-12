; Lab 2 Part B - Recursive Linked List Search
.include "m2560def.inc"

.cseg
.db 0 ; Just to make sure the list doesn't start at null.

.set NEXT_STRING = 0x0000
.macro defstring ; str
	.set T = PC ; save current position in program memory
	.dw NEXT_STRING << 1 ;write out address of next list node
	.set NEXT_STRING = T ; update NEXT_STRING to point to this node
	.if strlen(@0) & 1 ; odd length + null byte
		.db @0, 0
	.else ; even length + null byte, add padding byte
		.db @0, 0, 0
	.endif
.endmacro

;defstring "no"
;defstring "word"
;defstring "is"
;defstring "longer"
;defstring "than"
;defstring "pneumonoultramicroscopicsilicovolcanoconiosis"
;defstring "right"

defstring "lists"
defstring "are"
defstring "great"
defstring "but"
defstring "hard"

.dseg

.cseg
.def stringLengthReturn = r17
.def stringLengthTemp = r16
.def longestLength = r16
.def returnAddressL = r18
.def returnAddressH = r19
.def nextAddressL = r20
.def nextAddressH = r21

start:
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL, r16
	
	ldi ZH, high(NEXT_STRING << 1)
	ldi ZL, low(NEXT_STRING << 1)
	rcall findLongestLength
	rjmp halt

findLongestLength: ; The main call from outside the function. It preserves variables.
	push returnAddressH
	push returnAddressL
	push nextAddressH
	push nextAddressL
	push longestLength
	rcall findLongestLengthStart
	mov ZH, returnAddressH
	mov ZL, returnAddressL
	pop longestLength
	pop nextAddressL
	pop nextAddressH
	pop returnAddressL
	pop returnAddressH
	ret

findLongestLengthStart: ; The start of the recursive loop.
	push YH
	push YL
	push nextAddressH
	push nextAddressL
	push ZH
	push ZL

	; Get the address of the current word.
	movw Y, Z
	adiw Y, 2
	lpm nextAddressL, Z+
	lpm nextAddressH, Z
	sbiw Z, 1

	; Check if the next address is null.
	cpi nextAddressL, 0
	breq findLongestLengthSecondNullCheck
	rjmp findLongestLengthRecursiveCall ; The recursive check is first, so the list is checked forward.

	findLongestLengthSecondNullCheck:
		cpi nextAddressH, 0
		breq findLongestLengthContinue
		rjmp findLongestLengthRecursiveCall

	findLongestLengthRecursiveCall: ; The recursive call, preserving variables, and moving Z.
		push ZH
		push ZL
		mov ZH, nextAddressH
		mov ZL, nextAddressL
		rcall findLongestLengthStart
		pop ZL
		pop ZH
		rjmp findLongestLengthContinue

	findLongestLengthContinue: ; When the recursion is done, the string length is computed.
		push stringLengthReturn
		rcall getLengthOfStringInY
		cp longestLength, stringLengthReturn ; If the length isn't longer, then the function ends.
		brge findLongestLengthFinish
		mov longestLength, stringLengthReturn ; Otherwise it's stored.
		mov returnAddressL, YL
		mov returnAddressH, YH
		rjmp findLongestLengthFinish

	findLongestLengthFinish: ; Preserving variables.
		pop stringLengthReturn
		pop ZL
		pop ZH
		pop nextAddressL
		pop nextAddressH
		pop YL
		pop YH
		ret

; Takes an address as a parameter.
; Returns the length in r16.
getLengthOfStringInY:
	push stringLengthTemp
	push YH
	push YL
	push ZH
	push ZL
	ldi stringLengthReturn, 0
	movw Z, Y

	getLengthOfStringInYLoop:
		lpm stringLengthTemp, Z+
		cpi stringLengthTemp, 0
		breq getLengthOfStringInYBreak
		inc stringLengthReturn
		rjmp getLengthOfStringInYLoop

	getLengthOfStringInYBreak:
		pop ZL
		pop ZH
		pop YL
		pop YH
		pop stringLengthTemp
		ret

halt:
	rjmp halt