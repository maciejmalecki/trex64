#import "chipset/lib/cia.asm"
#import "_zero_page.asm"
#import "_constants.asm"
#import "_segments.asm"

.filenamespace c64lib

.segment Code
io_toggleControls: {
  lda z_gameConfig
  and #CFG_CONTROLS
  beq joy
    // switch joy -> keyb
    lda #<io_scanSpaceHit
    sta io_scanKeys.handler
    lda #>io_scanSpaceHit
    sta io_scanKeys.handler + 1
    jmp end
  joy:
    // switch keyb -> joy
    lda #<io_scanJoy
    sta io_scanKeys.handler
    lda #>io_scanJoy
    sta io_scanKeys.handler + 1
  end:
    // toggle control config bit
    lda z_gameConfig
    eor #CFG_CONTROLS
    sta z_gameConfig
  rts
}

io_scanSpaceHit: {
  // set up data direction
  lda #$FF
  sta CIA1_DATA_DIR_A 
  lda #$00
  sta CIA1_DATA_DIR_B
  // SPACE for being pressed
  lda #%01111111
  sta CIA1_DATA_PORT_A
  lda CIA1_DATA_PORT_B
  and #%00010000
  rts
}

io_scanFunctionKeys: {
  // copy current state to previous state
  lda z_currentKeys
  sta z_previousKeys
  // set up data direction
  lda #$FF
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
  lda #$00
  sta CIA1_DATA_DIR_A
  lda CIA1_DATA_PORT_A
  and #$01
  rts
}

io_scanKeys: {
  lda z_delay
  beq scan
  dec z_delay
  beq scan
  jmp skip
  scan:

  jsr handler:io_scanJoy

  bne !+ 
  {
    lda z_mode
    bne !+
      lda #1 
      sta z_mode
      lda #0
      sta z_jumpFrame
    !:
    lda #MAX_DELAY
    sta z_delay
  }
  !:

  skip:
  rts
}
