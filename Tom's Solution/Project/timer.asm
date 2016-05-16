; timer.asm
; Handles the timer stuff.

.ifndef TIMER_ASM
.equ TIMER_ASM = 1

.org OVF0addr
	rjmp Timer0Interrupt

; The interrupt when timer0 overflows.
Timer0Interrupt:
	call CreateRandomValue
	reti

.def temp1 = r16

; Sets up timer0 with the right stuff (from the lecture sides).
SetupTimer0:
	ldi temp1, 0b00000000
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1
	ldi temp1, 1 << TOIE0
	sts TIMSK0, temp1
	ret

.undef temp1

.endif