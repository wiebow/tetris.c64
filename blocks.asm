

// code concerning blocks


			.const screenPointer = $fb		// zero page pointer to a screen memory position
			.const screenPointer2 = $fd 	// 2nd pointer to move data


// sets screen memory pointer to x and y column
// set X and Y register before calling this routine.
SetScreenPointer:
			stx screenPointer		// set low byte. use x immediately...

			lda #4
			sta screenPointer+1 	// set hi byte

			cpy #0					// at top of the screen?
			beq !exit+				// then no change is needed
			txa 					// get the current low byte of screen pointer
!loop:
			clc
			adc #40					// add a row (screen is 40 chars wide)
			bcc !skip+ 				// no page boundery passed? then skip next instruction
			inc screenPointer+1 	// page boundery passed, increment screen memory hi byte
!skip:
			dey						// decrement the y count
			bne !loop-				// do next row if more needed
			sta screenPointer		// store the screen memory low byte
!exit:
			rts


// this subroutine adjusts the screenPointer pointer so it
// points to the row exactly below it.
DownOneRow:
			lda screenPointer 		// add 40 to the screen memory pointer
			clc
			adc #40
			bcc !skip+ 				// skip next instruction if page boundery was not passed
			inc screenPointer+1 	// inc hi byte of the screen address
!skip:
			sta screenPointer 		// store new lo byte
			rts


// this subroutine adjusts the screenPointer pointer so it
// points to the row exactly above it.
UpOneRow:
			lda screenPointer 		// dec 40 from the screen memory pointer
			sec
			sbc #40
			bcs !skip+ 				// skip next instruction if page boundery was not passed
			dec screenPointer+1 	// dec hi byte of the screen address
!skip:
			sta screenPointer 		// store new lo byte
			rts


// prints a block on the screen
// x and y position but be set for the use of SetScreenPosition ...
// and SelectBlock must have been called before calling this subroutine

PrintBlock:
			ldx blockXposition 		// print to the correct place on screen
			ldy blockYposition
			jsr SetScreenPointer

			// get pointer to the start of block data

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
			sta (screenPointer),y    // put it on the screen
!skip:
			inx 					// inc the block data pointer
			cpx #16 				// done 16 characters? (4x4)
			bne !skip+ 				// continue printing if not
			rts
!skip:
			iny						// inc the print counter
			cpy #$04 				// each block is 4 characters wide, done for this row?
			bne printLoop 			// continue this row

			jsr DownOneRow 			// go down one row

			ldy #$00 				// reset the counter for a new row
			jmp printLoop 			// do the next row


// Checks if there is space for a block to be printed.
// Set the position registers before calling this routine.
// A register is set according to outcome: 0 = no problem, 1 = no space

CheckBlockSpace:
			ldx blockXposition
			ldy blockYposition
			jsr SetScreenPointer

			// first, get pointer to the start of block data

			ldx currentFrame
			lda frameArrayLo,x 		// get the lo byte
			sta spaceLoop+1			// store in lda instruction
			lda frameArrayHi,x 		// same for hi byte
			sta spaceLoop+2 		// and store

			// check the space

			ldx #$00 				// reset the block data counter
			ldy #$00 				// reset the print counter
spaceLoop:
			lda $1010,x 		   	// get block data.
			cmp #$20 				// is it a space?
		    beq !skip+ 				// then skip the check it

		    // check the position where data must be printed

			lda (screenPointer),y    // load the data on this position
			cmp #$20 				// is it a space?
			beq !skip+ 				// yes. no problem. continue check

			lda #$01 				// no space for block. set flag
			rts
!skip:
			inx 					// inc the block data pointer
			cpx #16 				// done 16 characters? (4x4)
			bne !skip+ 				// continue printing if not
			lda #$00 				// all locations checked. done. clear flag
			rts
!skip:
			iny
			cpy #$04
			bne spaceLoop
			jsr DownOneRow
			ldy #$00
			jmp spaceLoop


// erases a block on the screen
// same as PrintBlock but outputting spaces
EraseBlock:
			ldx blockXposition
			ldy blockYposition
			jsr SetScreenPointer

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
			sta (screenPointer),y    // and erase this block character.
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


// this subroutine will select a block.
// set .A register with block id before calling this subroutine
SelectBlock:
			sta currentBlockID 		// store the block id
			tax
			lda blockFrameStart,x 	// get begin frame number for this block
			sta currentFrame 		// and store it for display
			sta firstFrame 			// and for AnimateBlock routine
			lda blockFrameEnd,x 	// get last frame number for this block
			sta lastFrame 			// and store it for AnimateBlock routine
			rts


// this subroutine will advance the block animation forward or backwards...
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


// this subroutine updates the block fall timer...
// and drops the block a row when needed.
// A register holds: 0: nothing happened ...
// 1: block fell, 2:block fell, new block needed.
DropBlock:
			dec fallDelayTimer 	// update the delay timer
			beq !skip+ 			// drop the block if 0 is reached
			lda #$00 			// return 0 = nothing happened
			rts
!skip:
			lda fallDelay 		// reset the block fall delay
			sta fallDelayTimer

			// drop the block

			jsr EraseBlock 		// erase from screen
			inc blockYposition 	// move 1 row down
			jsr CheckBlockSpace // will it fit?
			bne !skip+ 			// A is set to 1, so no.
			jsr PrintBlock 		// yes. print it
			lda #$01 			// status is block fell
			rts
!skip:
			dec blockYposition 	// no. move back.
			jsr PrintBlock 		// print it
			lda #$02 			// new block needed
			rts


