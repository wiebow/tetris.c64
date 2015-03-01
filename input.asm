

			.const GETIN = $ffe4 		// kernal routine for reading the keyboard

			.const LEFT = 44 			// , <
			.const RIGHT = 46	 		// . >
			.const TURNCOUNTER = 65		// A
			.const TURNCLOCK = 83	 	// S
			.const DOWN = 13 			// ENTER
			.const PAUSE = 80 			// P
			.const RESET = 133	 		// F1

			.const inputDelay = 10	 	// update delay between input checks


// this subroutine gets keyboard input during the game.
// the input has a delay of 10 updates.
// only one key at a time is registered

// collision detection etc is also included when movement is selected.

GetKeyInput:
//			dec keyDelayCounter 	// count down
//			beq continue 			// do nothing until the counter rolls over
//			rts
continue:
			lda inputDelay 			// get the delay value
			sta keyDelayCounter 	// and store it
			jsr GETIN 				// get the held key
			sta keyPressed 			// store for later reference
			bne !nextkey+ 			// A<>0, so a key is held
			rts 					// no key held
!nextkey:
			cmp #PAUSE 				// pause key held?
			bne !nextkey+ 			// no continue
			lda pauseFlag 			// yes, get the current pause flag
			eor #%00000001 			// flip between 0 and 1
			sta pauseFlag 			// store it
			rts
!nextkey:
 			cmp #LEFT 				// left key held?
 			bne !nextkey+ 			// no, check for next
			jsr EraseBlock 			// remove block on this position
			dec blockXposition 		// alter block position

			jsr CheckBlockSpace 	// will it fit?
			beq !skip+ 				// yes. print it
			inc blockXposition 		// no. move it back
!skip:
			jsr PrintBlock
 			rts
!nextkey:
 			cmp #RIGHT 				// right key held?
 			bne !nextkey+ 			// no. check for next
 			jsr EraseBlock 			// remove block on this position
 			inc blockXposition

 			jsr CheckBlockSpace 	// will it fit?
 			beq !skip+ 				// A register is 0, so yes
 			dec blockXposition 		// don't move!
!skip:
 			jsr PrintBlock 
 			rts
!nextkey:
 			cmp #TURNCOUNTER 		// turn counter clockwise?
 			bne !nextkey+ 			// no
 			jsr EraseBlock 			// remove block on this position
 			lda #$01 				// yes. 1 means counter
 			jsr AnimateBlock 		// and go

 			jsr CheckBlockSpace
 			beq !skip+
 			lda #$00
 			jsr AnimateBlock
!skip:
 			jsr PrintBlock 			// draw the new block frame
 			rts
!nextkey:
			cmp #TURNCLOCK 			// turn clockwise?
			bne !nextkey+ 			// no
			jsr EraseBlock 			// get rid of block on this position
			lda #$00 				// yes
			jsr AnimateBlock 		// do it

			jsr CheckBlockSpace 	// will it fit?
			beq !skip+ 				// yes. so print it
			lda #$01 				// no, rotate back
			jsr AnimateBlock 		// ..
!skip:
			jsr PrintBlock 			// print the block with new frame
			rts
!nextkey:
			cmp #DOWN 				// down one row?
			bne !nextkey+ 			// no
			jsr EraseBlock
			inc blockYposition 		// yes. change block position
			jsr CheckBlockSpace
			beq !skip+
			dec blockYposition		// cannot move down, so move back
			jsr PrintBlock			// and print
			rts
!skip:
			lda fallDelay 			// reset the fall delay timer
			sta fallDelayTimer 		// to avoid two movements close to each other.
			jsr PrintBlock 			// print the block
			rts
!nextkey:
			cmp #RESET 				// reset game?
			bne !nextkey+
			nop 					// reserved for later.
!nextkey:
			rts


// ------------------------------------------------

pauseFlag:
			.byte 0 				// game is pause when this is set to 1

keyDelayCounter:
			.byte 0					// if this reaches 0, the player input is read

keyPressed:
			.byte 0