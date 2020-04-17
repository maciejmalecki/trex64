//#define VISUAL_DEBUG
#import "common/lib/common.asm"
#import "common/lib/mem.asm"
#import "common/lib/invoke.asm"
#import "chipset/lib/sprites.asm"
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2.asm"
#import "chipset/lib/cia.asm"
#import "text/lib/text.asm"
#import "text/lib/tiles-2x2.asm"
#import "copper64/lib/copper64.asm"

#import "_constants.asm"
#import "_segments.asm"
#import "_zero_page.asm"
#import "_sprites.asm"
#import "_vic_layout.asm"

#import "physics.asm"
#import "delay_counter.asm"
#import "score.asm"

.filenamespace c64lib

.file [name="./rex.prg", segments="Code, Data, Charsets, LevelData, Sprites", modify="BasicUpstart", _start=$0810]

.label MAX_DELAY = 10

// ---- game state constants ----
.label GAME_STATE_LIVE = 1
.label GAME_STATE_KILLED = 2
.label GAME_STATE_GAME_OVER = 3
.label GAME_STATE_NEXT_MAP = 4
.label GAME_STATE_NEXT_WORLD = 5

// ---- game parameters ----

// starting amount of lives
.label LIVES = 3
// scoring
.label SCORE_FOR_PROGRESS_DELAY = 50
.label SCORE_FOR_PROGRESS = $0025
// collision detection
.label X_COLLISION_OFFSET = 8 - 24
.label Y_COLLISION_OFFSET = 29 - 50

// ---- levels ----
#import "levels/level1/data.asm"


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

// -------- Main program ---------
.segment Code

// ---- game flow management ----
start:
  // main init
  jsr configureC64
  jsr unpackData
  
  // main loop
  titleScreen: 
    jsr doTitleScreen
    jsr initGame
  levelScreen:
    lda #GAME_STATE_LIVE
    sta z_gameState
    jsr doLevelScreen
  ingame:
    jsr doIngame
    lda z_gameState
    cmp #GAME_STATE_GAME_OVER
    bne levelScreen

  jmp titleScreen
  // end of main loop

doTitleScreen: {
  jsr configureTitleVic2
  jsr startTitleCopper
  jsr prepareTitleScreen
  endlessTitle:
    jsr scanSpaceHit
    beq startIngame
    jmp endlessTitle
  startIngame:
  jsr wait
  jsr stopCopper
  rts
}

doLevelScreen: {

  jsr configureTitleVic2
  jsr startTitleCopper
  jsr prepareLevelScreen

  !:
    jsr scanSpaceHit
    beq !+
    jmp !-
  !:
  jsr wait
  jsr stopCopper
  rts
}

doIngame: {
  jsr configureIngameVic2
  jsr prepareIngameScreen
  jsr initDashboard
  jsr updateScoreOnDashboard
  jsr setUpWorld1
  jsr setUpMap1_2
  jsr initLevel
  jsr showPlayer
  jsr startIngameCopper
  mainMapLoop:
    // check death conditions
    jsr checkCollisions
    jsr updateScore
    // check game state
    lda z_gameState
    cmp #GAME_STATE_KILLED
    bne !+
      jsr showDeath
      wait #100
      // decrement lives
      dec z_lives
      bne livesLeft
        lda #GAME_STATE_GAME_OVER
        sta z_gameState
        jmp !+
      livesLeft:
    !:
    lda z_gameState
    cmp #GAME_STATE_LIVE
    beq !+
      jmp gameOver
    !:

  jmp mainMapLoop

  gameOver:
    jsr stopCopper
    jsr hidePlayers
    rts
}

initGame: {
  // set up lives count
  lda #LIVES
  sta z_lives

  // set score to 0
  resetScore()

  // set up start level
  lda #1
  sta z_worldCounter
  lda #1
  sta z_levelCounter

  rts
}

// ---- END: game flow ----

updateScore: {
  lda z_scoreDelay
  bne !+
    setScoreDelay #SCORE_FOR_PROGRESS_DELAY
    ldx #>SCORE_FOR_PROGRESS
    lda #<SCORE_FOR_PROGRESS
    jsr addScore
    jsr updateScoreOnDashboard
  !:
  rts
}


