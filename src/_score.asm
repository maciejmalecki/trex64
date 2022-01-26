/*
  MIT License

  Copyright (c) 2022 Maciej Malecki

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/
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
