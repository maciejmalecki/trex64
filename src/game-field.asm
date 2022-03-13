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
#import "chipset/lib/vic2.asm"
#import "text/lib/tiles-2x2.asm"
#import "copper64/lib/copper64.asm"

#import "_segments.asm"
#import "_zero_page.asm"
#import "_vic_layout.asm"
#import "_constants.asm"
#import "_sprites.asm"
#import "_score.asm"

#import "subroutines.asm"
#import "data.asm"
#import "delays.asm"
#import "music.asm"
#import "dashboard.asm"
#import "physics.asm"
#import "io.asm"
#import "music.asm"
#import "actors.asm"

#importonce

.filenamespace c64lib

/*
   Phase bit map:
   --------------
   %PW00000S

   - P page: 0=page0, 1=page1
   - W switching pages: 0=no switching, 1=switching
   - S scrolling: 0=no scrolling, 1=scrolling

   Usage:
     lda #%00000001
     bit z_phase
     bmi ... - branch if page1
     bpl ... - branch if page0
     bvc ... - branch if not switching pages
     bvs ... - branch if switching pages
     beq ... - branch if scrolling
     bne ... - branch if is not scrolling
 */
.label PHASE_SHOW_0         = %00000000
.label PHASE_WRAP_0_TO_1    = %01000000
.label PHASE_SWITCH_0_TO_1  = %00000001
.label PHASE_SHOW_1         = %10000000
.label PHASE_WRAP_1_TO_0    = %11000000
.label PHASE_SWITCH_1_TO_0  = %10000001

// copper raster lines (NTSC)
.label SWITCH_RASTER_NTSC   = 8

.segment Code

startCopper: {
  startCopper(
    z_displayListPtr,
    z_listPtr,
    List().add(c64lib.IRQH_JSR, c64lib.IRQH_BG_RASTER_BAR, c64lib.IRQH_BG_COL_0).lock())
  rts
}

stopCopper: {
  // TODO inconsistency, stopCopper shouldn't do rts inside, fix copper64 lib
  stopCopper()
}

scrollColorCycle2: {
  dec z_colorCycleDelay2
  bne !+
    lda #COLOR_CYCLE_DELAY
    sta z_colorCycleDelay2
    rotateMemRightFast(colorCycle2 + 1, 6)
  !:
  rts
}

rotateColors: {
  dec z_colorCycleDelay
  beq !+
  jmp next
    !:
    lda #TITLE_COLOR_CYCLE_DELAY
    sta z_colorCycleDelay
    rotateMemRightFast(COLOR_RAM + 40*(AUTHOR_TOP), 40)
  next:
  rts
}

// ---- Copper handling ----
.segment Code
startIngameCopper: {
  lda #<ingameCopperList
  sta z_displayListPtr
  lda #>ingameCopperList
  sta z_displayListPtr + 1

  lda z_ntsc
  bne ntsc
  jmp !+
  ntsc: {
    // for NTSC we want to change raster counter for last IRQ handler (switch pages)
    lda #SWITCH_RASTER_NTSC
    sta switchPagesCode + 1
    lda switchPagesCode
    and #%01111111
    sta switchPagesCode
  }
  !:
    jsr startCopper
  rts
}

startTitleCopper: {
  lda #<titleScreenCopperList
  sta z_displayListPtr
  lda #>titleScreenCopperList
  sta z_displayListPtr + 1
  jsr startCopper
  rts
}

startLevelScreenCopper: {
  lda #<levelScreenCopperList
  sta z_displayListPtr
  lda #>levelScreenCopperList
  sta z_displayListPtr + 1
  jsr startCopper
  rts
}

startEndGameScreenCopper: {
  lda #<endGameScreenCopperList
  sta z_displayListPtr
  lda #>endGameScreenCopperList
  sta z_displayListPtr + 1
  jsr startCopper
  rts
}

