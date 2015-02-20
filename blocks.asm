
// Tetris for 6502. (c) WdW 2015


// code concerning blocks


			.const screenMemory = $fb		// zero page pointer to a screen memory position


// translate x (column) and y (row) locations to screen memory positions
// and store these in screenMemory zero page registers
// values are taken from blockx and yposition.

SetScreenPosition:

			// first, reset the screen pointer to $0400, the start of screen memory

			lda #4
			sta screenMemory+1 		// set hi byte
			lda #0
			sta screenMemory		// set low byte

			// add the rows (y position) first. a=0 at this point.
						
			ldy blockYposition		
			cpy #0					// at top of the screen?
			beq ydone				// then no change is needed
yloop:
			clc
			adc #40					// add a row (screen is 40 chars wide)
			bcc !skip+ 				// no page boundery passed? then skip next instruction
			inc screenMemory+1 		// page boundery passed, increment screen memory hi byte
!skip:
			dey						// decrement the y count
			cpy #$00
			bne yloop				// do next row if needed
ydone:
			// add the columns (x position)

			ldx blockXposition
			cpx #0 					// at the leftmost position of the screen?
			beq xdone				// then no change is needed
			clc
			adc blockXposition		// add the columns
			bcc xdone 				// no page boundery passed? then skip next instruction
			inc screenMemory+1		// page boundery passed, increment screen memory hi byte
xdone:
			sta screenMemory		// store the screen memory low byte
			rts 					// done!




// prints a block on the screen
// x and y position but be set becaus of SetScreenPosition
// and SelectBlock must have been called before calling this subroutine

PrintBlock:
			jsr SetScreenPosition 	// ensure that we print on the right spot

			// first, get pointer to the start of block data

			ldx currentFrame 		// this has been set by calling SelectBlock or AnimateBlock

			lda frameArrayLo,x 		// get the lo byte
			sta printLoop+1			// store in lda instruction
			lda frameArrayHi,x 		// same for hi byte
			sta printLoop+2 		// and store

			// print the block

			ldx #$00 				// reset the block data counter
			ldy #$00 				// reset the print counter
printLoop:
			lda $1010,x 		   	// get block data. the adress is modified at the start of this subroutine
			cmp #$20 				// is it a space?
		    beq !skip+ 				// then skip printing it
			sta (screenMemory),y    // put it on the screen
!skip:
			inx 					// inc the block data pointer
			cpx #16 				// done 16 characters? (4x4)
			bne !skip+ 				// continue printing if not
			rts 					// done!
!skip:
			iny						// inc the print counter
			cpy #$04 				// each block is 4 characters wide, done for this row?
			bne printLoop 			// continue this row

			jsr DownOneRow 			// go down one row

			ldy #$00 				// reset the counter for a new row
			jmp printLoop 			// do the next row


// erases a block on the screen
// same as PrintBlock but outputting spaces

EraseBlock:
			jsr SetScreenPosition	// make sure we do the erasing on the right spot

			// first, get pointer to the start of block data

			ldx currentFrame 		// this has been set by calling SelectBlock or AnimateBlock

			lda frameArrayLo,x 		// get the lo byte
			sta eraseLoop+1			// store in lda instruction
			lda frameArrayHi,x 		// same for hi byte
			sta eraseLoop+2 		// and store

			// erase the block

			ldx #$00 				// reset the block data counter
			ldy #$00 				// reset the columns counter
eraseLoop:
			lda $1010,x 		   	// get block data. the adress is modified at the start of this subroutine
			cmp #$20 				// is it a space?
		    beq !skip+ 				// then skip erasing it.
		    lda #$20 				// use a space
			sta (screenMemory),y    // and erase this block character.
!skip:
			inx 					// inc the block data pointer
			cpx #16 				// done 16 characters? (4x4)
			bne !skip+ 				// continue printing if not
			rts 					// done!
