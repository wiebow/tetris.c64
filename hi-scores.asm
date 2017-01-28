

.const TABLE_ENTRIES = 3			// # entries in the table
.const TABLE_NAMELENGTH = 7		// # characters for the name
.const TABLE_SCORELENGTH = 3		// 3 bytes, up to 999999. hardcoded!!

// do NOT change the number of bytes in a score.
.const ENTRY_LENGTH = TABLE_NAMELENGTH + TABLE_SCORELENGTH

// you can have 255 characters in the table. depending on the length of the
// names there is a max to entries. // example: 3+8=11, 255/11= 23 entries


// Entry point.
// this function will look at the score located in new_score
// it will insert a new entry if a hiscore is detected and leave the
// offset to the name inentry_offset
PROCESS_NEW_SCORE:
	// start with no hiscore
	lda #0
	sta new_hiscore
	// reset entries counter
	lda #1
	sta current_entry
 	// reset table data offset
	ldy #0


entry_compare:
	// reset byte compare flags for this entry
	lda #0
	sta compare_flags
	sta compare_flags+1
	sta compare_flags+2
	//reset the compare flag counter
	ldx #0

byte_compare_loop:
	// check each byte in the new_score with current entry
	// set compare flag accordingly
	lda new_score,x
	cmp hiscore_table_start,y
	beq byte_compared	// score is same. skip
	bpl byte_is_higher	// score is higher
	dec compare_flags,x	// score is lower
	jmp byte_compared
byte_is_higher:
	inc compare_flags,x
byte_compared:
	iny 			// inc data counter
	inx 			// inc byte counter
	cpx #TABLE_SCORELENGTH
	bne byte_compare_loop

	// lets see if new_score was higher than the table entry
	// this is fixed to a score length of 3 bytes !!
	lda compare_flags
	beq !skip+ 			// this byte was the same, check next
	bpl found_hiscore 	// higher! :)
	jmp no_hiscore 		// lower :(
!skip:
	lda compare_flags+1
	beq !skip+ 			// same, check 3rd byte
	bpl found_hiscore   // :)
	jmp no_hiscore      // :(
!skip:
	lda compare_flags+2
	bmi no_hiscore 		// last byte is lower. so no new hi
	jmp found_hiscore 	// all 3 digits the same or last higher. new hiscore!
no_hiscore:
	// new_score was lower than this entry.
	// check the rest of the entries if not yet all done.
	inc current_entry
	ldx current_entry
	cpx #TABLE_ENTRIES+1
	beq all_entries_compared 	// all entries compared
								// so no hiscore at all! exit

	// goto start of next table entry
//	ldx current_entry
	jsr GET_ENTRY_OFFSET    // this uses X register.
	ldy entry_offset        // get offset to beginnig of next entry
	jmp entry_compare		// do the next entry

all_entries_compared:
	rts


found_hiscore:
	// hiscore found and its position is in current_entry
	// lda current_entry

	// save this so input routine can use it for name entry
	ldx current_entry
	jsr GET_ENTRY_OFFSET
	jsr INSERT_HISCORE_ENTRY

	// add the score to the entry
	ldy entry_offset
	lda new_score
	sta hiscore_table_start,y
	lda new_score+1
	sta hiscore_table_start+1,y
	lda new_score+2
	sta hiscore_table_start+2,y

	// clear the name. add dots
	ldx #TABLE_NAMELENGTH
	lda #$2e
!loop:
	sta hiscore_table_start+3,y
	iny
	dex
	bne !loop-

	// mark that a new hiscore has been detected at this entry.
	lda current_entry
	sta new_hiscore

	rts

// Entry point.
// set X register to index where you want to insert an entry.
// entries below will be moved down.

// this function will then insert the value in new_score
// into the cleared position and clear the name.
INSERT_HISCORE_ENTRY:
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

// ------------------------------------------

// calculate the offset to required entry.
// X register must be set to the entry #.
// new offset is stored in entry_offset
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

// ------------------------------------------

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
	sta current_entry
	// reset data offset
	ldy #0

print_table_entry:
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
	lda current_entry
	cmp #TABLE_ENTRIES
	beq !exit+
	// get ready for next entry
	inc current_entry
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
	jmp print_table_entry
!exit:
	rts

// -------------------------------------------

// resets the hiscore table with the default entries
RESET_HISCORE_TABLE:
	lda #TABLE_ENTRIES
	sta current_entry
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
	dec current_entry
	bne start_entry_reset
!exit:
	rts


// ------ data -------------------------------------------------------------

// flags for each byte in the score
// 0 means the byte in new score is the same as the checked hiscore
// 1 means the byte in new score is higher than the checked hiscore
// -1 means the byte in new score is lower than the checked hiscore
compare_flags:
	.fill TABLE_SCORELENGTH, 0

// new score needs to stored here, msB first.
new_score:
	.fill TABLE_SCORELENGTH, 0

// new score needs to be inserted on this position in the list
// is also used as a flag to indicate if a hiscore has been found
new_hiscore:
	.byte 0

// offset pointer, used by INSERT_ENTRY
// offset is counted from hiscore_table_start
entry_offset:
	.byte 0

// counter for RESET_HISCORES_TABLE and PRINT_HISCORE_TABLE
current_entry:
	.byte 0

// x and y positions for PRINT_HISCORE_TABLE
hiscore_table_position:
	.byte 0,0

// the default entry.
default_table_entry:
	.byte $00,$00,$00 // ,$12,$06
	.text "WDWBEST"
//         -------- 8 chars

// the hiscore table itself
// labels can be used to load and save memory from/to disk
hiscore_table_start:
	.fill ENTRY_LENGTH*TABLE_ENTRIES, 0
hiscore_table_end:

	// buffer area for moving data.
	.fill ENTRY_LENGTH, 0
