
// zero page pointers
.const startsave = $fe  // pointer to memory block to save

SAVE_FILE:
	// set logical file system
	lda #0
	ldx #8
	ldy #1
	jsr SETLFS

	// get length of file name
	lda #filename_end - str_filename
	ldx #<str_filename
	ldy #>str_filename
	jsr SETNAM

	// set pointers to the memory block to save
	lda #<hiscore_table_start
	sta startsave
	lda #>hiscore_table_start
	sta startsave+1

	// save up until to the end address
	lda #<startsave
	ldx #<hiscore_table_end
	ldy #>hiscore_table_end
	jsr SAVE
	rts
