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

.label VIC_BANK = 3
.label SCREEN_PAGE_0 = 0
.label SCREEN_PAGE_1 = 1
.label CHARGEN = 1

.label PLAYER_SPRITE = 0
.label PLAYER_COL = DARK_GREY
.label PLAYER_X = 80
.label PLAYER_Y = 180

.label TILES_COUNT = 4
.label MAP_WIDTH = 40

.label MAX_DELAY = 10

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

.pc = $0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// -------- Main program ---------
.pc = $0810 "Program"

start:
  jsr configureC64
  jsr prepareScreen
  jsr configureVic2
  jsr unpackData
  jsr initBackground
  jsr initDashboard
  jsr showPlayer
  jsr startCopper
  
endless:
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
  setVideoMode(STANDARD_TEXT_MODE)
  setVICBank(3 - VIC_BANK)
  configureTextMemory(SCREEN_PAGE_0, CHARGEN)
  // set background & border color
  lda #WHITE
  sta BG_COL_0
  lda #LIGHT_BLUE
  sta BORDER_COL
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
  lda #GREY
  jsr fillScreen

  rts
}

showPlayer: {
  lda #PLAYER_X
  sta spriteXReg(PLAYER_SPRITE)
  lda #PLAYER_Y
  sta spriteYReg(PLAYER_SPRITE)
  lda #PLAYER_COL
  sta spriteColorReg(PLAYER_SPRITE)
  lda #spriteMask(PLAYER_SPRITE)
  sta SPRITE_EXPAND_X
  sta SPRITE_EXPAND_Y
  sta SPRITE_ENABLE
  lda #128
  sta SCREEN_PAGE_ADDR_0 + 1024 - 8
  sta SCREEN_PAGE_ADDR_1 + 1024 - 8
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
  pushParamW(SCREEN_PAGE_ADDR_0 + 30)
  jsr outText

  pushParamW(page1Mark)
  pushParamW(SCREEN_PAGE_ADDR_1 + 30)
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

  pushParamW(z_x)
  pushParamW(SCREEN_PAGE_ADDR_1 + 6)
  jsr outHex
  pushParamW(z_x + 1)
  pushParamW(SCREEN_PAGE_ADDR_1 + 8)
  jsr outHex
  pushParamW(z_mode)
  pushParamW(SCREEN_PAGE_ADDR_1 + 24)
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
  dec z_delay
  beq scan
  jmp skip
  scan:
  lda #MAX_DELAY
  sta z_delay

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
  !:

  lda z_keyPressed
  and #%00010000
  bne !+ 
  {
    lda z_mode
    beq !+
      jsr incrementX
    !:
  }
  !:

  skip:
  rts
}

 #import "common/lib/sub/copy-large-mem-forward.asm"
 #import "common/lib/sub/fill-screen.asm"
 #import "text/lib/sub/out-text.asm"
 #import "text/lib/sub/out-hex.asm"
 
// ------------------- Background ----------------------

.align $100
copperList:
            copperEntry(0, IRQH_HSCROLL, 0, 0)
  hScroll:  copperEntry($3A, IRQH_HSCROLL, 5, 0)
            copperEntry($3F, IRQH_JSR, <scrollBackground, >scrollBackground)
            copperLoop()

dashboard:
  .text "xpos:$0000 ph:$00 mode:$00"; .byte $FF
page0Mark:
  .text "#0"; .byte $FF
page1Mark:
  .text "#1"; .byte $FF

.align $100
tileColors:
  .fill 256, DARK_GREY
mapOffsetsLo:
  .fill 256, 0
mapOffsetsHi:
  .fill 256, 0
tileDefinition0:
  .byte $45,$45,$45,$40; .fill 256 - TILES_COUNT, 0
tileDefinition1:
  .byte $45,$45,$45,$41; .fill 256 - TILES_COUNT, 0
tileDefinition2:
  .byte $45,$43,$44,$42; .fill 256 - TILES_COUNT, 0
tileDefinition3:
  .byte $45,$43,$43,$43; .fill 256 - TILES_COUNT, 0

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
  // debug indicator
  inc BORDER_COL

  // increment X coordinate
  lda z_mode
  bne !+
    jsr incrementX
  !:

  // test phase flags
  lda #1
  bit z_phase
  bpl page0
  page1: { 
    beq notScrolling
    // if scrolling
    lda z_phase
    and #%11111110
    sta z_phase
    jmp page1To0
    notScrolling: {
      // if do not switch the page
      bvc endSwitch
      // if switch the page
      and #%00111111
      sta z_phase
      jmp switch1To0
    }
  }
  page0: {
    beq notScrolling
    // if scrolling
    lda z_phase
    and #%11111110
    sta z_phase
    jmp page0To1
    notScrolling: {
      // if do not switch the page
      bvc endSwitch
      // if switch the page
      and #%00111111
      ora #%10000000
      sta z_phase
      jmp switch0To1
    }
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
    jmp end
  page0To1:
    _t2_shiftScreenLeft(tilesCfg, 0, 1)
    jmp end
  page1To0:
    _t2_shiftScreenLeft(tilesCfg, 1, 0)
  end:

  // check if we need to loop the background
  lda z_x + 1
  cmp #(MAP_WIDTH-20)
  bmi dontReset
    lda #0
    sta z_x + 1
  dontReset:
  // set scroll register
  lda z_x
  and #%01110000
  lsr
  lsr
  lsr
  lsr
  sta z_acc0
  cmp #%00000111
  bne notSeven
    lda z_phase
    ora #%01000000
    sta z_phase
  notSeven:
  // scroll register
  lda z_acc0
  bne notZero
    lda z_phase
    ora #%00000001
    sta z_phase
  notZero:

  sec
  lda #7
  sbc z_acc0
  sta hScroll + 2

  dec BORDER_COL

  jsr updateDashboard
  jsr scanKeys

  rts
}

// -- map definition --
mapDefinition: // 40 x 12
  .fill 40, 0 // 01
  .fill 40, 0 // 02
  .fill 40, 0 // 03
  .fill 40, 0 // 04
  .fill 40, 0 // 05
  .fill 40, 0 // 06
  .fill 40, 0 // 07
  .fill 40, 0 // 08
  .fill 40, 0 // 09
  .byte 1,1,2,1,1,2,3,1,1,2,1,3,1,3,1,2,3,1,2,2,1,3,3,1,3,1,2,1,3,1,1,2,2,1,2,3,3,3,2,1
  .fill 40, 0 // 11
  .fill 40, 0 // 12

// ------------------- DATA ---------------------------

// -- Sprites definition --
beginOfSprites:
  sh("................#######.")//1
  sh("...............##.######")//2
  sh("...............#########")//3
  sh("...............####.....")//4
  sh("...............#######..")//5
  sh("...............####.....")//6
  sh("#..............####.....")//7
  sh("#.............#####.....")//8
  sh("##...........#####......")//9
  sh("##..........##########..")//10
  sh(".##........########..#..")//11
  sh(".##.......#########.....")//12
  sh(".##......##########.....")//13
  sh(".###....###########.....")//14
  sh(".###..#############.....")//15
  sh("..#################.....")//16
  sh("...###############......")//17
  sh(".........##....##.......")//18
  sh(".........##....##.......")//19
  sh(".........####..##.......")//20
  sh("...............####.....")//21
  .byte 0

  sh("................#######.")//1
  sh("...............##.######")//2
  sh("...............#########")//3
  sh("...............####.....")//4
  sh("...............#######..")//5
  sh("...............####.....")//6
  sh("#..............####.....")//7
  sh("#.............#####.....")//8
  sh("##...........#####......")//9
  sh("##..........##########..")//10
  sh(".##........########..#..")//11
  sh(".##.......#########.....")//12
  sh(".##......##########.....")//13
  sh(".###....###########.....")//14
  sh(".###..#############.....")//15
  sh("..#################.....")//16
  sh("...###############......")//17
  sh(".........##....##.......")//18
  sh(".........##....##.......")//19
  sh(".........##....####.....")//20
  sh(".........####...........")//21
  .byte 0
endOfSprites:

// -- chargen definition --
beginOfChargen:
  // 0-63: letters, symbols, numbers
  #import "fonts/regular/base.asm"

afterOfChargen:

.print "Import size = " + (afterOfChargen - beginOfChargen)

  // 64-128: playfield graphics

  // $40 64
  ch("...##...")//1
  ch("..####..")//2
  ch(".######.")//3
  ch("..####..")//4
  ch(".#######")//5
  ch("..######")//6
  ch(".#######")//7
  ch("..####..")//8
  // $41 65
  ch("........")//1
  ch("..#.....")//2
  ch(".###....")//3
  ch(".####...")//4
  ch("####....")//5
  ch("###.....")//6
  ch("##......")//7
  ch("........")//8
  // $42 66
  ch(".######.")//1
  ch("..####..")//2
  ch(".######.")//3
  ch("..####..")//4
  ch("########")//5
  ch("..####..")//6
  ch("..####..")//7
  ch("........")//8
  // $43 67
  ch("........")//1
  ch("........")//2
  ch("........")//3
  ch("........")//4
  ch("########")//5
  ch("........")//6
  ch("........")//7
  ch("........")//8
  // $44 68
  ch("........")//1
  ch("........")//2
  ch("........")//3
  ch("........")//4
  ch("########")//5
  ch("...###..")//6
  ch("..##....")//7
  ch("..#.....")//8
  // $45 69
  ch("........")//1
  ch("........")//2
  ch("........")//3
  ch("........")//4
  ch("........")//5
  ch("........")//6
  ch("........")//7
  ch("........")//8
  // $46 70
  ch("........")//1
  ch("........")//2
  ch("........")//3
  ch("........")//4
  ch("........")//5
  ch("........")//6
  ch("........")//7
  ch("........")//8
  // $47 71
  ch("........")//1
  ch("........")//2
  ch("........")//3
  ch("........")//4
  ch("........")//5
  ch("........")//6
  ch("........")//7
  ch("........")//8

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