// selects a new random block
// it will take the id from the nextBlockID address.
// the next block will be again determined, and printed on the screen

// register A holds: 0 if all went well, 1 if new block overlaps screen data (game over!)
NewBlock:

			// reset the block fall delay

			lda fallDelay
			sta fallDelayTimer

			// nextBlockID was printed as the next block.
			// set location to remove from screen

			ldx #25 				// erase block from 25,15
			ldy #15
			stx blockXposition 		// save the position
			sty blockYposition
			jsr SetScreenPointer

			// select and save the ID
			// because we will create the block later on

			lda nextBlockID
			pha

			jsr SelectBlock 		// select it
			jsr EraseBlock 			// remove it

			// get the id of the NEW block
			// and print it on the bottomright of the screen

			jsr GetRandom
			sta nextBlockID 		// save next block id
			jsr SetScreenPointer 	// restore screenpointer to 25,15
									// as set previously
			lda nextBlockID
			jsr SelectBlock
			jsr PrintBlock 			// print it.

			// done.

			// create the new player block

			ldx #15 				// put new block on 15,0
			ldy #00
			stx blockXposition 		// save the position
			sty blockYposition
			jsr SetScreenPointer

			pla 					// restore the player block id
			sta currentBlockID 		// put in current id address
			jsr SelectBlock 		// select it

			jsr CheckBlockSpace 	// will it fit?
			bne !skip+ 				// A is set to 1, so no
			jsr PrintBlock 			// print it.
			lda #$00 				// notify all is well.
			rts
!skip:
			jsr PrintBlock 			// print it
			lda #$01 				// notify that it doesnt fit!!!
			rts


// ---------------------------------------------------------------------------------------------

// registers to store information in

blockXposition:
			.byte 0 				// current player block x position
blockYposition:
			.byte 0 				// current player block y position
currentBlockID:
			.byte 0 				// current block ID
nextBlockID:
			.byte 0 				// this is the next block to fall

currentFrame:
			.byte 0  				// frame of current block
firstFrame:
			.byte 0					// first animation frame for current block
lastFrame:
			.byte 0					// last animation frame for current block

fallDelay:
			.byte 0 				// delay between block drops for this level
fallDelayTimer:
			.byte 0 				// current timer for delay


// ---------------------------------------------------------------------------------------------

// arrays of block start and end animation frames.
// example: block 0 animation starts at frame 0 and ends at frame 3

//                0 1  2  3  4  5  6
blockFrameStart:
			.byte 0,4, 8,12,14,16,18

blockFrameEnd:
			.byte 3,7,11,13,15,17,18

// these lo and hi byte pointers refer to the block data adress values

frameArrayLo:
			.byte <frame00, <frame01, <frame02, <frame03 		// block 0
			.byte <frame04, <frame05, <frame06, <frame07 		// block 1
			.byte <frame08, <frame09, <frame10, <frame11 		// block 2
			.byte <frame12, <frame13					 		// block 3
			.byte <frame14, <frame15					 		// block 4
			.byte <frame16, <frame17					 		// block 5
			.byte <frame18								 		// block 6

frameArrayHi:
			.byte >frame00, >frame01, >frame02, >frame03 		// block 0
			.byte >frame04, >frame05, >frame06, >frame07 		// block 1
			.byte >frame08, >frame09, >frame10, >frame11 		// block 2
			.byte >frame12, >frame13					 		// block 3
			.byte >frame14, >frame15					 		// block 4
			.byte >frame16, >frame17					 		// block 5
			.byte >frame18								 		// block 6

// block0, 4 frames

frame00:
			.text " II "
			.text "  I "
			.text "  I "
			.text "    "
frame01:
			.text "   I"
			.text " III"
			.text "    "
			.text "    "
frame02:
			.text " I  "
			.text " I  "
			.text " II "
			.text "    "
frame03:
			.text "    "
			.text " III"
			.text " I  "
			.text "    "

// block1, 4 frames

frame04:
			.text "  G "
			.text " GG "
			.text "  G "
			.text "    "
frame05:
			.text "  G "
			.text " GGG"
			.text "    "
			.text "    "
frame06:
			.text "  G "
			.text "  GG"
			.text "  G "
			.text "    "
frame07:
			.text "    "
			.text " GGG"
			.text "  G "
			.text "    "

// block2, 4 frames

frame08:
			.text " HH "
			.text " H  "
			.text " H  "
			.text "    "
frame09:
			.text "    "
			.text "HHH "
			.text "  H "
			.text "    "
frame10:
			.text " H  "
			.text " H  "
			.text "HH  "
			.text "    "
frame11:
			.text "H   "
			.text "HHH "
			.text "    "
			.text "    "

// block3, 2 frames

frame12:
			.text " X  "
			.text " XX "
			.text "  X "
			.text "    "
frame13:
			.text " XX "
			.text "XX  "
			.text "    "
			.text "    "

// block4, 2 frames

frame14:
			.text "  H "
			.text " HH "
			.text " H  "
			.text "    "
frame15:
			.text "HH  "
			.text " HH "
			.text "    "
			.text "    "

//block5, 2 frames

frame16:

			.byte 32,92,32,32
			.byte 32,93,32,32
			.byte 32,93,32,32
			.byte 32,94,32,32

			// .text " K  "
			// .text " K  "
			// .text " K  "
			// .text " K  "
frame17:
			.text "    "
			.byte 89,90,90,91
//			.text "YZZK"
			.text "    "
			.text "    "

// block6, 1 frame

frame18:
			.text "    "
			.text " JJ "
			.text " JJ "
			.text "    "
