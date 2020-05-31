//#define VISUAL_DEBUG
#import "common/lib/common.asm"
#import "common/lib/mem.asm"
#import "common/lib/invoke.asm"
#import "chipset/lib/sprites.asm"
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2.asm"
#import "chipset/lib/cia.asm"
#import "text/lib/text.asm"
#import "text/lib/tiles-2x2.asm"
#import "copper64/lib/copper64.asm"

#import "_constants.asm"
#import "_segments.asm"
#import "_zero_page.asm"
#import "_sprites.asm"
#import "_vic_layout.asm"
#import "_score.asm"
#import "_animate.asm"

.filenamespace c64lib

.file [name="./rex.prg", segments="Code, Data, Charsets, LevelData, Sprites, Sfx, Music", modify="BasicUpstart", _start=$0810]
.var music = LoadSid("music/rex.sid")

// ---- game parameters ----
.label INVINCIBLE = 0
// starting amount of lives
.label LIVES = 3
// starting level
.label STARTING_WORLD = 1
.label STARTING_LEVEL = 1
// scoring
.label SCORE_FOR_PROGRESS_DELAY = 50
.label SCORE_FOR_PROGRESS = $0025
// collision detection
.label X_COLLISION_OFFSET = 12 - 24
.label Y_COLLISION_OFFSET = 29 - 50

// ---- levels ----
#import "levels/level1/data.asm"

// ---- sfx -----
#import "sfx.asm"


/*
   Phase bit map:
   --------------
   %PW00000S

   - P page: 0=page0, 1=page1
   - W switching pages: 0=no switching, 1=switching
   - S scrolling: 0=no scrolling, 1=scrolling

   Usage:
     lda #%00000001
     bit z_phase
     bmi ... - branch if page1
     bpl ... - branch if page0
     bvc ... - branch if not switching pages
     bvs ... - branch if switching pages
     beq ... - branch if scrolling
     bne ... - branch if is not scrolling
 */
.label PHASE_SHOW_0         = %00000000
.label PHASE_WRAP_0_TO_1    = %01000000
.label PHASE_SWITCH_0_TO_1  = %00000001
.label PHASE_SHOW_1         = %10000000
.label PHASE_WRAP_1_TO_0    = %11000000
.label PHASE_SWITCH_1_TO_0  = %10000001

// -------- Main program ---------
.segment Code

// ---- game flow management ----
start:
  // main init
  jsr cfg_configureC64
  jsr unpackData
  jsr initConfig

  // main loop
  titleScreen:
    jsr doTitleScreen
    jsr initGame
  levelScreen:
    lda z_gameState
    cmp #GAME_STATE_NEXT_LEVEL
    bne sameLevel
    jsr nextLevel
    lda z_gameState
    cmp #GAME_STATE_GAME_FINISHED
    beq gameFinished
  sameLevel:
    lda #GAME_STATE_LIVE
    sta z_gameState
    jsr doLevelScreen
  ingame:
    jsr doIngame
    lda z_gameState
    cmp #GAME_STATE_GAME_OVER
    bne levelScreen

    jmp titleScreen
  gameFinished:
    lda #GAME_STATE_LIVE
    sta z_gameState
    jsr doEndGameScreen
    jmp titleScreen
  // end of main loop

