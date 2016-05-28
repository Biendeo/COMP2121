; led.asm
; Handles the LED stuff.

.ifndef LED_ASM
.equ LED_ASM = 1

.equ LED_OUT = PORTC
.equ LED_DDR = DDRC
.equ LED_IN = PINC

.def temp1 = r16

SetupLED:
	SER TEMP1
	out LED_DDR, temp1
	;out LED_OUT, temp1
	ret

.undef temp1

.endif