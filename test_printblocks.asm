

// Tetris for 6502. (c) WdW 2015


			.pc = $c000


// print and animation test

			lda #10
			sta blockXposition
			lda #05
			sta blockYposition
			jsr SetScreenPosition

			lda #$00
			jsr SelectBlock
			lda #$00			// forward 1 frame
			jsr AnimateBlock
			jsr PrintBlock
			rts


			// import source files from here on

			.import source "blocks.asm"

