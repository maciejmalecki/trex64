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

.macro _generateJumpTable() {
  .fill _JUMP_LINEAR_LENGTH, _linearJump(i)
  .fill _JUMP_TABLE_LENGTH, _linearJump(_JUMP_LINEAR_LENGTH) + _polyJump(i)
  .fill _JUMP_LINEAR_LENGTH, _linearJump(_JUMP_LINEAR_LENGTH - i)
  .byte 0
  .byte $ff
}


// ---- Jump handling ----
.segment Code
phy_performJump: {
  lda z_mode
  beq end
    ldx z_jumpFrame
    lda jumpTable, x
    cmp #$ff
    bne nextFrame
      lda #0
      sta z_mode
      sta z_yPos
      sta z_jumpFrame
      jmp end
    nextFrame:
    sta z_yPos
    inx
    stx z_jumpFrame
  end:
  rts
}

phy_updateSpriteY: {
  // set Y coord
  sec
  cld
  lda #PLAYER_Y
  sbc z_yPos
  sta spriteYReg(PLAYER_SPRITE_TOP)
  sta spriteYReg(PLAYER_SPRITE_TOP_OVL)
  clc
  adc #21
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
jumpTable: _generateJumpTable()
// ---- END: Jump handling ----
