#import "_zero_page.asm"
#importonce

.filenamespace c64lib

/*
 * Set score to 0.
 */
.macro resetScore() {
  lda #0
  sta z_score
  sta z_score + 1
  sta z_score + 2
}

/*
 * Adds 4 digit decimal to the score.
 *
 * In:  A - low byte of operand
 *      X - hi byte of operand
 * Mod: A
 */
.macro addScore() {
  clc
  sed
  adc z_score
  sta z_score
  txa
  adc z_score + 1
  sta z_score + 1
  lda #0
  adc z_score + 2
  sta z_score + 2
  cld
}

/*
 * Mod: A
 */
.pseudocommand setScoreDelay delay {
  lda delay
  sta z_scoreDelay
}

/*
 * Mod: A
 */
.macro decrementScoreDelay() {
  lda z_scoreDelay
  beq !+
    dec z_scoreDelay
  !:
}
