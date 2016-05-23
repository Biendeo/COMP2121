; potentiometer.asm
; Handles the speaker stuff.

.ifndef POTENTIOMETER_ASM
.equ POTENTIOMETER_ASM = 1

; TODO: Figure out the ports.
.equ POTENT_OUT = PORTC
.equ POTENT_DDR = DDRC
.equ POTENT_IN = PINC

SetupPotent:
	; TODO: Set this up.
	ret

.endif

