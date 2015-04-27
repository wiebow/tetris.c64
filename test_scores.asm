
			.const chrout = $ffd2

			.pc = $1000

			// add 100038 to score

			lda #$10
			sta addition+0
			lda #$52
			sta addition+1
			lda #$38
			sta addition+2
			jsr AddScore
			jsr PrintScore
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

// http://www.obelisk.demon.co.uk/6502/algorithms.html

