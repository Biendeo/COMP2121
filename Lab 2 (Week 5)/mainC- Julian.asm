; Lab 2 - Part C: Recursive int array search

; lab2-1.asm
.include "m2560def.inc"
.dseg
.set NEXT_NODE = 0X0000
.macro node
	.set T = PC
	.dw NEXT_NODE << 1
	.set NEXT_NODE = T
	.dw @0
	
.endmacro
.cseg
  rjmp main
node 7 ; max value
node 27
node -1
node -100

main:
	ldi yh, high(ramend)
	ldi yl, low(ramend)
	out sph, yh
	out spl, yl
	ldi zh, high(NEXT_NODE<<1) ; init the arguments
	ldi zl, low(NEXT_NODE<<1)
	clr xh
	clr xl
	clr yh
	clr yl
	 
	call getMaxAndMin
	jmp end

.def currL = r18
.def currH = r19
.def stkl = r20
.def stkh = r21
.def temp1 = r24
.def temp2 = r25
; arguments:
; first item in list
; return address in z and length in r16
getMaxAndMin:
	; -- prolouge
	push zh
	push zl
	push currL
	push currH
	; -- body
	adiw z, 2				; get curr value
	lpm currL, z+
	lpm currH, z
	sbiw z, 3
	lpm temp1, z+			; if next == null: return curr as max and min
	lpm zh, z
	mov zl, temp1
	add temp1, zh
	cpi temp1, 0			
	breq newMaxAndMin
	call getMaxAndMin		; else find max and min
	mov temp1, xl			; get curr max
	mov temp2, xh
	cp xl, currL			; if max < curr : new max
	cpc xh, currH
	brlt newMax			
	cp currL, yl			; if curr < min: new min
	cpc currH, yh
	brlt newMin
	rjmp returnGetMaxAndMin	; else curr = max and min: return
	newMin:
		mov yl, currL
		mov yh, currH
		jmp returnGetMaxAndMin
	newMax:
		mov xh, currH
		mov xl, currL
		jmp returnGetMaxAndMin
	newMaxAndMin:
		mov xh, currH
		mov xl, currL
		mov yl, currL
		mov yh, currH
	returnGetMaxAndMin:
		pop currH
		pop currL
		pop zl
		pop zh
		ret

end: rjmp end

; compares two 2 byte numbers
; arguments a, b given in r19:r18 and r25:r24
; reterns result in r2