playMusicIrq: {
  jsr playMusic
  debugBorderEnd()
  lda z_anim_delay
  bne scrollBottom

  rotateCharRight(z_right_anim_char)
  jmp !+
  scrollBottom:
    rotateCharBottom(z_bottom_anim_char, store)
  !:
  inc z_anim_delay
  lda z_anim_delay
  cmp #2
  bne !+
    lda #0
    sta z_anim_delay
  !:
  debugBorderStart()
  rts
  store: .byte 0
}

// ---- END: Copper handling ----
beforeAlign:
.align $100
_copperListStart:
.print "wasted space because of Copper align $100: " + (_copperListStart - beforeAlign)
// here we define layout of raster interrupt handlers
ingameCopperList:
    // play music
    copperEntry(DASHBOARD_Y + 20, IRQH_JSR, <upperMultiplex, >upperMultiplex) // 50 + 20 = 70
    copperEntry(77, IRQH_JSR, <playMusicIrq, >playMusicIrq)
  scrollCode:
    // here we do the actual scrolling
    // add 1 (103, 279) here and below to revert
    copperEntry(103, IRQH_JSR, <scrollBackground, >scrollBackground)
    // here we do the page switching when it's time for this
  switchPagesCode:
    copperEntry(280, IRQH_JSR, <switchPages, >switchPages)
    // here we loop and so on, so on, for each frame
    copperLoop()

titleScreenCopperList:
      copperEntry(10, IRQH_JSR, <playMusic, >playMusic)
      copperEntry(80, IRQH_JSR, <scrollColorCycle2, >scrollColorCycle2)
    fadeEffectColor:
      copperEntry(166, IRQH_BG_COL_0, BLACK, 0)
      copperEntry(190, IRQH_JSR, <rotateColors, >rotateColors)
      copperEntry(206, IRQH_BG_COL_0, BLACK, 0)
      copperEntry(236, IRQH_BG_RASTER_BAR, <colorCycle2, >colorCycle2)
      copperEntry(250, IRQH_JSR, <dly_handleDelay, >dly_handleDelay)
      copperEntry(261, IRQH_JSR, <handleCredits, >handleCredits)
      copperLoop()

levelScreenCopperList:
    copperEntry(10, IRQH_JSR, <playMusic, >playMusic)
    copperEntry(80, IRQH_JSR, <scrollColorCycle2, >scrollColorCycle2)
    copperEntry(124, IRQH_BG_RASTER_BAR, <colorCycle1, >colorCycle1)
    copperEntry(140, IRQH_BG_RASTER_BAR, <colorCycle2, >colorCycle2)
    copperEntry(156, IRQH_BG_RASTER_BAR, <colorCycle1, >colorCycle1)
    copperEntry(245, IRQH_JSR, <dly_handleDelay, >dly_handleDelay)
    copperLoop()

endGameScreenCopperList:
    copperEntry(10, IRQH_JSR, <playMusic, >playMusic)
    copperEntry(80, IRQH_JSR, <scrollColorCycle2, >scrollColorCycle2)
    copperEntry(92, IRQH_BG_RASTER_BAR, <colorCycle1, >colorCycle1)
    copperEntry(108, IRQH_BG_RASTER_BAR, <colorCycle1, >colorCycle1)
    copperEntry(204, IRQH_BG_RASTER_BAR, <colorCycle2, >colorCycle2)
    copperEntry(245, IRQH_JSR, <dly_handleDelay, >dly_handleDelay)
    copperLoop()

_copperListEnd:
.assert "Copper list must fit into single 256b page.", (_copperListEnd - _copperListStart)<256, true
.print "Copper list size: " + (_copperListEnd - _copperListStart)
// ---- END: Copper Tables ----


// ---- Scrollable background handling ----

