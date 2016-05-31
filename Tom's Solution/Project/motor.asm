; motor.asm
; Handles the motor stuff.

.ifndef MOTOR_ASM
.equ MOTOR_ASM = 1

.def temp1 = r24

SetupMotor:
	push temp1

	ldi temp1, (1<<CS00)	; no prescaler for timer3
	sts TCCR3B, temp1		; TCCRNB handles prescaling
	ldi temp1, (1<<WGM30)|(1<<COM3B1) ; wgm30: pwm, phase correct. com3b1, compare output channel b used 
	sts TCCR3A, temp1 ; TCCRNA handles copmare output mode

	ldi temp1, 	1<<DDE4 ;pe2 is oc3b
	out DDRE, temp1	

	; duty cycle = nothing
	clr temp1
	sts OCR3BL, temp1
	sts OCR3BH, temp1
	
	; enable INT2
	ldi temp1, 2<<ISC20
	sts EICRA, temp1
	in temp1, EIMSK
	ori temp1, 1<<INT2
	out EIMSK, temp1

	pop temp1
	ret

MotorMaxPower:
	push temp1
	ser temp1
	sts OCR3BL, temp1
	clr temp1
	sts OCR3BH, temp1
	pop temp1
	ret

MotorOff:
	push temp1
	clr temp1
	sts OCR3BL, temp1
	sts OCR3BH, temp1
	pop temp1
	ret

.undef temp1

.endif