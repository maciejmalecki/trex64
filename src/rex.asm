#define VISUAL_DEBUG
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

#import "_segments.asm"
#import "_zero_page.asm"
#import "_sprites.asm"
#import "_vic_layout.asm"

#import "levels/levels.asm"
#import "physics.asm"

.filenamespace c64lib

.file [name="./rex.prg", segments="Code, Data, Charsets, LevelData, Sprites", modify="BasicUpstart", _start=$0810]

.label TILES_COUNT = 256
.label MAX_DELAY = 10
.label SPRITE_SHAPES_START = 128

.var tileData = LoadBinary("levels/level1/level-1-tiles.bin")
// levels
#import "levels/level1/level-1.asm"


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

start:
  jsr configureC64
  jsr prepareScreen
  jsr configureVic2
  jsr unpackData
  jsr setUpLevel1
  jsr init
  jsr initDashboard
  jsr showPlayer
  jsr startCopper
  
endless:
  // scan keyboard and joystick
  // jsr scanKeys

  jmp endless

// -------- Subroutines ----------
configureC64: {
  sei
  configureMemory(RAM_IO_RAM)
  disableNMI()
  disableCIAInterrupts() 
  cli
  rts
}

configureVic2: {
  setVideoMode(MULTICOLOR_TEXT_MODE)
  setVICBank(3 - VIC_BANK)
  configureTextMemory(SCREEN_PAGE_0, CHARGEN)
  // turn on 38 columns visible
  lda CONTROL_2
  and #%11110111
  sta CONTROL_2
  rts
}

.macro setUpLevel(levelCfg) {
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
  pushParamW(levelCfg.CHARSET_ADDRESS)
  pushParamW(CHARGEN_ADDR + (endOfChargen - beginOfChargen))
  pushParamW(levelCfg.CHARSET_SIZE)
  jsr copyLargeMemForward

  // set map definition pointer
  lda #<levelCfg.MAP_ADDRESS
  sta z_map
  lda #>levelCfg.MAP_ADDRESS
  sta z_map + 1

  // set map width
  lda #levelCfg.MAP_WIDTH
  sta z_width

  // set delta X
  lda #(1<<4)
  sta z_deltaX

  // do common level stuff
  jsr initLevel

  rts
}

setUpLevel1: setUpLevel(level1)

init: {
  lda #ANIMATION_WALK
  sta z_animationPhase
  lda #0
  sta z_animationFrame
  sta z_yPos
  sta z_jumpFrame
  rts
}

prepareScreen: {
  // clear page 0
  pushParamW(SCREEN_PAGE_ADDR_0)
  lda #32
  jsr fillScreen
  // clear page 1
  pushParamW(SCREEN_PAGE_ADDR_1)
  lda #32
  jsr fillScreen
  // set up playfield color to GREY
  pushParamW(COLOR_RAM)
  lda #0
  jsr fillScreen
  // hires colors for status bar
  pushParamW(COLOR_RAM)
  lda #WHITE
  ldx #40
  jsr fillMem

  rts
}

.macro setSpriteShape(spriteNum, shapeNum) {
  lda #shapeNum
  sta SCREEN_PAGE_ADDR_0 + 1024 - 8 + spriteNum
  sta SCREEN_PAGE_ADDR_1 + 1024 - 8 + spriteNum
}

