; speaker.asm
; Handles the speaker stuff.

.ifndef SPEAKER_ASM
.equ SPEAKER_ASM = 1

; TODO: Figure out the ports.
.equ SPEAKER_OUT = PORTC
.equ SPEAKER_DDR = DDRC
.equ SPEAKER_IN = PINC

SetupSpeaker:
	; TODO: Set this up.
	ret

.endif