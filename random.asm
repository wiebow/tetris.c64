
// generate random number code

SetupRandom:
			// set the 16 bit rnd seed

			ldx #$89
			stx rndseed
			dex
			stx rndseed+1
			rts

GetRandom:
			// get random number 0-6
			// it's in accumulator when returning

			lda rndseed 		// load seed high byte
			and #%00000111 		// keep values 0-7
			cmp #$07 			// we can only use 0-6
			bne !skip+ 			// valid number!
			jsr UpdateRandom 	// retry
			jmp GetRandom
!skip:
			rts

UpdateRandom:
			lda rndseed 		// get first byte of rnd seed
			and #%00000010 		// extract bit 1
			sta rndtemp			// save it
			lda rndseed+1 		// get 2nd byte of rnd seed
			and #%00000010 		// extract bit 1
			eor rndtemp 		// one or the other but not both.
			clc 				// clear carry bit in case result was 0
			beq !skip+
			sec 				// set carry bit if result was 1
!skip:
			// shift the 16 bit seed value to the right
			// feeds the carry bit value into the msb

			ror rndseed 		// rotate 1st byte
			ror rndseed+1 		// rotate 2nd byte
			rts

rndseed:
			.byte 0,0
rndtemp:
			.byte 0
