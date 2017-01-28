
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


SETUP_MUSIC_IRQ:
	sei
//	lda #$35
//	sta $01
	lda #<irq1
	sta $0314 //fffe
	lda #>irq1
	sta $0315 //ffff
	lda #$1b
	sta $d011
	lda #$80
	sta $d012
	lda #$81
	sta $d01a
	lda #$7f
	sta $dc0d
	sta $dd0d

	lda $dc0d
	lda $dd0d
	lda #$ff
	sta $d019

//	lda #$37
//	sta $01


	cli
	rts //jmp *
//----------------------------------------------------------
irq1:
	// pha
	// txa
	// pha
	// tya
	// pha
	lda #$ff
	sta	$d019

.if (DEBUG) {
	lda #1
	sta $d020
}
	jsr music.play

.if (DEBUG) {
	lda screenColor
	sta $d020
}
	// pla
	// tay
	// pla
	// tax
	// pla
	jmp $ea31
	rti



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
        jsr music.play
!skip:
		rts

sounddelayCounter:
	.byte 0

sounddelay:
//		  0  1  2  3  4  5  6  7  8 9
	.byte 10,10,10,35,35,25,25,10,0,0

