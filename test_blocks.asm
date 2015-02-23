/*

----------------------------------
Tetris for 6502. (c) WdW 2015
----------------------------------
*/

			.pc = $c000

			// set the used video bank to bank 0 ($0000-$3fff)
			// bits 0-1 control bank selection

			lda $dd00	 			// get data port register A
			ora #$00000011			// select bank 0 
			sta $dd00 				// and set register

			// select the memory part in bank 0 where our character set data resides
			// this is controlled by bits 1-3

        	lda $d018 				// get chip memory control register
        							// 1110 = 14, so 14*1024=14336 ($3800 in hex)
    	    ora #%00001110          // use char set at $3800
	        sta $d018 				// set register

	        jsr clearScreen
	        ldx #<playscreen
	        ldy #>playscreen
	        jsr printScreen

			// print and animation test

			lda #14
			sta blockXposition
			lda #00
			sta blockYposition
			jsr SetScreenPosition

			lda #$01
			jsr SelectBlock
			jsr PrintBlock

			// test loop for input
loop:
			jsr GetKeyInput
			jmp loop



// subroutine to clear the screen and color ram
// also detroys sprite pointers.
clearScreen:
			lda #11 			// dark grey
			sta $d020 			// set border color
			sta $d021 			// set screen color
			ldx #$00
!loop:		
			lda #$20			// space
			sta $0400,x 		// store in screen ram
			sta $0500,x
			sta $0600,x
			sta $0700,x
			lda #13 			// light green
			sta $d800,x 		// store in color ram
			sta $d900,x
			sta $da00,x
			sta $db00,x
			inx
			bne !loop-
			rts


// this subroutine prints a screen.
// set x and y to the lo and hi bytes of the data to be read before
// calling this.
printScreen:
			.const screenWidth = 21
			.const screenHeight = 20

			// first, set pointer to the start of data
			stx readdata+1			// store in lda instruction
			sty readdata+2 			// and store

			// reset screen memory pointer
			lda #10 				// start at column # 10
			sta writedata+1
			lda #$04
			sta writedata+2

			ldx #$00
			ldy #$00
readdata:
			lda $1010,x 			// get screen data
			bne writedata			// 0 marks end of data
			rts 					// done!
writedata:
			sta $0410,y 			// store in screen memory
			inx 					// update data read counter
			bne !skip+ 				// no roll over?
			inc readdata+2 			// go to next memory page
!skip:
			iny 					// update counter for this row
			cpy #screenWidth		// this row done?
			bne readdata 			// no, continue
			ldy #$00 				// reset the row counter
			lda writedata+1 		// get lo byte of current screen position
			clc
			adc #40 				// add 40 to that
			bcc !skip+ 				// overflow?
			inc writedata+2 		// then go to next memory page
!skip:
			sta writedata+1 		// store lo byte
			jmp readdata 			// and continue


// -----------------------------------------------






// -----------------------------------------------



			// import game source files

			.import source "blocks.asm"
			.import source "input.asm"


			// import the game screen data
			// it is pure data, so no need to skip metadata while importing
playscreen:
			.import binary "tetris_playscreen.raw"
			.byte 0 			// mark the end of the screen data

			// import the character set
			// skip the 1st 24 bytes as they are metadata.

			.pc = $3800
			.import binary "tetris.raw", 24





