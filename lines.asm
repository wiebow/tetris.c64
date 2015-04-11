
// check for lines

// this function will check for lines made.
// it is called before a new block is created.

			.const flashDelay = 15 	// speed of flash, in frames.

CheckLines:
			lda #$00 				// reset the lines made counter
			sta linesMade

			lda #20 				// set the amount of rows to check
			sta rowsToCheck

			lda #4 					// set screen memory pointer
			sta screenPointer+1 	// to the first row to check
			lda #12 				// so set it to $040c
			sta screenPointer


			ldx #$00 				// reset screen buffer memory pointer.
readStart:
			ldy #$00				// row width = 10 chars.
!loop:
			lda (screenPointer),y 	// get screen data
			cmp #$20 				// is it a space?
			beq nextRow 			// yes, this row is not complete so go to the next
			iny 					// update row character counter
			cpy #10 				// check all 10 characters?
			bne !loop-				// no, continue on this line

			// whole row checked, no space found: made a line!

			ldy linesMade 			// get index of current line
			lda screenPointer 		// get lo byte of screen position of this line
			sta madeLinesLo,y		// store it
			lda screenPointer+1 	// same for ...
			sta madeLinesHi,y		// ... hi byte.

			// lets save the row screen data into a buffer

			ldy #$00 				// more read pointer back to begin of row
!loop:
			lda (screenPointer),y 	// get line screen data
			sta madeLinesData,x 	// store it in the buffer
			inx 					// update buffer pointer
			iny  					// update row char counter
			cpy #10 				// done 10 characters?
			bne !loop- 				// no, keep reading the line

			inc linesMade 			// add line to score
			lda linesMade 			// get amount of lines made so far
			cmp #4 					// have we done 4? 
			beq readDone			// yes. all done.
nextRow:
			dec rowsToCheck 		// more rows to check?
			beq readDone			// no, all done.

			jsr DownOneRow 			// yes, go one row down. adjust screenPointer
			jmp readStart 			// do next row
readDone:
			rts


// this function will flash the made lines
// flash will happen 3 times.

FlashLines:
			dec lineFlashDelay 		// update counter
			beq !skip+				// ready to update?
			rts 					// no
!skip:
			lda #flashDelay			// restore the flash delay counter
			sta lineFlashDelay 

			lda #$00				// reset the line/row count
			sta flashCurrentLine 	// this is the index of the line we're currently handling

			lda lineFlashFlag 		// get line display flag
			eor #%00000001 			// toggle bit 0
			sta lineFlashFlag 		// store flag


			// hide or show made lines

			ldx #$00 				// reset memory pointer
updateLine:
			ldy flashCurrentLine 	// get the index if the line we are going to show/hide
			lda madeLinesLo,y 		// get lo byte of screen location of made line
			sta screenPointer 		// set pointer to it
			lda madeLinesHi,y 		// same for ...
			sta screenPointer+1 	// ... hi byte

			ldy #$00 				// reset row character counter

			lda lineFlashFlag 		// show or hide?
			bne hide 				// branch to hide

			// show line

show:
			lda madeLinesData,x 	// get screen data from memory
			sta (screenPointer),y 	// store on screen
			inx 					// update screen data pointer
			iny 					// update character counter
			cpy #10 				// 10 chars done?
			bne show 				// no, keep printing

			// line is complete. continue to next line

			inc flashCurrentLine 		// update counter
			lda flashCurrentLine 		// how many lines did we do?
			cmp linesMade 				// same as total made?
			beq exitFlashLines			// yes. all done!
			jmp updateLine 		 		// start next line

hide:
			lda #$20
			sta (screenPointer),y 	// store on screen
			inx 					// update screen data pointer
			iny 					// update character counter
			cpy #10 				// 10 chars done?
			bne hide 				// not yet.

			// line is complete. continue to next line

			inc flashCurrentLine 		// update counter
			lda flashCurrentLine 		// how many lines did we do?
			cmp linesMade 				// same as total made?
			beq exitFlashLines			// yes. all done!
			jmp updateLine 		 		// start next line

exitFlashLines:
			rts




//removes made lines from the playfield.

RemoveLines:



// ---------------------------------------------------------

flashCurrentLine:
			.byte 0 				// we are showing or hiding this line
lineFlashDelay:
			.byte flashDelay		// delay between flashing the lines, set to its default const value
lineFlashFlag:
			.byte 0 				// 1 or 0, show or hide flag.
rowsToCheck: 
			.byte 0 				// amount of rows left to check for lines. this is set to 20 when starting.
linesMade:
			.byte 0 				// amount of lines made
madeLinesLo:
			.byte 0,0,0,0			// lo bytes of made lines (screen memory address)
madeLinesHi:
			.byte 0,0,0,0 			// hi bytes of made lines

madeLinesData:
			.fill 40,0 				// memory reservation to save line data. max 4 lines of 10 chars

