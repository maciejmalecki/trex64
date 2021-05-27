//#define VISUAL_DEBUG
#import "common/lib/common.asm"
#import "common/lib/mem.asm"
#import "common/lib/invoke.asm"
#import "chipset/lib/sprites.asm"
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2.asm"
#import "chipset/lib/cia.asm"
#import "text/lib/text.asm"

#import "_constants.asm"
#import "_segments.asm"
#import "_zero_page.asm"
#import "_sprites.asm"
#import "_vic_layout.asm"
#import "_score.asm"
#import "_animate.asm"

.filenamespace c64lib

.file [name="./rex.prg", segments="Code, Data, Charsets, LevelData, Sprites, AuxGfx, Sfx, Music", modify="BasicUpstart", _start=$0810]
.disk [filename="./rex.d64", name="T-REX 64", id="C2021"] {
  [name="----------------", type="rel"],
  [name="T-REX 64", type="prg", segments="Code, Data, Charsets, LevelData, Sprites, AuxGfx, Sfx, Music", modify="BasicUpstart", _start=$0810],
  [name="----------------", type="rel"]
}

// starting amount of lives
.label LIVES = 3
// starting level
.label STARTING_WORLD = 1
.label STARTING_LEVEL = 1

// ---- levels ----
#import "levels/level1/data.asm"

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
    jsr checkNewHiScore
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

doIngame: {
  jsr screenOff
  jsr configureIngameVic2
  jsr prepareIngameScreen
  jsr updateScoreOnDashboard
  jsr updateHiScoreOnDashboard
  jsr setUpWorld
  jsr setUpMap

  // setup ingame tune according to cfg
  lda z_gameConfig
  and #CFG_SOUND
  bne !+
    lda #INGAME_SFX_TUNE
    jmp snd
  !:
  lda #INGAME_TUNE
  snd:
  jsr initSound

  jsr setupSounds
  jsr initLevel
  jsr screenOn
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

      // remember death position
      lda z_x
      sta z_hiScoreMark
      lda z_x + 1
      sta z_hiScoreMark + 1

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
    // play game over tune
    lda #GAME_OVER_TUNE
    jsr initSound
    // display text and wait
    lda #1
    sta z_doGameOver
    wait #255
    // hack to fix #54
    lda #GAME_STATE_GAME_OVER
    sta z_gameState
  gameOver:
    jsr stopCopper
    jsr spr_hidePlayers
    rts
}

initConfig: {
  // default controls - joystick + music
  lda #(CFG_CONTROLS + CFG_SOUND)
  sta z_gameConfig
  lda #STARTING_LEVEL
  sta z_startingLevel
  // hi score
  lda #0
  sta z_hiScore
  sta z_hiScore + 1
  sta z_hiScore + 2
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

  // zero hi-score counter
  lda #0
  sta z_hiScoreMark
  sta z_hiScoreMark + 1

  rts
}

// ---- END: game flow ----

checkNewHiScore: {

  lda z_hiScore + 2
  cmp z_score + 2
  bcc newHiScoreFound
  bne noNewHiScore
  lda z_hiScore + 1
  cmp z_score + 1
  bcc newHiScoreFound
  bne noNewHiScore
  lda z_hiScore
  cmp z_score
  bcc newHiScoreFound
  noNewHiScore:
    rts
  newHiScoreFound:
    lda z_score
    sta z_hiScore
    lda z_score + 1
    sta z_hiScore + 1
    lda z_score + 2
    sta z_hiScore + 2
    rts
}

updateScore: {

  // compare with last saved position
  lda z_hiScoreMark
  cmp z_x
  lda z_hiScoreMark + 1
  sbc z_x + 1
  bvc !+
  eor #$80
  !:
  bmi !+
    rts
  !:
  // do the score
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
  pushParamW(musicLocation)
  pushParamW(musicSize)
  jsr copyLargeMemForward
  rts
}
// ---- END: general configuration ----

// ---- graphics configuration ----

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

prepareIngameScreen: {
  lda #32
  ldx #0
  jsr clearBothScreens
  rts
}
// ---- END: graphics configuration ----


// ---- level handling ----
nextLevel: {
  // zero hi-score counter
  lda #0
  sta z_hiScoreMark
  sta z_hiScoreMark + 1

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
  rts
  end:
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
// library modules
#import "game-field.asm"
#import "data.asm"
#import "charsets.asm"
#import "aux-gfx.asm"
#import "music.asm"
#import "dashboard.asm"
#import "sprites.asm"
#import "io.asm"
#import "delays.asm"
#import "subroutines.asm"
// functional modules
#import "outgame-screens.asm"

// ---- END: import modules ----
.segment Music
endOfTRex:

.assert "Code and music overlap", sfxEnd <= music.location, true

// print memory map summary
.print "header="+music.header
.macro memSummary(name, address) {
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

memSummary("TITLE SCR ATTR ST:", beginOfTitleAttr)
memSummary("TITLE SCR MAP ST: ", beginOfTitleMap)

.print ""
.print "BREAKPOINTS"
.print "-----------"
.print "inGame.brkInGame = $" + toHexString(doIngame.mainMapLoop, 4)
.print "scrollBackground = $" + toHexString(scrollBackground, 4)
.print "  scrollColorRAM = $" + toHexString(scrollColorRam, 4)
.print "     switchPages = $" + toHexString(switchPages, 4)
