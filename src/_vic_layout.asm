#import "common/lib/common.asm"
#importonce
.filenamespace c64lib

/*
  VIC memory layout (16kb):
  - $0000 ($C000-$C3FF) - SCREEN_PAGE_0
  - $0400 ($C400-$C7FF) - SCREEN_PAGE_1
  - $0800 ($C800-$CFFF) - CHARGEN
  -       ($D000-$DFFF) - I/O space
  - $2000 ($E000)       - sprite data
 */
.label VIC_BANK = 3
.label SCREEN_PAGE_0 = 0
.label SCREEN_PAGE_1 = 1
.label CHARGEN = 1

.label VIC_MEMORY_START = VIC_BANK * toBytes(16)
.label SCREEN_PAGE_ADDR_0 = VIC_MEMORY_START + SCREEN_PAGE_0 * toBytes(1)
.label SCREEN_PAGE_ADDR_1 = VIC_MEMORY_START + SCREEN_PAGE_1 * toBytes(1)
.label CHARGEN_ADDR = VIC_MEMORY_START + CHARGEN * toBytes(2)
.label SPRITE_ADDR = VIC_MEMORY_START + $2000