showPlayer: {
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

startCopper: {
  lda #<copperList
  sta z_displayListPtr
  lda #>copperList
  sta z_displayListPtr + 1

  startCopper(
    z_displayListPtr, 
    z_listPtr, 
    List().add(c64lib.IRQH_HSCROLL, c64lib.IRQH_JSR).lock())
}

initDashboard: {
  pushParamW(dashboard)
  pushParamW(SCREEN_PAGE_ADDR_0)
  jsr outText

  pushParamW(page0Mark)
  pushParamW(SCREEN_PAGE_ADDR_0 + 37)
  jsr outText

  pushParamW(page1Mark)
  pushParamW(SCREEN_PAGE_ADDR_1 + 37)
  jsr outText

  pushParamW(dashboard)
  pushParamW(SCREEN_PAGE_ADDR_1)
  jsr outText

  rts
}

updateDashboard: {
  pushParamW(z_x)
  pushParamW(SCREEN_PAGE_ADDR_0 + 6)
  jsr outHex
  pushParamW(z_x + 1)
  pushParamW(SCREEN_PAGE_ADDR_0 + 8)
  jsr outHex
  pushParamW(z_jumpFrame)
  pushParamW(SCREEN_PAGE_ADDR_0 + 24)
  jsr outHex
  pushParamW(z_acc0)
  pushParamW(SCREEN_PAGE_ADDR_0 + 32)
  jsr outHex

  pushParamW(z_x)
  pushParamW(SCREEN_PAGE_ADDR_1 + 6)
  jsr outHex
  pushParamW(z_x + 1)
  pushParamW(SCREEN_PAGE_ADDR_1 + 8)
  jsr outHex
  pushParamW(z_jumpFrame)
  pushParamW(SCREEN_PAGE_ADDR_1 + 24)
  jsr outHex
  pushParamW(z_acc0)
  pushParamW(SCREEN_PAGE_ADDR_1 + 32)
  jsr outHex


  pushParamW(z_phase)
  pushParamW(SCREEN_PAGE_ADDR_0 + 15)
  jsr outHex

  pushParamW(z_phase)
  pushParamW(SCREEN_PAGE_ADDR_1 + 15)
  jsr outHex
  rts 
}

scanKeys: {
  lda z_delay
  beq scan
  dec z_delay
  beq scan
  jmp skip
  scan:

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

// -------------- utility subroutines ------------------
 #import "common/lib/sub/copy-large-mem-forward.asm"
 #import "common/lib/sub/fill-screen.asm"
 #import "common/lib/sub/fill-mem.asm"
 #import "text/lib/sub/out-text.asm"
 #import "text/lib/sub/out-hex.asm"
 
// ------------------- Background ----------------------

.align $100
// here we define layout of raster interrupt handlers
copperList:
    // at the top we reset HScroll register to 0
    copperEntry($31, IRQH_HSCROLL, 0, 0)
    // here we set scroll register to 5, but in fact this value will be modified by scrollBackground routine
  hScroll:
    copperEntry($39, IRQH_HSCROLL, 5, 0)
    // here we do the actual scrolling
  scrollCode: 
    copperEntry($3F, IRQH_JSR, <scrollBackground, >scrollBackground)
    // here we do the page switching when it's time for this
    copperEntry(280, IRQH_JSR, <switchPages, >switchPages)
    // here we loop and so on, so on, for each frame
    copperLoop()

dashboard:
  .text "xpos:$0000 ph:$00 mode:$00 scr:$00"; .byte $FF
page0Mark:
  .text "#0"; .byte $FF
page1Mark:
  .text "#1"; .byte $FF

.align $100
tileColors:
  .import binary "levels/level1/level-1-tiles-colors.bin"
mapOffsetsLo:
  .fill 256, 0
mapOffsetsHi:
  .fill 256, 0
tileDefinition0:
  .fill tileData.getSize() / 4, tileData.get(i*4) + 64
tileDefinition1:
  .fill tileData.getSize() / 4, tileData.get(i*4 + 1) + 64
tileDefinition2:
  .fill tileData.getSize() / 4, tileData.get(i*4 + 2) + 64
tileDefinition3:
  .fill tileData.getSize() / 4, tileData.get(i*4 + 3) + 64

// scrollable background configuration
.var tilesCfg = Tile2Config()
.eval tilesCfg.bank = VIC_BANK
.eval tilesCfg.page0 = SCREEN_PAGE_0
.eval tilesCfg.page1 = SCREEN_PAGE_1
.eval tilesCfg.startRow = 1
.eval tilesCfg.endRow = 24
.eval tilesCfg.x = z_x
.eval tilesCfg.y = z_y
.eval tilesCfg.width = z_width
.eval tilesCfg.height = z_height
.eval tilesCfg.tileColors = tileColors
.eval tilesCfg.mapOffsetsLo = mapOffsetsLo
.eval tilesCfg.mapOffsetsHi = mapOffsetsHi
.eval tilesCfg.mapDefinitionPtr = z_map
.eval tilesCfg.tileDefinition = tileDefinition0
.eval tilesCfg.lock()

drawTile: drawTile(tilesCfg, SCREEN_PAGE_ADDR_0, COLOR_RAM)

initLevel: {
  lda #12
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
  
  // set key mode to 0
  lda #$00
  sta z_keyPressed
  sta z_mode
  
  // set max delay
  lda #MAX_DELAY
  sta z_delay

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
    cpy #12
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
  cmp #(level1.MAP_WIDTH-20)
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
  lda #7
  sbc z_acc0
  sta hScroll + 2

  jsr updateDashboard
  jsr scanKeys
  jsr animate
  jsr performJump
  jsr updateSpriteY

  debugBorderEnd()
  rts
}

.segment Data
// ------------------- DATA ---------------
jumpTable: generateJumpTable()

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

// -- Sprites definition --
beginOfSprites:
  #import "sprites/dino.asm"
endOfSprites:
.print "Sprites import size = " + (endOfSprites - beginOfSprites)

// -- chargen definition --
beginOfChargen:
  // 0-63: letters, symbols, numbers
  #import "fonts/regular/base.asm"
endOfChargen:
.print "Chargen import size = " + (endOfChargen - beginOfChargen)


endOfTRex:

// print memory map summary

.macro memSummary(name, address) {
.print name + " = " + address + " ($" + toHexString(address, 4) + ")"
}

memSummary("       tile colors", tileColors)
memSummary("      mapOffsetsLo", mapOffsetsLo)
memSummary("      mapOffsetsHi", mapOffsetsHi)

memSummary("tiles definition 0", tileDefinition0)
memSummary("tiles definition 1", tileDefinition1)
memSummary("tiles definition 2", tileDefinition2)
memSummary("tiles definition 3", tileDefinition3)

memSummary("SCREEN_PAGE_ADDR_0", SCREEN_PAGE_ADDR_0)
memSummary("SCREEN_PAGE_ADDR_1", SCREEN_PAGE_ADDR_1)
memSummary("      CHARGEN_ADDR", CHARGEN_ADDR)
memSummary("       SPRITE_ADDR", SPRITE_ADDR)

.print ("total size = " + (endOfTRex - start) + " bytes")
