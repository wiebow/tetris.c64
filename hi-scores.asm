

.const TABLE_ENTRIES = 3			// # entries in the table
.const TABLE_NAMELENGTH = 7 		// # characters for the name
.const TABLE_SCORELENGTH = 3		// 3 bytes, up to 999999. hardcoded!!

// do NOT change the number of bytes in a score.
.const ENTRY_LENGTH = TABLE_NAMELENGTH + TABLE_SCORELENGTH

// you can have 255 characters in the table. depending on the length of the
// names there is a max to entries. // example: 3+8=11, 255/11= 23 entries


// Entry point.
// this function will look at the score located in new_score
// and leave the position for the new hiscore in new_score_entry
// if this is 0 then no new hiscore has been achieved
PROCESS_NEW_SCORE:
	// start with no hiscore
	lda #0
	sta new_score_entry
	// reset entries counter
	lda #1
	sta entries_done

 	// reset table offset
	ldy #0
score_compare:
	// reset byte compare flags
	lda #0
	sta compare_flags
	sta compare_flags+1
	sta compare_flags+2

	//reset the score and compare flags index
	ldx #0
!loop:
	// check each byte in the new score with the score in the entry
	// set flag accordingly
	lda new_score,x
	cmp hiscore_table_start,y
	beq bytes_compared	// score is same. skip
	bpl byte_is_higher	// score is higher
	dec compare_flags,x	// score is lower
	jmp bytes_compared
byte_is_higher:
	inc compare_flags,x
bytes_compared:
	iny
	inx
	cpx #TABLE_SCORELENGTH 	// do all bytes. 3 in this case
	bne !loop-

	// all bytes in this score were compared with the entry
	// lets see if this score was higher than the table entry
	// !! this is fixed to a score length of 3 bytes !!
	lda compare_flags
	beq !skip+ 			// same, check 2nd byte
	bpl found_hiscore 	// higher!
	jmp no_hiscore 		// lower
!skip:
	lda compare_flags+1
	beq !skip+ 			// same, check 3rd byte
	bpl found_hiscore
	jmp no_hiscore
!skip:
	lda compare_flags+2
	bmi no_hiscore 		// lower. so no new hi
	jmp found_hiscore 	// all 3 digits the same or last higher. new hiscore!
no_hiscore:
	// score compared was lower than the one in this entry.
	// check the rest of the entries if not yet all done.
	inc entries_done
	ldx entries_done
	cpx #TABLE_ENTRIES
	beq all_scores_compared 	// all entries compared
								// so no hiscore at all! exit
	// goto start of next table entry
	// x register is set to next entry.
	jsr GET_ENTRY_OFFSET
	jmp score_compare 			// do the next score
all_scores_compared:
	rts
found_hiscore:
	// hiscore found and it is in this entry
	// set the new entry value
	lda entries_done
	sta new_score_entry
	rts


// Entry point.
// resets the hiscore table with the default entries
RESET_HISCORE_TABLE:
	lda #TABLE_ENTRIES
	sta entries_done
	ldx #0
start_entry_reset:
	ldy #0
!loop:
	lda default_table_entry,y
	sta hiscore_table_start,x
	inx
	iny
	cpy #ENTRY_LENGTH
	bne !loop-
	dec entries_done
	bne start_entry_reset
!exit:
	rts


// Entry point.
// set x and y to the position you want to draw the table
// x register : yposition
// y register: xposition
PRINT_HISCORE_TABLE:
	// save coordinates
	stx hiscore_table_position
	sty hiscore_table_position+1
	// place cursor
	clc
	jsr PLOT
	// reset the entries done counter
	lda #1
	sta entries_done
	// reset offset
	ldy #0

print_table_entry:
	clc
	adc #$30
	jsr PRINT 		// print the entry number
	lda #29			// go to the right 1 position
	jsr PRINT

	ldx #TABLE_SCORELENGTH	// this amount of bytes in score
!loop:
	lda hiscore_table_start, y
	pha 				// store value
	lsr 				// shift right 4 times
	lsr
	lsr
	lsr
	clc
	adc #$30 			// add $30 to get a screen code
	jsr PRINT 			// print it
	pla 				// retrieve original value
	and #%00001111 		// get rid of leftmost bits
	clc
	adc #$30
	jsr PRINT
	iny
	dex 				// dec number counter
	bne !loop-
	// add a space
	lda #$20
	jsr PRINT
	// print the name
	ldx #TABLE_NAMELENGTH
!loop:
	lda hiscore_table_start,y
	jsr PRINT
	iny
	dex
	bne !loop-
	// all entries done?
	lda entries_done
	cmp #TABLE_ENTRIES
	beq !exit+
	// get ready for next entry
	inc entries_done
	// save memory pointer. we need the y register
	tya
	pha
	// go one line down
	inc hiscore_table_position
	// position cursor
	ldx hiscore_table_position
	ldy hiscore_table_position+1
	clc
	jsr PLOT
 	// restore memory pointer
	pla
	tay
	lda entries_done
	jmp print_table_entry
!exit:
	rts

// Entry point.
// set X register to index where you want to insert an entry.
// entries below will be moved down.
INSERT_HISCORE_ENTRY:

	// get the offset to the position we want to clear
	jsr GET_ENTRY_OFFSET

	// first we need to move the data down.
	// point y offset to end of table.
	ldy #hiscore_table_end - hiscore_table_start

!loop:
	// move data until we're on the wanted offset.
	lda hiscore_table_start - ENTRY_LENGTH,y
	sta hiscore_table_start,y
	dey
	cpy entry_offset
	bpl !loop-  		// keep going

clear_entry:
	// clear entry. test
	ldy entry_offset
	lda #$01
	ldx #0
!loop:
	sta hiscore_table_start,y
	iny
	inx
	cpx #ENTRY_LENGTH
	bne !loop-
!exit:
	rts


// Entry point.
// calculate the offset to required entry.
// x register must be set to the entry #.
// offset is stored in entry_offset
GET_ENTRY_OFFSET:
	lda #0
!loop:
	dex
	beq !done+
	clc
	adc #ENTRY_LENGTH
	jmp !loop-
!done:
	sta entry_offset
	rts



// ------ data -------------------------------------------------------------

// flags for each byte in the score
// 0 means the byte in new score is the same as the checked hiscore
// 1 means the byte in new score is higher than the checked hiscore
// -1 means the byte in new score is lower than the checked hiscore
compare_flags:
	.fill 3,0 //TABLE_SCORELENGTH, 0 // .byte 0,0,0

// new score needs to stored here, msB first.
new_score:
	.fill 3,0 //TABLE_SCORELENGTH, 0

// new score needs to be inserted on this position in the list
// is also used as a flag to indicate if a hiscore has been found
new_score_entry:
	.byte 0

// offset pointer, used by INSERT_ENTRY
entry_offset:
	.byte 0

// counter for RESET_HISCORES_TABLE and PRINT_HISCORE_TABLE
entries_done:
	.byte 0

// x and y positions for PRINT_HISCORE_TABLE
hiscore_table_position:
	.byte 0,0

// the default entry.
default_table_entry:
	//.byte $00,$12,$06
	.byte $00,$00,$00
	.text "WDWBEST"

// the hiscore table itself
// labels can be used to load and save memory from/to disk
hiscore_table_start:
	.fill ENTRY_LENGTH*TABLE_ENTRIES, 0
hiscore_table_end:

// buffer area for moving data.
.fill ENTRY_LENGTH, 0

