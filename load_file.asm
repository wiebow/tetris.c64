
// kernal routines
.label SETLFS = $ffba
.label SETNAM = $ffbd
.label LOAD = $ffd5


// main entry
// this will load data from set device to memory address defined
// in load_destination
LOAD_FILE:
	// set logical device
	lda #0
	ldx #8
	ldy #0
	jsr SETLFS
	// get length of file name
	lda #filename_end - str_filename
	ldx #<str_filename
	ldy #>str_filename
	jsr SETNAM
	// set memory destination and load
	lda #0
	ldx load_desitination
	ldy load_desitination+1
	jsr LOAD
	rts


// ---- helper functions

// this will set the address to load the data to
// set x and y before calling this. x = lsb, y = msb of load address.
SET_LOAD_DESTINATION:
	stx load_desitination
	sty load_desitination+1
	rts

// ---- data

// place to hold the address to load to. lsb first.
load_desitination:
	.byte 0,0

// name to load
str_filename:
	.text "filename here"
filename_end:
	.byte 0
