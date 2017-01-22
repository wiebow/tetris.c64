
/*
------------------------------------
Tetris for 6502. (c) WdW 2015/16/17
------------------------------------
*/

#import "kernal.asm"

// get music data
.var music = LoadSid("audio.sid")

// game modes
.const MODE_ATTRACT = 1
.const MODE_SELECTLEVEL = 2
.const MODE_PLAY = 3
.const MODE_GAMEOVER = 4
.const MODE_ENTERNAME = 5

// display debug info or not
.const DEBUG = true

:BasicUpstart2(START)

// ------------------------------------------------

.pc = $c000 "maincode"

// import game source files

.import source "sound.asm"
.import source "blocks.asm"
.import source "input.asm"
.import source "screens.asm"
.import source "lines.asm"
.import source "scores.asm"
.import source "random.asm"
.import source "play.asm"
.import source "hi-scores.asm"
.import source "entername.asm"
.import source "gameover.asm"
.import source "attract.asm"
.import source "levelselect.asm"

START:
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

    // load the hiscores

    // ..

	// initial setup done
	// select mode and call mode entry routine
	lda #MODE_ATTRACT
	sta gameMode
	jsr StartAttractMode

// --------------------------------------------------

loopstart:

.if (DEBUG) {
	lda #11
	sta $d020
	sta $d021
}

	lda $d012 			// get raster line position
	cmp #208			// wait for bottom of play area
	bne loopstart

.if (DEBUG) {
	lda #$0f
	sta $d020
	sta $d021
}
	// determine game mode and update accordingly
	lda gameMode
	cmp #MODE_ATTRACT
	bne !nextmode+
	jsr UpdateAttractMode
	jmp loopend
!nextmode:
	cmp #MODE_SELECTLEVEL
	bne !nextmode+
	jsr UpdateLevelSelectMode
	jmp loopend
!nextmode:
	cmp #MODE_PLAY
	bne !nextmode+
	jsr UpdatePlayMode
	jmp loopend
!nextmode:
	cmp #MODE_GAMEOVER
	bne !nextmode+
	jsr UpdateGameOverMode
	jmp loopend
!nextmode:
	cmp #MODE_ENTERNAME
	bne loopend
	jsr UpdateEnterNameMode
loopend:
	jsr music.play
	jmp loopstart

// ------------------------------------------

gameMode:
	.byte 0
pauseFlag:
	.byte 0 				// value is 1 when game is paused

// ------------------------------------------
// import the game screen data files
// it is pure data, so no need to skip meta data
// from char pad while importing

.pc = $4000 "screen data"

playscreen:
.import binary "tetris_playscreen.raw"

gameoverText:
.import binary "tetris_gameover.raw"

pauseText:
.import binary "tetris_paused.raw"

titleScreenData:
.import binary "tetris_titlescreen.raw"

keysScreenData:
.import binary "tetris_keys.raw"

creditsScreenData:
.import binary "tetris_credits.raw"

selectScreenData:
.import binary "tetris_select_and_high.raw"

// character set
.pc = $3800 "character set"
.import binary "tetris_chars2.raw"

// fill memory with music data
// music.location = $1000
.pc = music.location "Music"
.fill music.size, music.getData(i)