.segment Code
screen0RowOffsetsLo:  .fill 25, <(SCREEN_PAGE_ADDR_0 + i*40)
screen0RowOffsetsHi:  .fill 25, >(SCREEN_PAGE_ADDR_0 + i*40)
screen1RowOffsetsLo:  .fill 25, <(SCREEN_PAGE_ADDR_1 + i*40)
screen1RowOffsetsHi:  .fill 25, >(SCREEN_PAGE_ADDR_1 + i*40)

.label FREE_MEMORY_START = SPRITE_ADDR

.label tileDefinition = MUSIC_START_ADDR - 1024
.label mapOffsetsHi = tileDefinition - 12
.label mapOffsetsLo = mapOffsetsHi - 12
.label tileColors = mapOffsetsLo - 256

.var tilesCfg = Tile2Config()
.eval tilesCfg.bank = VIC_BANK
.eval tilesCfg.page0 = SCREEN_PAGE_0
.eval tilesCfg.page1 = SCREEN_PAGE_1
.eval tilesCfg.startRow = 0
.eval tilesCfg.endRow = 23
.eval tilesCfg.x = z_bgX
.eval tilesCfg.y = z_y
.eval tilesCfg.width = z_width
.eval tilesCfg.height = z_height
.eval tilesCfg.tileColors = tileColors
.eval tilesCfg.mapOffsetsLo = mapOffsetsLo
.eval tilesCfg.mapOffsetsHi = mapOffsetsHi
.eval tilesCfg.mapDefinitionPtr = z_map
.eval tilesCfg.tileDefinition = tileDefinition
.eval tilesCfg.lock()

// material based collision detection
checkBGCollisions: {
    lda #(PLAYER_Y + Y_COLLISION_OFFSET)
    sec
    sbc z_yPos
    lsr
    lsr
    lsr
    tay
    sta storeY
    lda #(PLAYER_X + X_COLLISION_OFFSET + X_COLLISION_OFFSET_RIGHT)
    lsr
    lsr
    lsr
    tax
    sta storeX
    jsr checkBGMaterialCollision
    beq !+
      jmp killPlayer
    !:
    ldy storeY
    iny
    ldx storeX
    jsr checkBGMaterialCollision
    beq !+
      jmp killPlayer
    !:

    ldy storeY
    lda #(PLAYER_X + X_COLLISION_OFFSET + X_COLLISION_OFFSET_LEFT)
    lsr
    lsr
    lsr
    tax
    sta storeX
    jsr checkBGMaterialCollision
    beq !+
      jmp killPlayer
    !:
    ldy storeY
    iny
    ldx storeX
    jsr checkBGMaterialCollision
    beq !+
      jmp killPlayer
    !:

    rts
    killPlayer:
      lda #GAME_STATE_KILLED
      .if (INVINCIBLE == 0) {
        sta z_gameState
        lda #1
        sta z_bgDeath
        sta z_bgDeathCopy
      }
      rts
    storeX: .byte 0
    storeY: .byte 0
}

checkBGMaterialCollision: {
      lda z_phase
    and #PHASE_SHOW_1
    bne checkPage12
    checkPage02:
      lda screen0RowOffsetsLo, y
      sta checkAddress2
      lda screen0RowOffsetsHi, y
      sta checkAddress2 + 1
      jmp doTheCheckActually2
    checkPage12:
      lda screen1RowOffsetsLo, y
      sta checkAddress2
      lda screen1RowOffsetsHi, y
      sta checkAddress2 + 1
    doTheCheckActually2:
      lda checkAddress2: $ffff, x // <-- A: intersecting background char code
      tay
      lda (z_materialsLo), y // <-- A: intersecting materials code
      and #MAT_KILLS
  rts
}

checkActorCollisions: {
  lda SPRITE_2S_COLLISION
  and #%11110000
  beq !+

  // lsr
  // lsr
  // lsr
  // lsr
  // sta BORDER_COL

    lda #1
    .if (INVINCIBLE == 0) {
      sta z_killedByActor
    }
  !:
  rts
}

