; potentiometer.asm
; Handles the speaker stuff.

.ifndef BUTTON_ASM
.equ BUTTON_ASM = 1

.org INT0addr
	jmp PushRightButton
.org INT1addr
	jmp PushLeftButton

SetupButtons:
	; TODO: Set this up.
	ret

PushLeftButton:
	
	ret

PushRightButton:

	ret

.endif