
// other kernal routines are defined in load_file.asm
.label SAVE = $ffd8

// zero page pointers
.const startsave = $fe  // pointer to memory block to save


* = 4096

// main entry
// this will save data to the logical device from memory address defined
// by the consts data_start to data_end
SAVE_FILE:

	// set logical file system
	lda #0
logical_device:
	ldx #8
	ldy #1
	jsr SETLFS

	// get length of file name
	lda #savename_end - str_savename
	ldx #<str_savename
	ldy #>str_savename
	jsr SETNAM

	// set pointers to the memory block to save
	lda #<data_start
	sta startsave
	lda #>data_start
	sta startsave+1

	// save up until to the end address
	lda #<startsave
	ldx #<data_end
	ldy #>data_end
	jsr SAVE
	rts

// ---- helper functions

// set the logical device to save to.
// set the accumulator before calling.
SET_LOGICAL_DEVICE:
	sta logical_device+1
	rts

// sets the zero page pointer to the start address to save
// load x and y register before calling this routine.
SET_START_ADDRESS:
	stx startsave
	sty startsave+1
	rts

SET_END_ADDRESS:
	stx

// ---- data

// adding @0: to the front of a filename will enable overwriting.
str_savename:
	.byte $40
	.text "0:FILENAME"
savename_end:
	.byte 0
