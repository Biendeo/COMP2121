; strobe.asm
; Handles the strobe LED stuff.

.ifndef STROBE_ASM
.equ STROBE_ASM = 1

.equ STROBE_OUT = PORTA
.equ STROBE_DDR = DDRA
.equ STROBE_PIN = PORTA1

.def temp1 = r24

; TODO: This.
SetupStrobe:
	push temp1

	in temp1, STROBE_DDR
	andi temp1, (1<<STROBE_PIN)
	out STROBE_DDR, temp1

	pop temp1
	ret

StrobeOn:
	push temp1
	ldi temp1, (1<<STROBE_PIN)
	out STROBE_OUT, temp1
	

	pop temp1
	ret

StrobeOff:
	push temp1

	ldi temp1,  (0<<STROBE_PIN)
	out STROBE_OUT, temp1

	pop temp1
	ret

ToggleStrobe:
	push temp1

	sbic STROBE_OUT, STROBE_PIN
	rjmp gotoStrobeOn
	; strobe off
	rcall StrobeOff
	rjmp ToggleStrobe_return

	gotoStrobeOn:
		rcall StrobeOn

	ToggleStrobe_return:
		pop temp1
		ret
		
		

.undef temp1

.endif