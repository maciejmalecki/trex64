#import "text/lib/text.asm"
#import "chipset/lib/vic2.asm"
#import "copper64/lib/copper64.asm"

#import "_segments.asm"
#import "_zero_page.asm"
#import "_vic_layout.asm"
#import "charsets.asm"
#importonce

.filenamespace c64lib

.segment Code

 #import "common/lib/sub/copy-large-mem-forward.asm"
 #import "common/lib/sub/fill-screen.asm"
 #import "common/lib/sub/fill-mem.asm"
 #import "text/lib/sub/out-text.asm"
 #import "text/lib/sub/out-hex.asm"
 #import "text/lib/sub/out-hex-nibble.asm"

 outHexNibbleInversed: 
    outHexNibbleOfs(64)

screenOff: {
  lda CONTROL_1
  and #neg(CONTROL_1_DEN)
  sta CONTROL_1
  rts
}

screenOn: {
  lda CONTROL_1
  ora #CONTROL_1_DEN
  sta CONTROL_1
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

unpackChargen: {
  // copy chargen
  pushParamW(beginOfChargen)
  pushParamW(CHARGEN_ADDR)
  pushParamW(endOfChargen - beginOfChargen)
  jsr copyLargeMemForward
  rts
}