!skip:
			iny						// inc the columns counter
			cpy #$04 				// each block is 4 columns wide, done for this row?
			bne eraseLoop 			// continue this row

			jsr DownOneRow 			// go down one row

			ldy #$00 				// reset the counter for a new row
			jmp eraseLoop 			// do the next row




// this subroutine adjusts the screenmemory pointer so it
// points to the row exactly below it.

DownOneRow:
			lda screenMemory 		// add 40 to the screen memory pointer
			clc
			adc #40
			bcc !skip+ 				// skip next instruction if page boundery was not passed
			inc screenMemory+1 		// inc hi byte of the screen address
!skip:
			sta screenMemory 		// store new lo byte
			rts



// this subroutine will select a block.
// set A register with block id before calling this subroutine

SelectBlock:
			sta currentBlockID 		// store the block id
			tax
			lda blockFrameStart,x 	// get begin frame number for this block
			sta currentFrame 		// and store it for display
			sta firstFrame 			// and for AnimateBlock routine
			lda blockFrameEnd,x 	// get last frame number for this block
			sta lastFrame 			// and store it for AnimateBlock routine
			rts


// this subroutine will advance the block animation forward or backwards
// depending on the value of the A register. Set that before calling this subroutine.
// 0 = forward, clockwise
// 1 = backward, counter clockwise
// Also, SelectBlock must have been called so the animation settings are correct.

AnimateBlock:
			cmp #1 					// see if we need to move the animation
			beq doBackward	 		// forward or backward
doForward:
			lda currentFrame 		// get the current frame number
			cmp lastFrame 			// already done the last frame?
			beq !skip+ 				// yes. go set to first frame
			inc currentFrame 		// no. go one frame forward
			rts 					// done!
!skip:
			lda firstFrame 			// reset the frame
			sta currentFrame 		// to the first frame
			rts 					// done!
doBackward:
			lda currentFrame 		// get the current frame.
			cmp firstFrame 			// already at the first frame? 
			beq !skip+ 				// then reset to last frame
			dec currentFrame 		// no. go back one frame
			rts 					// done!
!skip:
			lda lastFrame 			// reset the animation to
			sta currentFrame 		// the last frame.
			rts 					// done!

// ---------------------------------------------------------------------------------------------

// some registers to store information in

blockXposition:
			.byte 0 				// current player block x position
blockYposition:
			.byte 0 				// current player block y position
currentBlockID: 					
			.byte 0 				// current block ID
currentFrame:
			.byte 0  				// frame of current block
firstFrame: 			
			.byte 0					// first animation frame for current block
lastFrame: 				
			.byte 0					// last animation frame for current block


// ---------------------------------------------------------------------------------------------

// arrays of block start and end animation frames.
// example: block 0 animation starts at frame 0 and ends at frame 3

blockFrameStart:
			.byte 0, 4

blockFrameEnd:
			.byte 3, 7

// these lo and hi byte pointers refer to the block data adress values

frameArrayLo:
			.byte <frame00, <frame01, <frame02, <frame03 		// block 0
			.byte <frame04, <frame05, <frame06, <frame07 		// block 1

frameArrayHi:
			.byte >frame00, >frame01, >frame02, >frame03 		// block 0
			.byte >frame04, >frame05, >frame06, >frame07 		// block 1

// block0, 4 frames

frame00:
			.text " AA "
			.text "  A "
			.text "  A "
			.text "    "
frame01:
			.text "   A"
			.text " AAA"
			.text "    "
			.text "    "
frame02:
			.text "  A "
			.text "  A "
			.text "  AA"
			.text "    "
frame03:
			.text "    "
			.text " AAA"
			.text " A  "
			.text "    "

// block1, 4 frames

frame04:
			.text "  @ "
			.text " @@ "
			.text "  @ "
			.text "    "
frame05:
			.text "  @ "
			.text " @@@"
			.text "    "
			.text "    "
frame06:
			.text "  @ "
			.text "  @@"
			.text "  @ "
			.text "    "
frame07:
			.text "    "
			.text " @@@"
			.text "  @ "
			.text "    "

