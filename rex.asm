#import "common/lib/mem.asm"
#import "common/lib/invoke.asm"
#import "chipset/lib/sprites.asm"
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2.asm"
#import "chipset/lib/cia.asm"
#import "text/lib/text.asm"
#import "copper64/lib/copper64.asm"

.filenamespace c64lib

.label VIC_BANK = 3
.label SCREEN_PAGE_0 = 0
.label SCREEN_PAGE_1 = 1
.label CHARGEN = 1

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
  pushParamW(SCREEN_PAGE_ADDR_0)
  lda #32
  jsr fillScreen

  pushParamW(SCREEN_PAGE_ADDR_1)
  lda #32
  jsr fillScreen

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

 #import "common/lib/sub/copy-large-mem-forward.asm"
 #import "common/lib/sub/fill-screen.asm"


// ------------------- DATA ---------------------------


// -- Sprites definition --
beginOfSprites:
  sh("................#######.")//1
  sh("...............##.######")//2
  sh("...............#########")//3
  sh("...............####.....")//4
  sh("...............#######..")//5
  sh("#.............#####.....")//6
  sh("#............######.....")//7
  sh("#...........##########..")//8
  sh(".#.........########..#..")//9
  sh(".##.....###########.....")//10
  sh(".##...#############.....")//11
  sh("..#################.....")//12
  sh("...###############......")//13
  sh(".........##....##.......")//14
  sh(".........####..##.......")//15
  sh("...............####.....")//16
  sh("........................")//17
  sh("........................")//18
  sh("........................")//19
  sh("........................")//20
  sh("........................")//21
  .byte 0

  sh("................#######.")//1
  sh("...............##.######")//2
  sh("...............#########")//3
  sh("...............####.....")//4
  sh("...............#######..")//5
  sh("#.............#####.....")//6
  sh("#............######.....")//7
  sh("#...........##########..")//8
  sh(".#.........########..#..")//9
  sh(".##.....###########.....")//10
  sh(".##...#############.....")//11
  sh("..#################.....")//12
  sh("...###############......")//13
  sh(".........##....##.......")//14
  sh(".........##....####.....")//15
  sh(".........####...........")//16
  sh("........................")//17
  sh("........................")//18
  sh("........................")//19
  sh("........................")//20
  sh("........................")//21
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
  ch("..#..#..")//2
  ch(".##..##.")//3
  ch("..#..#..")//4
  ch(".##..###")//5
  ch("..#.....")//6
  ch(".##..###")//7
  ch("..#..#..")//8
  // $41 65
  ch("........")//1
  ch("..#.....")//2
  ch(".#.#....")//3
  ch(".#.##...")//4
  ch("#..#....")//5
  ch("..#.....")//6
  ch("##......")//7
  ch("........")//8
  // $42 66
  ch(".##..##.")//1
  ch("..#..#..")//2
  ch(".##..##.")//3
  ch("..#..#..")//4
  ch("###..###")//5
  ch("..#..#..")//6
  ch("..#..#..")//7
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