; keypad.asm
; Handles the keypad stuff.

.ifndef KEYPAD_ASM
.equ KEYPAD_ASM = 1

; TODO: Figure out the ports.
.equ KEYPAD_OUT = PORTC
.equ KEYPAD_DDR = DDRC
.equ KEYPAD_IN = PINC

SetupKeyPad:
	; TODO: Set this up.
	ret

.endif