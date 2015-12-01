

// attrack mode steps

.const STEP_TITLE = 0
.const STEP_CREDITS = 1
.const STEP_CONTROLS = 2
.const ATTRACT_DELAY = 50 * 5

attractStep:
			.byte 0

attractDelay:
			.byte 0

// -----------------------------------------

StartAttractMode:
			lda #ATTRACT_DELAY
			sta attractDelay
			lda #STEP_TITLE
			sta attractStep

			// set the screen size
			// this is the same for all steps
			// so doing it once is enough

			// set data dimensions
			lda #21
			sta dataWidth
			lda #20
			sta dataHeight

			// set start of area to print to

			lda #04
			sta dataDestinationHi
			lda #10
			sta dataDestinationLo

			// print the first screen

			lda #<titleScreenData
			sta dataSourceLo
			lda #>titleScreenData
			sta dataSourceHi
			jmp WriteScreenData

// -----------------------------------------

UpdateAttractMode:
			dec attractDelay
			beq triggered 			// swap screen when triggered

			// check for key or joy button press

			jsr GetKeyInput
			lda inputResult
			cmp #DOWN 				// enter pressed?
			beq !skip+ 				// yes
			jsr GetJoyInput
			lda inputResult
			cmp #TURNCLOCK 				// joy button pressed?
			beq !skip+ 					// yes
			rts
!skip:
			jmp EndAttractMode		// start the game
triggered:
			lda #ATTRACT_DELAY 		// reset the delay
			sta attractDelay

			inc attractStep 		// go to next screen
			lda attractStep
			cmp #3 					// have we done 3 screens?
			bne !skip+				// no. continue cycle
			lda #STEP_TITLE    	 // yes. reset cycle
			sta attractStep
!skip:
			// set data dimensions

			lda #21
			sta dataWidth
			lda #21
			sta dataHeight

			// reset the screen pointer

			lda #04
			sta dataDestinationHi
			lda #10
			sta dataDestinationLo

			// set start of data
			// dependent on attract step

			lda attractStep
			cmp #STEP_TITLE
			bne !nextstep+
			lda #<titleScreenData
			sta dataSourceLo
			lda #>titleScreenData
			sta dataSourceHi
			jmp WriteScreenData
!nextstep:
			cmp #STEP_CREDITS
			bne !nextstep+
			lda #<creditsScreenData
			sta dataSourceLo
			lda #>creditsScreenData
			sta dataSourceHi
			jmp WriteScreenData
!nextstep:
			cmp #STEP_CONTROLS
			bne !nextstep+
			lda #<keysScreenData
			sta dataSourceLo
			lda #>keysScreenData
			sta dataSourceHi
			jmp WriteScreenData
!nextstep:
			rts

// -----------------------------------------

EndAttractMode:

			lda #MODE_PLAY
			sta gameMode
			jsr StartPlayMode
			rts


//			lda #MODE_SELECTLEVEL
//			sta gameMode
//			jsr StartSelectLevelMode
//			brk
//			rts
