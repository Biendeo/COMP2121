; keypad.asm
; Handles the keypad stuff.

.ifndef KEYPAD_ASM
.equ KEYPAD_ASM = 1

.equ KEYPAD_OUT = PORTL
.equ KEYPAD_DDR = DDRL
.equ KEYPAD_IN = PINL

; TODO: Figure these out.
.equ KEYPAD_1 = 0x00
.equ KEYPAD_2 = 0x00
.equ KEYPAD_3 = 0x00
.equ KEYPAD_A = 0x00
.equ KEYPAD_4 = 0x00
.equ KEYPAD_5 = 0x00
.equ KEYPAD_6 = 0x00
.equ KEYPAD_B = 0x00
.equ KEYPAD_7 = 0x00
.equ KEYPAD_8 = 0x00
.equ KEYPAD_9 = 0x00
.equ KEYPAD_C = 0x00
.equ KEYPAD_HASH = 0x00
.equ KEYPAD_0 = 0x00
.equ KEYPAD_STAR = 0x00
.equ KEYPAD_D = 0x00

; TODO: Rename these to much more useful things.
.equ PORTA_DIR = 0xF0
.equ INIT_COL_MASK = 0xEF
.equ INIT_ROW_MASK = 0x01
.equ ROW_MASK = 0x0F

.dseg


.cseg

.def temp1 = r16
.def temp2 = r17
.def row = r18
.def col = r19
.def rowMask = r20
.def colMask = r21

SetupKeyPad:
	; TODO: Set this up.
	push temp1

	ldi temp1, PORTA_DIR
	sts KEYPAD_DDR, temp1
	ser temp1
	; This is just the LED stuff from the slides.
	; Use this to test that we've done this right, but remove it once we need
	; to start working.
	; out LED_DDR, temp1
	; out LED_OUT, temp1

	pop temp1
	ret

; Returns the key pressed into r16.
GetKeyPadInput:
	push temp2
	push row
	push col
	push rowMask
	push colMask

	GetKeyPadInput_Start:
		ldi colMask, INIT_COL_MASK
		clr col
	GetKeyPadInput_ColLoop:
		cpi col, 4
		breq GetKeyPadInput_Start
		sts KEYPAD_OUT, colMask
		ldi temp1, 0xFF
	GetKeyPadInput_Delay:
		dec temp1
		brne GetKeyPadInput_Delay
		lds temp1, KEYPAD_IN
		andi temp1, ROW_MASK
		cpi temp1, 0x0F
		breq GetKeyPadInput_NextCol
		ldi rowMask, INIT_ROW_MASK
		clr row
	GetKeyPadInput_RowLoop:
		cpi row, 4
		breq GetKeyPadInput_NextCol
		mov temp2, temp1
		and temp2, rowMask
		breq GetKeyPadInput_Convert
		inc row
		lsl rowMask
		rjmp GetKeyPadInput_RowLoop
	GetKeyPadInput_NextCol:
		lsl colMask
		inc col
		rjmp GetKeyPadInput_ColLoop
	; Currently this part converts the row column so the first 4 bits are the
	; column and the second four bits are the row. We should handle the input
	; outside of getting it, so we just need a convenient way to describe this.
	GetKeyPadInput_Convert:
		mov temp1, col
		lsl temp1
		lsl temp1
		lsl temp1
		lsl temp1
		add temp1, row

	GetKeyPadInput_Return:
		pop colMask
		pop rowMask
		pop col
		pop row
		pop temp2
		ret

.undef temp1
.undef temp2
.undef row
.undef col
.undef rowMask
.undef colMask

.endif