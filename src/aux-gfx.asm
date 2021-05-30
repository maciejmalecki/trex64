#import "_segments.asm"
#importonce

.filenamespace c64lib

.var titleAttrs = LoadBinary("charset/game-logo-attr.bin")
.var titleMap = LoadBinary("charset/game-logo-map.bin")

.segment AuxGfx
beginOfTitleAttr:
  .fill titleAttrs.getSize(), titleAttrs.get(i)
endOfTitleAttr:
beginOfTitleMap:
  .fill titleMap.getSize(), titleMap.get(i) + 128
endOfTitleMap:
beginOfAuthorColorRainbow:
  .byte LIGHT_BLUE, BLUE, LIGHT_BLUE, LIGHT_BLUE, LIGHT_BLUE, WHITE, WHITE, WHITE, WHITE, LIGHT_BLUE, LIGHT_BLUE
endOfAuthorColorRainbow:
beginOfAuthor2ColorRainbow:
  .byte BLACK, DARK_GREY, DARK_GREY, GREY, GREY, LIGHT_GREY, LIGHT_GREY, WHITE, LIGHT_GREY, GREY,DARK_GREY
endOfAuthor2ColorRainbow:
