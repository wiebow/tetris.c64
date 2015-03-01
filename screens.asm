

// code concerning game screens


			// game screen dimensions

			.const screenWidth = 21
			.const screenHeight = 21


// subroutine to clear the screen and color ram
// also detroys sprite pointers.
ClearScreen:
			lda #11 			// dark grey
			sta $d020 			// set border color
			sta $d021 			// set screen color
			ldx #$00 			// reset offset register
!loop:		
			lda #$20			// #$20 is space
			sta $0400,x 		// store in screen ram
			sta $0500,x
			sta $0600,x
			sta $0700,x
			lda #13 			// light green
			sta $d800,x 		// store in color ram
			sta $d900,x
			sta $da00,x
			sta $db00,x
			inx 				// increment counter
			bne !loop- 			// continue?
			rts


// this subroutine prints a screen.
// set x and y to the lo and hi bytes of the data to be read before ..
// calling this.
PrintScreen:
			// first, set pointer to the start of data
			stx readdata+1			// store in lda instruction
			sty readdata+2 			// and store

			// reset screen memory pointer
			lda #10 				// start at column # 10
			sta writedata+1
			lda #$04
			sta writedata+2

			ldx #$00
			ldy #$00
readdata:
			lda $1010,x 			// get screen data
			bne writedata			// 0 marks end of data
			rts
writedata:
			sta $0410,y 			// store in screen memory
			inx 					// update data read counter
			bne !skip+ 				// no roll over?
			inc readdata+2 			// go to next memory page
!skip:
			iny 					// update counter for this row
			cpy #screenWidth		// this row done?
			bne readdata 			// no, continue
			ldy #$00 				// reset the row counter
			lda writedata+1 		// get lo byte of current screen position
			clc
			adc #40 				// add 40 to that
			bcc !skip+ 				// overflow?
			inc writedata+2 		// then go to next memory page
!skip:
			sta writedata+1 		// store lo byte
			jmp readdata 			// and continue