// ---- General configuration ----
configureC64: {
  sei
  configureMemory(RAM_IO_RAM)
  disableNMI()
  disableCIAInterrupts() 
  cli
  rts
}

unpackData: {
  // copy chargen
  pushParamW(beginOfChargen)
  pushParamW(CHARGEN_ADDR)
  pushParamW(endOfChargen - beginOfChargen)
  jsr copyLargeMemForward
  // copy sprites
  pushParamW(beginOfSprites)
  pushParamW(SPRITE_ADDR)
  pushParamW(endOfSprites - beginOfSprites)
  jsr copyLargeMemForward
  
  rts
}
// ---- END: general configuration ----

// ---- graphics configuration ----
configureTitleVic2: {
  lda #BLACK
  sta BORDER_COL
  sta BG_COL_0
  setVideoMode(STANDARD_TEXT_MODE)
  setVICBank(3 - VIC_BANK)
  configureTextMemory(SCREEN_PAGE_0, CHARGEN)
  // turn on 40 columns visible
  lda CONTROL_2
  ora #%00001000
  sta CONTROL_2
  rts
}

configureIngameVic2: {
  setVideoMode(MULTICOLOR_TEXT_MODE)
  setVICBank(3 - VIC_BANK)
  configureTextMemory(SCREEN_PAGE_0, CHARGEN)
  // turn on 38 columns visible
  lda CONTROL_2
  and #%11110111
  sta CONTROL_2
  rts
}

/*
 * In:  - A char code
 *      - X color code
 */
clearBothScreens: {
  sta charCode
  stx colorCode
  // clear page 0
  pushParamW(SCREEN_PAGE_ADDR_0)
  lda charCode
  jsr fillScreen
  // clear page 1
  pushParamW(SCREEN_PAGE_ADDR_1)
  lda charCode
  jsr fillScreen
  // set up playfield color to GREY
  pushParamW(COLOR_RAM)
  lda colorCode
  jsr fillScreen

  rts
  // private data
  charCode: .byte $00
  colorCode: .byte $00
}

prepareTitleScreen: {
  lda #32
  ldx #LIGHT_GRAY
  jsr clearBothScreens

  pushParamW(txt_title)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*3 + 14)
  jsr outText

  pushParamW(txt_subTitle)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*5 + 14)
  jsr outText

  pushParamW(txt_author)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 11)
  jsr outText

  pushParamW(txt_originalConcept)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*12 + 4)
  jsr outText

  pushParamW(txt_pressAnyKey)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*18 + 13)
  jsr outText

  rts
}

prepareLevelScreen: {
  lda #32
  ldx #LIGHT_GRAY
  jsr clearBothScreens

  pushParamW(txt_entering)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 15)
  jsr outText

  pushParamW(txt_getReady)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*12 + 15)
  jsr outText

  pushParamW(z_worldCounter)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 22)
  jsr outHexNibble

  pushParamW(z_levelCounter)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 24)
  jsr outHexNibble

  rts
}

prepareIngameScreen: {
  lda #32
  ldx #0
  jsr clearBothScreens
  // hires colors for status bar
  pushParamW(COLOR_RAM + 24*40)
  lda #WHITE
  ldx #40
  jsr fillMem

  rts
}

initDashboard: {
  pushParamW(txt_dashboard)
  pushParamW(SCREEN_PAGE_ADDR_0 + 24*40)
  jsr outText

  pushParamW(txt_dashboard)
  pushParamW(SCREEN_PAGE_ADDR_1 + 24*40)
  jsr outText

  rts
}

updateScoreOnDashboard: {
  .for (var i = 0; i < 3; i++) {
    pushParamW(z_score + i)
    pushParamW(SCREEN_PAGE_ADDR_0 + 24*40 + 27 - i*2)
    jsr outHex
  }
  .for (var i = 0; i < 3; i++) {
    pushParamW(z_score + i)
    pushParamW(SCREEN_PAGE_ADDR_1 + 24*40 + 27 - i*2)
    jsr outHex
  }
  rts
}

updateDashboard: {
  pushParamW(z_lives)
  pushParamW(SCREEN_PAGE_ADDR_0 + 24*40 + 7)
  jsr outHexNibble

  pushParamW(z_lives)
  pushParamW(SCREEN_PAGE_ADDR_1 + 24*40 + 7)
  jsr outHexNibble

  rts 
}
// ---- END: graphics configuration ----

