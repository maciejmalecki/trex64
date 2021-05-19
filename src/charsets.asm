#import "common/lib/common.asm"
#import "_segments.asm"

#importonce

.filenamespace c64lib

.var charset = LoadBinary("charset/charset.bin")
.var titleCharset = LoadBinary("charset/game-logo-chars.bin")

.segment Charsets
beginOfChargen:
  // 0-63: letters, symbols, numbers
  .fill charset.getSize(), charset.get(i)
endOfChargen:
beginOfInversedChargen:
  .fill charset.getSize(), neg(charset.get(i))
endOfInversedChargen:
beginOfTitleScreenChargen:
  .fill titleCharset.getSize(), titleCharset.get(i)
endOfTitleScreenChargen:

.print "Inversed chargen import size = " + (endOfInversedChargen - beginOfInversedChargen)
.print "Chargen import size = " + (endOfChargen - beginOfChargen)
.print "Title Screen Chargen import size = " + (endOfTitleScreenChargen - beginOfTitleScreenChargen)
