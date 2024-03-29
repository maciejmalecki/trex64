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
#import "chipset/lib/cia.asm"
#import "_zero_page.asm"
#import "_constants.asm"
#import "_segments.asm"
#importonce

.filenamespace c64lib

.segment Code
io_toggleControls: {
  lda z_gameConfig
  and #CFG_CONTROLS
  beq joy
    // switch joy -> keyb
    lda #<io_scanIngameKeys
    sta io_scanControls.handler
    lda #>io_scanIngameKeys
    sta io_scanControls.handler + 1
    jmp end
  joy:
    // switch keyb -> joy
    lda #<io_scanJoy
    sta io_scanControls.handler
    lda #>io_scanJoy
    sta io_scanControls.handler + 1
  end:
    // toggle control config bit
    lda z_gameConfig
    eor #CFG_CONTROLS
    sta z_gameConfig
  rts
}

io_scanIngameKeys: {
  // set up data direction
  lda #$ff
  sta CIA1_DATA_DIR_A
  lda #$00
  sta CIA1_DATA_DIR_B
  // F keys
  lda #%01111111
  sta CIA1_DATA_PORT_A
  lda CIA1_DATA_PORT_B
  and #KEY_INGAME_MASK
  eor #KEY_INGAME_MASK
  sta z_currentKeys
  rts
}

/*
 * Check Z after this subroutine: Z=0 -> no keys hit, Z=1 -> any key hit
 */
io_checkAnyKeyHit: {
  lda z_previousKeys
  bne !+
  lda z_currentKeys
  rts
  !:
  lda #0
  rts
}

io_checkJump: {
  lda z_currentKeys
  and #KEY_SPACE
  rts
}

/*
 * beq -> do ducking
 */
io_checkDoduck: {
  lda z_previousKeys
  and #KEY_COMMODORE
  // CBM pressed -> NZ -> end
  bne !+
  {
    lda z_currentKeys
    and #KEY_COMMODORE
    // NZ -> do duck, Z -> no do duck
    rts
  }
  !:
  // invert -> Z - no do duck
  eor #KEY_COMMODORE
  rts
}

/*
 * beq -> no unduck
 */
io_checkUnduck: {
  lda z_previousKeys
  and #KEY_COMMODORE
  // CBM depressed -> Z -> end ( no unduck)
  beq !+
  {
    lda z_currentKeys
    and #KEY_COMMODORE
    // Z -> unduck, NZ -> no unduck
    eor #KEY_COMMODORE // invert
    rts
  }
  !:
  rts
}

io_scanFunctionKeys: {
  // set up data direction
  lda #$ff
  sta CIA1_DATA_DIR_A
  lda #$00
  sta CIA1_DATA_DIR_B
  // F keys
  lda #%11111110
  sta CIA1_DATA_PORT_A
  lda CIA1_DATA_PORT_B
  and #KEY_FUNCTION_MASK
  eor #KEY_FUNCTION_MASK
  sta z_currentKeys
  rts
}

io_scanJoy: {
  // read joystick
  lda #$00
  sta CIA1_DATA_DIR_A
  lda CIA1_DATA_PORT_A
  and #%00010011
  eor #%00010011
  sta tmp
  and #%00010001
  bne fireOrUp
  lda tmp
  and #%00000010
  bne down
  lda #0
  sta z_currentKeys
  jmp end
  fireOrUp:
    lda z_currentKeys
    ora #KEY_SPACE
    sta z_currentKeys
    jmp end
  down:
    lda z_currentKeys
    ora #KEY_COMMODORE
    sta z_currentKeys
  end:
  rts
  tmp: .byte $00
}

io_resetControls: {
  lda #0
  sta z_previousKeys
  sta z_currentKeys
  rts
}

io_scanControls: {
  // copy current state to previous state
  lda z_currentKeys
  sta z_previousKeys
  // jump to dedicated handler
  jsr handler:io_scanJoy
  rts
}
