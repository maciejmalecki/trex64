#import "chipset/lib/sprites.asm"

#import "_segments.asm"
#import "_zero_page.asm"
#import "_sprites.asm"
#import "_constants.asm"

.filenamespace c64lib

.label _JUMP_TABLE_LENGTH = 14
.label _JUMP_LINEAR_LENGTH = 16
.label _GRAVITY_FACTOR = 3

.function _polyJump(i) {
  .return (pow(_JUMP_TABLE_LENGTH / 2, 2) - pow(_JUMP_TABLE_LENGTH / 2 - i, 2)) / _GRAVITY_FACTOR
}

.function _linearJump(i) {
  .return i * _polyJump(1)
}

// ---- Jump handling ----
.segment Code

phy_performProgressiveJump: {
  lda z_mode
  sta z_prevMode
  beq end
    lda z_jumpPhase
    bne peakPhase
      // up phase
      lda z_currentKeys
      and #KEY_SPACE
      bne goUp
        lda #0
        sta z_jumpFrame
        lda #1
        sta z_jumpPhase
        jmp peakPhase
      goUp:
      ldx z_jumpLinear
      inx
      lda jumpTableLinear,x
      cmp #$ff
      bne !+
        lda #0
        sta z_jumpFrame
        lda #1
        sta z_jumpPhase
        jmp peakPhase
      !:
      sta z_yPos
      stx z_jumpLinear
      jmp end
    peakPhase:
      cmp #1
    bne downPhase
    {
      // peak phase
      ldx z_jumpFrame
      lda jumpTablePeak,x
      cmp #$ff
      bne !+
        lda z_jumpLinear
        sta z_jumpFrame
        lda #2
        sta z_jumpPhase
        jmp downPhase
      !:
      sta z_yPos
      clc
      ldx z_jumpLinear
      lda jumpTableLinear,x
      adc z_yPos
      sta z_yPos
      ldx z_jumpFrame
      inx
      stx z_jumpFrame
      jmp end
    }
    downPhase:
    {
      // down phase
      ldx z_jumpLinear
      bne nextFrame
        lda #0
        sta z_mode
        sta z_yPos
        sta z_jumpFrame
        jmp end
      nextFrame:
      lda jumpTableLinear,x
      sta z_yPos
      dex
      stx z_jumpLinear
    }
  end:
  rts
}

phy_updateSpriteY: {
  // set Y coord
  sec
  cld
  lda z_yPosTop
  sbc z_yPos
  sta spriteYReg(PLAYER_SPRITE_TOP)
  sta spriteYReg(PLAYER_SPRITE_TOP_OVL)
  clc
  lda z_yPosBottom
  sbc z_yPos
  sta spriteYReg(PLAYER_SPRITE_BOTTOM)
  sta spriteYReg(PLAYER_SPRITE_BOTTOM_OVL)

  lda z_gameState
  cmp #GAME_STATE_LEVEL_END_SEQUENCE
  bne !+
    lda z_xPos
    sta spriteXReg(PLAYER_SPRITE_TOP)
    sta spriteXReg(PLAYER_SPRITE_TOP_OVL)
    sta spriteXReg(PLAYER_SPRITE_BOTTOM)
    sta spriteXReg(PLAYER_SPRITE_BOTTOM_OVL)
  !:

  rts
}
.segment Data


jumpTableLinear:
  .fill _JUMP_LINEAR_LENGTH, _linearJump(i)
  .byte $ff
jumpTablePeak:
  .fill _JUMP_TABLE_LENGTH, _polyJump(i)
  .byte $ff
 // ---- END: Jump handling ----
