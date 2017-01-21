
.const ATTRACT_DELAY = 254

// -----------------------------------------

StartAttractMode:
	lda #SND_MUSIC_TITLE
	jsr playsound
	lda #ATTRACT_DELAY
	sta attractDelay
	ldy #SCREEN_TITLE
	sty attractStep
	jmp PRINT_SCREEN

// -----------------------------------------

UpdateAttractMode:
	dec attractDelay
	beq triggered 			// swap screen when triggered

	// check for key or joy button press
	jsr GetKeyInput
	lda inputResult
	cmp #DOWN 				// enter pressed?
	beq !skip+ 				// yes
	jsr GetJoyInput
	lda inputResult
	cmp #TURNCLOCK 			// joy button pressed?
	beq !skip+ 				// yes
	rts
!skip:
	jmp EndAttractMode		// start the game

triggered:
	lda #ATTRACT_DELAY 		// reset the delay
	sta attractDelay

	inc attractStep 		// go to next screen
	lda attractStep
	cmp #3 					// have we done 3 screens?
	bne !skip+				// no. continue cycle
	lda #SCREEN_TITLE 		// yes. reset cycle
	sta attractStep
!skip:

	ldy attractStep
	jmp PRINT_SCREEN

// -----------------------------------------

EndAttractMode:
	lda #MODE_SELECTLEVEL
	sta gameMode
	jsr StartLevelSelectMode
	rts

// -----------------------------------------

attractStep:
	.byte 0

attractDelay:
	.byte 0
