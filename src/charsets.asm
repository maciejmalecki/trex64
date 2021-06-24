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
