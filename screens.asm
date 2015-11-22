

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

// ---------------------------------------------

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



// ---------------------------------------------

// this subroutine saves the content of the total play area
// into a buffer.
// If playAreaErase is set to 1 then the area is cleared as well

SavePlayArea:
			// point to the beginning of the first row

			ldx #12 				// x position is set to 12
			ldy #0 					// y position to 0
			jsr SetScreenPointer 	// set screen memory pointer

			ldx #$00				// reset buffer pointer
			stx currentRow 			// reset the row counter
!loop:
			lda (screenPointer),y 	// get screen data
			sta playAreaBuffer,x 	// store it in the buffer
			lda playAreaErase 		// erase it as well?
			beq !skip+ 				// no
			lda #$20 				// write a space
			sta (screenPointer),y
!skip:
			inx 					// update buffer pointer
			iny  					// update row character counter
			cpy #10 				// stored whole line?
			bne !loop- 				// no, keep reading

			inc currentRow 			// go to the next row
			lda currentRow 			// what value is it now?
			cmp #20 				// all 20 rows checked?
			beq !skip+	 			// yes, exit
			jsr DownOneRow 			// no, go one row down
			ldy #$00 				// reset row character counter
			jmp !loop-	 			// do next row
!skip:
			rts

// ---------------------------------------------

// restores the play area by reading the buffer

RestorePlayArea:
			ldx #12
			ldy #0
			jsr SetScreenPointer

			ldx #$00 				// reset buffer counter
			stx currentRow 			// and row index
!loop:
			lda playAreaBuffer,x 	// get buffer data
			sta (screenPointer),y 	// store on screen
!skip:
			inx 					// update buffer pointer
			iny  					// update row character counter
			cpy #10 				// done whole line?
			bne !loop- 				// no

			inc currentRow 			// go to the next row
			lda currentRow 			// what value is it now?
			cmp #20 				// all 20 rows checked?
			beq !skip+	 			// yes, exit
			jsr DownOneRow 			// no, go one row down
			ldy #$00 				// reset row character counter
			jmp !loop-	 			// do next row
!skip:
			rts

// ----------------------------------------------

PrintPaused:
			clc 					// clear carry bit to set cursor
			ldx #5 					// y position
			stx pauseYpos 			// save it
			ldy #12 				// column 12
			jsr plot 				// place cursor
			ldx #$00 				// reset text index
!loop:
			lda pauseText,x
			beq !skip+ 				// next line!
			jsr chrout 				// print char
			inx 					// do next char
			jmp !loop-
!skip:
			inx 					// skip the 0
			txa 					// save current text index..
			pha 					// to stack

			lda pauseYpos 			// get current y position
			adc #2
			cmp #15 				// was this the last line?
			bne !skip+ 				// no. continue
			pla 					// restore stack before quit
			rts
!skip:
			sta pauseYpos 			// save it
			tax 					// send to x register
			clc
			ldy #12 				// column 12
			jsr plot 				// place cursor
			pla  					// restore text index
			tax
			jmp !loop-

// -----------------------------------------------

pauseText:
		.text "   HIT    "
		.byte 0
		.text "   'P'    "
		.byte 0
		.text "    TO    "
		.byte 0
		.text " CONTINUE "
		.byte 0
		.text "   GAME   "
		.byte 0

pauseYpos:
		.byte 0

playAreaErase:
		.byte 0

playAreaBuffer:
		.fill 10*20, 0
