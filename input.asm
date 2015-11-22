
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

// reset and pause keys are checked first. if game is paused, then
// no more keys are checked to prevent input

GetKeyInput:
			lda KEYPRESSED 			// get held key code
			cmp previousKey 		// is it a different key than before?
			bne !skip+	 			// if yes, then skip the current input delay
									// because we want snappy controls
doDelay:
			dec inputDelayCounter 	// count down
			beq !skip+
			rts
!skip:
			ldx #INPUTDELAY 		// get the delay value
			stx inputDelayCounter 	// and restore it

			sta previousKey 		// save the held key
			cmp #NOKEY 				// none?
			bne !nextkey+
			rts
!nextkey:
			cmp #RESET 				// reset game?
			bne !nextkey+
			nop 					// add later
!nextkey:
			cmp #PAUSE
			bne !nextkey+

			lda pauseFlag 			// get the current pause flag
			eor #%00000001 			// flip between 0 and 1
			sta pauseFlag 			// store it
			beq !skip+ 				// skip next bit if not paused

			// game is paused. so clear the screen

			lda #$01 				// set the erase flag
			sta playAreaErase 		// so area gets cleared as well
			jsr SavePlayArea 		// save and clear the play area
			jmp PrintPaused
!skip:
			jmp RestorePlayArea 	// restore the screen

!nextkey:
			ldx pauseFlag 			// get the pause flag
			beq !skip+ 				// continue if not in pause mode

			// game is in pause mode. we do not check more keys
			rts
!skip:
			cmp #LEFT 				// left key held?
			bne !nextkey+ 			// if not check next key
			jmp BlockLeft
!nextkey:
  			cmp #RIGHT
  			bne !nextkey+
  			jmp BlockRight
!nextkey:
  			cmp #TURNCOUNTER 		// turn counter-clockwise held?
  			bne !nextkey+ 			// no
  			jmp BlockRotateCCW
!nextkey:
 			cmp #TURNCLOCK
 			bne !nextkey+
 			jmp BlockRotateCW
!nextkey:
			cmp #DOWN
			bne !nextkey+
			jmp BlockDown
!nextkey:
			rts

// -------------------------------------------------

// this subroutine checks for joystick input from port 2
// the input register is rotated and the carry bit is checked
// we have only one joystick button, so UP is used for rotate CCW :/


.const CIAPRA = $dc00 				// joystick port 2 input register
.const NOJOY  = $ff 				// value for no joy input


GetJoyInput:
			lda CIAPRA 				// load the input byte
			cmp previousJoy 		// same as previous input?
			bne !skip+ 				// no, so skip delay
joyDelay:
			dec inputDelayCounter	// update delay
			beq !skip+ 				// continue if delay complete
			rts
!skip:
			ldx #INPUTDELAY 		// reset the counter
			stx inputDelayCounter

			sta previousJoy 		// save this input value
			cmp #NOJOY 				// is there input?
			bne !nextjoy+ 			// yes, continue
			rts 					// no. done.
!nextjoy:
			clc 					// clear the carry bit
			lsr 					// check bit 0: joy up
			bcs !nextjoy+
			jmp BlockRotateCCW 		// we only have one button so
									// compromise with using up
!nextjoy:
			lsr 					// check bit 1: joy down
			bcs !nextjoy+ 			// bit set means not pressed
			jmp BlockDown
!nextjoy:
			lsr 					// check bit 2: joy left
			bcs !nextjoy+
			jmp BlockLeft
!nextjoy:
			lsr 					// check bit 3: joy right
			bcs !nextjoy+
			jmp BlockRight
!nextjoy:
			lsr 					// check bit 4: joy fire button
			bcs !nextjoy+
			jmp BlockRotateCW
!nextjoy:
			rts 					// those were all the relevant bits.

// -------------------------------------------------
// movement subroutines

BlockLeft:
			jsr EraseBlock 			// remove block on this position
			dec blockXposition 		// alter block position
			jsr CheckBlockSpace 	// will it fit?
			beq !skip+ 				// yes. print it
			inc blockXposition 		// no. move it back
!skip:
			jsr PrintBlock
 			rts

BlockRight:
  			jsr EraseBlock
  			inc blockXposition
  			jsr CheckBlockSpace
 			beq !skip+
  			dec blockXposition
!skip:
  			jsr PrintBlock
  			rts

BlockDown:
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

BlockRotateCCW:
  			jsr EraseBlock 			// remove block on this position
  			lda #$01 				// yes. 1 means counter clock wise
 			jsr AnimateBlock 		// rotate it
 			jsr CheckBlockSpace 	// will it fit?
 			beq !skip+ 				// yes, print it
 			lda #$00 				// no
  			jsr AnimateBlock 		// turn it back
!skip:
  			jsr PrintBlock
  			rts

BlockRotateCW:
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

// ------------------------------------------------

pauseFlag:
			.byte 0 				// game is pause when this is set to 1

inputDelayCounter:
			.byte INPUTDELAY		// if this reaches 0, the player input is read

previousKey:
			.byte 64				// previous key held

previousJoy:
			.byte 255 				// previous joy direction held

