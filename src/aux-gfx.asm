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
