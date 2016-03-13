
// sound main file.
// sets up irq and provides a way to play sounds

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

playsound:
        ldx #0
        ldy #0
        jsr music.init

// setup_music:
//         sei
//         lda #<irq1
//         sta $0314
//         lda #>irq1
//         sta $0315
//         asl $d019
//         lda #$7b
//         sta $dc0d
//         lda #$81
//         sta $d01a
//         lda #$1b
//         sta $d011
//         lda #$00
//         sta $d012
//         cli
//         rts

//---------------------------------------------------------
irq1:
//         asl $d019
// //        inc $d020
//         jsr music.play
// //        dec $d020
//         jmp $ea31
//         pla
//         tay
//         pla
//         tax
//         pla
//         rti


