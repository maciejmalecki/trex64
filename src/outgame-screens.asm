#import "chipset/lib/mos6510.asm"

#import "_segments.asm"
#import "_zero_page.asm"
#import "_constants.asm"
#import "subroutines.asm"
#import "charsets.asm"
#import "aux-gfx.asm"
#import "data.asm"
#import "delays.asm"
#import "io.asm"
#import "music.asm"
#import "game-field.asm"

.filenamespace c64lib
.segment Code

configureTitleVic2: {
  lda #BLACK
  sta BORDER_COL
  sta BG_COL_0
  setVideoMode(STANDARD_TEXT_MODE)
  setVICBank(3 - VIC_BANK)
  configureTextMemory(SCREEN_PAGE_0, CHARGEN)
  // turn on 40 columns visible
  lda CONTROL_2
  ora #%00001000
  and #%11111000
  sta CONTROL_2
  lda CONTROL_1
  and #%11110000
  ora #%00001000
  sta CONTROL_1
  // copy inversed charset
  sei
  configureMemory(RAM_RAM_RAM)
  pushParamW(beginOfInversedChargen)
  pushParamW(CHARGEN_ADDR + (endOfChargen - beginOfChargen))
  pushParamW(endOfTitleScreenChargen - beginOfInversedChargen)
  jsr copyLargeMemForward
  configureMemory(RAM_IO_RAM)
  cli
  rts
}

doTitleScreen: {
  // reset keyboard readouts
  lda #0
  sta z_previousKeys
  sta z_currentKeys
  lda #TITLE_COLOR_CYCLE_DELAY
  sta z_colorCycleDelay

  lda #32
  ldx #YELLOW
  jsr clearBothScreens

  jsr configureTitleVic2
  jsr initSound
  jsr startTitleCopper
  jsr prepareTitleScreen
  endlessTitle:
    // scan keyboard
    jsr io_scanFunctionKeys
    lda z_previousKeys
    bne endlessTitle
    lda z_currentKeys
    and #KEY_F7
    bne startIngame
    lda z_currentKeys
    and #KEY_F1
    beq !+
      jsr toggleControls
      jmp endlessTitle
    !:
    lda z_currentKeys
    and #KEY_F5
    beq !+
      jsr toggleLevel
      jmp endlessTitle
    !:
    lda z_currentKeys
    and #KEY_F3
    beq !+
      jsr toggleSound
      jmp endlessTitle
    !:
    jmp endlessTitle
  startIngame:
  jsr dly_wait10
  jsr stopCopper
  rts
}

toggleControls: {
  jsr io_toggleControls
  jsr drawConfig
  rts
}

toggleSound: {
  lda z_gameConfig
  eor #CFG_SOUND
  sta z_gameConfig
  jsr drawConfig
  rts
}

toggleLevel: {
  inc z_startingLevel
  lda z_startingLevel
  cmp #4
  bne !+
    lda #1
    sta z_startingLevel
  !:
  jsr drawConfig
  rts
}

prepareTitleScreen: {
  // decode coloring for logo
  .for (var line = 0; line < 10; line++) {
    ldx #0
    nextChar:
      lda (beginOfTitleMap + line*40),x
      and #$7F
      tay
      lda beginOfTitleAttr,y
      sta COLOR_RAM + 40*(LOGO_TOP + line),x
      inx
      cpx #40
    bne nextChar
  }

  // set up colors for title
  {
    ldy #0
    nextChar:
      ldx #(endOfAuthorColorRainbow - beginOfAuthorColorRainbow)
      nextColor:
        lda beginOfAuthorColorRainbow - 1, x
        sta COLOR_RAM + (40*AUTHOR_TOP), y
        iny
        cpy #40
        beq end
        dex
      bne nextColor
    jmp nextChar
    end:
  }

  {
    ldy #0
    nextChar:
      ldx #(endOfAuthor2ColorRainbow - beginOfAuthor2ColorRainbow)
      nextColor:
        lda beginOfAuthor2ColorRainbow - 1, x
        sta COLOR_RAM + (40*(AUTHOR_TOP + 2)), y
        iny
        cpy #40
        beq end
        dex
      bne nextColor
    jmp nextChar
    end:
  }

  pushParamW(beginOfTitleMap)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*LOGO_TOP)
  pushParamW(400)
  jsr copyLargeMemForward

  pushParamW(txt_author)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*AUTHOR_TOP + 10)
  jsr outText

  pushParamW(txt_originalConcept)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(AUTHOR_TOP + 2) + 4)
  jsr outText

  pushParamW(txt_controls)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*MENU_TOP + 6)
  jsr outText
  pushParamW(txt_sound)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(MENU_TOP + 1) + 6)
  jsr outText
  pushParamW(txt_startingLevel)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(MENU_TOP + 2) + 6)
  jsr outText
  pushParamW(txt_startGame)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(MENU_TOP + 3) + 6)
  jsr outText

  jsr drawConfig
  rts
}


prepareLevelScreen: {
  lda #(32 + 64)
  ldx #BLACK
  jsr clearBothScreens

  pushParamW(txt_entering)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 15)
  jsr outText

  pushParamW(txt_getReady)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*12 + 15)
  jsr outText

  pushParamW(z_worldCounter)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 22)
  jsr outHexNibbleInversed

  pushParamW(z_levelCounter)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 24)
  jsr outHexNibbleInversed

  rts
}

prepareEndGameScreen: {

  pushParamW(txt_endGame1)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 12)
  jsr outText

  pushParamW(txt_endGame2)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*12 + 7)
  jsr outText

  pushParamW(txt_pressAnyKey)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*15 + 13)
  jsr outText

  rts
}

drawConfig: {
  // controls
  lda z_gameConfig
  and #CFG_CONTROLS
  beq keys
    pushParamW(txt_controlsJoy)
    jmp controlMethodSelected
  keys:
    pushParamW(txt_controlsKey)
  controlMethodSelected:
    pushParamW(SCREEN_PAGE_ADDR_0 + 40*MENU_TOP + 21)
    jsr outText
  // sound
  lda z_gameConfig
  and #CFG_SOUND
  beq soundFx
    pushParamW(txt_soundMus)
    jmp soundSelected
  soundFx:
    pushParamW(txt_soundFx)
  soundSelected:
    pushParamW(SCREEN_PAGE_ADDR_0 + 40*(MENU_TOP + 1) + 21)
    jsr outText
  // starting level
  pushParamW(z_startingLevel)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(MENU_TOP + 2) + 23)
  jsr outHexNibble

  rts
}
