; strobe.asm
; Handles the strobe LED stuff.

.ifndef STROBE_ASM
.equ STROBE_ASM = 1

.equ STROBE_OUT = PORTC
.equ STROBE_DDR = DDRC
.equ STROBE_IN = PINC

.def temp1 = r24

; TODO: This.
SetupStrobe:
	ret

.undef temp1

.endif