
			.const KEYPRESSED = $cb 	// scnkey puts code of held key here.

			// keycodes

			.const LEFT = 47 			// , <
			.const RIGHT = 44	 		// . >
			.const TURNCOUNTER = 10		// A
			.const TURNCLOCK = 13	 	// S
			.const DOWN = 1 			// ENTER
			.const PAUSE = 41 			// P
			.const RESET = 4	 		// F1
			.const NOKEY = 64 			// hehe

			.const INPUTDELAY = 7	 	// update delay between input checks


// this subroutine gets keyboard input during the game.
// it also moves and prints the affected block
// only one key at a time is registered
// collision detection etc is also included when move is made.

GetKeyInput:
			lda KEYPRESSED 			// get held key code
			cmp previousKey 		// is it a different key than before?
			bne !skip+	 			// if yes, then skip the current input delay
									// because we want snappy controls
doDelay:
			dec keyDelayCounter 	// count down
			beq !skip+
			rts
!skip:
			ldx #INPUTDELAY 		// get the delay value
			stx keyDelayCounter 	// and restore it

			sta previousKey 		// save the held key
			cmp #NOKEY 				// none?
			bne !nextkey+
			rts
!nextkey:
			cmp #LEFT 				// left key held?
			bne !nextkey+ 			// if not check next key

			jsr EraseBlock 			// remove block on this position
			dec blockXposition 		// alter block position
			jsr CheckBlockSpace 	// will it fit?
			beq !skip+ 				// yes. print it
			inc blockXposition 		// no. move it back
!skip:
			jsr PrintBlock
 			rts
!nextkey:
  			cmp #RIGHT
  			bne !nextkey+
  			jsr EraseBlock
  			inc blockXposition
  			jsr CheckBlockSpace
 			beq !skip+
  			dec blockXposition
!skip:
  			jsr PrintBlock
  			rts
!nextkey:
  			cmp #TURNCOUNTER 		// turn counter-clockwise held?
  			bne !nextkey+ 			// no
  			jsr EraseBlock 			// remove block on this position
  			lda #$01 				// yes. 1 means counter
 			jsr AnimateBlock 		// rotate it
 			jsr CheckBlockSpace 	// will it fit?
 			beq !skip+ 				// yes, print it
 			lda #$00 				// no
  			jsr AnimateBlock 		// turn it back
!skip:
  			jsr PrintBlock
  			rts
!nextkey:
 			cmp #TURNCLOCK
 			bne !nextkey+
 			jsr EraseBlock
 			lda #$00
 			jsr AnimateBlock
 			jsr CheckBlockSpace
 			beq !skip+
 			lda #$01
 			jsr AnimateBlock
!skip:
 			jsr PrintBlock
 			rts
!nextkey:
			cmp #DOWN
			bne !nextkey+

			jsr EraseBlock
			inc blockYposition
			jsr CheckBlockSpace
			beq !skip+

			// block doesn't fit
			dec blockYposition
			jsr PrintBlock

			lda #$04 				// we made block drop
			sta fallDelayTimer 		// so create new one without delay
			rts
!skip:
			jsr PrintBlock

 			lda #$04 	 			// have a smaller falldelay
 			sta fallDelayTimer 		// as we move down ourselves

 			// moving the block down gives points

			lda #1
 			sta addition
 			lda #0
 			sta addition+1
 			sta addition+2
 			jsr AddScore
 			jsr PrintScore
			rts
!nextkey:
			cmp #RESET 				// reset game?
			bne !nextkey+
			nop 					// add  later
!nextkey:
			// cmp #PAUSE
			// bne !nextkey+
			// lda pauseFlag 			// get the current pause flag
			// eor #%00000001 			// flip between 0 and 1
			// sta pauseFlag 			// store it
			// rts
nokey:
			rts


// ------------------------------------------------

pauseFlag:
			.byte 0 				// game is pause when this is set to 1

keyDelayCounter:
			.byte INPUTDELAY		// if this reaches 0, the player input is read

previousKey:
			.byte 64				// previous key held