drawTile: drawTile(tilesCfg, SCREEN_PAGE_ADDR_0, COLOR_RAM)

initLevel: {
  lda #MAP_HEIGHT
  sta z_height

  // set phase to 0
  lda #PHASE_SHOW_0
  sta z_phase

  lda #0
  sta z_spritesStashed
  sta z_doGameOver
  sta z_bgDeath
  sta z_bgDeathCopy
  sta z_spriteEnable
  sta z_colorRAMShifted
  sta z_anim_delay
  sta z_scrollReg
  sta z_acc0
  sta z_killedByActor

  // set [x,y] = [0,0]
  lda #$ff
  sta z_oldX
  lda #0
  sta z_x
  sta z_x + 1
  sta z_y
  sta z_y + 1
  sta z_bgX
  sta z_bgX + 1

  // set xpos
  lda #PLAYER_X
  sta z_xPos

  // init animation
  lda #0
  sta z_yPos
  sta z_jumpFrame
  sta z_jumpPhase
  sta z_jumpLinear

  // set key mode to 0
  lda #$00
  sta z_mode
  sta z_prevMode
  sta z_duckAfterLanding

  // set max delay
  lda #MAX_DELAY
  sta z_delay

  // set game state
  lda #GAME_STATE_LIVE
  sta z_gameState

  // set initial score delay
  setScoreDelay #SCORE_FOR_PROGRESS_DELAY

  // initialize tile2 system
  tile2Init(tilesCfg)

  // draw the screen
  ldx #0
  ldy #0
  draw:
    jsr drawTile
    inx
    cpx #20
    bne draw
    ldx #0
    iny
    cpy #MAP_HEIGHT
    bne draw

  rts
}

incrementX: {
  clc
  lda z_x
  adc z_deltaX
  sta z_x
  lda z_x + 1
  adc #0
  sta z_x + 1
  rts
}

detectPhases: {

  lda z_phase
  and #%10111110
  sta z_phase
  // detect page switching phase
  lda z_acc0
  cmp z_wrappingMark
  bne notSeven
    lda z_phase
    ora #%01000000
    sta z_phase
  notSeven:

  // detect scrolling phase
  lda z_acc0
  cmp z_scrollingMark
  bne notZero
    lda z_phase
    ora #%00000001
    sta z_phase
  notZero:
  rts
}

scrollBackground: {
  debugBorderStart()

  cld

  jsr detectPhases

  // are we actually moving?
  lda z_x
  cmp z_oldX
  bne !+
    // no movement -> no page switching - to disable strange artifacts when scrolling is stopped
    jmp end2
  !:

  // test phase flags
  lda #1
  bit z_phase
  bne scrolling
    jmp end2
  scrolling:
    bpl page0
  // we're on page 1
  page1: {
    lda z_x
    sta z_bgX
    lda z_x + 1
    sta z_bgX + 1
      // if scrolling
      lda z_phase
      and #%11111110
      sta z_phase
      jmp page1To0
  }
  // we're on page 0
  page0: {
    lda z_x
    sta z_bgX
    lda z_x + 1
    sta z_bgX + 1
      // if scrolling
      lda z_phase
      and #%11111110
      sta z_phase
      jmp page0To1
  }
  jmp end
  // do the screen shifting
  page0To1:
    shiftScreenLeft(tilesCfg, 0)
    jmp end
  page1To0:
    shiftScreenLeft(tilesCfg, 1)

  end:
    // setup IRQ handler back to scrollColorRam
    lda #<scrollColorRam
    sta scrollCode + 2
    lda #>scrollColorRam
    sta scrollCode + 3
  end2:

    debugBorderEnd()
    rts
}

