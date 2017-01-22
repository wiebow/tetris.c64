


// ------------------------------------------------

StartEnterNameMode:
	ldy #SCREEN_LEVELSELECT
	jsr PRINT_SCREEN

	// see if we have a high score


	rts

// ------------------------------------------------

UpdateEnterNameMode:

	rts

// ------------------------------------------------

EndEnterNameMode:
	lda #MODE_ATTRACT
	sta gameMode
	jsr StartAttractMode
	rts

// ------------------------------------------------



// ------------------------------------------------

waitingForName:
	.byte 0
