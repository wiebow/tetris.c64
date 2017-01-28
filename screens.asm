// code concerning game screens

// well dimensions
.const wellWidth = 10
.const wellHeight = 20

// screen dimensions
.const screenWidth = 21 		// columns
.const screenHeight = 21		// rows

// screen id
.const SCREEN_TITLE = 0
.const SCREEN_CREDITS = 1
.const SCREEN_KEYS = 2
.const SCREEN_LEVELSELECT = 3
.const SCREEN_PLAY = 4

// well data id
.const WELL_PAUSE = 0
.const WELL_GAMEOVER = 1
.const WELL_TEMP = 2

// -----------------------------------------

// set Y register with the index of the screen you want to print
PRINT_SCREEN:
	// get source address
	lda screenDataLow,y
	sta readScreen+1
	lda screenDataHigh,y
	sta readScreen+2
	// reset screen address
	lda #10
	sta writeScreen+1
	lda #04
	sta writeScreen+2
	// set the data counters
	lda #screenWidth
	sta dataWidth
	lda #screenHeight
	sta dataHeight

	ldx #0 					// reset read index
	ldy #0 					// reset write index
readScreen:
	lda $ffff,x 			// get data
writeScreen:
	sta $ffff,y 			// store at destination
	inx 					// update read counter
	bne !skip+ 				// roll over?
	inc readScreen+2  		// yes. go to next memory page
!skip:
	iny 					// update row counter
	cpy dataWidth			// this row done?
	bne readScreen 	 			// no, continue
	ldy #$00 				// reset the row counter
	lda writeScreen+1 			// get lo byte of current screen position
	clc
	adc #40 				// add 40 to that, goto next row
	bcc !skip+ 				// overflow?
	inc writeScreen+2  			// then go to next memory page
!skip:
	sta writeScreen+1 			// store lo byte

	dec dataHeight 			// update counter
	bne readScreen 				// not all rows done yet
	rts

// -----------------------------------------

// set Y register with the index of the well text you want to print
PRINT_WELLDATA:
	// get source address
	lda wellDataLow,y
	sta wellRead+1
	lda wellDataHigh,y
	sta wellRead+2
	// reset screen address
	lda #12
	sta wellWrite+1
	lda #04
	sta wellWrite+2
	// set the data counters
	lda #wellWidth
	sta dataWidth
	lda #wellHeight
	sta dataHeight

	ldx #0 					// reset read index
	ldy #0 					// reset write index
wellRead:
	lda $ffff,x 			// get data
wellWrite:
	sta $ffff,y 			// store at destination

	inx 					// update read counter
	bne !skip+ 				// roll over?
	inc wellRead+2  		// yes. go to next memory page
!skip:
	iny 					// update write counter
	cpy dataWidth			// this row done?
	bne wellRead 	 		// no, continue
	ldy #$00 				// reset the row counter
	lda wellWrite+1 		// get lo byte of current screen position
	clc
	adc #40 				// add 40 to that, goto next row
	bcc !skip+ 				// overflow?
	inc wellWrite+2 		// then go to next memory page
!skip:
	sta wellWrite+1 		// store lo byte

	dec dataHeight 			// update counter
//	lda dataHeight
	bne wellRead 			// not all rows done yet
	rts

// -----------------------------------------

// subroutine to clear the screen and color ram
// also detroys sprite pointers.
ClearScreen:
	lda screenColor
	sta $d020 			// set border color
	sta $d021 			// set screen color
	ldx #$00 			// reset offset register
!loop:
	lda #$20			// #$20 is space
	sta $0400,x 		// store in screen ram
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx 				// increment counter
	bne !loop- 			// continue?
	jsr SET_CHAR_COLOR
	rts

SET_CHAR_COLOR:
	ldx #0
	lda charColor
!loop:
	sta $d800,x 		// store in color ram
	sta $d900,x
	sta $da00,x
	sta $db00,x
	inx 				// increment counter
	bne !loop- 			// continue?

	ldx charColor
	lda chrColorCodes,x // get correct chr$ code
	jsr PRINT
	rts


// ---------------------------------------------

// this subroutine saves the content of the total play area
// into a buffer.
// If playAreaErase is set to 1 then the area is cleared as well

SavePlayArea:
	// point to the beginning of the first row

	ldx #12 				// x position is set to 12
	ldy #0 					// y position to 0
	jsr SetScreenPointer 	// set screen memory pointer

	ldx #$00				// reset buffer pointer
	stx currentRow 			// reset the row counter
!loop:
	lda (screenPointer),y 	// get screen data
	sta playAreaBuffer,x 	// store it in the buffer
	lda playAreaErase 		// erase it as well?
	beq !skip+ 				// no
	lda #$20 				// write a space
	sta (screenPointer),y
!skip:
	inx 					// update buffer pointer
	iny  					// update row character counter
	cpy #10 				// stored whole line?
	bne !loop- 				// no, keep reading

	inc currentRow 			// go to the next row
	lda currentRow 			// what value is it now?
	cmp #20 				// all 20 rows checked?
	beq !skip+	 			// yes, exit
	jsr DownOneRow 			// no, go one row down
	ldy #$00 				// reset row character counter
	jmp !loop-	 			// do next row
!skip:
	rts

// ---------------------------------------------

// restores the play area by reading the buffer
RestorePlayArea:
	ldx #12
	ldy #0
	jsr SetScreenPointer

	ldx #$00 				// reset buffer counter
	stx currentRow 			// and row index
!loop:
	lda playAreaBuffer,x 	// get buffer data
	sta (screenPointer),y 	// store on screen
!skip:
	inx 					// update buffer pointer
	iny  					// update row character counter
	cpy #10 				// done whole line?
	bne !loop- 				// no

	inc currentRow 			// go to the next row
	lda currentRow 			// what value is it now?
	cmp #20 				// all 20 rows checked?
	beq !skip+	 			// yes, exit
	jsr DownOneRow 			// no, go one row down
	ldy #$00 				// reset row character counter
	jmp !loop-	 			// do next row
!skip:
	rts

// ------------------------------------------------

// screens mapped to their memory positions
screenDataLow:
	.byte <titleScreenData, <creditsScreenData, <keysScreenData
	.byte <selectScreenData, <playscreen
screenDataHigh:
	.byte >titleScreenData, >creditsScreenData, >keysScreenData
	.byte >selectScreenData, >playscreen

// well text mapped to memory locations
wellDataLow:
	.byte <pauseText, <gameoverText
wellDataHigh:
	.byte >pauseText, >gameoverText

// where is the screen data coming from?
dataSourceHi:
			.byte 0
dataSourceLo:
			.byte 0

// what is the data size?
// also used as counters!
dataWidth:
			.byte 0
dataHeight:
			.byte 0

// where does it need to go?
// this is a screen memory location
dataDestinationHi:
			.byte 0
dataDestinationLo:
			.byte 0


// -----------------------------------------------

// chr$ codes needed for cursor when the character color is changed
chrColorCodes:
//        0	  1	2  3   4   5  6  7   8   9   10  11  12  13  14  15
	.byte 144,5,28,159,156,30,31,158,129,149,150,151,152,153,154,155

playAreaErase:
		.byte 0

playAreaBuffer:
		.fill wellWidth * wellHeight, 0