scrollColorRam: {
  debugBorderEnd()

  cld

  jsr detectPhases

  // are we actually moving?
  lda z_x
  cmp z_oldX
  bne !+
    // no movement -> no page switching - to disable strange artifacts when scrolling is stopped
    jmp switchBackIrq
  !:

  lda #1
  sta z_colorRAMShifted

  shiftColorRamLeft(tilesCfg)
  decodeColorRight(tilesCfg)
  switchBackIrq:
  // setup IRQ handler back to scrollBackground
  lda #<scrollBackground
  sta scrollCode + 2
  lda #>scrollBackground
  sta scrollCode + 3
  end:

  debugBorderStart()
  rts
}

switchPages: {
  debugBorderStart()

  cld

  doSwitching:
  // are we actually moving?
  lda z_x
  cmp z_oldX
  bne !+
    // no movement -> no page switching - to disable strange artifacts when scrolling is stopped
    jmp endOfPhase
  !:
  sta z_oldX
  lda z_colorRAMShifted
  bne !+
    // switch pages only if color RAM have been shifted
    jmp end
  !:
  // test phase
  lda #1
  bit z_phase
  bpl page0
  // we're on page 1
  page1: {
      // if do not switch the page
      bvc endSwitch
      // if switch the page
      and #%00111111
      sta z_phase
      jmp switch1To0
  }
  // we're on page 0
  page0: {
      // if do not switch the page
      bvc endSwitch
      // if switch the page
      and #%00111111
      ora #%10000000
      sta z_phase
      jmp switch0To1
  }
  endSwitch:
    jmp end
  switch0To1:
    decodeScreenRight(tilesCfg, 1)
    lda MEMORY_CONTROL
    and #%00001111
    ora #(SCREEN_PAGE_1 << 4)
    sta MEMORY_CONTROL
    jmp end
  switch1To0:
    decodeScreenRight(tilesCfg, 0)
    lda MEMORY_CONTROL
    and #%00001111
    ora #(SCREEN_PAGE_0 << 4)
    sta MEMORY_CONTROL
  end:

  // calculate scroll register
  lda z_x
  and #%01110000
  lsr
  lsr
  lsr
  lsr
  sta z_acc0

  // update scroll register for scrollable area
  sec
  lda #7
  sbc z_scrollReg
  sta z_scrollReg
  lda CONTROL_2
  and #%11111000
  ora z_scrollReg
  sta CONTROL_2
  //sta hScroll + 2
  lda z_acc0
  sta z_scrollReg
  endOfPhase:

  // increment X coordinate
  lda z_gameState
  cmp #GAME_STATE_LIVE
  bne abnormal
    jsr incrementX
    jmp endOfIncrementX
  abnormal:
    cmp #GAME_STATE_LEVEL_END_SEQUENCE
    bne endOfIncrementX
      lda z_xPos
      cmp #$ff
    beq nextLevel
      inc z_xPos
      jmp endOfIncrementX
    nextLevel:
      lda #GAME_STATE_NEXT_LEVEL
      sta z_gameState
      jmp dontReset
  endOfIncrementX:

  // check end of level condition
  clc
  lda z_x + 1
  adc #19
  cmp z_width
  bne dontReset
    lda z_gameState
    cmp #GAME_STATE_LEVEL_END_SEQUENCE
    beq !+
      lda #GAME_STATE_LEVEL_END_SEQUENCE
      sta z_gameState
      jsr spr_showPlayerWalkLeft
    !:
  dontReset:

  jsr runEndOfFrameLogic

  lda #0
  sta z_colorRAMShifted

  debugBorderEnd()
  rts
}

runEndOfFrameLogic: {
  jsr io_scanControls
  jsr handleControls
  jsr animate

  jsr disposeActors
  jsr checkForNewActors
  jsr drawActors
  jsr enableActors
  jsr checkActorCollisions
  jsr doGameOver

  stashSprites(z_stashArea)

  jsr act_animate

  jsr phy_performProgressiveJump
  jsr phy_updateSpriteY
  jsr dly_handleDelay
  decrementScoreDelay()

  rts
}