doTitleScreen: {
  // reset keyboard readouts
  lda #0
  sta z_previousKeys
  sta z_currentKeys

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

doLevelScreen: {
  jsr configureTitleVic2
  jsr startTitleCopper
  jsr prepareLevelScreen
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
  jsr configureTitleVic2
  jsr startTitleCopper
  jsr prepareEndGameScreen
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

doIngame: {
  jsr configureIngameVic2
  jsr prepareIngameScreen
  jsr updateScoreOnDashboard
  jsr setUpWorld
  jsr setUpMap
  jsr setupSounds
  jsr initLevel
  jsr act_reset
  jsr io_resetControls
  jsr spr_showPlayer
  jsr startIngameCopper
  brkInGame:
  mainMapLoop:
    // check death conditions
    jsr checkBGCollisions
    jsr updateScore
    // check game state
    lda z_gameState
    cmp #GAME_STATE_KILLED
    bne !+
      {
        lda z_mode
        bne !+
          lda #1
          sta z_mode
          lda #0
          sta z_jumpFrame
        !:
      }

      jsr spr_showDeath
      jsr playDeath
      // decrement lives
      dec z_lives
      bne livesLeft
        lda #GAME_STATE_GAME_OVER
        sta z_gameState
        jmp displayGameOver
      livesLeft:
      wait #100
    !:
    lda z_gameState
    cmp #GAME_STATE_LIVE
    beq !+
      cmp #GAME_STATE_LEVEL_END_SEQUENCE
      beq !+
      jmp gameOver
    !:

  jmp mainMapLoop

  displayGameOver:
    lda #1
    sta z_doGameOver
    wait #200
  gameOver:
    jsr stopCopper
    jsr spr_hidePlayers
    rts
}

  doGameOver: {
    lda z_doGameOver
    beq !+
      jsr act_reset
      jsr spr_hidePlayers
      lda SPRITE_ENABLE
      and #%00000000
      sta SPRITE_ENABLE
      .for (var i = 4; i < 8; i++) {
        ldx #i
        jsr disableAnimation
      }
      jsr spr_showGameOver
    !:
    rts
  }


// Initialize music player.
initSound: {
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  rts
}

setupSounds: {
  lda #0
  sta z_sfxChannel
  rts
}

playMusic: {
  debugBorderStart()
  jsr music.play
  debugBorderEnd()
  rts
}

playJump: {
  lda #<sfxJump
  ldy #>sfxJump
  jmp playSfx
}

playDuck: {
  lda #<sfxDuck
  ldy #>sfxDuck
  jmp playSfx
}

playDeath: {
  lda #<sfxDeath
  ldy #>sfxDeath
  jmp playSfx
}

playLanding: {
  lda #<sfxLanding
  ldy #>sfxLanding
  jmp playEnemy
}

playSfx: {
  ldx #14
  jsr music.init + 6
  rts
}

playSnake: {
  lda #<sfxSnake
  ldy #>sfxSnake
  jmp playEnemy
}

playVogel: {
  lda #<sfxVogel
  ldy #>sfxVogel
  jmp playEnemy
}

playScorpio: {
  lda #<sfxScorpio
  ldy #>sfxScorpio
  jmp playEnemy
}

playEnemy: {
  ldx z_sfxChannel
  beq !+
    ldx #0
    stx z_sfxChannel
    jmp play
  !:
    ldx #7
    stx z_sfxChannel
  play:
  jsr music.init + 6
  rts
}

initConfig: {
  // default controls - joystick + music
  lda #(CFG_CONTROLS + CFG_SOUND)
  sta z_gameConfig
  lda #STARTING_LEVEL
  sta z_startingLevel
  rts
}

initGame: {
  // set up lives count
  lda #LIVES
  sta z_lives

  // set up start level
  lda #STARTING_WORLD
  sta z_worldCounter
  lda z_startingLevel
  sta z_levelCounter

  lda #0
  sta z_isDuck

  // set score to 0
  resetScore()

  rts
}

// ---- END: game flow ----

updateScore: {
  lda z_scoreDelay
  bne !+
    setScoreDelay #SCORE_FOR_PROGRESS_DELAY
    ldx #>SCORE_FOR_PROGRESS
    lda #<SCORE_FOR_PROGRESS
    jsr addScore
    jsr updateScoreOnDashboard
  !:
  rts
}
addScore: { addScore(); rts }

// ---- General configuration ----
cfg_configureC64: {
  sei
  configureMemory(RAM_IO_RAM)
  disableNMI()
  disableCIAInterrupts()
  cli
  rts
}

unpackData: {
  // copy chargen
  pushParamW(beginOfChargen)
  pushParamW(CHARGEN_ADDR)
  pushParamW(endOfChargen - beginOfChargen)
  jsr copyLargeMemForward
  // copy sprites
  pushParamW(beginOfSprites)
  pushParamW(SPRITE_ADDR)
  pushParamW(endOfSprites - beginOfSprites)
  jsr copyLargeMemForward
  // copy music
  pushParamW(musicData)
  pushParamW(music.location)
  pushParamW(music.size)
  jsr copyLargeMemForward
  rts
}
// ---- END: general configuration ----

// ---- graphics configuration ----
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
  sta CONTROL_2
  lda CONTROL_1
  and #%11110000
  ora #%00001000
  sta CONTROL_1
  rts
}

configureIngameVic2: {
  setVideoMode(MULTICOLOR_TEXT_MODE)
  setVICBank(3 - VIC_BANK)
  configureTextMemory(SCREEN_PAGE_0, CHARGEN)
  // turn on 38 columns visible
  lda CONTROL_2
  and #%11110111
  sta CONTROL_2
  lda CONTROL_1
  and #%11110000
  ora #%00000110
  sta CONTROL_1
  rts
}

/*
 * In:  - A char code
 *      - X color code
 */
clearBothScreens: {
  sta charCode
  stx colorCode
  // clear page 0
  pushParamW(SCREEN_PAGE_ADDR_0)
  lda charCode
  jsr fillScreen
  // clear page 1
  pushParamW(SCREEN_PAGE_ADDR_1)
  lda charCode
  jsr fillScreen
  // set up playfield color to GREY
  pushParamW(COLOR_RAM)
  lda colorCode
  jsr fillScreen

  rts
  // private data
  charCode: .byte $00
  colorCode: .byte $00
}

prepareTitleScreen: {
  lda #32
  ldx #LIGHT_GRAY
  jsr clearBothScreens

  pushParamW(txt_title)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*3 + 14)
  jsr outText

  pushParamW(txt_subTitle)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*5 + 14)
  jsr outText

  pushParamW(txt_author)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 11)
  jsr outText

  pushParamW(txt_originalConcept)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*12 + 4)
  jsr outText

  pushParamW(txt_controls)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*18 + 6)
  jsr outText
  pushParamW(txt_sound)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*20 + 6)
  jsr outText
  pushParamW(txt_startingLevel)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*22 + 6)
  jsr outText
  pushParamW(txt_startGame)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*24 + 6)
  jsr outText

  jsr drawConfig
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
    pushParamW(SCREEN_PAGE_ADDR_0 + 40*18 + 21)
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
    pushParamW(SCREEN_PAGE_ADDR_0 + 40*20 + 21)
    jsr outText
  // starting level
  pushParamW(z_startingLevel)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*22 + 23)
  jsr outHexNibble

  rts
}

