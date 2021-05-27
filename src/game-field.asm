#import "text/lib/tiles-2x2.asm"
#import "copper64/lib/copper64.asm"

#import "_segments.asm"
#import "_zero_page.asm"
#import "_vic_layout.asm"
#import "_constants.asm"
#import "_sprites.asm"
#import "_score.asm"

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

.segment Code

startCopper: {
  startCopper(
    z_displayListPtr,
    z_listPtr,
    List().add(c64lib.IRQH_HSCROLL, c64lib.IRQH_JSR, c64lib.IRQH_BG_RASTER_BAR).lock())
  rts
}

stopCopper: {
  // TODO inconsistency, stopCopper shouldn't do rts inside, fix copper64 lib
  stopCopper()
}

scrollColorCycle2: {
  dec z_colorCycleDelay 
  bne !+
    lda #COLOR_CYCLE_DELAY
    sta z_colorCycleDelay
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
    rotateMemRightFast(COLOR_RAM + 40*(AUTHOR_TOP + 2), 40)
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
// ---- END: Copper handling ----

.align $100
_copperListStart:
// here we define layout of raster interrupt handlers
ingameCopperList:
  hScroll:
    // play music
    copperEntry(0, IRQH_JSR, <playMusic, >playMusic)
    copperEntry(DASHBOARD_Y + 20, IRQH_JSR, <upperMultiplex, >upperMultiplex)
  scrollCode:
    // here we do the actual scrolling
    copperEntry(88, IRQH_JSR, <scrollBackground, >scrollBackground)
    // here we do the page switching when it's time for this
    copperEntry(260, IRQH_JSR, <switchPages, >switchPages)
    // here we loop and so on, so on, for each frame
    copperLoop()

titleScreenCopperList:
    copperEntry(10, IRQH_JSR, <playMusic, >playMusic)
    copperEntry(200, IRQH_JSR, <rotateColors, >rotateColors)
    copperEntry(245, IRQH_JSR, <dly_handleDelay, >dly_handleDelay)
    copperLoop()

levelScreenCopperList:
    copperEntry(10, IRQH_JSR, <playMusic, >playMusic)
    copperEntry(80, IRQH_JSR, <scrollColorCycle2, >scrollColorCycle2)
    copperEntry(124, IRQH_BG_RASTER_BAR, <colorCycle1, >colorCycle1)
    copperEntry(140, IRQH_BG_RASTER_BAR, <colorCycle2, >colorCycle2)
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
// ---- END: Copper Tables ----


// ---- Scrollable background handling ----

.segment Code

.align $100
tileColors:
  .fill 256, $0
mapOffsetsLo:
  .fill 256, 0
mapOffsetsHi:
  .fill 256, 0
tileDefinition:
  .fill 256*4, $0

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

checkBGCollisions: {
  cld
  lda #(PLAYER_Y + Y_COLLISION_OFFSET)
  sec
  sbc z_yPos
  lsr
  lsr
  lsr
  lsr
  tay
  lda #(PLAYER_X + X_COLLISION_OFFSET)
  lsr
  lsr
  lsr
  lsr
  tax
  decodeTile(tilesCfg)
  and z_obstaclesMark
  cmp z_obstaclesMark
  bne !+
    lda #GAME_STATE_KILLED
    .if (INVINCIBLE == 0) {
      sta z_gameState
    }
    rts
  !:
  lda #(PLAYER_X + X_COLLISION_OFFSET - 8)
  lsr
  lsr
  lsr
  lsr
  tax
  decodeTile(tilesCfg)
  and z_obstaclesMark
  cmp z_obstaclesMark
  bne !+
    lda #GAME_STATE_KILLED
    .if (INVINCIBLE == 0) {
      sta z_gameState
    }
  !:
  rts
}

checkActorCollisions: {
  lda SPRITE_2S_COLLISION
  and #%11110000
  beq !+
    lda #GAME_STATE_KILLED
    .if (INVINCIBLE == 0) {
      sta z_gameState
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

  // set sprite enable ghost reg to 0
  lda #0
  sta z_spriteEnable

  lda #0
  sta z_colorRAMShifted

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

  // set key mode to 0
  lda #$00
  sta z_mode
  sta z_prevMode

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
  cld
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
    _t2_shiftScreenLeft(tilesCfg, 0, 1)
    jmp end
  page1To0:
    _t2_shiftScreenLeft(tilesCfg, 1, 0)

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

  _t2_shiftColorRamLeft(tilesCfg, 2)
  _t2_decodeColorRight(tilesCfg, COLOR_RAM)
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
    _t2_decodeScreenRight(tilesCfg, 1)
    lda MEMORY_CONTROL
    and #%00001111
    ora #(SCREEN_PAGE_1 << 4)
    sta MEMORY_CONTROL
    jmp end
  switch1To0:
    _t2_decodeScreenRight(tilesCfg, 0)
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
  cld
  lda z_x + 1
  adc #20
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

  jsr updateDashboard
  jsr io_scanControls
  jsr handleControls
  jsr animate
  jsr phy_performProgressiveJump
  jsr phy_updateSpriteY
  jsr dly_handleDelay

  jsr disposeActors
  jsr checkForNewActors
  jsr drawActors
  jsr act_animate
  jsr enableActors
  jsr checkActorCollisions
  jsr doGameOver

  decrementScoreDelay()

  stashSprites(z_stashArea)

  lda #0
  sta z_colorRAMShifted

  debugBorderEnd()
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

  afterDuck:
  // if back on earth -> switch to walk left again
  lda z_prevMode
  beq !+
    lda z_mode
    bne stillInAir
      playSfx(playLanding)
      jsr spr_showPlayerWalkLeft
    stillInAir:
  !:

  rts
}


upperMultiplex: {
  debugBorderStart()
  popSprites(z_stashArea)
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

