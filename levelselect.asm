
.const FLASH_DELAY = 18

// ----------------------------------

StartLevelSelectMode:

			lda #$00
			sta currentLevel
			sta previousLevel
			sta levelDisplayFlag
			lda #1
			sta levelFlashDelay 		// and delay counter

			// print the screen

			lda #<selectScreenData
			sta dataSourceLo
			lda #>selectScreenData
			sta dataSourceHi
			lda #21
			sta dataWidth
			lda #21
			sta dataHeight
			lda #04
			sta dataDestinationHi
			lda #10
			sta dataDestinationLo
			jmp WriteScreenData

// --------------------------------------------------

UpdateLevelSelectMode:
			jsr GetInput 				// check for input
			ldx inputResult
			cpx #NOINPUT
			beq doLevelFlash

			// there is input

			cpx #TURNCLOCK 				// hit fire?
			bne !skip+
			jmp EndLevelSelectMode
!skip:
			cpx #DOWN 					// hit return?
			bne !skip+
			jmp EndLevelSelectMode
!skip:
			cpx #LEFT
			bne !skip+
			lda currentLevel
			beq doLevelFlash 			// we cant go lower, goto flashing
			sta previousLevel 			// store level
			dec currentLevel 			// and change level
			jmp inputDone
!skip:
			cpx #RIGHT
			bne doLevelFlash  			// no further relevant input, goto flashing
			lda currentLevel
			cmp #9
			beq doLevelFlash 			// we cannot go higher, goto flashing
			sta previousLevel
			inc currentLevel
inputDone:
			// level select has changed
			// make sure previous level is showing

			ldx previousLevel
			lda levelY,x
			pha
			lda levelX,x
			tay
			pla
			tax
			clc
			jsr PLOT

			lda previousLevel
			adc #$30  				// add #$30 to it to get a screencode
			jsr PRINT

			// make sure to show change asap

			lda #$01
			sta levelDisplayFlag
			sta levelFlashDelay

doLevelFlash:
			dec levelFlashDelay
			beq !skip+ 				// do flashing
			rts 					// nothing to do anymore
!skip:
			// we are going to flash the level indicator

			lda #FLASH_DELAY
			sta levelFlashDelay 	// reset the delay counter

			// set cursor to correct location

			ldx currentLevel
			lda levelY,x
			pha
			lda levelX,x
			tay
			pla
			tax
			clc
			jsr PLOT

			// flip the display flag

			lda levelDisplayFlag
			eor #%00000001
			sta levelDisplayFlag

			beq space 				// flag clear? then print space
			lda currentLevel 		// get the level value
			adc #$30 				// add #$30 to it to get a screencode
			jmp PRINT 				// print and exit
space:
			lda #$20
			jmp PRINT 				// and exit

// ----------------------------------

EndLevelSelectMode:
			lda #MODE_PLAY
			sta gameMode
			jsr StartPlayMode
			rts

// ----------------------------------

// x/y positions of level numbers on screen

//                0  1  2  3  4  5  6  7  8  9
levelX:
			.byte 16,18,20,22,24,16,18,20,22,24
levelY:
			.byte 07,07,07,07,07,09,09,09,09,09

levelFlashDelay:
			.byte 0 				// counter
levelDisplayFlag:
			.byte 0					// render number or space
previousLevel:
			.byte 0
