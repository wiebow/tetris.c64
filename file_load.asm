

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
	ldx #<hiscore_table_start
	ldy #>hiscore_table_start
	jsr LOAD
	rts

str_filename:
	.text "0:HISCORES"
filename_end:
