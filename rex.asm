#define VISUAL_DEBUG
#import "common/lib/mem.asm"
#import "common/lib/invoke.asm"
#import "chipset/lib/sprites.asm"
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2.asm"
#import "chipset/lib/cia.asm"
#import "text/lib/text.asm"
#import "text/lib/tiles-2x2.asm"
#import "copper64/lib/copper64.asm"

.filenamespace c64lib


// ZERO page
.label z_x = 2                // $02,$03
.label z_y = 4                // $04,$05
.label z_width = 6            // $06
.label z_height = 7           // $07
.label z_map = 8              // $08, $09
.label z_phase = 10           // $0A
.label z_listPtr = 11         // $0B
.label z_displayListPtr = 12  // $0C,$0D
.label z_deltaX = 14          // $0E
.label z_acc0 = 15            // $0F
.label z_keyPressed = 16      // $10
.label z_mode = 17            // $11
.label z_delay = 18           // $12
.label z_animationPhase = 19  // $13
.label z_animationFrame = 20  // $14

.label VIC_BANK = 3
.label SCREEN_PAGE_0 = 0
.label SCREEN_PAGE_1 = 1
.label CHARGEN = 1

// player
.label PLAYER_SPRITE_TOP_OVL = 0
.label PLAYER_SPRITE_TOP = 1
.label PLAYER_SPRITE_BOTTOM_OVL = 2
.label PLAYER_SPRITE_BOTTOM = 3
.label PLAYER_COL = $0  // overlay color
.label PLAYER_COL0 = $5 // multi individual
.label PLAYER_COL1 = $9 // multi color 0
.label PLAYER_COL2 = $8 // multi color 1
.label PLAYER_X = 80
.label PLAYER_Y = 175
.label PLAYER_BOTTOM_Y = PLAYER_Y + 21
// animation phases
.label ANIMATION_WALK = 1
.label ANIMATION_JUMP_UP = 2
.label ANIMATION_JUMP_DOWN = 3
.label ANIMATION_DELAY = 4

.label TILES_COUNT = 256
.label MAP_WIDTH = 40

.label MAX_DELAY = 10

.label SPRITE_SHAPES_START = 128

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

/*
  VIC memory layout (16kb):
  - $0000 ($C000-$C3FF) - SCREEN_PAGE_0
  - $0400 ($C400-$C7FF) - SCREEN_PAGE_1
  - $0800 ($C800-$CFFF) - CHARGEN
  -       ($D000-$DFFF) - I/O space
  - $2000 ($E000)       - sprite data
 */

.label VIC_MEMORY_START = VIC_BANK * toBytes(16)
.label SCREEN_PAGE_ADDR_0 = VIC_MEMORY_START + SCREEN_PAGE_0 * toBytes(1)
.label SCREEN_PAGE_ADDR_1 = VIC_MEMORY_START + SCREEN_PAGE_1 * toBytes(1)
.label CHARGEN_ADDR = VIC_MEMORY_START + CHARGEN * toBytes(2)
.label SPRITE_ADDR = VIC_MEMORY_START + $2000

.var tileData = LoadBinary("background/level-1-tiles.bin")

.pc = $0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// -------- Main program ---------
.pc = $0810 "Program"

start:
  jsr configureC64
  jsr prepareScreen
  jsr configureVic2
  jsr unpackData
  jsr init
  jsr initBackground
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
  // set background & border color
  lda #$06
  sta BG_COL_0
  lda #LIGHT_GREY
  sta BG_COL_1
  lda #LIGHT_BLUE
  sta BG_COL_2
  lda #LIGHT_BLUE
  sta BORDER_COL
  // turn on 38 columns visible
  lda CONTROL_2
  and #%11110111
  sta CONTROL_2
  rts
}

init: {
  lda #ANIMATION_WALK
  sta z_animationPhase
  lda #0
  sta z_animationFrame
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
  pushParamW(z_mode)
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
  pushParamW(z_mode)
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
  // scan F7 and SPACE for being pressed
  lda #%00011000
  sta CIA1_DATA_PORT_A
  lda CIA1_DATA_PORT_B
  sta z_keyPressed

  and #%00001000
  bne !+
    lda z_mode
    eor #1
    sta z_mode
    lda #MAX_DELAY
    sta z_delay
  !:

  lda z_keyPressed
  and #%00010000
  bne !+ 
  {
    lda z_mode
    beq !+
      jsr incrementX
    !:
    lda #MAX_DELAY
    sta z_delay
  }
  !:

  skip:
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
    copperEntry(0, IRQH_HSCROLL, 0, 0)
    // here we set scroll register to 5, but in fact this value will be modified by scrollBackground routine
  hScroll:
    copperEntry($3A, IRQH_HSCROLL, 5, 0)
    // here we do the actual scrolling
  scrollCode: 
    copperEntry($3F, IRQH_JSR, <scrollBackground, >scrollBackground)
    // here we do the page switching when it's time for this
    copperEntry(250, IRQH_JSR, <switchPages, >switchPages)
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
  .import binary "background/level-1-tiles-colors.bin"
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

initBackground: {
  // set map definition pointer
  lda #<mapDefinition
  sta z_map
  lda #>mapDefinition
  sta z_map + 1
  // set map dimensions
  lda #MAP_WIDTH
  sta z_width
  lda #12
  sta z_height
  // set [x,y] = [0,0]
  lda #0
  sta z_x
  sta z_x + 1
  sta z_y
  sta z_y + 1
  // set delta X
  lda #(1<<4)
  sta z_deltaX
  // set phase to 0
  lda #PHASE_SHOW_0
  sta z_phase
  // set key mode to 0
  lda #$00
  sta z_keyPressed
  sta z_mode
  // set max delay
  lda #MAX_DELAY
  sta z_delay

  // initialize tile2 system
  tile2Init(tilesCfg)
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
  lda z_mode
  bne !+
    jsr incrementX
  !:

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
  cmp #(MAP_WIDTH-20)
  bmi dontReset
    lda #0
    sta z_x + 1
  dontReset:

  // detect scrolling phase
  /*
  lda z_acc0
  bne notZero
    lda z_phase
    ora #%00000001
    sta z_phase
  notZero:
  */

  // update scroll register for scrollable area
  sec
  lda #7
  sbc z_acc0
  sta hScroll + 2

  jsr updateDashboard
  jsr scanKeys
  jsr animate

  debugBorderEnd()
  rts
}

// -- map definition --
mapDefinition: // 40 x 12
  .import binary "background/level-1-map.bin"

// ------------------- DATA ---------------------------

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

// -- chargen definition --
beginOfChargen:
  // 0-63: letters, symbols, numbers
  #import "fonts/regular/base.asm"
afterOfChargen:

.print "Import size = " + (afterOfChargen - beginOfChargen)
  // 64-128: playfield graphics
  .import binary "background/level-1-charset.bin"

endOfChargen:
endOfTRex:

// print memory map summary

.macro memSummary(name, address) {
.print name + " = " + address + " ($" + toHexString(address, 4) + ")"
}

memSummary("SCREEN_PAGE_ADDR_0", SCREEN_PAGE_ADDR_0)
memSummary("SCREEN_PAGE_ADDR_1", SCREEN_PAGE_ADDR_1)
memSummary("      CHARGEN_ADDR", CHARGEN_ADDR)
memSummary("       SPRITE_ADDR", SPRITE_ADDR)

.print ("total size = " + (endOfTRex - start) + " bytes")
