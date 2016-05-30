; keypad.asm
; Handles the keypad stuff.

.ifndef KEYPAD_ASM
.equ KEYPAD_ASM = 1

.equ KEYPAD_OUT = PORTL
.equ KEYPAD_DDR = DDRL
.equ KEYPAD_IN = PINL

; Keypad values:
;	Lowest 4 bits Stores column
;	Highest 4 bits stores row
.equ KEYPAD_1 = 0b00000000
.equ KEYPAD_2 = 0b00010000
.equ KEYPAD_3 = 0b00100000
.equ KEYPAD_A = 0b00110000
.equ KEYPAD_4 = 0b00000001
.equ KEYPAD_5 = 0b00010001
.equ KEYPAD_6 = 0b00100001
.equ KEYPAD_B = 0b00110001
.equ KEYPAD_7 = 0b00000010
.equ KEYPAD_8 = 0b00010010
.equ KEYPAD_9 = 0b00100010
.equ KEYPAD_C = 0b00110010
.equ KEYPAD_STAR = 0b00000011
.equ KEYPAD_0 = 0b00010011
.equ KEYPAD_HASH = 0b00100011
.equ KEYPAD_D = 0b00110011

; TODO: Rename these to much more useful things.
.equ PORTL_DIR = 0xF0
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

	ldi temp1, PORTL_DIR
	sts KEYPAD_DDR, temp1

	ldi temp1, FLAG_UNSET
	sts keypadFlag, temp1
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

	GetKeyPadInput_Start_Initial:
		ldi colMask, INIT_COL_MASK
		clr col
		rjmp GetKeyPadInput_ColLoop
	GetKeyPadInput_Start_Repeated:
		ldi colMask, INIT_COL_MASK
		clr col
		; col loop has run without detecting input
		; unset keypad hold flag
		;ldi temp1, FLAG_UNSET
		;sts keypadHoldFlag, temp1 
	GetKeyPadInput_ColLoop:
		lds temp1, keypadFlag
		cpi temp1, FLAG_SET ; is keypad enabled?
		cpi col, 4
		breq GetKeyPadInput_Start_Repeated
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