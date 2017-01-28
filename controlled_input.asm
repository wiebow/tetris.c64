
.const MAX_INPUT_CHARS = 7

// main entry
// make sure that the cursor is where you want to input text to appear.
// when done, the location input_buffer will hold the input, 0 terminated
CONTROLLED_INPUT:
	jsr GETIN
	beq !exit+ //input

	// skip unwanted character codes
	ldx #7
!loop:
	cmp input_filter,x
	beq !exit+ //input
	dex
	bpl !loop-

	// return pressed?
	cmp #13
	beq input_done

	// delete pressed?
	cmp #20
	bne valid_character
delete:
	ldy input_len
	beq !exit+ //input
	dec input_len
	dey
	lda #$2e          	// set dot
	jsr PRINT  			// on screen
	lda #$20 			// space
	sta input_buffer,y 	// in buffer

	lda #157			// move cursor back
	jsr PRINT
	jsr PRINT
	jsr PRINT_CURSOR

	lda #0
	rts
	// jmp input

// a valid character was entered
// add it to the buffer if space left.
valid_character:
	ldy input_len
	cpy #MAX_INPUT_CHARS
	beq !exit+ //input
	sta input_buffer,y
	jsr PRINT
	jsr PRINT_CURSOR
	inc input_len

	lda #0
	rts // jmp input

input_done:
	lda #1
!exit:
	rts

// ---- helper functions

PRINT_CURSOR:
	lda #18 	//rvs on, we need inverse pi
	jsr PRINT
	lda #126 	// print underscore
	jsr PRINT
	lda #146
	jsr PRINT
	lda #157 	// move cursor left
	jsr PRINT
	rts

// ---- data

// no cursor movement, home, quotation mark
// clear screen, insert
input_filter:
	.byte 17,19,29,34,145,147,148,157

input_len:
	.byte 0

input_buffer:
	.fill MAX_INPUT_CHARS,0

