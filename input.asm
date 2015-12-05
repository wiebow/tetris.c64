
.const keyPressed = $cb 	// scnkey puts code of held key here.
.const INPUTDELAY = 15	 	// update delay between input checks

// keycodes to check for in inputResult values
// valid controls are also used for joystick results.

.const LEFT = 47 			// , <
.const RIGHT = 44	 		// . >
.const TURNCOUNTER = 10		// A
.const TURNCLOCK = 13	 	// S
.const DOWN = 1 			// ENTER
.const PAUSE = 41 			// P
.const RESET = 4	 		// F1
.const CHANGEBACKGROUND = 5 // F3
.const CHANGECOLOUR = 6 	// F5
.const NOKEY = 64
.const NOINPUT = 253		// no input detected

// this byte holds the result of the input query
// game modes can check this byte and get the
// registered input after calling GetInput

inputResult:
			.byte 0


// ------------------------------------------------------

// this routine will scan keyboard first and then the joystick
// but only if there was no input from the keyboard

GetInput:
			jsr GetKeyInput
			lda inputResult
			cmp #NOINPUT
			bne !skip+
			jsr GetJoyInput
!skip:
			rts

// ------------------------------------------------------

// this subroutine gets keyboard input
// only one key at a time is registered
// "inputResult" will hold the registered input

GetKeyInput:
			lda #NOINPUT 			// first assume there is no input
			sta inputResult

			lda keyPressed 			// get held key code
			cmp previousKey 		// is it a different key than before?
			bne !skip+	 			// if yes, then skip the current input delay
									// because we want snappy controls
doDelay:
			dec inputDelayCounter 	// count down
			beq !skip+ 				// continue if delay passed
			rts 					// delay ongoing. exit. no input.
!skip:
			sta previousKey 		// save key code for next update
			cmp #NOKEY 				// is it the no key held code?
			bne !skip+ 				// no
			lda #NOINPUT 			// yes. select that input result
!skip:
			sta inputResult 		// store input result

			lda #INPUTDELAY 		// restore key delay counter
			sta inputDelayCounter
			rts

// -------------------------------------------------

// this subroutine checks for joystick input from port 2
// the input register is rotated and the carry bit is checked
// we have only one joystick button, so UP is used for rotate CCW
// "inputResult" will hold the registered input

.const CIAPRA = $dc00 				// joystick port 2 input register
.const NOJOY  = $ff 				// value for no joy input

GetJoyInput:
			lda #NOINPUT 			// assume there is no input
			sta inputResult

			lda CIAPRA 				// load the input byte
			cmp previousJoy 		// same as previous input?
			bne !skip+ 				// no, so skip delay
joyDelay:
			dec inputDelayCounter	// update delay
			beq !skip+ 				// continue if delay complete
			rts
!skip:
			ldx #INPUTDELAY 		// reset the delay counter
			stx inputDelayCounter

			sta previousJoy 		// save this input value
			cmp #NOJOY 				// same as noinput?
			bne !nextjoy+ 			// no, so go check the possiblities

			lda #NOINPUT 			// there is no input, store it
			sta inputResult 		// in result
			rts
!nextjoy:
			clc 					// clear the carry bit
			lsr 					// check bit 0: joy up
			bcs !nextjoy+

			lda #TURNCOUNTER 		// store the correct code ...
			sta inputResult 		// as result
			rts
!nextjoy:
			lsr 					// check bit 1: joy down
			bcs !nextjoy+ 			// bit set means not pressed
			lda #DOWN
			sta inputResult
			rts
!nextjoy:
			lsr 					// check bit 2: joy left
			bcs !nextjoy+
			lda #LEFT
			sta inputResult
			rts
!nextjoy:
			lsr 					// check bit 3: joy right
			bcs !nextjoy+
			lda #RIGHT
			sta inputResult
			rts
!nextjoy:
			lsr 					// check bit 4: joy fire button
			bcs !nextjoy+
			lda #TURNCLOCK
			sta inputResult
			rts
!nextjoy:
			rts 					// those were all the relevant bits.
									// if we get to this, NOINPUT is still
									// stored in inputResult.

// ------------------------------------------------

inputDelayCounter:
			.byte INPUTDELAY		// if this reaches 0, the player input is read

previousKey:
			.byte DOWN				// previous key held

previousJoy:
			.byte 255 				// previous joy direction held