prepareLevelScreen: {
  lda #32
  ldx #LIGHT_GRAY
  jsr clearBothScreens

  pushParamW(txt_entering)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 15)
  jsr outText

  pushParamW(txt_getReady)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*12 + 15)
  jsr outText

  pushParamW(z_worldCounter)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 22)
  jsr outHexNibble

  pushParamW(z_levelCounter)
  pushParamW(SCREEN_PAGE_ADDR_0 + 40*10 + 24)
  jsr outHexNibble

  rts
}

prepareEndGameScreen: {
  lda #32
  ldx #LIGHT_GRAY
  jsr clearBothScreens

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

prepareIngameScreen: {
  lda #32
  ldx #0
  jsr clearBothScreens
  // hires colors for status bar
  pushParamW(COLOR_RAM + 24*40)
  lda #WHITE
  ldx #40
  jsr fillMem

  rts
}

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
  lda #32
  sta SPRITE_4_X
  lda #8
  sta SPRITE_5_X
  lda #32
  sta SPRITE_6_X
  lda #56
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
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 20, z_score, CHARGEN_ADDR)
  drawHiDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 19, z_score, CHARGEN_ADDR)
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 3)*64 + 18, z_score + 1, CHARGEN_ADDR)
  drawHiDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 2)*64 + 20, z_score + 1, CHARGEN_ADDR)
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 2)*64 + 19, z_score + 2, CHARGEN_ADDR)
  drawHiDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD + 2)*64 + 18, z_score + 2, CHARGEN_ADDR)
  rts
}

updateDashboard: {
  drawLoDigitOnSprite( VIC_MEMORY_START + (SPRITE_SHAPES_START + SPR_DASHBOARD)*64 + 20, z_lives, CHARGEN_ADDR)
  rts
}
// ---- END: graphics configuration ----

// ---- actors handling ----

.macro playEnemy(enemyRoutine) {
  txa
  pha
  playSfx(enemyRoutine)
  pla
  tax
}

.macro playSfx(enemyRoutine) {
  lda z_gameConfig
  and #CFG_SOUND
  bne !+
    jsr enemyRoutine
  !:
}

checkForNewActors: {
  ldy #0
  lda (z_actorsBase),y
  // check actor code
  cmp #$ff
  beq end
    iny
    lda (z_actorsBase),y
    // check trigger position
    cmp z_x + 1
    bne end
    // new actor trigger condition met
    jmp newActor
  end:
    rts
  newActor:
    ldy #0
    // actor code
    lda (z_actorsBase),y
    pha
    // actor X position
    lda #$60 // #87 TODO: to make it visible from behind the border
    pha
    lda #$14
    pha
    // actor Y position
    iny
    iny
    lda (z_actorsBase),y
    pha
    // actor speed
    iny
    lda (z_actorsBase),y
    pha
    // actor color
    iny
    lda (z_actorsBase),y
    sta color
    // add new actor
    jsr act_add
    lda act_sprite,x
    tax
    // X <- sprite number
    lda color:#$00
    sta SPRITE_0_COLOR,x
    ldy #0
    lda (z_actorsBase),y
    cmp #EN_VOGEL
    beq vogel
    cmp #EN_SCORPIO
    beq scorpio
    cmp #EN_SNAKE
    beq snake
    jmp moveActorsBase
    vogel:
      jsr spr_showVogel
      playEnemy(playVogel)
      jmp showEnemy
    scorpio:
      jsr spr_showScorpio
      playEnemy(playScorpio)
      jmp showEnemy
    snake:
      jsr spr_showSnake
      playEnemy(playSnake)
      jmp showEnemy
    showEnemy:
      // sprite enable
      lda z_spriteEnable
      ora bitMaskTable,x
      sta z_spriteEnable
    moveActorsBase:
    // move actors base to the next entry
    clc
    lda z_actorsBase
    adc #5
    sta z_actorsBase
    lda z_actorsBase + 1
    adc #0
    sta z_actorsBase + 1
    rts
}

