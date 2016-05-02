; Lab 3 Part C - Dynamic Pattern
.include "m2560def.inc"

.cseg
.def 
.equ timer0Flag     = 0b00000001
.equ timer1Flag     = 0b00000010
.equ displayingFlag = 0b00000100

.equ displayTimeLimit = 7500
.equ debounceTimeLimit = 200

.def temp1 = r16
.def temp2 = r17
.def currentPattern = r18
.def displayingPattern = r19
.def timer0Count = r20
.def timer1Count = r21
.def currentPatternTimerCountHigh = r22
.def currentPatternTimerCountLow = r23
.def currentPatternLength = r24
.def currentPatternDisplayStage = r25

.dseg
flags: .byte 1

.cseg
.org 0x0000
	jmp reset
.org INT0addr
	jmp setZero
.org INT1addr
	jmp setOne
.org OVF0addr
	jmp timer0Interrupt
.org OVF1addr
	jmp timer1Interrupt
.org OVF2addr
	jmp displayTimerInterrupt

reset:
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL, r16

	ldi timer0Count, 0
	ldi timer1Count, 0
	ldi currentPatternTimerCount, 0

	clr temp1
	out DDRB, temp1

	sez temp1
	out DDRC, temp1
	
	clr temp1
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1
	ldi temp1, 1<<TOIE0
	sts TIMSK0, temp1

	clr temp1
	out TCCR1A, temp1
	ldi temp1, 0b00000010
	out TCCR1B, temp1
	ldi temp1, 1<<TOIE1
	sts TIMSK1, temp1

	clr temp1
	out TCCR2A, temp1
	ldi temp1, 0b00000010
	out TCCR2B, temp1
	ldi temp1, 1<<TOIE2
	sts TIMSK2, temp1

	rjmp start

start:
    rjmp halt
	
setZero:
	push temp1
	push temp2

	cpi currentPatternLength, 8
	breq setZeroFinish

	clr temp1
	ori temp1, timer0Flag
	cpi temp1, 0
	brne setZeroStartTimer
	rjmp setZeroFinish
	
	setZeroStartTimer:
		ld temp1, flags
		ori temp1, timer0Flag
		st flags, temp1
		ldi timer0Count, debounceTimeLimit
		rjmp setZeroFinish

	setZeroFinish:
		pop temp2
		pop temp1
		reti

setOne:
	push temp1
	push temp2

	cpi currentPatternLength, 8
	breq setOneFinish

	clr temp1
	ori temp1, timer1Flag
	cpi temp1, 0
	brne setOneStartTimer
	rjmp setOneFinish
	
	setZeroStartTimer:
		ld temp1, flags
		ori temp1, timer1Flag
		st flags, temp1
		ldi timer1Count, debounceTimeLimit
		rjmp setOneFinish

	setZeroFinish:
		pop temp2
		pop temp1
		reti

timer0Interrupt:
	push temp1
	push temp2

	clr temp1
	ori temp1, timer1Flag
	cpi temp1, 0
	brne timer0InterruptCountdown
	rjmp timer0InterruptFinish

	timer0InterruptCountdown:
		dec timer0Count
		cpi timer0Count, 0
		breq timer0InterruptAct
		rjmp timer0InterruptFinish

	timer0InterruptAct:
		

	timer0InterruptFinish:
		pop temp2
		pop temp1
		reti

halt:
	rjmp halt
