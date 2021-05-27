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