disposeActors: {
  ldx #(ACT_MAX_SIZE-1)
  loop:
    lda act_code,x
    beq next
    lda act_xHi,x
    and #%00010000
    bne next
    lda act_xHi,x
    and #%00001111
    bne next
    lda act_sprite,x
    pha
    stx preserveX
    jsr act_remove
    // disable animation
    pla
    tax
    jsr disableAnimation
    // disable sprite
    lda SPRITE_ENABLE
    and bitMaskInvertedTable,x
    sta SPRITE_ENABLE
    // restore X
    ldx preserveX
  next:
    cpx #0
    beq end
    dex
    jmp loop
  end:
  rts
    // local vars
    preserveX: .byte $00
}

drawActors: {
  ldy #0
  loop:
    cpy #ACT_MAX_SIZE
    beq end
    lda act_code,y
    beq end
    lda act_sprite,y
    tax
    lda spriteYPosRegisters,x
    sta spriteY
    lda spriteXPosRegisters,x
    sta spriteX
    lda act_y,y
    sta spriteY:$d000
    // round
    lda act_xLo,y
    lsr
    lsr
    lsr
    lsr
    sta tempX
    lda act_xHi,y
    asl
    asl
    asl
    asl
    ora tempX
    sta spriteX:$d000
    lda act_xHi,y
    and #%00010000
    beq hiZero // TODO: branch on carry should work as well
      // X bigger than 255
      lda SPRITE_MSB_X
      ora bitMaskTable,x
      sta SPRITE_MSB_X
      jmp next
    hiZero:
      // less than 256
      lda SPRITE_MSB_X
      and bitMaskInvertedTable,x
      sta SPRITE_MSB_X
    next:
    iny
    jmp loop
  end:
  rts
  // local vars
    tempX: .byte $00
}

enableActors: {
  lda z_spriteEnable
  beq !+
    lda SPRITE_ENABLE
    ora z_spriteEnable
    sta SPRITE_ENABLE
    lda #0
    sta z_spriteEnable
  !:
  rts
}

// ---- END: actors handling ----

// ---- level handling ----
nextLevel: {
  lda z_worldCounter
  // cmp #3
  // cmp #2
  world1:
    lda z_levelCounter
    cmp #3
    beq level1_end
      inc z_levelCounter
      jmp end
    level1_end:
      lda #GAME_STATE_GAME_FINISHED
      sta z_gameState
      jmp end
  end:
  rts
}

.macro setUpWorld(levelCfg) {
 // set background & border color
  lda #levelCfg.BG_COLOR_0
  sta BG_COL_0
  lda #levelCfg.BG_COLOR_1
  sta BG_COL_1
  lda #levelCfg.BG_COLOR_2
  sta BG_COL_2
  lda #levelCfg.BORDER_COLOR
  sta BORDER_COL

  // copy level chargen
  sei
  configureMemory(RAM_RAM_RAM)
  pushParamW(levelCfg.CHARSET_ADDRESS)
  pushParamW(CHARGEN_ADDR + (endOfChargen - beginOfChargen))
  pushParamW(levelCfg.CHARSET_SIZE*8)
  jsr copyLargeMemForward
  configureMemory(RAM_IO_RAM)
  cli

  // copy tiles colors
  pushParamW(levelCfg.TILES_COLORS_ADDRESS)
  pushParamW(tileColors)
  pushParamW(levelCfg.TILES_SIZE)
  jsr copyLargeMemForward

  // copy tiles
  pushParamW(levelCfg.TILES_ADDRESS)
  pushParamW(tileDefinition)
  pushParamW(levelCfg.TILES_SIZE*4)
  jsr copyLargeMemForward

  rts
}

.macro setUpMap(mapAddress, mapWidth, deltaX, wrappingMark, scrollingMark, obstaclesMark, mapActors) {
  // set map definition pointer
  lda #<mapAddress
  sta z_map
  lda #>mapAddress
  sta z_map + 1

  // set map width
  lda #mapWidth
  sta z_width

  // set delta X
  lda #deltaX
  sta z_deltaX

  // set marks
  lda #wrappingMark
  sta z_wrappingMark
  lda #scrollingMark
  sta z_scrollingMark
  lda #obstaclesMark
  sta z_obstaclesMark

  // set actors base and pointer
  lda #<mapActors
  sta z_actorsBase
  lda #>mapActors
  sta z_actorsBase + 1

  rts
}

setUpWorld1: setUpWorld(level1)
/*
 * Mod: A
 */
setUpWorld: {
  lda z_worldCounter
  cmp #2
  beq world2
  cmp #3
  beq world3
  world1:
    jsr setUpWorld1
    jmp end
  world2:
    jmp end
  world3:
  end:
  rts
}

