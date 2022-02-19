/*
 MIT License

 Copyright (c) 2022 Maciej Malecki

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
#import "_vic_layout.asm"
#import "_zero_page.asm"
#import "_constants.asm"
#import "sprites.asm"
#import "charsets.asm"
#importonce

.filenamespace c64lib

// 48 -> 0, 49 -> -1 and so on...
.macro drawLoDigitOnSprite(spriteAddr, numberAddr, charsetAddr) {
  lda numberAddr
  and #%00001111
  asl
  asl
  asl
  tax
  ldy #0
  !:
    lda charsetAddr + 48*8,x
    sta spriteAddr,y
    inx
    iny
    iny
    iny
    cpy #(3*8)
  bne !-
}

.macro drawHiDigitOnSprite(spriteAddr, numberAddr, charsetAddr) {
  lda numberAddr
  and #%11110000
  lsr
  tax
  ldy #0
  !:
    lda charsetAddr + 48*8,x
    sta spriteAddr,y
    inx
    iny
    iny
    iny
    cpy #(3*8)
  bne !-
}

updateScoreOnDashboard: {
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 20, z_score, beginOfChargen)
  drawHiDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 19, z_score, beginOfChargen)
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 18, z_score + 1, beginOfChargen)
  drawHiDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 2)*64 + 20, z_score + 1, beginOfChargen)
  rts
}

updateHiScoreOnDashboard: {
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 20 + 3*8, z_hiScore, beginOfChargen)
  drawHiDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 19 + 3*8, z_hiScore, beginOfChargen)
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 18 + 3*8, z_hiScore + 1, beginOfChargen)
  drawHiDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 2)*64 + 20 + 3*8, z_hiScore + 1, beginOfChargen)
  rts
}

updateDashboard: {
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD)*64 + 20, z_lives, beginOfChargen)
  rts
}

// ---- BEGIN: dashboard ----
.macro stashSprites(stash) {
  // stash
  .for (var i = 0; i < 8; i++) {
    lda SPRITE_4_X + i
    sta stash + i
  }
  .for (var i = 0; i < 4; i++) {
    lda SPRITE_4_COLOR + i
    sta stash + 8 + i
  }
  lda SPRITE_MSB_X
  sta stash + 12
  lda SPRITE_ENABLE
  sta stash + 13
  lda SPRITE_COL_MODE
  sta stash + 14

  .for (var i = 0; i < 4; i++) {
    lda SCREEN_PAGE_ADDR_0 + 1020 + i
    sta stash + 15 + i
  }
  .for (var i = 0; i < 4; i++) {
    lda SCREEN_PAGE_ADDR_1 + 1020 + i
    sta stash + 19 + i
  }

  // setup
  lda #DASHBOARD_Y
  sta SPRITE_4_Y
  sta SPRITE_5_Y
  sta SPRITE_6_Y
  sta SPRITE_7_Y
  lda #DASHBOARD_LEFT_X
  sta SPRITE_4_X
  lda #DASHBOARD_RIGHT_X
  sta SPRITE_5_X
  lda #(DASHBOARD_RIGHT_X + 24 + DASHBOARD_RIGHT_SPC)
  sta SPRITE_6_X
  lda #(DASHBOARD_RIGHT_X + 48 + DASHBOARD_RIGHT_SPC)
  sta SPRITE_7_X
  lda SPRITE_MSB_X
  and #%11101111
  ora #%11100000
  sta SPRITE_MSB_X
  lda SPRITE_COL_MODE
  and #%00001111
  sta SPRITE_COL_MODE
  lda #WHITE
  .for(var i = 0; i < 4; i++) {
    sta SPRITE_4_COLOR + i
  }
  // sprite shapes
  .for(var i = 0; i < 4; i++) {
    lda #(SPRITE_SHAPES_START + SPR_DASHBOARD + i)
    sta SCREEN_PAGE_ADDR_0 + 1020 + i
    sta SCREEN_PAGE_ADDR_1 + 1020 + i
  }
  lda SPRITE_ENABLE
  ora #%11110000
  sta SPRITE_ENABLE

  lda #1
  sta z_spritesStashed
}

.macro popSprites(stash) {
  lda z_spritesStashed
  bne !+
    jmp end
  !:
  // pop
  lda SPRITE_ENABLE
  and #%00001111
  sta SPRITE_ENABLE
  .for (var i = 0; i < 8; i++) {
    lda stash + i
    sta SPRITE_4_X + i
  }
  .for (var i = 0; i < 4; i++) {
    lda stash + 8 + i
    sta SPRITE_4_COLOR + i
  }
  lda stash + 12
  sta SPRITE_MSB_X
  lda stash + 14
  sta SPRITE_COL_MODE
  .for (var i = 0; i < 4; i++) {
    lda stash + 15 + i
    sta SCREEN_PAGE_ADDR_0 + 1020 + i
  }
  .for (var i = 0; i < 4; i++) {
    lda stash + 19 + i
    sta SCREEN_PAGE_ADDR_1 + 1020 + i
  }
  lda stash + 13
  sta SPRITE_ENABLE
  lda #0
  sta z_spritesStashed
  end:
}

// ---- END: dashboard ----
