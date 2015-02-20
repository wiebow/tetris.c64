/*

----------------------------------
Tetris for 6502. (c) WdW 2015
----------------------------------

*/

			.pc = $c000

			// print and animation test

			lda #10
			sta blockXposition
			lda #05
			sta blockYposition
			jsr SetScreenPosition

			lda #$00
			jsr SelectBlock
			jsr PrintBlock

			// test loop for input
loop:
			jsr GetKeyInput
			jmp loop

			// import source files

			.import source "blocks.asm"
			.import source "input.asm"
