
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
	// AddLevel will modify the drop delay
	ldx currentLevel
	beq !skip+
!loop:
	jsr AddLevel
	dex
	bne !loop-
!skip:
	ldy #SCREEN_PLAY
	jsr PRINT_SCREEN
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
	// and set the nextBlockID again for the next call
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
	// check to see if we are in pause mode
	lda pauseFlag
	beq !skip+
	jsr UpdatePause
	rts
!skip:
	// check if we are flashing made lines
	lda linesMade
	beq !skip+
	jsr UpdateLineFlash
	rts
!skip:
	// check input and react
	// we only allow one action per update.
	jsr GetInput
	ldx inputResult
	cpx #NOINPUT
	bne !nextControl+
	// no input, so forward game
	jmp DoLogic

!nextControl:
	cpx #RESET
	bne !nextControl+

	// to do : jmp ResetGame

!nextControl:
	cpx #PAUSE
	bne !nextControl+
	jmp SetPause

!nextControl:
	cpx #LEFT
	bne !nextControl+
	jsr BlockLeft
	lda #SND_MOVE_BLOCK
	jsr playsound
	rts
!nextControl:
	cpx #RIGHT
	bne !nextControl+
	jsr BlockRight
	lda #SND_MOVE_BLOCK
	jsr playsound
	rts
!nextControl:
	cpx #TURNCOUNTER
	bne !nextControl+
	jsr BlockRotateCCW
	lda #SND_ROTATE_BLOCK
	jsr playsound
	rts
!nextControl:
	cpx #TURNCLOCK
	bne !nextControl+
	jsr BlockRotateCW
	lda #SND_ROTATE_BLOCK
	jsr playsound
	rts
!nextControl:
	cpx #DOWN
	bne DoLogic
	jsr BlockDown
	lda #SND_MOVE_BLOCK
	jsr playsound
	rts

DoLogic:
	// ---- execute game logic

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

SetPause:
	lda #1
	sta pauseFlag
	lda #0
	sta sounddelayCounter
	lda #SND_PAUSE_ON
	jsr playsound

	// save the well data
	lda #1 					// set the erase flag
	sta playAreaErase
	jsr SavePlayArea

	// print the pause text
	ldy #WELL_PAUSE
	jsr PRINT_WELLDATA
	rts

// ----------------------------------------------

UpdatePause:
	jsr GetInput
	lda inputResult
	cmp #PAUSE
	bne !exit+
	lda #0
	sta pauseFlag
	sta sounddelayCounter
	lda #SND_PAUSE_OFF
	jsr playsound
	jsr RestorePlayArea
!exit:
	rts

// ----------------------------------------------

// -----------------------------------------------------

// current player level
currentLevel:
	.byte 0
// values for printing the current level. LSB first.
gameLevel:
	.byte 0,0

// this byte holds lines made after last
// level increase. threshold is declared on top of file.
levelLinesCounter:
	.byte 0