handleControls: {
  lda z_gameState
  cmp #GAME_STATE_LIVE
  beq !+
    rts
  !:
  jsr io_checkJump
  beq !+
  {
    // start jumping sequence
    lda z_mode
    bne !+
      lda #1
      sta z_mode
      lda #0
      sta z_jumpFrame
      sta z_jumpPhase
      sta z_jumpLinear
      jsr spr_showPlayerJump
      jsr playJump
      jmp end
    !:
    end:
      jmp afterDuck
  }
  !:
  // handle ducking

  lda z_mode
  bne inAir
  jsr io_checkUnduck
  beq !+
    jsr spr_showPlayerWalkLeft
    jmp afterDuck
  !:
  jsr io_checkDoduck
  beq !+
    jsr playDuck
    jsr spr_showPlayerDuck
  !:
  jmp afterDuck
  // --->
  inAir:
    jsr io_checkDoduck
    beq !+
      lda #1
      sta z_duckAfterLanding
    !:
    jsr io_checkUnduck
    beq !+
      lda #0
      sta z_duckAfterLanding
    !:
  // <---
  afterDuck:
  // if back on earth -> switch to walk left again
  lda z_prevMode
  beq stillInAir
    lda z_mode
    bne stillInAir
      playSfx(playLanding)
      lda z_duckAfterLanding
      beq !+
        jsr spr_showPlayerDuck
        lda #0
        sta z_duckAfterLanding
        jmp stillInAir
      !:
      jsr spr_showPlayerWalkLeft
  stillInAir:

  rts
}


upperMultiplex: {
  debugBorderStart()
  popSprites(z_stashArea)
    // clear sprite collision reg
  lda SPRITE_2S_COLLISION
  debugBorderEnd()
  rts
}

// ---- END: Scrollable background handling ----

// ---- actors handling ----

.macro playEnemy(enemyRoutine) {
  txa
  pha
  playSfx(enemyRoutine)
  pla
  tax
}

.macro playSfx(enemyRoutine) {
  lda z_gameConfig
  and #CFG_SOUND
  bne !+
    jsr enemyRoutine
  !:
}

checkForNewActors: {
  ldy #0
  lda (z_actorsBase),y
  // check actor code
  cmp #$ff
  beq end
    iny
    lda (z_actorsBase),y
    // check trigger position
    cmp z_x + 1
    bne end
    // new actor trigger condition met
    jmp newActor
  end:
    rts
  newActor:
    ldy #0
    // actor code
    lda (z_actorsBase),y
    pha
    // actor X position
    lda #$60 // #87 TODO: to make it visible from behind the border
    pha
    lda #$14
    pha
    // actor Y position
    iny
    iny
    lda (z_actorsBase),y
    pha
    // actor speed
    iny
    lda (z_actorsBase),y
    pha
    // actor color
    iny
    lda (z_actorsBase),y
    sta color
    // add new actor
    jsr act_add
    lda act_sprite,x
    tax
    // X <- sprite number
    lda color:#$00
    sta SPRITE_0_COLOR,x
    ldy #0
    lda (z_actorsBase),y
    cmp #EN_VOGEL
    beq vogel
    cmp #EN_SCORPIO
    beq scorpio
    cmp #EN_SNAKE
    beq snake
    jmp moveActorsBase
    vogel:
      jsr spr_showVogel
      playEnemy(playVogel)
      jmp showEnemy
    scorpio:
      jsr spr_showScorpio
      playEnemy(playScorpio)
      jmp showEnemy
    snake:
      jsr spr_showSnake
      playEnemy(playSnake)
      jmp showEnemy
    showEnemy:
      // sprite enable
      lda z_spriteEnable
      ora bitMaskTable,x
      sta z_spriteEnable
    moveActorsBase:
    // move actors base to the next entry
    clc
    lda z_actorsBase
    adc #5
    sta z_actorsBase
    lda z_actorsBase + 1
    adc #0
    sta z_actorsBase + 1
    rts
}

