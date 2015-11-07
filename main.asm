
/*
----------------------------------
Tetris for 6502. (c) WdW 2015
----------------------------------
*/
			.const plot = 	$fff0 			// kernel routine to set cursor position
			.const chrout = $ffd2 			// routine to print character
			.const linesPerLevel = 10		// level advance threshold
			.const delayChange = 4 			// game goes this much faster each level.

			.pc = $c000 "code"

			jsr SetUp
			jsr StartGame
mainloop:


waitraster:
			lda $d012 				// get raster line position
			cmp #208				// wait for bottom of screen
			bne waitraster

			lda #$01				// debug
			sta $d020

			jsr UpdateRandom 		// update the random seed

			lda linesMade 			// did we make lines?
			beq continueloop		// no, continue with game

			jsr FlashLines 			// yes, show the lines made and flash them
			lda totalFlashDelay 	// need to flash more?
			bne mainloop 			// yes, so go back to beginning of loop

			// flashing is all done

			jsr AddLinesTotal 		// add the made lines to total
			jsr PrintTotalLinesMade // and print these.

			jsr AddLineScore		// add score made by lines
			jsr PrintScore 			// show the score

			jsr RemoveLines 		// then remove lines from screen

			lda levelLinesCounter 	// get lines made so far in this level
			clc
			adc linesMade 			// add the made lines
			sta levelLinesCounter

			lda #$00				// clear the lines made counter
			sta linesMade

			// go up a level?

			lda levelLinesCounter	// get lines made so far in this level
			cmp #linesPerLevel 		// did we make enough to go up a level?
			bcc nolevelinc 			// no: If the C flag is 0, then A (unsigned) < NUM (unsigned)
									// and BCC will branch

			jsr AddLevel 			// go up 1 level

nolevelinc:
			// lines stuff is all done.

			jsr NewBlock 		// create a new block
			jmp mainloop 		// and continue

continueloop:

			// we made no line, so do input
			// and check for lines made

			jsr GetKeyInput 	// get player input
			jsr DropBlock 		// move the block down if delay has passed
			cmp #$02 			// a 2 means that a new block is needed
			bne endloop 		// no. end the loop

			// a new block is needed so we might have made line(s)

			jsr CheckLines 		// check if line(s) has been made.
			lda linesMade 		// get lines made value
			bne endloop 		// yes. don't create a new block just yet, as the next
								// loop will flash the lines and THEN create a new block

			// we made no lines. so continue

			jsr NewBlock 		// select a new block
			beq endloop			// a value of 0 means it fits, so continue

			// game over!!!

			brk 				// NewBlock returned 1. game over!
endloop:
			lda #$0f 			// debug
			sta $d020

			jmp mainloop

// ------------------------------------------------


// main setup
// this is called when the program starts
SetUp:
			// set the used video bank to bank 0 ($0000-$3fff)
			// bits 0-1 control bank selection

			lda $dd00	 			// get data port register A
			ora #$00000011			// select bank 0
			sta $dd00 				// and set register

			// select the memory in bank 0 where our character set data resides
			// in the selected video bank. this is controlled by bits 1-3

        	lda $d018 				// get chip memory control register
        							// 1110 = 14, so 14*1024=14336 ($3800 in hex)
    	    ora #%00001110          // use char set at $3800
	        sta $d018 				// set register

	        jsr SetupRandom 		// set the rnd seed

	        lda #153 				// print everything in light green ...
	        jsr $ffd2 				// from now on

	        rts


// starts a new game
// level and drop delay have already been set
StartGame:
	        jsr ClearScreen 		// clear the screen and set colors

	        ldx #<playscreen 		// set hi byte ..
	        ldy #>playscreen 		// and lo byte of screen data ..
	        jsr PrintScreen 		// and print it.

	        jsr ResetScore 			// reset player score,
	        jsr ResetLinesMade		// and total lines made

	        lda #$00 				// reset the lines counter ...
	        sta levelLinesCounter 	// which is used to go up levels.

	        sta currentLevel 		// and reset the player level

			lda #70 				// set the fall delay timer. this is for level 0
			sta fallDelay 			// each level, this is decreased with 2.
			sta fallDelayTimer 		// current timer for next block

			// set the next block value
			// NewBlock will use this value for a new block
			// and set the next block value again for the next call

			jsr GetRandom
			sta nextBlockID 		// this will be printed as the next block
									// to fall
	        jsr NewBlock 			// get a new player block
			rts

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



//prints the current play level on the screen
PrintLevel:
			clc 					// position cursor at 26,8
			ldx #8
			ldy #26
			jsr plot

			// do 1st byte.
			// only do the first 4 bits of this byte

			lda gameLevel+1
			and #%00001111 			// get rid of leftmost bits
			clc
			adc #$30 				// create a screen code
			jsr chrout 				// print it

			// do 2nd byte

			lda gameLevel+0
			pha 					// push to stack
			lsr 					// shift 4 times to right
			lsr
			lsr
			lsr
			clc
			adc #$30 				// add #$30 to it to get a screencode
			jsr chrout 				// print it

			pla 					// restore value
			and #%00001111 			// get rid of leftmost bits
			clc
			adc #$30 				// create a screen code
			jsr chrout 				// print it
			rts

// ------------------------------------------

			// import game source files

			.import source "blocks.asm"
			.import source "input.asm"
			.import source "screens.asm"
			.import source "lines.asm"
			.import source "scores.asm"
			.import source "random.asm"

// ------------------------------------------

currentLevel:
			.byte 0 					// current player level

gameLevel:
			.byte 0,0 					// values for printing the current level. LSB first.




levelLinesCounter:
			.byte 0 					// this byte holds lines made after last
										// level increase. threshold is declared on top of file.

			// import the game screen data
			// it is pure data, so no need to skip meta data while importing
			// data ends with a 0.

playscreen:
			.import binary "tetris_playscreen.raw"
			.byte 0



			// import the character set
			// skip the 1st 24 bytes as they are metadata.

			.pc = $3800 "character data"
			.import binary "tetris_chars.raw" //, 24
