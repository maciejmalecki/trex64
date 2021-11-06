/*
  MIT License

  Copyright (c) 2021 Maciej Malecki

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/
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
.label SPRITE_SHAPES_START = 128

.label VIC_MEMORY_START = VIC_BANK * toBytes(16)
.label SCREEN_PAGE_ADDR_0 = VIC_MEMORY_START + SCREEN_PAGE_0 * toBytes(1)
.label SCREEN_PAGE_ADDR_1 = VIC_MEMORY_START + SCREEN_PAGE_1 * toBytes(1)
.label CHARGEN_ADDR = VIC_MEMORY_START + CHARGEN * toBytes(2)
.label SPRITE_ADDR = VIC_MEMORY_START + SPRITE_SHAPES_START*64
