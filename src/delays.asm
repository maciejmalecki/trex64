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
#import "_segments.asm"
#importonce

.filenamespace c64lib

/*
 * Busy waits until delay counter gets down to 0.
 *
 * In:  delay - amount of delay cycles to wait;
 *              if handleDelay is called in raster IRQ then 1 delay cycle = 1/50 sec (PAL) or 1/60 sec (NTSC).
 * Mod: A
 */
.pseudocommand wait delay {
  lda delay
  sta z_delayCounter
  !:
    lda z_delayCounter
  bne !-
}

/*
 * Decrements delay counter if not zero already. To be called periodically i.e. within scope of (raster) IRQ handler.
 *
 * Mod: A
 */
.macro handleDelay() {
  txa
  ldx z_delayCounter
  beq !+
    dex
    stx z_delayCounter
  !:
  tax
}

.segment Code

dly_wait10: {
  wait #10
  rts
}

dly_handleDelay: {
  handleDelay()
  rts
}
