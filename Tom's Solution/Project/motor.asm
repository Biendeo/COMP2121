; motor.asm
; Handles the motor stuff.

.ifndef MOTOR_ASM
.equ MOTOR_ASM = 1

; TODO: Figure out the ports.
.equ MOTOR_OUT = PORTC
.equ MOTOR_DDR = DDRC
.equ MOTOR_IN = PINC

SetupMotor:
	; TODO: Set this up.
	ret

.endif