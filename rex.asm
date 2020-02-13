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


.label VIC_BANK = 3
.label SCREEN_PAGE_0 = 0
.label SCREEN_PAGE_1 = 1
.label CHARGEN = 1

.label PLAYER_SPRITE = 0
.label PLAYER_COL = DARK_GREY
.label PLAYER_X = 80
.label PLAYER_Y = 180

.label TILES_COUNT = 4

/*
 * VIC memory layout (16kb):
 * $0000 ($C000-$C3FF) - SCREEN_PAGE_0
 * $0400 ($C400-$C7FF) - SCREEN_PAGE_1
 * $0800 ($C800-$CFFF) - CHARGEN
 *       ($D000-$DFFF) - I/O space
 * $2000 ($E000)       - sprite data
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
    List().add(c64lib.IRQH_HSCROLL, c64lib.IRQH_JSR, c64lib.IRQH_BORDER_BG_0_COL).lock())
}

 #import "common/lib/sub/copy-large-mem-forward.asm"
 #import "common/lib/sub/fill-screen.asm"
 
// ------------------- Background ----------------------

.align $100
copperList:
            copperEntry(30, IRQH_BORDER_BG_0_COL, BLUE, 0)
            copperEntry(40, IRQH_BORDER_BG_0_COL, WHITE, 0)
  hScroll:  copperEntry(45, IRQH_HSCROLL, 5, 0)
            copperEntry(50, IRQH_JSR, <scrollBackground, >scrollBackground)
            copperEntry(255, IRQH_HSCROLL, 0, 0)
            copperLoop()

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
.eval tilesCfg.bank = 3 - VIC_BANK
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
  lda #40
  sta z_width
  lda #12
  sta z_height
  // set [x,y] = [0,0]
  lda #0
  sta z_x
  sta z_x + 1
  sta z_y
  sta z_y + 1
  // set phase to 0
  lda #0
  sta z_phase
  // initialize tile2 system
  tile2Init(tilesCfg)
  rts
}

scrollBackground: {
  inc BORDER_COL

  lda z_phase
  beq page0To1
  cmp #1
  beq switch0To1
  cmp #2
  beq _page1To0
  cmp #3
  beq switch1To0
  switch0To1:
    lda MEMORY_CONTROL
    and #00001111
    ora SCREEN_PAGE_1 << 4
    sta MEMORY_CONTROL
    jmp end
  switch1To0:
    lda MEMORY_CONTROL
    and #00001111
    ora SCREEN_PAGE_0 << 4
    sta MEMORY_CONTROL
    jmp end
  _page1To0: jmp page1To0
  page0To1:
    _t2_shiftScreenLeft(tilesCfg, 0, 1)
    _t2_decodeScreenRight(tilesCfg, 1)
    jmp end
  page1To0:
    _t2_shiftScreenLeft(tilesCfg, 1, 0)
    _t2_decodeScreenRight(tilesCfg, 0)
  end:
    inc z_phase
    lda z_phase
    cmp #4
    bne end2
      lda #0
      sta z_phase
    end2:

  dec BORDER_COL

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

// print memory map summary

.macro memSummary(name, address) {
  .print name + " = " + address + " ($" + toHexString(address, 4) + ")"
}

memSummary("SCREEN_PAGE_ADDR_0", SCREEN_PAGE_ADDR_0)
memSummary("SCREEN_PAGE_ADDR_1", SCREEN_PAGE_ADDR_1)
memSummary("      CHARGEN_ADDR", CHARGEN_ADDR)
memSummary("       SPRITE_ADDR", SPRITE_ADDR)