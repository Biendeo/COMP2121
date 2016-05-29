; potentiometer.asm
; Handles the speaker stuff.

.ifndef POTENTIOMETER_ASM
.equ POTENTIOMETER_ASM = 1

; TODO: Figure out the ports.
.equ POTENT_OUT = PORTC
.equ POTENT_DDR = DDRC
.equ POTENT_IN = PINC
.def temp1 = r24
.def temp2 = r25

SetupPotent:
	push temp1

	; REFS0 Internal 2.56V reference with external capacitor at external AFREF pin
	; 0 << ADLAR sets to right adjusted input
	; 0 << MUX0 && 1 << MUX5 -> selects ADC8 as analog input channel
	; 1 << ADEN -> enables the ADC
	; 1 << ADSC -> starts the first conversion
	; 1 << ADIE -> ADC conversion complete interrupt is activated
	; 5 << ADPS0 -> Division factor between xtal freq and input clock to adc?
	;				division factor = 32
	ldi temp1, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0) 
	sts ADMUX, temp1
	ldi temp1, (1 << MUX5)
	sts ADCSRB, temp1
	ldi temp1, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0) | (1 << ADATE)
	sts ADCSRA, temp1
	pop temp1

	ldi temp1, FLAG_UNSET
	sts potFlag, temp1
	ret

ADCCint:
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	push r16
	
	lds temp1, currentMode
	; RESET POT MODE
	cpi temp1, MODE_RESETPOTENT
	brne return_ADCCint
	lds temp1, ADCL
	lds temp2, ADCH
	cpi temp1, 0
	brne potIsNotZero
	cpi temp2, 0
	brne potIsNotZero
	
	rjmp potIsZero
	
	setPotResetFlag:
		sts potFlag, r16

	return_ADCCint:
		pop r16
		pop temp2
		pop temp1
		out SREG, temp1
		pop temp1
		reti

potIsZero:
	lds r16, potFlag
	cpi r16, FLAG_SET
	breq setPotResetFlag
	clr r16
	sts potTimer, r16
	sts potTimer+1, r16
	ldi r16, FLAG_SET
	rjmp setPotResetFlag

potIsNotZero:
	ldi r16, FLAG_UNSET
	rjmp setPotResetFlag

.undef temp1
.undef temp2
.endif

