#import "chipset/lib/sprites.asm"
#import "chipset/lib/vic2.asm"

#import "_segments.asm"
#import "_vic_layout.asm"
#import "_zero_page.asm"
#import "_sprites.asm"

.filenamespace c64lib

.macro _setSpriteShape(spriteNum, shapeNum) {
  lda #shapeNum
  sta SCREEN_PAGE_ADDR_0 + 1024 - 8 + spriteNum
  sta SCREEN_PAGE_ADDR_1 + 1024 - 8 + spriteNum
}

.segment Code
spr_showPlayer: {
  lda #0
  sta SPRITE_ENABLE
  // set X coord
  lda #PLAYER_X
  sta spriteXReg(PLAYER_SPRITE_TOP)
  sta spriteXReg(PLAYER_SPRITE_TOP_OVL)
  sta spriteXReg(PLAYER_SPRITE_BOTTOM)
  sta spriteXReg(PLAYER_SPRITE_BOTTOM_OVL)
  // set Y coord
  lda #PLAYER_Y
  sta spriteYReg(PLAYER_SPRITE_TOP)
  sta spriteYReg(PLAYER_SPRITE_TOP_OVL)
  lda #PLAYER_BOTTOM_Y
  sta spriteYReg(PLAYER_SPRITE_BOTTOM)
  sta spriteYReg(PLAYER_SPRITE_BOTTOM_OVL)
  // set colors
  lda #PLAYER_COL
  sta spriteColorReg(PLAYER_SPRITE_TOP_OVL)
  sta spriteColorReg(PLAYER_SPRITE_BOTTOM_OVL)
  lda #PLAYER_COL0
  sta spriteColorReg(PLAYER_SPRITE_TOP)
  sta spriteColorReg(PLAYER_SPRITE_BOTTOM)
  lda #%00001010
  sta SPRITE_COL_MODE
  lda #PLAYER_COL1
  sta SPRITE_COL_0
  lda #PLAYER_COL2
  sta SPRITE_COL_1
  lda #$0F
  sta SPRITE_ENABLE
  _setSpriteShape(PLAYER_SPRITE_TOP, 128)
  _setSpriteShape(PLAYER_SPRITE_TOP_OVL, 129)
  _setSpriteShape(PLAYER_SPRITE_BOTTOM, 130)
  _setSpriteShape(PLAYER_SPRITE_BOTTOM_OVL, 131)
  rts
}

spr_showDeath: {
  lda #0
  sta SPRITE_ENABLE
  // set X coord
  lda #PLAYER_X
  sta spriteXReg(PLAYER_SPRITE_TOP)
  sta spriteXReg(PLAYER_SPRITE_TOP_OVL)
  // set Y coord
  lda #PLAYER_Y
  sta spriteYReg(PLAYER_SPRITE_TOP)
  sta spriteYReg(PLAYER_SPRITE_TOP_OVL)
  // set colors
  lda #DEATH_COL
  sta spriteColorReg(PLAYER_SPRITE_TOP_OVL)
  lda #DEATH_COL0
  sta spriteColorReg(PLAYER_SPRITE_TOP)
  lda #%00000010
  sta SPRITE_COL_MODE
  lda #PLAYER_COL1
  sta SPRITE_COL_0
  lda #PLAYER_COL2
  sta SPRITE_COL_1
  lda #%00000011
  sta SPRITE_ENABLE
  _setSpriteShape(PLAYER_SPRITE_TOP, 128 + 12)
  _setSpriteShape(PLAYER_SPRITE_TOP_OVL, 128 + 12 + 1)
  rts
}

spr_showGameOver: {
  .label _GAME_OVER_X = 130
  .label _GAME_OVER_Y = 135

  .for(var i = 0; i < 4; i++) {
    _setSpriteShape(4 + i, 128 + 14 + i)
  }
  lda #WHITE
  .for(var i = 0; i < 4; i++) {
    sta spriteColorReg(4 + i)
  }
  lda #_GAME_OVER_Y
  .for(var i = 0; i < 4; i++) {
    sta spriteYReg(4 + i)
  }
  .for(var i = 0; i < 2; i++) {
    lda #(_GAME_OVER_X + i*24)
    sta spriteXReg(4 + i)
  }
  .for(var i = 2; i < 4; i++) {
    lda #(_GAME_OVER_X + 20 + i*24)
    sta spriteXReg(4 + i)
  }
  lda #%11110011
  sta SPRITE_ENABLE
  rts
}

spr_hidePlayers: {
  lda #0
  sta SPRITE_ENABLE
  rts
}

spr_animate: {
  lda z_animationPhase
  cmp animatePhaseOld
  beq phaseNotChanged
    // phase has been changed
    sta animatePhaseOld
    ldx #0
    stx z_animationFrame
  phaseNotChanged:
    // load next phase
    ldx z_animationFrame
    lda animWalkLeftBottomOvl, x
    bne !+
      // end of animation sequence, wrap to 0
      ldx #0
      stx z_animationFrame
      jmp phaseNotChanged
    !:
      // set up correct sprite shape
      sta SCREEN_PAGE_ADDR_0 + 1024 - 8 + PLAYER_SPRITE_BOTTOM_OVL
      sta SCREEN_PAGE_ADDR_1 + 1024 - 8 + PLAYER_SPRITE_BOTTOM_OVL

    lda animWalkLeftBottom, x
      // set up correct sprite shape
      sta SCREEN_PAGE_ADDR_0 + 1024 - 8 + PLAYER_SPRITE_BOTTOM
      sta SCREEN_PAGE_ADDR_1 + 1024 - 8 + PLAYER_SPRITE_BOTTOM

      inx
      stx z_animationFrame
  rts
  animatePhaseOld: .byte 0
}

.segment Data
animWalkLeft:
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 0
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 0 + 4
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 0 + 8
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 0 + 4
  .byte 0
animWalkLeftOvl:
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 1
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 1 + 4
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 1 + 8
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 1 + 4
  .byte 0
animWalkLeftBottom:
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 2
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 2 + 4
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 2 + 8
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 2 + 4
  .byte 0
animWalkLeftBottomOvl:
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 3
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 3 + 4
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 3 + 8
  .fill ANIMATION_DELAY, SPRITE_SHAPES_START + 3 + 4
  .byte 0
animJumpUp:
  .byte SPRITE_SHAPES_START + 0
  .byte 0
animJumpDown:
  .byte SPRITE_SHAPES_START + 1
  .byte 0