disposeActors: {
  ldx #(ACT_MAX_SIZE-1)
  loop:
    lda act_code,x
    beq next
    lda act_xHi,x
    and #%00010000
    bne next
    lda act_xHi,x
    and #%00001111
    bne next
    lda act_sprite,x
    pha
    stx preserveX
    jsr act_remove
    // disable animation
    pla
    tax
    jsr disableAnimation
    // disable sprite
    lda SPRITE_ENABLE
    and bitMaskInvertedTable,x
    sta SPRITE_ENABLE
    // restore X
    ldx preserveX
  next:
    cpx #0
    beq end
    dex
    jmp loop
  end:
  rts
    // local vars
    preserveX: .byte $00
}

drawActors: {
  ldy #0
  loop:
    cpy #ACT_MAX_SIZE
    beq end
    lda act_code,y
    beq end
    lda act_sprite,y
    tax
    lda spriteYPosRegisters,x
    sta spriteY
    lda spriteXPosRegisters,x
    sta spriteX
    lda act_y,y
    sta spriteY:$d000
    // round
    lda act_xLo,y
    lsr
    lsr
    lsr
    lsr
    sta tempX
    lda act_xHi,y
    asl
    asl
    asl
    asl
    ora tempX
    sta spriteX:$d000
    lda act_xHi,y
    and #%00010000
    beq hiZero // TODO: branch on carry should work as well
      // X bigger than 255
      lda SPRITE_MSB_X
      ora bitMaskTable,x
      sta SPRITE_MSB_X
      jmp next
    hiZero:
      // less than 256
      lda SPRITE_MSB_X
      and bitMaskInvertedTable,x
      sta SPRITE_MSB_X
    next:
    iny
    jmp loop
  end:
  rts
  // local vars
    tempX: .byte $00
}

enableActors: {
  lda z_spriteEnable
  beq !+
    lda SPRITE_ENABLE
    ora z_spriteEnable
    sta SPRITE_ENABLE
    lda #0
    sta z_spriteEnable
  !:
  rts
}

// ---- END: actors handling ----

doGameOver: {
  lda z_doGameOver
  beq !+
    jsr act_reset
    jsr spr_hidePlayers
    lda SPRITE_ENABLE
    and #%00000000
    sta SPRITE_ENABLE
    .for (var i = 4; i < 8; i++) {
      ldx #i
      jsr disableAnimation
    }
    jsr spr_showGameOver
  !:
  rts
}

