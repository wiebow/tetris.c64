
// code concerning the game over mode

.const STEP_FILLWELL = 0
.const STEP_CLEARWELL = 1
.const STEP_TEXT = 2

			// the character to fill the well with
drawCharacter:
			.byte 0

			// the mode step variable
currentStep:
			.byte 0

			// the amount of lines left to fill
linesLeft:
			.byte 0


// ------------------------------------------------

StartGameOverMode:

			// prepare for the first step

			lda #STEP_FILLWELL
			sta currentStep

			// we will render this block
			lda #88
			sta drawCharacter

			// and we need to do 20 lines
			lda #20
			sta linesLeft

			// point to the bottom line
			ldx #12
			ldy #19
			jsr SetScreenPointer
			rts

// ---------------------------------------------------

UpdateGameOverMode:

			lda currentStep 		// which step to ...
			cmp #STEP_FILLWELL 		// perform?
			bne !otherStep+

			jsr FillLine
			dec linesLeft			// all lines done?
			beq !skip+ 				// yes. prepare next step
			rts 					// no. continue on next update
!skip:
			// done filling
			// go to next step

			lda #STEP_CLEARWELL
			sta currentStep
			lda #$20
			sta drawCharacter
			sta linesLeft

			// point to the bottom line
			ldx #12
			ldy #19
			jsr SetScreenPointer
			rts
!otherStep:
			cmp #STEP_CLEARWELL
			bne !otherStep+

			jsr FillLine
			dec linesLeft			// all lines done?
			beq !skip+ 				// yes. prepare next step
			rts 					// no. continue on next update
!skip:
			// done clearing
			// print text and go to next mode

			lda #STEP_TEXT 			// go to next step
			sta currentStep
			jmp PrintGameOver
!otherStep:

			// waiting for a key or fire button

			rts


// ---------------------------------------------------

EndGameOverMode:



// ---------------------------------------------------


// files a line with the drawcharacter

FillLine:
			lda drawCharacter	 	// get char
			ldy #$00
!loop:
			sta (screenPointer),y 	// store on screen
			iny
			cpy #10 				// line done?
			bne !loop-
			jsr UpOneRow 			// prepare for next line
			rts

// -----------------------------------------------

PrintGameOver:

			// set start of data

			lda #<gameoverText
			sta dataSourceLo
			lda #>gameoverText
			sta dataSourceHi
			lda #10
			sta dataWidth
			lda #20
			sta dataHeight
			lda #04
			sta dataDestinationHi
			lda #12
			sta dataDestinationLo
			jmp WriteScreenData
