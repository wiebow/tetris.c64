
// code concerning the game over mode

// states of the game over mode
.const STEP_FILLWELL = 0
.const STEP_CLEARWELL = 1
.const STEP_GAMEOVERTEXT = 2

// ------------------------------------------------

StartGameOverMode:
	// play game over music
	lda #0
	sta sounddelayCounter
	lda #SND_MUSIC_GAMEOVER
	jsr playsound

	// prepare for the first step
	lda #STEP_FILLWELL
	sta currentStep
	// we will render this block
	lda #105
	sta drawCharacter
	// and we need to do 20 lines
	lda #19
	sta linesLeft
	rts

// ---------------------------------------------------

UpdateGameOverMode:
	lda currentStep 		// which step to ...

	cmp #STEP_FILLWELL 		// perform?
	bne !otherStep+

	jsr DrawLine
	dec linesLeft
	bmi !skip+
	rts
!skip:
	inc currentStep
	lda #$20
	sta drawCharacter
	lda #19
	sta linesLeft
	rts

!otherStep:
	cmp #STEP_CLEARWELL
	bne !otherStep+

	jsr DrawLine
	dec linesLeft
	bmi !skip+
	rts
!skip:
	// done clearing
	// print text and go to next mode
	ldy #WELL_GAMEOVER
	jsr PRINT_WELLDATA
	inc currentStep
	rts
!otherStep:

	// waiting for a key or fire button

	jsr GetInput
	lda inputResult
	cmp #DOWN
	beq !exit+
	cmp #TURNCLOCK
	beq !exit+
	rts
!exit:
	jmp EndGameOverMode
	//rts

// ----------------------------------------------------

DrawLine:
	clc
	ldy #12
	ldx linesLeft
	jsr PLOT

	lda drawCharacter
	ldy #10
!loop:
	jsr PRINT
	dey
	bne !loop-
	rts

// ---------------------------------------------------

EndGameOverMode:
	lda #MODE_ENTERNAME
	sta gameMode
	jsr StartEnterNameMode
	rts

// ---------------------------------------------------


// the character to fill the well with
drawCharacter:
	.byte 0
// the mode step variable
currentStep:
	.byte 0
// the amount of lines left to fill
linesLeft:
	.byte 0