// ---- level handling ----
.macro setUpWorld(levelCfg) {
 // set background & border color
  lda #levelCfg.BG_COLOR_0
  sta BG_COL_0
  lda #levelCfg.BG_COLOR_1
  sta BG_COL_1
  lda #levelCfg.BG_COLOR_2
  sta BG_COL_2
  lda #levelCfg.BORDER_COLOR
  sta BORDER_COL

  // copy level chargen
  sei
  configureMemory(RAM_RAM_RAM)
  pushParamW(levelCfg.CHARSET_ADDRESS)
  pushParamW(CHARGEN_ADDR + (endOfChargen - beginOfChargen))
  pushParamW(levelCfg.CHARSET_SIZE*8)
  jsr copyLargeMemForward
  configureMemory(RAM_IO_RAM)
  cli

  // copy tiles colors
  pushParamW(levelCfg.TILES_COLORS_ADDRESS)
  pushParamW(tileColors)
  pushParamW(levelCfg.TILES_SIZE)
  jsr copyLargeMemForward

  // copy tiles
  pushParamW(levelCfg.TILES_ADDRESS)
  pushParamW(tileDefinition)
  pushParamW(levelCfg.TILES_SIZE*4)
  jsr copyLargeMemForward

  rts
}

.macro setUpMap(mapAddress, mapWidth) {
  // set map definition pointer
  lda #<mapAddress
  sta z_map
  lda #>mapAddress
  sta z_map + 1

  // set map width
  lda #mapWidth
  sta z_width

  // set delta X
  lda #(1<<4)
  sta z_deltaX

  rts
}


setUpWorld1: setUpWorld(level1)
setUpMap1_1: setUpMap(level1.MAP_1_ADDRESS, level1.MAP_1_WIDTH)
setUpMap1_2: setUpMap(level1.MAP_2_ADDRESS, level1.MAP_2_WIDTH)

addScore: { addScore(); rts }
// ---- END: level handling ----


// ---- sprite handling ----
.macro setSpriteShape(spriteNum, shapeNum) {
  lda #shapeNum
  sta SCREEN_PAGE_ADDR_0 + 1024 - 8 + spriteNum
  sta SCREEN_PAGE_ADDR_1 + 1024 - 8 + spriteNum
}

showPlayer: {
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
  setSpriteShape(PLAYER_SPRITE_TOP, 128)
  setSpriteShape(PLAYER_SPRITE_TOP_OVL, 129)
  setSpriteShape(PLAYER_SPRITE_BOTTOM, 130)
  setSpriteShape(PLAYER_SPRITE_BOTTOM_OVL, 131)
  rts
}

showDeath: {
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
  setSpriteShape(PLAYER_SPRITE_TOP, 128 + 12)
  setSpriteShape(PLAYER_SPRITE_TOP_OVL, 128 + 12 + 1)
  rts
}

hidePlayers: {
  lda #0
  sta SPRITE_ENABLE
  rts
}

