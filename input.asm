

.const keyPressed = $cb 	// scnkey puts code of held key here.
.const INPUTDELAY = 10	 	// update delay between input checks. in frames


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

// ------------------------------------------------------

// this routine will scan keyboard first and then the joystick
// but only if there was no input from the keyboard
// it will leave the detected input in inputResult
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
// and accumulator as well

GetKeyInput:
	lda keyPressed 			// get held key code
	cmp previousKey 		// is it a different key than before?
	bne !skip+ 				// yes. dont use key delay

	// key is the same. update delay counter
	dec keyDelayCounter
	beq !skip+
	lda #NOINPUT
	sta inputResult
	rts
!skip:
	// restore key delay counter
	ldx #INPUTDELAY
	stx keyDelayCounter
	// save key code for next update
	sta previousKey

	cmp #NOKEY
	bne !skip+
	lda #NOINPUT 			// yes
	sta inputResult
	rts

!skip:
	cmp #DOWN
	bne !skip+

	// if we press down, the delay is shorter
	ldx #4 // INPUTDELAY / 2
	stx keyDelayCounter

!skip:
	sta inputResult 	// store input result

	rts

// -------------------------------------------------

// this subroutine checks for joystick input from port 2
// the input register is rotated and the carry bit is checked
// we have only one joystick button, so UP is used for rotate CCW
// "inputResult" will hold the registered input

.const CIAPRA = $dc00 				// joystick port 2 input register
.const NOJOY  = $ff 				// value for no joy input

GetJoyInput:
	lda CIAPRA 				// load the input byte
	cmp previousJoy 		// same as previous input?
	bne !skip+ 				// no, so skip delay

	// key is the same. update delay counter
	dec joyDelayCounter
	beq !skip+
	lda #NOINPUT
	sta inputResult
	rts

!skip:
	ldx #INPUTDELAY 		// reset the delay counter
	stx joyDelayCounter

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
	ldx #4					// force shorter delay
	stx joyDelayCounter
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
	bcs !exit+
	lda #TURNCLOCK
	sta inputResult
!exit:
	rts 					// those were all the relevant bits.
							// if we get to this, NOINPUT is still
							// stored in inputResult.

// ------------------------------------------------

// this byte holds the result of the input query
inputResult:
	.byte 0

keyDelayCounter:
	.byte INPUTDELAY

previousKey:
	.byte NOINPUT			// previous key held

joyDelayCounter:
	.byte INPUTDELAY

previousJoy:
	.byte 255 				// previous joy direction held

