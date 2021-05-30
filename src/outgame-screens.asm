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

.importonce

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
  sta z_colorCycleDelay2

  lda #32
  ldx #BLACK
  jsr clearBothScreens

  jsr screenOff
  jsr configureTitleVic2
  lda #TITLE_TUNE
  jsr initSound
  jsr screenOn
  jsr prepareTitleScreen
  jsr startTitleCopper
  endlessTitle:
    // scan start game
    jsr io_scanIngameKeys
    jsr io_checkJump
    beq !+
      jmp startIngame
    !:
    jsr io_scanJoy
    jsr io_checkJump
    beq !+
      jmp startIngame
    !:
    // scan menu
    jsr io_scanFunctionKeys
    lda z_previousKeys
    bne storePreviousState
    lda z_currentKeys
    and #KEY_F1
    beq !+
      jsr toggleControls
      jmp storePreviousState
    !:
    lda z_currentKeys
    and #KEY_F5
    beq !+
      jsr toggleLevel
      jmp storePreviousState
    !:
    lda z_currentKeys
    and #KEY_F3
    beq !+
      jsr toggleSound
      jmp storePreviousState
    !:
    storePreviousState:
    // copy current state to previous state
    lda z_currentKeys
    sta z_previousKeys
    jmp endlessTitle
  startIngame:
  jsr dly_wait10
  jsr stopCopper
  rts
}

doLevelScreen: {
  lda #COLOR_CYCLE_DELAY
  sta z_colorCycleDelay
  sta z_colorCycleDelay2

  jsr screenOff
  jsr configureTitleVic2

  lda #NEXT_LEVEL_TUNE
  jsr initSound

  jsr startLevelScreenCopper
  jsr prepareLevelScreen
  jsr screenOn
  
  jsr io_resetControls
  jsr dly_wait10

  !:
    jsr io_scanControls
    jsr io_checkAnyKeyHit
    bne !+
    jmp !-
  !:
  jsr dly_wait10
  jsr stopCopper
  rts
}

doEndGameScreen: {
  lda #COLOR_CYCLE_DELAY
  sta z_colorCycleDelay
  sta z_colorCycleDelay2

  jsr screenOff

  lda #END_GAME_TUNE
  jsr initSound

  jsr configureTitleVic2
  jsr startEndGameScreenCopper

  jsr prepareEndGameScreen
  jsr screenOn

  jsr io_resetControls
  jsr dly_wait10

  !:
    jsr io_scanControls
    jsr io_checkAnyKeyHit
    bne !+
    jmp !-
  !:
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
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*AUTHOR_TOP)
  jsr outText

  pushParamW(txt_originalConcept)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(AUTHOR_TOP + 2) + 4)
  jsr outText

  pushParamW(COLOR_RAM + 40*MENU_TOP); lda #WHITE; ldx #40; jsr fillMem

  pushParamW(txt_menu)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*MENU_TOP)
  jsr outText

  // prepare credits
  jsr initCredits

  // prepare press to play
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(MENU_TOP+1)); lda #(32 + 64); ldx #80; jsr fillMem
  pushParamW(COLOR_RAM + 40*(MENU_TOP+1)); lda #BLACK; ldx #80; jsr fillMem
  pushParamW(txt_startGame)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*(MENU_TOP+2) + 7)
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

  lda #(32 + 64)
  ldx #BLACK
  jsr clearBothScreens


  pushParamW(txt_endGame1)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*6 + 12)
  jsr outText

  pushParamW(txt_endGame2)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*8 + 7)
  jsr outText

  pushParamW(COLOR_RAM + 40*11 + 11); lda #YELLOW; ldx #17; jsr fillMem
  pushParamW(txt_fullGame0); pushParamW(SCREEN_PAGE_ADDR_0 + 40*11 + 11); jsr outText
  pushParamW(COLOR_RAM + 40*13 + 11); lda #YELLOW; ldx #11; jsr fillMem
  pushParamW(txt_fullGame1); pushParamW(SCREEN_PAGE_ADDR_0 + 40*13 + 11); jsr outText
  pushParamW(COLOR_RAM + 40*14 + 11); lda #YELLOW; ldx #11; jsr fillMem
  pushParamW(txt_fullGame2); pushParamW(SCREEN_PAGE_ADDR_0 + 40*14 + 11); jsr outText
  pushParamW(COLOR_RAM + 40*15 + 11); lda #YELLOW; ldx #12; jsr fillMem
  pushParamW(txt_fullGame3); pushParamW(SCREEN_PAGE_ADDR_0 + 40*15 + 11); jsr outText
  pushParamW(COLOR_RAM + 40*16 + 11); lda #YELLOW; ldx #12; jsr fillMem
  pushParamW(txt_fullGame4); pushParamW(SCREEN_PAGE_ADDR_0 + 40*16 + 11); jsr outText
  pushParamW(COLOR_RAM + 40*17 + 11); lda #WHITE; ldx #19; jsr fillMem
  pushParamW(txt_fullGame5); pushParamW(SCREEN_PAGE_ADDR_0 + 40*17 + 11); jsr outText

  pushParamW(txt_pressAnyKey)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*20 + 13)
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
    pushParamW(SCREEN_PAGE_ADDR_0 + 40*MENU_TOP + 7)
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
    pushParamW(SCREEN_PAGE_ADDR_0 + 40*MENU_TOP + 17)
    jsr outText
  // starting level
  pushParamW(z_startingLevel)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*MENU_TOP + 35)
  jsr outHexNibble

  rts
}