/*
 * Mod: A
 */
setUpMap: {
  lda z_worldCounter
  cmp #2
  beq world2
  cmp #3
  beq world3
  world1:
    lda z_levelCounter
    cmp #2
    beq level1_2
    cmp #3
    beq level1_3
    level1_1:
      jsr setUpMap1_1
      jmp end
    level1_2:
      jsr setUpMap1_2
      jmp end
    level1_3:
      jsr setUpMap1_3
      jmp end
  world2:
    jmp end
  world3:
  end:
  rts
}

setUpMap1_1: setUpMap(level1.MAP_1_ADDRESS, level1.MAP_1_WIDTH, level1.MAP_1_DELTA_X, level1.MAP_1_WRAPPING_MARK, level1.MAP_1_SCROLLING_MARK, level1.MAP_1_OBSTACLES_MARK, level1.MAP_1_ACTORS)
setUpMap1_2: setUpMap(level1.MAP_2_ADDRESS, level1.MAP_2_WIDTH, level1.MAP_2_DELTA_X, level1.MAP_2_WRAPPING_MARK, level1.MAP_2_SCROLLING_MARK, level1.MAP_2_OBSTACLES_MARK, level1.MAP_2_ACTORS)
setUpMap1_3: setUpMap(level1.MAP_3_ADDRESS, level1.MAP_3_WIDTH, level1.MAP_3_DELTA_X, level1.MAP_3_WRAPPING_MARK, level1.MAP_3_SCROLLING_MARK, level1.MAP_3_OBSTACLES_MARK, level1.MAP_3_ACTORS)

// ---- END: level handling ----

// ---- import modules ----
#import "sprites.asm"
#import "io.asm"
#import "physics.asm"
#import "delays.asm"
#import "actors.asm"
// ---- END: import modules ----

// ---- Utility subroutines ----
.segment Code
 #import "common/lib/sub/copy-large-mem-forward.asm"
 #import "common/lib/sub/fill-screen.asm"
 #import "common/lib/sub/fill-mem.asm"
 #import "text/lib/sub/out-text.asm"
 #import "text/lib/sub/out-hex.asm"
 #import "text/lib/sub/out-hex-nibble.asm"

// ---- END: Utility subroutines ----

// ---- Copper handling ----
startIngameCopper: {
  lda #<ingameCopperList
  sta z_displayListPtr
  lda #>ingameCopperList
  sta z_displayListPtr + 1
  jsr startCopper
  rts
}

startTitleCopper: {
  lda #<titleScreenCopperList
  sta z_displayListPtr
  lda #>titleScreenCopperList
  sta z_displayListPtr + 1
  jsr startCopper
  rts
}

startCopper: {
  startCopper(
    z_displayListPtr,
    z_listPtr,
    List().add(c64lib.IRQH_HSCROLL, c64lib.IRQH_JSR).lock())
  rts
}

stopCopper: {
  // TODO inconsistency, stopCopper shouldn't do rts inside, fix copper64 lib
  stopCopper()
}
// ---- END: Copper handling ----

// ---- Copper Tables ----
.align $100
_copperListStart:
// here we define layout of raster interrupt handlers
ingameCopperList:
  hScroll:
    // play music
    copperEntry(0, IRQH_JSR, <playMusic, >playMusic)
    copperEntry(DASHBOARD_Y + 20, IRQH_JSR, <upperMultiplex, >upperMultiplex)
  scrollCode:
    // here we do the actual scrolling
    copperEntry(88, IRQH_JSR, <scrollBackground, >scrollBackground)
    // here we do the page switching when it's time for this
    copperEntry(260, IRQH_JSR, <switchPages, >switchPages)
    // here we loop and so on, so on, for each frame
    copperLoop()

titleScreenCopperList:
    copperEntry(10, IRQH_JSR, <playMusic, >playMusic)
    copperEntry(245, IRQH_JSR, <dly_handleDelay, >dly_handleDelay)
    // here we loop and so on, so on, for each frame
    copperLoop()
_copperListEnd:
.assert "Copper list must fit into single 256b page.", (_copperListEnd - _copperListStart)<256, true
// ---- END: Copper Tables ----

.align $100
tileColors:
  .fill 256, $0
mapOffsetsLo:
  .fill 256, 0
mapOffsetsHi:
  .fill 256, 0
tileDefinition:
  .fill 256*4, $0

