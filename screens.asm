

// code concerning game screens

// game screen dimensions
.const screenWidth = 21
.const screenHeight = 21


// ----------------------------------------------

// subroutine to clear the screen and color ram
// also detroys sprite pointers.
ClearScreen:
			lda #11 			// dark grey
			sta $d020 			// set border color
			sta $d021 			// set screen color
			ldx #$00 			// reset offset register
!loop:
			lda #$20			// #$20 is space
			sta $0400,x 		// store in screen ram
			sta $0500,x
			sta $0600,x
			sta $0700,x
			lda #13				// light green (screen color code)
			sta $d800,x 		// store in color ram
			sta $d900,x
			sta $da00,x
			sta $db00,x
			inx 				// increment counter
			bne !loop- 			// continue?

	        lda #153 			// print everything in light green ...
	        jsr $ffd2 			// from now on (ascii code)

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

// this routine will copy data to another memory location
// in this case the screen memory
// source and dimensions must be set before calling this

WriteScreenData:
			// get the source address

			lda dataSourceLo
			sta read+1
			lda dataSourceHi
			sta read+2

			// get the destination address

			lda dataDestinationLo
			sta write+1
			lda dataDestinationHi
			sta write+2

			ldx #$00 				// reset read index
			ldy #$00 				// reset write index

			// start copy
read:
			lda $1000,x 			// get data
write:
			sta $1000,y 			// store at destination
			inx 					// update read counter
			bne !skip+ 				// roll over?
			inc read+2  			// yes. go to next memory page
!skip:
			iny 					// update row counter
			cpy dataWidth			// this row done?
			bne read 	 			// no, continue
			ldy #$00 				// reset the row counter
			lda write+1 			// get lo byte of current screen position
			clc
			adc #40 				// add 40 to that, goto next row
			bcc !skip+ 				// overflow?
			inc write+2  			// then go to next memory page
!skip:
			sta write+1 			// store lo byte

			dec dataHeight 			// update counter
			lda dataHeight
			bne read 				// not all rows done yet
			rts

// where is the data coming from?
dataSourceHi:
			.byte 0
dataSourceLo:
			.byte 0

// what is the data size?
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

playAreaErase:
		.byte 0

playAreaBuffer:
		.fill 10*20, 0
