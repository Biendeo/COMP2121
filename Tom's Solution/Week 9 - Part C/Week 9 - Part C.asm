; Lab 4 Part A - Keypad

;
; part a.asm
;
; Created: 03/05/2016 09:24:51
; Author : Julian Blacket
;
.include "m2560def.inc"

; Replace with your application code
.def arg1 = r22
.def row = r16
.def col = r17
.def rmask = r18
.def cmask = r19
.def temp1 = r20
.def temp2 = r21

.equ PORTLDIR = 0xf0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F
.equ DEBOUNCE_INTERVAL = 1000
.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro lcd_set
	push r16
	lds r16, PORTL
	sbr r16, @0
	pop r16
.endmacro
.macro lcd_clr
	push r16
	lds r16, PORTL
	cbr r16, @0
	pop r16
.endmacro


.dseg
DEBOUNCE_FLAG: .byte 1
DEBOUNCE_TIMER: .byte 2
CURRENT_VALUE: .byte 1
INPUT_VALUE: .byte 1

.cseg
.org 0x0000
	rjmp RESET
.org OVF0ADDR
	rjmp HANDLE_DEBOUNCE_TIMER

RESET:
	ldi temp1, low(RAMEND)
	out SPL, temp1
	ldi temp1, high(RAMEND)
	out SPH, temp1

	ldi temp1, PORTLDIR
	sts DDRL, temp1
	ser temp1
	out DDRC, temp1
	out PORTC, temp1
	;breakpt:
		;rjmp breakpt
	; clear all data vars
	clr temp1
	sts DEBOUNCE_FLAG, temp1
	sts DEBOUNCE_TIMER, temp1
	sts DEBOUNCE_TIMER+1, temp1
	
	; set debounce timer interrupt
	out TCCR0A, temp1 ; timer reg to normal mode
	ldi temp1, 0b00000010 
	out TCCR0B, temp1 ; set prescaler
	ldi temp1, 1<<TOIE0
	sts TIMSK0, temp1 ; set overflow interrupt

	ser r16
	sts DDRL, r16
	out DDRA, r16
	clr r16
	sts PORTL, r16
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


	sei 
	rjmp main
	


main:
	rjmp pollKeypad

pollKeypad:
	push temp1
	push temp2
	push rmask
	push cmask
	push row
	push col
	clr temp1
	clr temp2
	resetcol:
		ldi cmask, INITCOLMASK
		clr col

	colloop:
		; reset if visited all the columns
		cpi col, 4
		breq resetcol
		; else scan the row
		sts PORTL, cmask

		ldi temp1, 0xff

		; read the keypad
		lds temp1, PINL
		; test the keyboard output
		andi temp1, ROWMASK ;
		cpi temp1, 0xF		; if none of the bits were changed, no row is pressed
		breq nextcol
		; find the low row
		ldi rmask, INITROWMASK
		clr row
		
	rowloop:
		cpi row, 4
		breq nextcol
		mov temp2, temp1
		and temp2, rmask
		breq handleButton
		inc row
		lsl rmask
		jmp rowloop
	nextcol:
		lsl cmask
		inc col
		jmp colloop
	
	handleButton:
		; handle debounce
		lds temp1, DEBOUNCE_FLAG
		cpi temp1, 1 ; is the flag set
		breq resetcol
		ldi temp1, 1 ; set the flag
		sts DEBOUNCE_FLAG, temp1
		
		cpi col, 3
		breq LETTER
		cpi row, 3
		breq SYMBOLS_AND_ZERO

	NUMBER:
		mov temp1, row
		lsl temp1
		add temp1, row
		add temp1, col
		subi temp1, -1
		;lds temp2, INPUT_VALUE
		;ldi arg1, 10
		;mul temp2, arg1
		;add temp2, temp1
		;sts INPUT_VALUE, temp2
		out PORTC, temp1
		rjmp PRINT_INPUT
	LETTER:
		;cpi col, 3
		;breq CALL_DIVIDE 
		subi arg1, -'A'
		rjmp UPDATE_TOTAL
	SYMBOLS_AND_ZERO:
		cpi col, 1
		breq ZERO
		cpi col, 0
		rjmp RESET
		cpi col, 2
		breq nextcol
		rjmp PRINT_INPUT
	ZERO:
		ldi arg1, 0
		sts INPUT_VALUE, temp1
		rjmp PRINT_INPUT
	;CALL_DIVIDE:
;		rcall DIVISION
;		rjmp PRINT
	PRINT_INPUT:
		;lds arg1, INPUT_VALUE
		;out portc, arg1
	UPDATE_TOTAL:
		rjmp resetcol
	
	pop col
	pop row
	pop cmask
	pop rmask
	pop temp2
	pop temp1

HANDLE_DEBOUNCE_TIMER:
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	push yh
	push yl
	
	lds temp1, DEBOUNCE_FLAG
	cpi temp1, 0
	breq return_HANDLEDEBOUNCE

	testTimer:
		lds yl, DEBOUNCE_TIMER
		lds yh, DEBOUNCE_TIMER+1
		adiw yh:yl, 1
		cpi yl, low(DEBOUNCE_INTERVAL)
		ldi temp1, high(DEBOUNCE_INTERVAL)
		cpc yh, temp1
		brlt storeTimer
		ldi yl, 0
		ldi yh, 0
		sts DEBOUNCE_FLAG, yh

	storeTimer:
		sts DEBOUNCE_TIMER, YL
		sts DEBOUNCE_TIMER+1, YH
		
	return_HANDLEDEBOUNCE:
		pop yl
		pop yh
		pop temp2
		pop temp1
		out SREG, temp1
		pop temp1
		reti

;
; Send a command to the LCD (r16)
;

lcd_command:
	sts PORTL, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	sts PORTL, r16
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
	sts DDRL, r16
	sts PORTL, r16
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
	sts DDRL, r16
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