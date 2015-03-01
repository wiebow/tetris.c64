/*
----------------------------------
Tetris for 6502. (c) WdW 2015
----------------------------------
*/

			.pc = $c000 "code"

			jsr SetUp
			jsr StartGame
mainloop:
			// timing
			// wait for the raster to be at the bottom of the screen
			lda $d012
			cmp #$d0 			// 208
			bne mainloop

			inc $d020 			// show start of code

			jsr GetKeyInput
			jsr DropBlock
			cmp #$02 			// new block needed??
			bne !skip+
			jsr NewBlock 		// select a new block
			beq !skip+
			brk 				// newblock returned 1. game over!
!skip:
			dec $d020 			// show end of code

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
			// this is controlled by bits 1-3

        	lda $d018 				// get chip memory control register
        							// 1110 = 14, so 14*1024=14336 ($3800 in hex)
    	    ora #%00001110          // use char set at $3800
	        sta $d018 				// set register

	        // use the SID chip to generate random numbers.
	        // we use this for block selection.
	        // after setting this, $d41b will contain a number from 0-255
	        lda #$ff 				// maximum frequency
	        sta $d40e 				// set voice 3 frequency control low byte
	        sta $d40f 				// and hi byte
	        lda #$80 				// use noise waveform
	        sta $d412 				// set voice 3 control register to waveform

	        rts


// starts a new game
// level and drop delay have already been set
// and score etc have been reset as well.
StartGame:
	        jsr ClearScreen 		// clear the screen and set colors

	        ldx #<playscreen 		// set hi byte ..
	        ldy #>playscreen 		// and lo byte of screen data ..
	        jsr PrintScreen 		// and print it.

	        jsr NewBlock 			// get a new player block

			lda #70 				// set the fall delay timer
			sta fallDelay
			sta fallDelayTimer
			rts 


// ------------------------------------------

			// import game source files

			.import source "blocks.asm"
			.import source "input.asm"
			.import source "screens.asm"

			// import the game screen data
			// it is pure data, so no need to skip metadata while importing
			// data ends with a 0.
playscreen:
			.import binary "tetris_playscreen.raw"
			.byte 0



			// import the character set
			// skip the 1st 24 bytes as they are metadata.

			.pc = $3800 "character data"
			.import binary "tetris_chars.raw" //, 24
