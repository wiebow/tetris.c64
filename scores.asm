
// resets player score and total lines made.
ResetScore:
			lda #$00
			sta score+0
			sta score+1
			sta score+2
			rts

// this adds the score that is put in the
// addition bytes.
// we start at the rightmost byte (LSB)
AddScore:
			sed 					// set decimal mode
			clc 					// clear the carry bit
			lda score+2 			// get this score
			adc addition+2 			// add the first byte
			sta score+2 			// store it.
			lda score+1 			// and the 2nd byte
			adc addition+1
			sta score+1
			lda score+0				// and the 3rd byte
			adc addition+0
			sta score+0
			cld 					// clear decimal mode
			rts

// prints the score into the playing field
PrintScore:
			// set cursor position
			clc 					// clear carry bit so we set cursor
			ldx #4 					// row 4
			ldy #24 				// column 24
			jsr PLOT 				// move cursor so we can use PRINT

			ldx #0					// start with left most byte (MSB)
!loop:
			lda score,x 			// get value
			pha 					// push to stack
			lsr 					// shift 4 times to right
			lsr
			lsr
			lsr
			clc
			adc #$30 				// add #$30 to it to get a screencode
			jsr PRINT 				// print it
			pla 					// restore value
			and #%00001111 			// get rid of leftmost bits
			clc
			adc #$30 				// create a screen code
			jsr PRINT 				// print it
			inx 					// update counter
			cpx #3
			bne !loop- 				// continue
			rts

// this looks at the made lines amount, and the current
// level, and adds the appropriate score: (level+1) * line score
AddLineValue:
			ldy linesMade 			// get made lines amount
			dey 					// minus 1 to get currect offset to lineValue array
			lda lineValue1,y 		// get 1st byte
			sta addition+0 			// put in addition
			lda lineValue2,y 		// same for middle byte
			sta addition+1
			lda lineValue3,y 		// and last byte
			sta addition+2

			ldx currentLevel 		// get the current player level
									// this is how many times the score is added
!loop:
			jsr AddScore 			// add the score
			dex
			bpl !loop- 				// keep doing this until all levels have been added
			rts


//prints the current play level on the screen
PrintLevel:
			clc 					// position cursor at 26,8
			ldx #8
			ldy #26
			jsr PLOT

			// do 1st byte.
			// only do the first 4 bits of this byte

			lda gameLevel+1
			and #%00001111 			// get rid of leftmost bits
			clc
			adc #$30 				// create a screen code
			jsr PRINT 				// print it

			// do 2nd byte

			lda gameLevel+0
			pha 					// push to stack
			lsr 					// shift 4 times to right
			lsr
			lsr
			lsr
			clc
			adc #$30 				// add #$30 to it to get a screencode
			jsr PRINT 				// print it

			pla 					// restore value
			and #%00001111 			// get rid of leftmost bits
			clc
			adc #$30 				// create a screen code
			jsr PRINT 				// print it
			rts



// ---------------------------

score:
			.byte 0,0,0 		// 24 bits score value, MSB first.
addition:
			.byte 0,0,0 		// score to add goes here


// http://tetris.wikia.com/wiki/Scoring
// lines:          1   2   3   4
lineValue1:
			.byte  00, 00, 00, 00 	// right most byte of scores (LSB)
lineValue2:
			.byte  00, 01, 03,$12	// middle byte
lineValue3:
			.byte $40, 00, 00, 00   // left most byte of score (MSB)

