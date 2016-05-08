; Lab 4 Part A - Keypad

;
; part a.asm
;
; Created: 03/05/2016 09:24:51
; Author : Julian Blacket
;
.include "m2560def.inc"

; Replace with your application code
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

.cseg
rjmp RESET

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
		delay:
			dec temp1
			brne delay

		; read the keypad
		lds temp1, PINL
		; test the keyboard output
		andi temp1, ROWMASK ; all lower bits set to 1 are preserved
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
		cpi row, 3
		breq zero

		mov temp1, row
		lsl temp1
		add temp1, row
		add temp1, col
		subi temp1, -1
		out portc, temp1
		rjmp resetcol
	zero:
		ldi temp1, 0
		out portc, temp1
		rjmp resetcol


		
	


	pop col
	pop row
	pop cmask
	pop rmask
	pop temp2
	pop temp1