// ---- Scrollable background handling ----
.var tilesCfg = Tile2Config()
.eval tilesCfg.bank = VIC_BANK
.eval tilesCfg.page0 = SCREEN_PAGE_0
.eval tilesCfg.page1 = SCREEN_PAGE_1
.eval tilesCfg.startRow = 0
.eval tilesCfg.endRow = 23
.eval tilesCfg.x = z_bgX
.eval tilesCfg.y = z_y
.eval tilesCfg.width = z_width
.eval tilesCfg.height = z_height
.eval tilesCfg.tileColors = tileColors
.eval tilesCfg.mapOffsetsLo = mapOffsetsLo
.eval tilesCfg.mapOffsetsHi = mapOffsetsHi
.eval tilesCfg.mapDefinitionPtr = z_map
.eval tilesCfg.tileDefinition = tileDefinition
.eval tilesCfg.lock()

checkBGCollisions: {
  cld
  lda #(PLAYER_Y + Y_COLLISION_OFFSET)
  sec
  sbc z_yPos
  lsr
  lsr
  lsr
  lsr
  tay
  lda #(PLAYER_X + X_COLLISION_OFFSET)
  lsr
  lsr
  lsr
  lsr
  tax
  decodeTile(tilesCfg)
  and z_obstaclesMark
  cmp z_obstaclesMark
  bne !+
    lda #GAME_STATE_KILLED
    .if (INVINCIBLE == 0) {
      sta z_gameState
    }
    rts
  !:
  lda #(PLAYER_X + X_COLLISION_OFFSET - 8)
  lsr
  lsr
  lsr
  lsr
  tax
  decodeTile(tilesCfg)
  and z_obstaclesMark
  cmp z_obstaclesMark
  bne !+
    lda #GAME_STATE_KILLED
    .if (INVINCIBLE == 0) {
      sta z_gameState
    }
  !:
  rts
}

checkActorCollisions: {
  lda SPRITE_2S_COLLISION
  and #%11110000
  beq !+
    lda #GAME_STATE_KILLED
    .if (INVINCIBLE == 0) {
      sta z_gameState
    }
  !:
  rts
}

drawTile: drawTile(tilesCfg, SCREEN_PAGE_ADDR_0, COLOR_RAM)

initLevel: {
  lda #MAP_HEIGHT
  sta z_height

  // set phase to 0
  lda #PHASE_SHOW_0
  sta z_phase

  lda #0
  sta z_spritesStashed
  sta z_doGameOver

  // set sprite enable ghost reg to 0
  lda #0
  sta z_spriteEnable

  lda #0
  sta z_colorRAMShifted

  // set [x,y] = [0,0]
  lda #$ff
  sta z_oldX
  lda #0
  sta z_x
  sta z_x + 1
  sta z_y
  sta z_y + 1
  sta z_bgX
  sta z_bgX + 1

  // set xpos
  lda #PLAYER_X
  sta z_xPos

  // init animation
  lda #0
  sta z_yPos
  sta z_jumpFrame

  // set key mode to 0
  lda #$00
  sta z_mode
  sta z_prevMode

  // set max delay
  lda #MAX_DELAY
  sta z_delay

  // set game state
  lda #GAME_STATE_LIVE
  sta z_gameState

  // set initial score delay
  setScoreDelay #SCORE_FOR_PROGRESS_DELAY

  // initialize tile2 system
  tile2Init(tilesCfg)

  // draw the screen
  ldx #0
  ldy #0
  draw:
    jsr drawTile
    inx
    cpx #20
    bne draw
    ldx #0
    iny
    cpy #MAP_HEIGHT
    bne draw

  rts
}

incrementX: {
  cld
  clc
  lda z_x
  adc z_deltaX
  sta z_x
  lda z_x + 1
  adc #0
  sta z_x + 1
  rts
}

upperMultiplex: {
  debugBorderStart()
  popSprites(z_stashArea)
  debugBorderEnd()
  rts
}

detectPhases: {

  lda z_phase
  and #%10111110
  sta z_phase
  // detect page switching phase
  lda z_acc0
  cmp z_wrappingMark
  bne notSeven
    lda z_phase
    ora #%01000000
    sta z_phase
  notSeven:

  // detect scrolling phase
  lda z_acc0
  cmp z_scrollingMark
  bne notZero
    lda z_phase
    ora #%00000001
    sta z_phase
  notZero:
  rts
}

scrollBackground: {
  debugBorderStart()

  jsr detectPhases

  // are we actually moving?
  lda z_x
  cmp z_oldX
  bne !+
    // no movement -> no page switching - to disable strange artifacts when scrolling is stopped
    jmp end2
  !:

  // test phase flags
  lda #1
  bit z_phase
  bne scrolling
    jmp end2
  scrolling:
    bpl page0
  // we're on page 1
  page1: {
    lda z_x
    sta z_bgX
    lda z_x + 1
    sta z_bgX + 1
      // if scrolling
      lda z_phase
      and #%11111110
      sta z_phase
      jmp page1To0
  }
  // we're on page 0
  page0: {
    lda z_x
    sta z_bgX
    lda z_x + 1
    sta z_bgX + 1
      // if scrolling
      lda z_phase
      and #%11111110
      sta z_phase
      jmp page0To1
  }
  jmp end
  // do the screen shifting
  page0To1:
    _t2_shiftScreenLeft(tilesCfg, 0, 1)
    jmp end
  page1To0:
    _t2_shiftScreenLeft(tilesCfg, 1, 0)

  end:
    // setup IRQ handler back to scrollColorRam
    lda #<scrollColorRam
    sta scrollCode + 2
    lda #>scrollColorRam
    sta scrollCode + 3
  end2:

    debugBorderEnd()
    rts
}

