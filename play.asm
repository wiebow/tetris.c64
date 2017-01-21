
// play mode

.const linesPerLevel = 10		// level advance threshold
.const delayChange = 4 			// game goes this much faster each level
.const DEFAULT_DROP_DELAY = 70

// --------------------------------------------

// starts a new game
// level and drop delay have already been set!

StartPlayMode:

			lda #0
			sta sounddelayCounter

			lda #SND_TETRIS
			jsr playsound

			// reset drop delay

			lda #DEFAULT_DROP_DELAY
			sta fallDelay
			sta fallDelayTimer

			// add the levels
			// currentLevel has been set by levelselect.asm

			ldx currentLevel
			beq !skip+
!loop:
			jsr AddLevel
			dex
			bne !loop-
!skip:
			jsr PrintPlayScreen
			jsr PrintLevel

	        // set up player stats

	        jsr ResetScore 			// reset player score...
	        jsr ResetLinesMade		// and total lines made

	        // reset play stats

	        lda #$00 				// reset the lines counter...
	        sta levelLinesCounter 	// which is used to go up levels.
	        sta linesMade 			// and no lines made

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
			jsr UpdateRandom

			lda sounddelayCounter
			beq !skip+
			dec sounddelayCounter
!skip:
			// check if we are flashing made lines
			lda linesMade
			beq !skip+
			jmp UpdateLineFlash
!skip:
			jsr GetInput
			ldx inputResult
			cpx #NOINPUT
			beq doLogic 			// no input, so continue
			cpx #PAUSE 				// pressed p?
			bne !skip+
			jmp TogglePause 		// toggle and abort rest of update
!skip:
			cpx #RESET
			bne !skip+
			// to do : jmp ResetGame
!skip:
			lda pauseFlag 			// are we in pause mode?
			beq doInput 			// no, so continue
			rts 					// yes paused, abort rest of update

doInput:
			// cpx #NOINPUT
			// bne doControls		 	// if there was input, process it.
			// jsr GetJoyInput 		// if not, check joystick input

			// ldx inputResult
			// cpx #NOINPUT 			// if there was no input ...
			// beq doLogic 			// perform game logic and skip control process
doControls:
			cpx #LEFT
			bne !skipControl+
			jsr BlockLeft

			lda #SND_MOVE_BLOCK
			jsr playsound

			jmp doLogic
!skipControl:
  			cpx #RIGHT
  			bne !skipControl+
  			jsr BlockRight

			lda #SND_MOVE_BLOCK
			jsr playsound

  			jmp doLogic
!skipControl:
  			cpx #TURNCOUNTER
  			bne !skipControl+
  			jsr BlockRotateCCW

			lda #SND_ROTATE_BLOCK
			jsr playsound

  			jmp doLogic
!skipControl:
 			cpx #TURNCLOCK
 			bne !skipControl+
 			jsr BlockRotateCW

			lda #SND_ROTATE_BLOCK
			jsr playsound

 			jmp doLogic
!skipControl:
			cpx #DOWN
			bne doLogic
			jsr BlockDown

			// lda #SND_MOVE_BLOCK
			// jsr playsound

doLogic:
			jsr DropBlock 			// move play block down if delay has passed
			cmp #$02 				// Acc=2 means that a new block is needed
			beq !skip+
			rts 					// block still in play, no line check needed
!skip:
			lda #SND_DROP_BLOCK
			jsr playsound

			jsr CheckLines 			// block has dropped, so check
			lda linesMade 			// are lines made?
			beq !skip+ 				// no, place new block
			rts 					// yes. do not create a new block now
									// UpdateLineFlash will do that later on
!skip:
			jsr NewBlock 			// Acc=0 means the new block fits
			beq !skip+ 				// fits. so exit
			jmp EndPlayMode 		// no fit!
!skip:
			rts

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

UpdateLineFlash:
			jsr FlashLines
			lda totalFlashDelay 	// flashed long enough?
			// sta $0400
			beq exitflash			// yes. remove the lines and update score
			rts 					// not yet. do this again on next update

exitflash:
			// flashing is all done

			jsr AddLinesTotal 		// add the made lines to total
			jsr PrintTotalLinesMade // and print these

			jsr AddLineValue		// add score made by lines
			jsr PrintScore 			// show the score

			jsr RemoveLines 		// then remove lines from screen

			lda levelLinesCounter 	// get lines made so far in this level
			clc
			adc linesMade 			// add the made lines
			sta levelLinesCounter

			lda #SND_LINE
			ldx linesMade 			// determine sound to play
			cpx #4
			bne !skip+
			lda #SND_TETRIS
!skip:
			jsr playsound 			// play it

			lda #$00				// reset the lines made
			sta linesMade

			// go up a level?

			lda levelLinesCounter	// get lines made so far at this level
			cmp #linesPerLevel 		// did we make enough to go up a level?
			bcc !skip+ 				// no: If the C flag is 0, then A (unsigned) < NUM (unsigned)
									// and BCC will branch
			jsr AddLevel 			// go up 1 level
			jsr PrintLevel 			// print it
!skip:
			// add a new block to play with

			jsr NewBlock 			// create a new block
			beq !skip+ 				// fits. so exit
			jmp EndPlayMode 		// no fit!
!skip:
			rts

// --------------------------------------------------

TogglePause:
			lda pauseFlag 			// get the current pause flag
			eor #%00000001 			// flip between 0 and 1
			sta pauseFlag 			// store it

			cmp #$01 				// pause mode?
			beq !skip+ 				// yes

			lda #SND_PAUSE_OFF
			jsr playsound

			jmp RestorePlayArea 	// no, restore the screen
!skip:
			// game is paused. so clear the screen

			lda #$01 				// set the erase flag
			sta playAreaErase 		// so area gets cleared as well
			jsr SavePlayArea 		// save and clear the play area

			lda #SND_PAUSE_ON
			jsr playsound

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

PrintPaused:
			lda #<pauseText
			sta dataSourceLo
			lda #>pauseText
			sta dataSourceHi
			lda #10
			sta dataWidth
			lda #20
			sta dataHeight
			lda #04
			sta dataDestinationHi
			lda #12
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
