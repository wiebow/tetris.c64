

// ------------------------------------------------

StartEnterNameMode:
	ldy #SCREEN_LEVELSELECT
	jsr PRINT_SCREEN

	// see if we have a high score
	// copy player score to the hiscore new_score variable
	lda score
	sta new_score
	lda score+1
	sta new_score+1
	lda score+2
	sta new_score+2
	jsr PROCESS_NEW_SCORE

	ldx #14
	ldy #14
	jsr PRINT_HISCORE_TABLE

	// this is not zero when a score has been added
	lda new_hiscore // new_score_entry
	beq noNewHiScore

	// print the hiscore message
	jsr PrintHappyMessage

	// reset input len counter
	ldx #0
	stx input_len

	// put cursor in right position
	lda #13
	clc
	adc new_hiscore // new_score_entry
	tax
	ldy #21 		// x pos
	clc
	jsr PLOT
	jsr PRINT_CURSOR

	// clear input buffer
	lda #0
	sta $c6
	rts

noNewHiScore:
	jsr PrintSadMessage
	rts

// ------------------------------------------------

UpdateEnterNameMode:
	lda new_hiscore // new_score_entry
	bne waitForInput

	// wait for a button or key
	lda inputResult
	cmp #DOWN
	beq !exit+
	cmp #TURNCLOCK
	beq !exit+
	rts
!exit:
	jmp EndEnterNameMode

// player is entering name
waitForInput:

	// accumulator is 0 when input is not yet done
	jsr CONTROLLED_INPUT
	beq !exit+

	// done
	// copy name from buffer to score entry
	ldy entry_offset
	ldx #0
!loop:
	lda input_buffer,x
	sta hiscore_table_start+3,y
	iny
	inx
	cpx #TABLE_NAMELENGTH
	bne !loop-

	// save to disk
	jsr SAVE_FILE

	jmp EndEnterNameMode
!exit:
	rts

// ------------------------------------------------

EndEnterNameMode:
	lda #MODE_ATTRACT
	sta gameMode
	jsr StartAttractMode
	rts

// ------------------------------------------------

PrintHappyMessage:
	ldy #0
	ldx #17
!loop:
	lda hiscoremessage1,y
	sta $0400+52,y
	lda hiscoremessage2,y
	sta $0400+52+40,y
	iny
	dex
	bne !loop-
	rts

PrintSadMessage:
	ldy #0
	ldx #17
!loop:
	lda noHiscoremessage1,y
	sta $0400+52,y
	lda noHiscoremessage2,y
	sta $0400+52+40,y
	iny
	dex
	bne !loop-
	rts

// ------------------------------------------------

hiscoremessage1:
	.text " a new hiscore!! "
hiscoremessage2:
	.text " enter your name "
noHiscoremessage1:
	.text "   too bad  :(   "
noHiscoremessage2:
	.text "    game over    "