animate: {
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
// ---- END: sprite handling ----

// ---- IO handling ----
scanSpaceHit: {
  // set up data direction
  lda #$FF
  sta CIA1_DATA_DIR_A 
  lda #$00
  sta CIA1_DATA_DIR_B
  // SPACE for being pressed
  lda #%00011000
  sta CIA1_DATA_PORT_A
  lda CIA1_DATA_PORT_B
  sta z_keyPressed

  lda z_keyPressed
  and #%00010000
  rts
}

scanKeys: {
  lda z_delay
  beq scan
  dec z_delay
  beq scan
  jmp skip
  scan:

  jsr scanSpaceHit

  bne !+ 
  {
    lda z_mode
    bne !+
      lda #1 
      sta z_mode
      lda #0
      sta z_jumpFrame
    !:
    lda #MAX_DELAY
    sta z_delay
  }
  !:

  skip:
  rts
}
// ---- END: IO handling ----

// ---- Jump handling ----
performJump: {
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

updateSpriteY: {
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

  rts
}
// ---- END: Jump handling ----


// ---- Utility subroutines ----
 #import "common/lib/sub/copy-large-mem-forward.asm"
 #import "common/lib/sub/fill-screen.asm"
 #import "common/lib/sub/fill-mem.asm"
 #import "text/lib/sub/out-text.asm"
 #import "text/lib/sub/out-hex.asm"
 #import "text/lib/sub/out-hex-nibble.asm"

wait: {
  wait #10
  rts
}

handleDelay: {
  handleDelay()
  rts
}
// ---- END: Utility subroutines ----

// ---- Copper handling ----
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

startCopper: {
  startCopper(
    z_displayListPtr, 
    z_listPtr, 
    List().add(c64lib.IRQH_HSCROLL, c64lib.IRQH_JSR).lock())
  rts
}

stopCopper: {
  // TODO inconsistency, stopCopper shouldn't do rts inside, fix copper64 lib
  stopCopper()
}
// ---- END: Copper handling ----

// ---- Copper Tables ----
.align $100
_copperListStart:
// here we define layout of raster interrupt handlers
ingameCopperList:
    // here we set scroll register to 5, but in fact this value will be modified by scrollBackground routine
  hScroll:
    copperEntry(50, IRQH_HSCROLL, 5, 0)
    // here we do the actual scrolling
  scrollCode: 
    copperEntry(54, IRQH_JSR, <scrollBackground, >scrollBackground)
    // at the top we reset HScroll register to 0
    copperEntry(241, IRQH_HSCROLL, 0, 0)
    // here we do the page switching when it's time for this
    copperEntry(245, IRQH_JSR, <switchPages, >switchPages)
    // here we loop and so on, so on, for each frame
    copperLoop()

titleScreenCopperList:
    copperEntry(245, IRQH_JSR, <handleDelay, >handleDelay)
    // here we loop and so on, so on, for each frame
    copperLoop()
_copperListEnd:
.assert "Copper list must fit into single 256b page.", (_copperListEnd - _copperListStart)<256, true
// ---- END: Copper Tables ----

.align $100
tileColors:
  .fill 256, $0
mapOffsetsLo:
  .fill 256, 0
mapOffsetsHi:
  .fill 256, 0
tileDefinition:
  .fill 256*4, $0

// ---- Scrollable background handling ----
.var tilesCfg = Tile2Config()
.eval tilesCfg.bank = VIC_BANK
.eval tilesCfg.page0 = SCREEN_PAGE_0
.eval tilesCfg.page1 = SCREEN_PAGE_1
.eval tilesCfg.startRow = 0
.eval tilesCfg.endRow = 23
.eval tilesCfg.x = z_x
.eval tilesCfg.y = z_y
.eval tilesCfg.width = z_width
.eval tilesCfg.height = z_height
.eval tilesCfg.tileColors = tileColors
.eval tilesCfg.mapOffsetsLo = mapOffsetsLo
.eval tilesCfg.mapOffsetsHi = mapOffsetsHi
.eval tilesCfg.mapDefinitionPtr = z_map
.eval tilesCfg.tileDefinition = tileDefinition
.eval tilesCfg.lock()

checkCollisions: {
  cld
  lda #(PLAYER_X + X_COLLISION_OFFSET)
  lsr
  lsr
  lsr
  lsr
  tax
  lda #(PLAYER_Y + Y_COLLISION_OFFSET)
  sec
  sbc z_yPos
  lsr
  lsr
  lsr
  lsr
  tay
  decodeTile(tilesCfg)
  and #%10000000
  beq !+
    lda #GAME_STATE_KILLED
    sta z_gameState
  !:
  sta z_collisionTile
  rts
}

drawTile: drawTile(tilesCfg, SCREEN_PAGE_ADDR_0, COLOR_RAM)

initLevel: {
  lda #MAP_HEIGHT
  sta z_height
  
  // set phase to 0
  lda #PHASE_SHOW_0
  sta z_phase

  // set [x,y] = [0,0]
  lda #0
  sta z_x
  sta z_x + 1
  sta z_y
  sta z_y + 1

  // init animation
  lda #ANIMATION_WALK
  sta z_animationPhase
  lda #0
  sta z_animationFrame
  sta z_yPos
  sta z_jumpFrame
  
  // set key mode to 0
  lda #$00
  sta z_keyPressed
  sta z_mode

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

scrollBackground: {
  debugBorderStart()
  // test phase flags
  lda #1
  bit z_phase
  beq scrolling
    jmp end
  scrolling:
  bpl page0
  // we're on page 1
  page1: { 
      // if scrolling
      lda z_phase
      and #%11111110
      sta z_phase
      jmp page1To0
  }
  // we're on page 0
  page0: {
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
    lda #1
    bit z_phase
    bvc noSwitching
      // setup IRQ handler back to scrollColorRam
      lda #<scrollColorRam
      sta scrollCode + 2
      lda #>scrollColorRam
      sta scrollCode + 3
    noSwitching:
    debugBorderEnd()
    rts
}

scrollColorRam: {
  debugBorderEnd()
  _t2_shiftColorRamLeft(tilesCfg, 2)
  _t2_decodeColorRight(tilesCfg, COLOR_RAM)
  // setup IRQ handler back to scrollBackground
  lda #<scrollBackground
  sta scrollCode + 2
  lda #>scrollBackground
  sta scrollCode + 3
  debugBorderStart()
  rts
}

switchPages: {
  debugBorderStart()
  doSwitching:
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

  // increment X coordinate
  jsr incrementX

  // calculate scroll register
  lda z_x
  and #%01110000
  lsr
  lsr
  lsr
  lsr
  sta z_acc0

  // detect page switching phase
  lda z_acc0
  cmp #%00000111
  bne notSeven
    lda z_phase
    and #%11111110
    ora #%01000000
    sta z_phase
  notSeven:


  // check if we need to loop the background
  lda z_x + 1
  cmp #(level1.MAP_1_WIDTH-20)
  bne dontReset
    lda #0
    sta z_x + 1
  dontReset:

  // detect scrolling phase
  lda z_acc0
  bne notZero
    lda z_phase
    ora #%00000001
    sta z_phase
  notZero:

  // update scroll register for scrollable area
  sec
  cld
  lda #7
  sbc z_acc0
  sta hScroll + 2

  jsr updateDashboard
  jsr scanKeys
  jsr animate
  jsr performJump
  jsr updateSpriteY
  jsr handleDelay
  decrementScoreDelay()

  debugBorderEnd()
  rts
}
// ---- END: Scrollable background handling ----

// ---- DATA ----
.segment Data
jumpTable: generateJumpTable()
// ---- texts ----
// title screen
txt_title: .text "t-rex runner"; .byte $ff
txt_subTitle: .text "c64  edition"; .byte $ff
txt_author: .text "by  maciej malecki"; .byte $ff
txt_originalConcept: .text "based on google chrome easter egg"; .byte $ff
txt_pressAnyKey: .text "hit the button"; .byte $ff
// level start screen
txt_entering: .text "world  0-0"; .byte $ff
txt_getReady: .text "get ready!"; .byte $ff
// ingame screen
txt_dashboard: .text " lives 0         score 000000 hi 000000"; .byte $FF

// -- animations --
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

// ---- END:DATA ----

// ---- Sprites definition ----
.segment Sprites
beginOfSprites:
  #import "sprites/dino.asm"
  #import "sprites/death.asm"
endOfSprites:
.print "Sprites import size = " + (endOfSprites - beginOfSprites)
// ---- END: Sprites definition ----

// ---- chargen definition ----
.segment Charsets
beginOfChargen:
  // 0-63: letters, symbols, numbers
  #import "fonts/regular/base.asm"
endOfChargen:
.print "Chargen import size = " + (endOfChargen - beginOfChargen)
// ---- END: chargen definition ----
endOfTRex:


// print memory map summary
.macro memSummary(name, address) {
.print name + " = " + address + " ($" + toHexString(address, 4) + ")"
}

memSummary("       tile colors", tileColors)
memSummary("      mapOffsetsLo", mapOffsetsLo)
memSummary("      mapOffsetsHi", mapOffsetsHi)

memSummary("tiles definition 0", tileDefinition)

memSummary("SCREEN_PAGE_ADDR_0", SCREEN_PAGE_ADDR_0)
memSummary("SCREEN_PAGE_ADDR_1", SCREEN_PAGE_ADDR_1)
memSummary("      CHARGEN_ADDR", CHARGEN_ADDR)
memSummary("       SPRITE_ADDR", SPRITE_ADDR)

.print ("total size = " + (endOfTRex - start) + " bytes")
