
/*
----------------------------------
Tetris for 6502. (c) WdW 2015
----------------------------------
*/

.const plot = 	$fff0 			// routine to set cursor position
.const chrout = $ffd2 			// routine to print character

// game modes

.const MODE_ATTRACT = 1
.const MODE_SELECTLEVEL = 2
.const MODE_PLAY = 3
.const MODE_GAMEOVER = 4
.const MODE_ENTERNAME = 5

.const DEBUG = true


// ------------------------------------------------

.pc = $c000 "code"

			// initial setup

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

	        jsr ClearScreen 		// clear the screen and set colors

	        lda #153 				// print everything in light green ...
	        jsr $ffd2 				// from now on

			// initial setup done. select mode and call mode entry routine.

			lda #MODE_PLAY
			sta gameMode
			jsr StartPlayMode

// --------------------------------------------------

loopstart:
			lda $d012 			// get raster line position
			cmp #208			// wait for bottom of play area
			bne loopstart

.if (DEBUG) {
			lda #$01
			sta $d020
}
			// determine game mode and update accordingly

			lda gameMode
			cmp #MODE_ATTRACT
			bne !skip+
			jmp loopend
!skip:
			cmp #MODE_SELECTLEVEL
			bne !skip+
			jmp loopend
!skip:
			cmp #MODE_PLAY
			bne !skip+
			jsr UpdatePlayMode
			jmp loopend
!skip:
			cmp #MODE_GAMEOVER
			bne !skip+

			jmp loopend
!skip:
			cmp #MODE_ENTERNAME
			bne loopend
loopend:

.if (DEBUG) {
			lda #$0f
			sta $d020
}
			jmp loopstart

// ------------------------------------------

gameMode:
			.byte 0

// ------------------------------------------

			// import game source files

			.import source "play.asm"

			.import source "blocks.asm"
			.import source "input.asm"
			.import source "screens.asm"
			.import source "lines.asm"
			.import source "scores.asm"
			.import source "random.asm"


			// import game data files

			// import the game screen data
			// it is pure data, so no need to skip meta data while importing
			// data ends with a 0.

playscreen:
			.import binary "tetris_playscreen.raw"
			.byte 0

			// import the character set

.pc = $3800 "character data"

			.import binary "tetris_chars.raw" //, 24
