

			.const plot = 	$fff0 			// kernel routine to set cursor position
			.const chrout = $ffd2 			// routine to print character


// this looks at the made lines amount, and the current
// level, and adds the appropriate score: level+1 * line score
AddLineScore:

			ldx currentLevel 		// get the current player level
			inx

			rts
// http://tetris.wikia.com/wiki/Scoring



ResetScore:
			lda #$00
			sta score+0
			sta score+1
			sta score+2
			rts

AddScore:
			sed 					// set decimal mode
			clc 					// clear the carry bit
			lda score+0 			// get this score
			adc addition+0 			// add the first byte
			sta score+0 			// store it.
			lda score+1 			// and the 2nd byte
			adc addition+1
			sta score+1
			lda score+2				// and the 3rd byte
			adc addition+2
			sta score+2
			cld 					// clear decimal mode
			rts

PrintScore:

			// set cursor position
			clc
			ldx #4 					// row 4
			ldy #24 				// column 24
			jsr plot 				// move cursor so we can use chrout

			ldx #$02 				// start with right most byte
!loop:
			lda score,x 			// get the msb
			pha 					// push to stack
			lsr 					// shift 4 times to right
			lsr
			lsr
			lsr
			clc 					
			adc #$30 				// add #$30 to it to get a screencode
			jsr chrout 				// print it
			pla 					// restore value
			and #%00001111 			// get rid of leftmost bits
			clc
			adc #$30 				// create a screen code
			jsr chrout 				// print it
			dex 					// update counter
			bpl !loop- 				// continue
			rts

// ---------------------------

score:
			.byte 0,0,0 		// 24 bits score value. little endian so LSB first.
addition:
			.byte 0,0,0 		// score to add goes here



lineScores:
			.byte 40,00,00 		// 1 line,   40
			.byte 00,01,00 		// 2 lines, 100
			.byte 00,03,00 		// 3 lines, 300
			.byte 00,12,00 		// tetris, 1200

