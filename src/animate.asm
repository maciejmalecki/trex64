#import "_animate.asm"
#import "common/lib/invoke.asm"

.filenamespace c64lib

/*
 * In:
 *      X - slot index 0..7
 *      A - control byte
 *      pushParam0 - sequenceLo, Hi
 * Mod: A
 */
.macro ani_setAnimation(aniConfig) {
  // store control
  sta aniConfig.control,x
  // init frame
  lda #00
  sta aniConfig.frames,x
  // init animation counters
  _ani_calculateSpeedCounterInit(aniConfig)
  // store sequence addresses
  invokeStackBegin(ptr)
  pullParamB(sequenceHi)
  pullParamB(sequenceLo)
  lda sequenceLo:#$00
  sta aniConfig.sequenceLo,x
  lda sequenceHi:#$00
  sta aniConfig.sequenceHi,x
  invokeStackEnd(ptr)
  rts
  ptr: .word $0000
}

/*
 * In: X - slot number
 */
.macro _ani_calculateSpeedCounterInit(aniConfig) {
  lda aniConfig.control,x
  lsr
  lsr
  lsr
  lsr
  sta aniConfig.speedCounters,x
}

/*
 * Mod: A, X
 */
.macro ani_animate(aniConfig) {
  ldx #07
  loopThruSlots:
    // skip slot if disabled
    lda aniConfig.control,x
    and #ANI_CTRL_ENABLE
    beq nextSlot
      // decrement speed counter
      ldy aniConfig.speedCounters,x
      dey
      beq speedCounterFinished
        sty aniConfig.speedCounters,x
        jmp nextSlot
      speedCounterFinished:
        _ani_calculateSpeedCounterInit(aniConfig)
      // calculate next frame
      lda aniConfig.sequenceLo,x
      sta sequenceAddr
      lda aniConfig.sequenceHi,x
      sta sequenceAddr + 1
      ldy aniConfig.frames,x
      lda sequenceAddr:$ffff,y
      cmp #$ff
      beq endOfSequence
        iny
        sty aniConfig.frames,y
        // save new pointer in screen memories
        sta aniConfig.page0 + 1024 - 8,x
        sta aniConfig.page1 + 1024 - 8,x
        jmp nextSlot
      endOfSequence:
        lda #0
        // TODO only if LOOP = 1
        sta aniConfig.frames,x
    nextSlot:
    dex
  bne loopThruSlots
}