scrollColorRam: {
  debugBorderEnd()

  jsr detectPhases

  // are we actually moving?
  lda z_x
  cmp z_oldX
  bne !+
    // no movement -> no page switching - to disable strange artifacts when scrolling is stopped
    jmp switchBackIrq
  !:

  lda #1
  sta z_colorRAMShifted

  _t2_shiftColorRamLeft(tilesCfg, 2)
  _t2_decodeColorRight(tilesCfg, COLOR_RAM)
  switchBackIrq:
  // setup IRQ handler back to scrollBackground
  lda #<scrollBackground
  sta scrollCode + 2
  lda #>scrollBackground
  sta scrollCode + 3
  end:
  debugBorderStart()
  rts
}

switchPages: {
  debugBorderStart()
  doSwitching:
  // are we actually moving?
  lda z_x
  cmp z_oldX
  bne !+
    // no movement -> no page switching - to disable strange artifacts when scrolling is stopped
    jmp end
  !:
  sta z_oldX
  lda z_colorRAMShifted
  bne !+
    // switch pages only if color RAM have been shifted
    jmp end
  !:
  // test phase
  lda #1
  bit z_phase
  bpl page0
  // we're on page 1
  page1: {
      // if do not switch the page
      bvc endSwitch
      // if switch the page
      and #%00111111
      sta z_phase
      jmp switch1To0
  }
  // we're on page 0
  page0: {
      // if do not switch the page
      bvc endSwitch
      // if switch the page
      and #%00111111
      ora #%10000000
      sta z_phase
      jmp switch0To1
  }
  endSwitch:
    jmp end
  switch0To1:
    _t2_decodeScreenRight(tilesCfg, 1)
    lda MEMORY_CONTROL
    and #%00001111
    ora #(SCREEN_PAGE_1 << 4)
    sta MEMORY_CONTROL
    jmp end
  switch1To0:
    _t2_decodeScreenRight(tilesCfg, 0)
    lda MEMORY_CONTROL
    and #%00001111
    ora #(SCREEN_PAGE_0 << 4)
    sta MEMORY_CONTROL
  end:

  // calculate scroll register
  lda z_x
  and #%01110000
  lsr
  lsr
  lsr
  lsr
  sta z_acc0

  // increment X coordinate
  lda z_gameState
  cmp #GAME_STATE_LIVE
  bne abnormal
    jsr incrementX
    jmp endOfIncrementX
  abnormal:
    cmp #GAME_STATE_LEVEL_END_SEQUENCE
    bne endOfIncrementX
      lda z_xPos
      cmp #$ff
    beq nextLevel
      inc z_xPos
      jmp endOfIncrementX
    nextLevel:
      lda #GAME_STATE_NEXT_LEVEL
      sta z_gameState
      jmp endOfPhase
  endOfIncrementX:

  // check end of level condition
  clc
  cld
  lda z_x + 1
  adc #20
  cmp z_width
  bne dontReset
    lda z_gameState
    cmp #GAME_STATE_LEVEL_END_SEQUENCE
    beq !+
      lda #GAME_STATE_LEVEL_END_SEQUENCE
      sta z_gameState
      jsr spr_showPlayerWalkLeft
    !:
  dontReset:

  // update scroll register for scrollable area
  sec
  lda #7
  sbc z_scrollReg
  sta z_scrollReg
  lda CONTROL_2
  and #%11111000
  ora z_scrollReg
  sta CONTROL_2
  //sta hScroll + 2
  lda z_acc0
  sta z_scrollReg
  endOfPhase:

  jsr updateDashboard
  jsr io_scanControls
  jsr handleControls
  jsr animate
  jsr phy_performProgressiveJump
  jsr phy_updateSpriteY
  jsr dly_handleDelay

  jsr disposeActors
  jsr checkForNewActors
  jsr drawActors
  jsr act_animate
  jsr enableActors
  jsr checkActorCollisions
  jsr doGameOver

  decrementScoreDelay()

  stashSprites(z_stashArea)

  lda #0
  sta z_colorRAMShifted

  debugBorderEnd()
  rts
}

