

			.const flashDelay = 15 				// delay in frames.
			.const flashTime = flashDelay * 6 	// how long to flash. 3 times.


// this function will check for lines made.
// it is called before a new block is created.

CheckLines:
			lda #$00
			sta linesMade 			// reset the score
			sta currentRow 			// reset the row counter

			// point to the beginning of the first row

			ldx #12 				// x position is set to 12
			ldy #0 					// y position to 0
			jsr SetScreenPointer 	// set screen memory pointer

			ldx #$00 				// reset memory buffer pointer
readStart:
			ldy #$00				// reset row character counter
!loop:
			lda (screenPointer),y 	// get row character
			cmp #$20 				// is it a space?
			beq nextRow 			// yes, this row is not complete so go to the next
			iny 					// no, so update row character counter
			cpy #10 				// checked all 10 characters in a row?
			bne !loop-				// no, continue this row

			// whole row checked and no space found: we made a line!

			ldy linesMade 			// get index for this made line
			lda currentRow 			// save the row number in ...
			sta lineRowNumbers,y 	// memory, using this index

			// lets save the row screen data into a buffer

			ldy #$00 				// start at begin of line
!loop:
			lda (screenPointer),y 	// get screen data
			sta madeLinesData,x 	// store it in the buffer
			inx 					// update buffer pointer
			iny  					// update row character counter
			cpy #10 				// stored all 10 characters?
			bne !loop- 				// no, keep reading the line

			inc linesMade 			// add line to score
			lda linesMade 			// get amount of lines made so far
			cmp #4 					// have we done 4? 
			beq readDone			// yes. all done.
nextRow:
			inc currentRow 			// go to the next row
			lda currentRow 			// what value is it now?
			cmp #20 				// all 20 rows checked?
			beq readDone 			// yes, exit
			jsr DownOneRow 			// no, go one row down. adjust screenPointer.
			jmp readStart 			// do next row
readDone:
			lda linesMade 			// did we make lines?
			beq !skip+ 				// no, then exit

			lda #flashTime 			// yes. so set flash delay ...
			sta totalFlashDelay 	// counter which we check in the mainloop.
!skip:
			rts


// this function will flash the made lines

FlashLines:
			dec totalFlashDelay		// update total flash time counter.

			dec currentFlashDelay 	// update flash delay counter
			beq !skip+				// ready to update?
			rts 					// no
!skip:
			lda #flashDelay			// restore the flash delay counter ...
			sta currentFlashDelay   // ... to its default value

			lda #$00				// reset the line/row count
			sta currentLineIndex 	// this is the index of the line we're currently handling

			lda lineFlashFlag 		// get line display flag
			eor #%00000001 			// toggle bit 0
			sta lineFlashFlag 		// store flag

			// start modifying screen data to show the lines flashing

			ldx #$00 				// reset screen buffer memory pointer
updateLine:
			txa 					// save mem buffer index to 
			pha 					// the stack

			ldy currentLineIndex 	// get the index if the line we are going to show/hide
			lda lineRowNumbers,y 	// get row number of made line
			tay 					// set y register
			ldx #12 				// set x position
			jsr SetScreenPointer 	// set screenpointer to this position

			pla 					// retrieve mem buffer index from 
			tax 					// the stack

			ldy #$00 				// reset line character counter

			lda lineFlashFlag 		// show or hide the lines?
			bne hide 				// branch to hide

show:
			lda madeLinesData,x 	// get screen data from memory
			sta (screenPointer),y 	// store on screen
			inx 					// update screen data pointer
			iny 					// update character counter
			cpy #10 				// 10 chars done?
			bne show 				// no, keep printing
			jmp gotoNextLine 		// line is complete. continue to next line
hide:
			lda #$20 				// load a space
			sta (screenPointer),y 	// store on screen
			iny 					// update character counter
			cpy #10 				// 10 chars done?
			bne hide 				// not yet.

			// line is complete. continue to next line

gotoNextLine:
			inc currentLineIndex 		// update counter
			lda currentLineIndex 		// how many lines did we do?
			cmp linesMade 				// same as total made?
			beq exitFlashLines			// yes. all done!
			jmp updateLine 		 		// start next line

exitFlashLines:
			rts


//removes made lines from the playfield
RemoveLines:
			lda #$00 				// reset the index to the line
			sta currentLineIndex 	// we are modifying

			// get the row number of the line we need to remove
setPointers:
			ldx currentLineIndex	// get index of current line
			lda lineRowNumbers,x 	// get the row number of current line
			tay 					// put in .Y register
			jsr SetLinePointers 	// set screen memory pointers. assumes .Y has been set
			jsr MoveLineData 		// move the data. empty row is added at the top.

			// do the next line

			inc currentLineIndex 		// update the line index
			lda currentLineIndex 		// how many have we done?
			cmp linesMade  				// done all the made lines?
			bne setPointers 			// no. continue
			rts


// this sets the screen memory pointers to the made line
// and the line above it so data can be moved.
// set .Y to the row to point to before calling this routine.

SetLinePointers:
			ldx #12 					// set horizontal position

			// first, set pointer2 to one row above the
			// the row number in .Y
			dey 						// go up one row
			jsr SetScreenPointer 		// set screen pointer
			lda screenPointer 			
			sta screenPointer2 			// copy values to pointer2
			lda screenPointer+1
			sta screenPointer2+1
			jsr DownOneRow 				// set pointer1 to the row below
			rts


// this routine will move data down until the top of the screen ...
// has been reached. a clear line is added at the top.

MoveLineData:
			// get value of starting row

			ldy currentLineIndex 		// get index of line we're moving data into
			lda lineRowNumbers,y 		// and then get the start row number
			tax 						// move row value to .X

			// move the data
			// until top of screen has been reached.
!startLoop:
			ldy #0 						// reset line character counter
!loop:
			lda (screenPointer2),y 		// get data from row above made line
			sta (screenPointer),y 		// store it in the made line
			iny
			cpy #10
			bne !loop- 					// all 10 done? no, then go back

			// go up one row

			dex 						// update row number to the one above
			beq !skip+ 					// we don't need to do row 0
			txa 						// move the row number ...
			tay 						// to .Y

			pha 						// save row number as next call uses .X

			jsr SetLinePointers 		// update pointers

			pla 						// get row number back
			tax 						// and move to .X

			jmp !startLoop- 			// do the next row
!skip:
			// done moving data, clear the top row

			ldx #12
			ldy #0
			jsr SetScreenPointer 		// point to the top row

			ldy #0 							// reset char counter
			lda #$20 					// load a space
!loop:
			sta (screenPointer),y 		// store on screen
			iny 						// update char counter
			cpy #10
			bne !loop- 					// all done? no continue
!exit:
			rts






// ---------------------------------------------------------

rowsToCheck: 
			.byte 0 				// amount of rows left to check for lines. this is set to 20 when starting.

linesMade:
			.byte 0 				// amount of lines made

currentRow:
			.byte 0 				// we're currently at this row

currentLineIndex:
			.byte 0 				// index to the line we're currenly showing or hinding.

currentFlashDelay:
			.byte flashDelay 		// delay between flashing the lines, set to its default const value

lineFlashFlag:
			.byte 0 				// flag to indicate line hide or show.

totalFlashDelay: 					// flashing takes this amount of time. we flash 3 times.
			.byte 0

lineRowNumbers:
			.fill 4,0 				// row numbers of made lines. 4 bytes.

madeLinesData:
			.fill 40,0 				// memory reservation to save line data. max 4 lines of 10 chars wide
