; Lab 5 Part A - Speed Measurement

.include "m2560def.inc"
.include "lcd_macros.inc"

.macro incStack
	in yl, SPL
	in yh, SPH
	sbiw yl, @0
	out SPL, yl
	out SPH, yh
.endmacro
.macro decStack
	in yl, SPL
	in yh, SPH
	adiw yl, @0
	out SPL, yl
	out SPH, yh
.endmacro

.def temp1 = r24
.def temp2 = r25
.equ qtrSecond = 1953

.dseg
cRot: .db 2
cTimer: .db 2

.cseg
.org 0x0000
	jmp RESET
.org INT2ADDR
	jmp handleINT2
.org OVF0addr
	jmp TIMER0ovf
jmp DEFAULT
DEFAULT:
	reti

RESET: 
	ldi temp1, high(RAMEND)
	out sph, temp1
	ldi temp1, low(RAMEND)
	out spl, temp1

	; reset data memory
	clr temp1
	sts cRot, temp1
	sts cRot+1,temp1
	sts cTimer, temp1
	sts cTimer+1, temp1

	; led output
	ser temp1
	out DDRC, temp1

	; motor interrupt setup, INT2
	ldi temp1, 2<<ISC20
	sts EICRA, temp1
	in temp1, EIMSK
	ori temp1, 1<<INT2
	out EIMSK, temp1

	; 250ms timer
	ldi temp1, 0b00000000
	OUT TCCR0A, temp1
	ldi temp1, 0b00000010
	OUT TCCR0B, temp1 ; prescler of 8
	ldi temp1, 1<<TOIE0
	sts TIMSK0, temp1 ; enable timer0 intr
	
	rcall setupLCD

	sei

main:
	rjmp main


handleINT2:
	push temp1
	in temp1, SREG
	push temp1
	push temp2

	lds temp1, cRot
	lds temp2, cRot+1
	adiw temp1, 1

	storeMOTORREVS:
		sts cRot, temp1
		sts cRot+1, temp2
	pop temp2
	pop temp1
	out SREG, temp1
	pop temp1
	reti
	
TIMER0ovf:
	push yh
	push yl
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	incStack 2

	lds temp1, cTimer
	lds temp2, cTimer+1

	adiw temp1, 1
	std Y+1, temp1
	std Y+2, temp2
	cpi temp1, low(qtrSecond)
	ldi temp1, high(qtrSecond)
	cpc temp2, temp1
	brlt notQTRSECOND

	QTRSECONDPASSED:
		clr temp1
		std Y+1, temp1
		std Y+2, temp1

		lds temp1, cRot
		lds temp2, cRot+1
		out portc, temp1
		do_lcd_command lcd_clear
		rcall displayIAsASCII
		clr temp1
		sts cRot, temp1
		sts cRot+1, temp1


	notQTRSECOND:
		ldd temp1, Y+1
		ldd temp2, Y+2
		sts cTimer, temp1
		sts cTimer+1, temp2 
	
	returnTIMER0OVF:
		decStack 2
		pop temp2
		pop temp1
		out SREG, temp1
		pop temp1
		pop yl
		pop yh
		reti
; given a one byte number in r24, displays to the lcd in ascii
displayIAsASCII:
	push yh
	push yl
	push temp1
	push temp2 
	incStack 4
	std Y+1, temp1 ; load starting number
	clr temp2
	std Y+2, temp2 ; num Hundreds
	std Y+3, temp2 ; num tens
	std Y+4, temp2 ; num ones


	divOneHundred:
		cpi temp1, 100
		brlt pushHundreds
		subi temp1, 100
		inc temp2
		rjmp divOneHundred
	
	pushHundreds:
		std Y+2, temp2
		clr temp2

	divTen:
		cpi temp1, 10
		brlt pushTens
		subi temp1, 10
		inc temp2
		rjmp divTen

	pushTens:
		std Y+3, temp2
		clr temp2

	divOne:
		cpi temp1, 1
		brlt pushOnes
		subi temp1, 1
		inc temp2
		rjmp divOne

	pushOnes:
		std Y+4, temp2
	
	ldd temp2, y+2
	subi temp2, -'0'
	do_lcd_data_reg temp2
	ldd temp2, y+3
	subi temp2, -'0'
	do_lcd_data_reg temp2
	ldd temp2, y+4
	subi temp2, -'0'
	do_lcd_data_reg temp2


	return_displayIAsASCII:
		decStack 4
		pop temp2
		pop temp1
		pop yl
		pop yh
		ret


SetupLCD:
	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	ret


;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret