#import "chipset/lib/sprites.asm"
#import "chipset/lib/vic2.asm"
#import "common/lib/invoke.asm"

#import "_segments.asm"
#import "_vic_layout.asm"
#import "_zero_page.asm"
#import "_sprites.asm"
#import "_animate.asm"

.filenamespace c64lib

.label SPR_DINO = 0
.label SPR_DINO_JUMP = SPR_DINO + 8
.label SPR_DINO_DUCK = SPR_DINO_JUMP + 4
.label SPR_DEATH = SPR_DINO_DUCK + 8
.label SPR_GAME_OVER = SPR_DEATH + 4
.label SPR_VOGEL = SPR_GAME_OVER + (_b_vogel - _b_gameOver)/64
.label SPR_SCORPIO = SPR_VOGEL + (_b_scorpio - _b_vogel)/64
.label SPR_SNAKE = SPR_SCORPIO + (_b_snake - _b_scorpio)/64

.macro _setSpriteShape(spriteNum, shapeNum) {
  lda #shapeNum
  sta SCREEN_PAGE_ADDR_0 + 1024 - 8 + spriteNum
  sta SCREEN_PAGE_ADDR_1 + 1024 - 8 + spriteNum
}

.segment Code
animControl:
  .fill 8, 0
animSequenceLo:
  .fill 8, 0
animSequenceHi:
  .fill 8, 0
animFrames:
  .fill 8, 0
animSpeedCounters:
  .fill 8, 0
.var aniConfig = AniConfig()
.eval aniConfig.page0 = SCREEN_PAGE_ADDR_0
.eval aniConfig.page1 = SCREEN_PAGE_ADDR_1
.eval aniConfig.control = animControl
.eval aniConfig.sequenceLo = animSequenceLo
.eval aniConfig.sequenceHi = animSequenceHi
.eval aniConfig.frames = animFrames
.eval aniConfig.speedCounters = animSpeedCounters
.eval aniConfig.lock()

setAnimation: { ani_setAnimation(aniConfig) }
disableAnimation: { ani_disableAnimation(aniConfig); rts }
animate: { ani_animate(aniConfig); rts }

spr_showPlayer: {
  lda #0
  sta SPRITE_ENABLE
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

  jsr spr_showPlayerWalkLeft

  lda z_spriteEnable
  ora #$0F
  sta z_spriteEnable

  rts
}

_spr_setNormalPosition: {
  // set X coord
  lda #PLAYER_X
  sta spriteXReg(PLAYER_SPRITE_TOP)
  sta spriteXReg(PLAYER_SPRITE_TOP_OVL)
  sta spriteXReg(PLAYER_SPRITE_BOTTOM)
  sta spriteXReg(PLAYER_SPRITE_BOTTOM_OVL)
  // set Y coord
  cld
  lda #PLAYER_Y
  sta z_yPosTop
  sbc z_yPos
  sta spriteYReg(PLAYER_SPRITE_TOP)
  sta spriteYReg(PLAYER_SPRITE_TOP_OVL)
  clc
  lda #PLAYER_BOTTOM_Y
  sta z_yPosBottom
  sbc z_yPos
  sta spriteYReg(PLAYER_SPRITE_BOTTOM)
  sta spriteYReg(PLAYER_SPRITE_BOTTOM_OVL)
  rts
}

_spr_setDuckPosition: {
  // set X coord
  lda #(PLAYER_X - 12)
  sta spriteXReg(PLAYER_SPRITE_TOP)
  sta spriteXReg(PLAYER_SPRITE_TOP_OVL)
  lda #(PLAYER_X + 12)
  sta spriteXReg(PLAYER_SPRITE_BOTTOM)
  sta spriteXReg(PLAYER_SPRITE_BOTTOM_OVL)
  // set Y coord
  lda #(PLAYER_Y + 10)
  sta z_yPosTop
  sta z_yPosBottom
  sta spriteYReg(PLAYER_SPRITE_TOP)
  sta spriteYReg(PLAYER_SPRITE_TOP_OVL)
  sta spriteYReg(PLAYER_SPRITE_BOTTOM)
  sta spriteYReg(PLAYER_SPRITE_BOTTOM_OVL)
  rts
}

spr_showPlayerWalkLeft: {

  jsr _spr_setNormalPosition

  pushParamW(dinoWalkLeft)
  ldx #PLAYER_SPRITE_TOP
  lda #$43
  jsr setAnimation

  pushParamW(dinoWalkLeftOvl)
  ldx #PLAYER_SPRITE_TOP_OVL
  lda #$43
  jsr setAnimation

  pushParamW(dinoWalkLeftBottom)
  ldx #PLAYER_SPRITE_BOTTOM
  lda #$43
  jsr setAnimation

  pushParamW(dinoWalkLeftBottomOvl)
  ldx #PLAYER_SPRITE_BOTTOM_OVL
  lda #$43
  jsr setAnimation

  rts
}

spr_showPlayerJump: {
  jsr _spr_setNormalPosition

  pushParamW(dinoJump)
  ldx #PLAYER_SPRITE_TOP
  lda #$43
  jsr setAnimation

  pushParamW(dinoJumpOvl)
  ldx #PLAYER_SPRITE_TOP_OVL
  lda #$43
  jsr setAnimation

  pushParamW(dinoJumpBottom)
  ldx #PLAYER_SPRITE_BOTTOM
  lda #$43
  jsr setAnimation

  pushParamW(dinoJumpBottomOvl)
  ldx #PLAYER_SPRITE_BOTTOM_OVL
  lda #$43
  jsr setAnimation

  rts
}

spr_showPlayerDuck: {

  jsr _spr_setDuckPosition

  pushParamW(dinoDuck)
  ldx #PLAYER_SPRITE_TOP
  lda #$43
  jsr setAnimation

  pushParamW(dinoDuckOvl)
  ldx #PLAYER_SPRITE_TOP_OVL
  lda #$43
  jsr setAnimation

  pushParamW(dinoDuckBottom)
  ldx #PLAYER_SPRITE_BOTTOM
  lda #$43
  jsr setAnimation

  pushParamW(dinoDuckBottomOvl)
  ldx #PLAYER_SPRITE_BOTTOM_OVL
  lda #$43
  jsr setAnimation

  rts
}

spr_showVogel: {
  // set sprite hires
  lda SPRITE_COL_MODE
  and bitMaskInvertedTable,x
  sta SPRITE_COL_MODE
  // set animation
  pushParamW(vogel)
  lda #$43
  jsr setAnimation
  rts
}

spr_showScorpio: {
  // set sprite hires
  lda SPRITE_COL_MODE
  and bitMaskInvertedTable,x
  sta SPRITE_COL_MODE
  // set animation
  pushParamW(scorpio)
  lda #$43
  jsr setAnimation
  rts
}

spr_showSnake: {
  // set sprite hires
  lda SPRITE_COL_MODE
  and bitMaskInvertedTable,x
  sta SPRITE_COL_MODE
  // set animation
  pushParamW(snake)
  lda #$43
  jsr setAnimation
  rts
}

spr_showDeath: {

  jsr _spr_setNormalPosition

  pushParamW(dinoDeath)
  ldx #PLAYER_SPRITE_TOP
  lda #$43
  jsr setAnimation

  pushParamW(dinoDeathOvl)
  ldx #PLAYER_SPRITE_TOP_OVL
  lda #$43
  jsr setAnimation

  pushParamW(dinoDeathBottom)
  ldx #PLAYER_SPRITE_BOTTOM
  lda #$43
  jsr setAnimation

  pushParamW(dinoDeathBottomOvl)
  ldx #PLAYER_SPRITE_BOTTOM_OVL
  lda #$43
  jsr setAnimation

  rts
}

spr_showGameOver: {

  .label _GAME_OVER_X = 130
  .label _GAME_OVER_Y = 135

  .for(var i = 0; i < 4; i++) {
    _setSpriteShape(4 + i, 128 + SPR_GAME_OVER + i)
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
  lda SPRITE_MSB_X
  and #%00001111
  sta SPRITE_MSB_X
  lda #%11111111
  sta SPRITE_ENABLE
  rts
}

spr_hidePlayers: {
  lda #0
  sta SPRITE_ENABLE
  rts
}

// ---- Sprites definition ----
.segment Sprites
beginOfSprites:
  _b_dino:
  .import binary "sprites/dino.bin"
  _b_gameOver:
  #import "sprites/gameover.asm"
  _b_vogel:
  #import "sprites/vogel.asm"
  _b_scorpio:
  .import binary "sprites/scorpio.bin"
  _b_snake:
  .import binary "sprites/snake.bin"
endOfSprites:
.print "Sprites import size = " + (endOfSprites - beginOfSprites)
// ---- END: Sprites definition ----

.segment Data
bitMaskTable:
  .byte $01, $02, $04, $08, $10, $20, $40, $80
bitMaskInvertedTable:
  .byte neg($01), neg($02), neg($04), neg($08), neg($10), neg($20), neg($40), neg($80)
// ---- Animation sequences -----
dinoWalkLeft:
  .byte SPRITE_SHAPES_START + SPR_DINO
  .byte SPRITE_SHAPES_START + SPR_DINO + 4
  .byte $ff
dinoWalkLeftOvl:
  .byte SPRITE_SHAPES_START + SPR_DINO + 1
  .byte SPRITE_SHAPES_START + SPR_DINO + 1 + 4
  .byte $ff
dinoWalkLeftBottom:
  .byte SPRITE_SHAPES_START + SPR_DINO + 2
  .byte SPRITE_SHAPES_START + SPR_DINO + 2 + 4
  .byte $ff
dinoWalkLeftBottomOvl:
  .byte SPRITE_SHAPES_START + SPR_DINO + 3
  .byte SPRITE_SHAPES_START + SPR_DINO + 3 + 4
  .byte $ff
dinoDeath:
  .byte SPRITE_SHAPES_START + SPR_DEATH
  .byte $ff
dinoDeathOvl:
  .byte SPRITE_SHAPES_START + SPR_DEATH + 1
  .byte $ff
dinoDeathBottom:
  .byte SPRITE_SHAPES_START + SPR_DEATH + 2
  .byte $ff
dinoDeathBottomOvl:
  .byte SPRITE_SHAPES_START + SPR_DEATH + 3
  .byte $ff
dinoJump:
  .byte SPRITE_SHAPES_START + SPR_DINO_JUMP
  .byte $ff
dinoJumpOvl:
  .byte SPRITE_SHAPES_START + SPR_DINO_JUMP + 1
  .byte $ff
dinoJumpBottom:
  .byte SPRITE_SHAPES_START + SPR_DINO_JUMP + 2
  .byte $ff
dinoJumpBottomOvl:
  .byte SPRITE_SHAPES_START + SPR_DINO_JUMP + 3
  .byte $ff
dinoDuck:
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK + 4
  .byte $ff
dinoDuckOvl:
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK + 1
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK + 4 + 1
  .byte $ff
dinoDuckBottom:
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK + 2
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK + 4 + 2
  .byte $ff
dinoDuckBottomOvl:
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK + 3
  .byte SPRITE_SHAPES_START + SPR_DINO_DUCK + 4 + 3
  .byte $ff
vogel:
  .byte SPRITE_SHAPES_START + SPR_VOGEL
  .byte SPRITE_SHAPES_START + SPR_VOGEL + 1
  .byte SPRITE_SHAPES_START + SPR_VOGEL + 2
  .byte SPRITE_SHAPES_START + SPR_VOGEL + 3
  .byte SPRITE_SHAPES_START + SPR_VOGEL + 4
  .byte SPRITE_SHAPES_START + SPR_VOGEL + 3
  .byte SPRITE_SHAPES_START + SPR_VOGEL + 2
  .byte SPRITE_SHAPES_START + SPR_VOGEL + 1
  .byte $ff
scorpio:
  .byte SPRITE_SHAPES_START + SPR_SCORPIO
  .byte SPRITE_SHAPES_START + SPR_SCORPIO + 1
  .byte SPRITE_SHAPES_START + SPR_SCORPIO + 2
  .byte SPRITE_SHAPES_START + SPR_SCORPIO + 1
  .byte $ff
snake:
  .byte SPRITE_SHAPES_START + SPR_SNAKE
  .byte SPRITE_SHAPES_START + SPR_SNAKE + 1
  .byte SPRITE_SHAPES_START + SPR_SNAKE + 2
  .byte SPRITE_SHAPES_START + SPR_SNAKE + 1
  .byte $ff
// ----- END: Animation sequences -----
