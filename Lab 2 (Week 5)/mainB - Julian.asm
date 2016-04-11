; lab2-1.asm
.include "m2560def.inc"
.dseg
.set NEXT_STRING = 0X0000
.macro defstring ; str
	.set T = PC
	.dw NEXT_STRING << 1
	.set NEXT_STRING = T

	.if strlen(@0) & 1
		.db @0, 0
	.else
		.db @0, 0, 0
	.endif
.endmacro
.cseg
  rjmp main
defstring ""
defstring ""
defstring ""
defstring ""
main:
	ldi yh, high(ramend)
	ldi yl, low(ramend)
	out sph, yh
	out spl, yl
	ldi zh, high(NEXT_STRING<<1) ; init the arguments
	ldi zl, low(NEXT_STRING<<1)
	 
	call findLongest
	jmp end

.def upper = r16
.def curr = r18
; arguments:
; first item in list
; return address in z and length in r16
findLongest:
	; -- prolouge
	push yh
	push yl
	push curr
	in yh, sph
	in yl, spl
	sbiw y,3
	out sph, yh
	out spl, yl
	std y+1, zl ; save start address of curr item in list 
	std y+2, zh

	; -- body
	clr curr
	adiw zl, 2 ; point z to the string
	call getLength ; return value in r25
	mov curr, r25
	sbiw zl, 2 ; point z to next address
	lpm upper, z+
	lpm zh, z
	mov zl, upper
	add upper, zh			; if next == null: return curr
	cpi upper, 0			
	breq returnCurr
	rcall findLongest		; else find length of next in list
	cp upper, curr
	brpl returnfindLongest	; if upper > curr: return upper
	returnCurr: 			; else curr > return value
		mov r16, curr			; pass length of the string
		ldd zl, y+1				; pass the address of this string
		ldd zh, y+2
		adiw zl, 2
	returnfindLongest:
		adiw y, 3
		out sph, yh
		out spl, yl
		pop curr
		pop yl
		pop yh
		ret

; takes a pointer to string in z and returns length in r25
getLength:
	push curr
	push zh
	push zl
	push yh
	push yl
	clr curr
	clr r25
	loop:
		lpm curr, z+
		cpi curr, 0
		breq return
		inc r25
		rjmp loop
	return:
		pop yl
		pop yh
		pop zl
		pop zh
		pop curr
		ret

end: rjmp end
