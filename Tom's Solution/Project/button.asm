; potentiometer.asm
; Handles the speaker stuff.

.ifndef BUTTON_ASM
.equ BUTTON_ASM = 1
.equ flagSet = 1
.equ flagUnSet = 0

.def temp1 = r24
SetupButtons:
	; set as falling edge for int1 and int0
	ldi yh, high(EICRA)
	ldi yl, low(EICRA)		
	ldi temp1, ISC01
	ori temp1, ISC11
	st y, temp1 
	; enable the interrupts
	in temp1, EIMSK
	ori temp1, (1<<INT0)
	ori temp1, (1<<INT1)
	out EIMSK, temp1

	ldi temp1, FLAG_UNSET
	sts PB0dbFlag, temp1
	sts PB1dbFlag, temp1
	
	sei
	ret

PushLeftButton:
	push temp1
	; handle debouncing
	lds temp1, PB1dbFlag
	cpi temp1, flagSet
	breq return_PushLeftButton
	ldi temp1, flagSet		; set debounce flag
	sts PB1dbFlag, temp1
	
	; main logic
	lds temp1, currentMode
	cpi temp1, MODE_TITLESCREEN
	brne return_PushLeftButton
	rcall StartTitleWait

	return_PushLeftButton:
		pop temp1
		reti

PushRightButton:
	push temp1
	; handle debouncing
	lds temp1, PB0dbFlag
	cpi temp1, flagSet
	breq return_PushRightButton
	ldi temp1, flagSet		; set debounce flag
	sts PB0dbFlag, temp1
	
	; main logic
	jmp Reset

	return_PushRightButton:
		pop temp1
		reti

.endif