// shouldn't be in this file!
handleCredits: {
  lda z_creditsPhase
  and #CREDITS_FADE_IN
  cmp #CREDITS_FADE_IN
  bne !+
    jmp handleFadeIn
  !:
  lda z_creditsPhase
  and #CREDITS_FADE_OUT
  cmp #CREDITS_FADE_OUT
  bne !+
    jmp handleFadeOut
  !:
  lda z_creditsPhase
  and #CREDITS_DISPLAY
  cmp #CREDITS_DISPLAY
  bne !+
    jmp handleDelayCtr
  !:

  lda z_creditsPhase
  and #$f0
  cmp #$00
  bne !+
    jmp displayPage0
  !:
  cmp #$10
  bne !+
    jmp displayPage1
  !:
  cmp #$20
  bne !+
    jmp displayPage2
  !:
  cmp #$30
  bne !+
    jmp displayPage3
  !:
  cmp #$40
  bne !+
    jmp displayPage4
  !:
  cmp #$50
  bne !+
    jmp displayPage5
  !:
  cmp #$60
  bne !+
    jmp displayPage6
  !:
  jmp displayPage7

  // -----------------------
  displayPage0: {
    jsr clearCredits
    pushParamW(txt_page_0_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP+2) + 6); jsr outText
    jmp initFadeIn
  }
  displayPage1: {
    jsr clearCredits
    pushParamW(txt_page_1_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 2) + 11); jsr outText
    jmp initFadeIn
  }
  displayPage2: {
    jsr clearCredits
    pushParamW(txt_page_2_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 1) + 16); jsr outText

    lda z_ntsc
    beq !+
      pushParamW(txt_page_2_2)
      pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 3) + 18)
      jsr outText
    !:

    jmp initFadeIn
  }
  displayPage3: {
    jsr clearCredits
    pushParamW(txt_page_3_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 2) + 2); jsr outText
    jmp initFadeIn
  }
  displayPage4: {
    jsr clearCredits
    pushParamW(txt_page_4_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 0) + 7); jsr outText
    pushParamW(txt_page_4_1); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 2) + 18) ; jsr outText
    pushParamW(txt_page_4_2); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 4) + 18); jsr outText
    jmp initFadeIn
  }
  displayPage5: {
    jsr clearCredits
    pushParamW(txt_page_5_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 1) + 6); jsr outText
    pushParamW(txt_page_5_1); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 3) + 6); jsr outText
    jmp initFadeIn
  }
  displayPage6: {
    jsr clearCredits
    pushParamW(txt_page_6_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 2) + 10); jsr outText
    jmp initFadeIn
  }
  displayPage7: {
    jsr clearCredits
    pushParamW(txt_page_7_0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP) + 13); jsr outText
    pushParamW(txt_page_7_1); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 2)) ; jsr outText
    pushParamW(txt_page_7_2); pushParamW(SCREEN_PAGE_ADDR_0 + 40*(CREDITS_TOP + 4)); jsr outText
    jmp initFadeIn
  }
  initFadeIn: {
    lda z_creditsPhase
    ora #CREDITS_FADE_IN
    sta z_creditsPhase
    lda #0
    sta z_creditsFadeCtr
    rts
  }

  handleDelayCtr: {
    dec z_creditsDelayCtr
    lda z_creditsDelayCtr
    cmp #0
    bne !+
      lda z_creditsPhase
      and #$f0
      // increment page
      clc
      adc #$10
      cmp #CREDITS_LAST
      bne initFadeOut
        // after last: back to page 0
        lda #0
      initFadeOut:
      ora #CREDITS_FADE_OUT
      sta z_creditsPhase
      lda #0
      sta z_creditsFadeCtr
      rts
    !:
    rts
  }
  handleFadeIn: {
    ldx z_creditsFadeCtr
    lda fadeIn, x
    cmp #$ff
    beq fadeInEnd
      sta fadeEffectColor + 2
      inx
      stx z_creditsFadeCtr
      rts
    fadeInEnd:
      lda z_creditsPhase
      and #neg(CREDITS_FADE_IN)
      ora #CREDITS_DISPLAY
      sta z_creditsPhase
      lda #CREDITS_PAGE_DISPLAY_TIME
      sta z_creditsDelayCtr
      rts
  }
  handleFadeOut: {
    ldx z_creditsFadeCtr
    lda fadeOut, x
    cmp #$ff
    beq fadeOutEnd
      sta fadeEffectColor + 2
      inx
      stx z_creditsFadeCtr
      rts
    fadeOutEnd:
      lda z_creditsPhase
      and #neg(CREDITS_FADE_OUT)
      and #neg(CREDITS_DISPLAY)
      sta z_creditsPhase
      rts
  }
}

initCredits: {
  lda #0
  sta z_creditsFadeCtr
  sta z_creditsDelayCtr
  lda #0
  sta z_creditsPhase

  pushParamW(COLOR_RAM + 40*CREDITS_TOP)
  lda #BLACK
  ldx #(CREDITS_SIZE*40)
  jsr fillMem

  jsr clearCredits

  rts
}

clearCredits: {
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*CREDITS_TOP);
  lda #(32 + 64);
  ldx #(CREDITS_SIZE*40);
  jsr fillMem
  rts
}