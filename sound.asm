
// sound main file.

// music definitions in sound file

.const SND_MOVE_BLOCK = 0
.const SND_ROTATE_BLOCK = 1
.const SND_DROP_BLOCK = 2
.const SND_LINE = 3
.const SND_TETRIS = 4
.const SND_PAUSE_ON = 5
.const SND_PAUSE_OFF = 6
.const SND_OPTION = 7
.const SND_MUSIC_TITLE = 9
.const SND_MUSIC_GAMEOVER = 8


// set accumulator before calling this
// it will not play when the sound delay counter is not 0
playsound:
		// dont play if counter is not 0
		ldx sounddelayCounter
		bne !skip+
		tax
		lda sounddelay,x
		sta sounddelayCounter
		txa
play:
		ldx #0
		ldy #0
        jsr music.init
!skip:
		rts

sounddelayCounter:
	.byte 0

sounddelay:
//		  0  1  2  3  4  5  6  7  8 9
	.byte 10,10,10,35,35,25,25,10,0,0