handleControls: {
  lda z_gameState
  cmp #GAME_STATE_LIVE
  beq !+
    rts
  !:
  jsr io_checkJump
  beq !+
  {
    // start jumping sequence
    lda z_mode
    bne !+
      lda #1
      sta z_mode
      lda #0
      sta z_jumpFrame
      sta z_jumpPhase
      sta z_jumpLinear
      jsr spr_showPlayerJump
      jsr playJump
      jmp end
    !:
    end:
      jmp afterDuck
  }
  !:
  // handle ducking
  jsr io_checkUnduck
  beq !+
    jsr spr_showPlayerWalkLeft
    jmp afterDuck
  !:
  jsr io_checkDoduck
  beq !+
    jsr playDuck
    jsr spr_showPlayerDuck
  !:

  afterDuck:
  // if back on earth -> switch to walk left again
  lda z_prevMode
  beq !+
    lda z_mode
    bne stillInAir
      playSfx(playLanding)
      jsr spr_showPlayerWalkLeft
    stillInAir:
  !:

  rts
}
// ---- END: Scrollable background handling ----

// ---- DATA ----
.segment Data
spriteXPosRegisters:
  .byte <SPRITE_0_X; .byte <SPRITE_1_X; .byte <SPRITE_2_X; .byte <SPRITE_3_X
  .byte <SPRITE_4_X; .byte <SPRITE_5_X; .byte <SPRITE_6_X; .byte <SPRITE_7_X
spriteYPosRegisters:
  .byte <SPRITE_0_Y; .byte <SPRITE_1_Y; .byte <SPRITE_2_Y; .byte <SPRITE_3_Y
  .byte <SPRITE_4_Y; .byte <SPRITE_5_Y; .byte <SPRITE_6_Y; .byte <SPRITE_7_Y
// ---- texts ----
// title screen
txt_title:            .text "t-rex runner"; .byte $ff
txt_subTitle:         .text "c64  edition"; .byte $ff
txt_author:           .text "by  maciej malecki"; .byte $ff
txt_originalConcept:  .text "based on google chrome easter egg"; .byte $ff
// title screen menu
txt_controls:         .text "f1   controls"; .byte $ff
txt_controlsJoy:      .text "joystick 2"; .byte $ff
txt_controlsKey:      .text "keyboard  "; .byte $ff
txt_sound:            .text "f3     ingame"; .byte $ff
txt_soundMus:         .text "music"; .byte $ff
txt_soundFx:          .text "fx   "; .byte $ff
txt_startingLevel:    .text "f5      level  1-"; .byte $ff
txt_startGame:        .text "f7      start  game"; .byte $ff
// level start screen
txt_entering:         .text "world  0-0"; .byte $ff
txt_getReady:         .text "get ready!"; .byte $ff
// end game screen
txt_endGame1:         .text "congratulations!"; .byte $ff
txt_endGame2:         .text "you have finished the game"; .byte $ff
txt_pressAnyKey:      .text "hit the button"; .byte $ff

.segment Music
musicData:
                      .fill music.size, music.getData(i)
endOfMusicData:

// ---- END:DATA ----

// ---- chargen definition ----
.segment Charsets
beginOfChargen:
  // 0-63: letters, symbols, numbers
  #import "fonts/regular/base.asm"
.print "Chargen import size = " + (endOfChargen - beginOfChargen)
endOfChargen:
.print "Chargen import size = " + (endOfChargen - beginOfChargen)
// ---- END: chargen definition ----
endOfTRex:

.assert "Code and music overlap", sfxEnd <= music.location, true

// print memory map summary
.print "header="+music.header
.macro memSummary(name, address) {
.print name + " = " + address + " ($" + toHexString(address, 4) + ")"
.print name + " = " + address + " ($" + toHexString(address, 4) + ")"
}

.print "copyright="+music.copyright
.print "copyright="+music.copyright
.print "--------"
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength
.print ""
.print "Memory summary"
.print "--------------"
memSummary("        total size", (endOfTRex - start))
memSummary("       tile colors", tileColors)
memSummary("      mapOffsetsLo", mapOffsetsLo)
memSummary("      mapOffsetsHi", mapOffsetsHi)

memSummary("tiles definition 0", tileDefinition)

memSummary("SCREEN_PAGE_ADDR_0", SCREEN_PAGE_ADDR_0)
memSummary("SCREEN_PAGE_ADDR_1", SCREEN_PAGE_ADDR_1)
memSummary("      CHARGEN_ADDR", CHARGEN_ADDR)
memSummary("       SPRITE_ADDR", SPRITE_ADDR)
.print ""
.print "BREAKPOINTS"
.print "-----------"
.print "inGame.brkInGame = $" + toHexString(doIngame.mainMapLoop, 4)
.print "scrollBackground = $" + toHexString(scrollBackground, 4)
.print "  scrollColorRAM = $" + toHexString(scrollColorRam, 4)
.print "     switchPages = $" + toHexString(switchPages, 4)
