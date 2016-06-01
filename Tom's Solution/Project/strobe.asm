; strobe.asm
; Handles the strobe LED stuff.

.ifndef STROBE_ASM
.equ STROBE_ASM = 1

.equ STROBE_OUT = PORTE
.equ STROBE_DDR = DDRE
.equ STROBE_PIN = DDE3

.def temp1 = r24

; TODO: This.
SetupStrobe:
	push temp1

	ldi temp1, STROBE_PIN
	out DDRE, temp1

	pop temp1
	ret

StrobeOn:
	push temp1
	ldi temp1, (1<<STROBE_PIN)
	out porte, temp1
	

	pop temp1
	ret

StrobeOff:
	push temp1

	ldi temp1,  (0<<DDE2)
	out porte, temp1

	pop temp1
	ret

.undef temp1

.endif