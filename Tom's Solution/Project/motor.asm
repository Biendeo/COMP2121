; motor.asm
; Handles the motor stuff.

.ifndef MOTOR_ASM
.equ MOTOR_ASM = 1
.equ MOTOR_PORT = PORTE
.equ MOTOR_PIN = DDE4

.def temp1 = r24

SetupMotor:
	push temp1

	; SET PORTE, PIN 4 FOR OUTPUT
	ldi temp1, 	1<<MOTOR_PIN ;pe2 is oc3b
	out DDRE, temp1	

	pop temp1
	ret

MotorMaxPower:
	push temp1
	ldi temp1, (1<<MOTOR_PIN)
	out porte, temp1
	pop temp1
	ret

MotorOff:
	push temp1
	;clr temp1
	;sts OCR3BL, temp1
	;sts OCR3BH, temp1
	ldi temp1, (0<<MOTOR_PIN)
	out porte, temp1
	pop temp1
	ret

.undef temp1

.endif