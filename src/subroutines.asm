#import "text/lib/text.asm"
#import "chipset/lib/vic2.asm"
#import "copper64/lib/copper64.asm"

#import "_segments.asm"
#import "_zero_page.asm"
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

