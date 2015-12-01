
// play mode


.const linesPerLevel = 10		// level advance threshold
.const delayChange = 4 			// game goes this much faster each level


// --------------------------------------------

// starts a new game
// level and drop delay have already been set!

StartPlayMode:

// -- temp!!
			lda #$00 				// temp!!!
			sta currentLevel 		// reset the player level

			lda #70 				// set the fall delay timer. this is for level 0
			sta fallDelay 			// each level, this is decreased with 2.
			sta fallDelayTimer 		// current timer for next block

// --
			jsr PrintPlayScreen

	        // set up player stats

	        jsr ResetScore 			// reset player score...
	        jsr ResetLinesMade		// and total lines made

	        // reset play stats

	        lda #$00 				// reset the lines counter...
	        sta levelLinesCounter 	// which is used to go up levels.

			// set the next block value
			// NewBlock will use this value for a new block
			// and set the next block value again for the next call

			jsr GetRandom
			sta nextBlockID 		// this will be printed as the next block
									// to fall
	        jsr NewBlock 			// get a new player block
			rts

// ----------------------------------------------

UpdatePlayMode:

			jsr UpdateRandom 		// update the random number

			// check if we are in 'flash mode'

			lda linesMade 			// did we make lines in previous update?
			beq continueplay		// no, continue with normal play

			// we are flashing the made lines

			jsr FlashLines
			lda totalFlashDelay 	// waited long enough?
			beq exitflash			// yes. remove the lines and update score
			rts 					// not yet. do this again on next update

exitflash:
			// flashing is all done

			jsr AddLinesTotal 		// add the made lines to total
			jsr PrintTotalLinesMade // and print these

			jsr AddLineScore		// add score made by lines
			jsr PrintScore 			// show the score

			jsr RemoveLines 		// then remove lines from screen

			lda levelLinesCounter 	// get lines made so far in this level
			clc
			adc linesMade 			// add the made lines
			sta levelLinesCounter

			lda #$00				// reset the lines made
			sta linesMade

			// go up a level?

			lda levelLinesCounter	// get lines made so far at this level
			cmp #linesPerLevel 		// did we make enough to go up a level?
			bcc !skip+ 				// no: If the C flag is 0, then A (unsigned) < NUM (unsigned)
									// and BCC will branch
			jsr AddLevel 			// go up 1 level
!skip:
			// add a new block to play with

			jsr NewBlock 			// create a new block

continueplay:

			// do game logic

			jsr DropBlock 			// move the block down if delay has passed
			cmp #$02 				// Acc=2 means that a new block is needed
			bne !skip+

			// a new block is needed so we might have made line(s)

			jsr CheckLines 			// check if line(s) has been made.
			lda linesMade 			// get lines made value
			beq nolines				// no lines made, so continue game

			rts 					// do not create a new block just yet.
									// loop will flash the lines and THEN create a new block

nolines:
			// we made no lines. so continue

			jsr NewBlock 			// select a new block
			beq !skip+				// Acc=0 means the new block fits, so continue

			// new block didn't fit, so game over!

			jmp EndPlayMode
!skip:

			jsr GetKeyInput 		// get player input from keyboard
			ldx inputResult 		// what was the input?

			// first check generic keys

			cpx #RESET
			bne !skip+

			// reset the game
			brk
			rts
!skip:
			cpx #PAUSE
			bne !skip+

			jsr TogglePause

			lda pauseFlag 			// get pause flag
			beq !skip+ 				// continue if not paused
			rts 					// paused, we're done
!skip:
			cpx #NOINPUT 			// other input?
			bne !skip+				// yes. process it

			// no other input from keys, check joystick

			jsr GetJoyInput
			ldx inputResult
			cpx #NOINPUT 			// valid input?
			bne !skip+				// yes, process it
			rts 					// no input from joy either. end!
!skip:
			// only block control movement input left, so check those

			cpx #LEFT
			bne !skip+
			jmp BlockLeft
!skip:
  			cpx #RIGHT
  			bne !skip+
  			jmp BlockRight
!skip:
  			cpx #TURNCOUNTER
  			bne !skip+
  			jmp BlockRotateCCW
!skip:
 			cpx #TURNCLOCK
 			bne !skip+
 			jmp BlockRotateCW
!skip:
			cpx #DOWN
			bne !skip+
			jmp BlockDown
!skip:
			rts



// ------------------------------------------------

EndPlayMode:
			lda #MODE_GAMEOVER
			sta gameMode
			jsr StartGameOverMode
			rts

// -------------------------------------------------

// up the player level

AddLevel:
			inc currentLevel		// go up a level

			// update the level values
			// so we can print it later

			sed 					// set decimal mode
			clc 					// clear the carry bit
			lda gameLevel+0  		// get current total lines value
			adc #$01   				// go up a level
			sta gameLevel+0 		// store it.

			lda gameLevel+1 		// and the 2nd byte.
			adc #$00 				// always 0, we can add 4 lines max.
			sta gameLevel+1
			cld 					// clear decimal mode

			jsr PrintLevel 			// print it

			// reset the 'lines made this level' counter

			lda levelLinesCounter
			sec
			sbc #linesPerLevel		// restart count ...
			sta levelLinesCounter 	// ... so we can restart this check.

			// decrease the game delay

			lda fallDelay 			// get the current delay
			sec
			sbc #delayChange		// make delay shorter
			bcs !skip+ 				// is delay lower than 0?
			lda #delayChange 		// yes: set shortest delay.
!skip:
			sta fallDelay 			// store the new delay value
			sta fallDelayTimer 		// reset the current delay counter
			rts


// --------------------------------------------------

TogglePause:
			lda pauseFlag 			// get the current pause flag
			eor #%00000001 			// flip between 0 and 1
			sta pauseFlag 			// store it

			cmp #$01 				// pause mode?
			beq !skip+ 				// yes
			jmp RestorePlayArea 	// no, restore the screen
!skip:
			// game is paused. so clear the screen

			lda #$01 				// set the erase flag
			sta playAreaErase 		// so area gets cleared as well
			jsr SavePlayArea 		// save and clear the play area
			jmp PrintPaused

// --------------------------------------------------


PrintPlayScreen:

			// set start of data

			lda #<playscreen
			sta dataSourceLo
			lda #>playscreen
			sta dataSourceHi

			// set data dimensions

			lda #21
			sta dataWidth
			lda #21
			sta dataHeight

			// set start of area to print to

			lda #04
			sta dataDestinationHi
			lda #10
			sta dataDestinationLo

			jmp WriteScreenData

// -----------------------------------------------------

currentLevel:
			.byte 0 					// current player level

gameLevel:
			.byte 0,0 					// values for printing the current level. LSB first.

levelLinesCounter:
			.byte 0 					// this byte holds lines made after last
										// level increase. threshold is declared on top of file.
