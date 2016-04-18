;
; lab2-0.asm
;
; Created: 21/01/2016 20:12:15
; Author : Julian Blacket
;


; Replace with your application code
.equ length = 20
.def curr = r16
.def i = r17
.dseg
reversedString: .byte 20
.cseg
rjmp main
string: .db "I'm a string",0
main:
	ldi yh, high(ramend)
	ldi yl, low(ramend)
	out sph, yh
	out spl, yl
	
	ldi yh, high(reversedString<<1)
	ldi yl, low(reversedString<<1)

	 ldi zh, high(string<<1)
	 ldi zl, low(string<<1)

	 clr i

pushString:
	lpm curr, z+
	cpi curr, 0
	breq popString
	inc i
	push curr
	rjmp pushString

popString:
	cpi i, 0
	brlt end
	dec i
	pop curr
	st y+, curr
	rjmp popString


end: rjmp end