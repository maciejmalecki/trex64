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

// #define VISUAL_DEBUG

#import "common/lib/common.asm"
#import "common/lib/mem.asm"
#import "common/lib/math.asm"
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

.file [name="./rex.prg", segments="Code, Data, AuxGfx, Sfx, Materials, Charsets, LevelData, Sprites, Music", modify="BasicUpstart", _start=$0810]

// starting amount of lives
.label LIVES = 9
// starting level
.label STARTING_WORLD = 2
.label STARTING_LEVEL = 1

// ---- levels ----
#import "levels/level1/data.asm"
#import "levels/level2/data.asm"
#import "levels/level3/data.asm"

// -------- Main program ---------
.segment Code

// ---- game flow management ----
start:
  // main init
  jsr cfg_configureC64
  // jsr clearZeroPage
  jsr detectNTSC
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
  jsr updateDashboard
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
    beq !+
    jmp notKilled
    !:
      lda z_bgDeath
      beq alwaysJump
      lda z_worldCounter
      cmp #1
      bne noJump
      alwaysJump:
      {
        lda z_mode
        bne !+
          lda #1
          sta z_mode
          lda #0
          sta z_jumpFrame
        !:
      }
      noJump:

      lda z_worldCounter
      cmp #1
      beq goShowDeath
      cmp #2
      bne world3
        lda z_bgDeath
        bne goShowWaterDeath
        jmp goShowDeath
      world3:
        lda z_bgDeath
        bne goShowFireDeath
      goShowDeath:
        jsr spr_showDeath
        jsr playDeath
        jmp goAfterPlayDeath
      goShowFireDeath:
        jsr spr_showFireDeath
        jsr playBurn
        jmp goAfterPlayDeath
      goShowWaterDeath:
        jsr spr_showWaterDeath
        jsr playSplash
      goAfterPlayDeath:

      // remember death position
      lda z_x
      sta z_hiScoreMark
      lda z_x + 1
      sta z_hiScoreMark + 1

      // check for combo death
      lda #0
      sta z_bgDeath
      lda #100
      sta z_delayCounter
      checkDelay: {
        jsr checkBGCollisions
        lda z_bgDeath
        beq noCombo
          lda z_worldCounter
          cmp #2
          bne checkWorld3
            jsr spr_showWaterDeath
            jsr playSplash
            jmp !+
          checkWorld3:
            cmp #3
            bne noCombo
              jsr spr_showFireDeath
              jsr playBurn
          !:
          wait #100
        noCombo:
        lda z_delayCounter
      }
      bne checkDelay

      // decrement lives
      dec z_lives
      bne livesLeft
        lda #GAME_STATE_GAME_OVER
        sta z_gameState
        jmp displayGameOver
      livesLeft:

    notKilled:
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
    wait #80
    // hack to fix #54
    lda #GAME_STATE_GAME_OVER
    sta z_gameState
  gameOver:
    jsr stopCopper
    jsr spr_hidePlayers
    rts
}

setNTSC: {
  lda #1
  sta z_ntsc
  rts
}

detectNTSC: {
  lda #0
  sta z_ntsc
  sta z_ntscMusicCtr
  detectNtsc(0, setNTSC)
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
  sta z_extraLiveAwarded

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
  lda z_hiScoreMark + 1
  cmp z_x + 1
  bcc doScore
  bne dontScore
  lda z_hiScoreMark
  cmp z_x
  bcc doScore
  dontScore:
    rts
  doScore:
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
  sei
  // just in case sprites and music are below IO are after decrunching
  configureMemory(RAM_RAM_RAM)
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
  configureMemory(RAM_IO_RAM)
  cli
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
  and #%11110000
  ora #%00000111
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
  cmp #3
  beq world3
  cmp #2
  beq world2
  world1:
    lda z_levelCounter
    cmp #5
    beq nextWorld
    inc z_levelCounter
    jmp end
  world2:
    lda z_levelCounter
    cmp #5
    beq nextWorld
    inc z_levelCounter
    jmp end
  world3:
    lda z_levelCounter
    cmp #4
    beq level3_end
    inc z_levelCounter
    jmp end
    level3_end:
      lda #GAME_STATE_GAME_FINISHED
      sta z_gameState
      jmp end
  nextWorld:
      inc z_worldCounter
      inc z_lives
      lda #1
      sta z_levelCounter
      sta z_extraLiveAwarded
  end:
  rts
}

// TODO move it to text/text2x2/subs
/*
 * In: startAddress, targetAddress, X (TileSet size).
 * Mod: A
 */
unpackTileSet: {
  stx store
  invokeStackBegin(returnPtr)
  pullParamW(dest)
  pullParamW(src)
  ldy #4
  loop:
    ldx store
    !:
      dex
      lda src: $ffff,x
      sta dest: $ffff,x
      cpx #0
    bne !-
    // increment src address base
    clc
    lda src
    adc store
    sta src
    lda src + 1
    adc #0
    sta src + 1
    // increment destination address base
    inc dest + 1
    dey
  bne loop

  invokeStackEnd(returnPtr)
  rts
  returnPtr: .word $0000
  store: .byte $0 // <- tileset size
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
  pushParamW(CHARGEN_ADDR)
  pushParamW(levelCfg.CHARSET_SIZE*8)
  jsr copyLargeMemForward

  // copy tiles colors
  pushParamW(levelCfg.TILES_COLORS_ADDRESS)
  pushParamW(tileColors)
  pushParamW(levelCfg.TILES_SIZE)
  jsr copyLargeMemForward

  // copy tiles
  pushParamW(levelCfg.TILES_ADDRESS)
  pushParamW(tileDefinition)
  ldx #levelCfg.TILES_SIZE
  jsr unpackTileSet

  configureMemory(RAM_IO_RAM)
  cli

  // set up materials pointer
  lda #[<levelCfg.MATERIALS_ADDRESS]
  sta z_materialsLo
  lda #[>levelCfg.MATERIALS_ADDRESS]
  sta z_materialsLo + 1

  // set up bg animation
  lda #<CHARGEN_ADDR
  sta z_right_anim_char
  sta z_bottom_anim_char
  lda #>CHARGEN_ADDR
  sta z_right_anim_char + 1
  sta z_bottom_anim_char + 1

  mulAndAdd(levelCfg.RIGHT_ANIM_CHAR, 8, z_right_anim_char)
  mulAndAdd(levelCfg.BOTTOM_ANIM_CHAR, 8, z_bottom_anim_char)

  rts
}

.macro setUpMap(mapAddress, mapWidth, deltaX, wrappingMark, scrollingMark, mapActors) {
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

  // set actors base and pointer
  lda #<mapActors
  sta z_actorsBase
  lda #>mapActors
  sta z_actorsBase + 1

  rts
}

setUpWorld1: setUpWorld(level1)
setUpWorld2: setUpWorld(level2)
setUpWorld3: setUpWorld(level3)

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
    jsr setUpWorld2
    jmp end
  world3:
    jsr setUpWorld3
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
    cmp #4
    beq level1_4
    cmp #5
    beq level1_5
    level1_1:
      jsr setUpMap1_1
      jmp end
    level1_2:
      jsr setUpMap1_2
      jmp end
    level1_3:
      jsr setUpMap1_3
      jmp end
    level1_4:
      jsr setUpMap1_4
      jmp end
    level1_5:
      jsr setUpMap1_5
      jmp end
  world2:
    lda z_levelCounter
    cmp #2
    beq level2_2
    cmp #3
    beq level2_3
    cmp #4
    beq level2_4
    cmp #5
    beq level2_5
    level2_1:
      jsr setUpMap2_1
      jmp end
    level2_2:
      jsr setUpMap2_2
      jmp end
    level2_3:
      jsr setUpMap2_3
      jmp end
    level2_4:
      jsr setUpMap2_4
      jmp end
    level2_5:
      jsr setUpMap2_5
      jmp end
  world3:
    lda z_levelCounter
    cmp #2
    beq level3_2
    cmp #3
    beq level3_3
    cmp #4
    beq level3_4
    level3_1:
      jsr setUpMap3_1
      jmp end
    level3_2:
      jsr setUpMap3_2
      jmp end
    level3_3:
      jsr setUpMap3_3
      jmp end
    level3_4:
      jsr setUpMap3_4
  end:
  rts
}

setUpMap1_1: setUpMap(level1.MAP_1_ADDRESS, level1.MAP_1_WIDTH, level1.MAP_1_DELTA_X, level1.MAP_1_WRAPPING_MARK, level1.MAP_1_SCROLLING_MARK, level1.MAP_1_ACTORS)
setUpMap1_2: setUpMap(level1.MAP_2_ADDRESS, level1.MAP_2_WIDTH, level1.MAP_2_DELTA_X, level1.MAP_2_WRAPPING_MARK, level1.MAP_2_SCROLLING_MARK, level1.MAP_2_ACTORS)
setUpMap1_3: setUpMap(level1.MAP_3_ADDRESS, level1.MAP_3_WIDTH, level1.MAP_3_DELTA_X, level1.MAP_3_WRAPPING_MARK, level1.MAP_3_SCROLLING_MARK, level1.MAP_3_ACTORS)
setUpMap1_4: setUpMap(level1.MAP_4_ADDRESS, level1.MAP_4_WIDTH, level1.MAP_4_DELTA_X, level1.MAP_4_WRAPPING_MARK, level1.MAP_4_SCROLLING_MARK, level1.MAP_4_ACTORS)
setUpMap1_5: setUpMap(level1.MAP_5_ADDRESS, level1.MAP_5_WIDTH, level1.MAP_5_DELTA_X, level1.MAP_5_WRAPPING_MARK, level1.MAP_5_SCROLLING_MARK, level1.MAP_5_ACTORS)

setUpMap2_1: setUpMap(level2.MAP_1_ADDRESS, level2.MAP_1_WIDTH, level2.MAP_1_DELTA_X, level2.MAP_1_WRAPPING_MARK, level2.MAP_1_SCROLLING_MARK, level2.MAP_1_ACTORS)
setUpMap2_2: setUpMap(level2.MAP_2_ADDRESS, level2.MAP_2_WIDTH, level2.MAP_2_DELTA_X, level2.MAP_2_WRAPPING_MARK, level2.MAP_2_SCROLLING_MARK, level2.MAP_2_ACTORS)
setUpMap2_3: setUpMap(level2.MAP_3_ADDRESS, level2.MAP_3_WIDTH, level2.MAP_3_DELTA_X, level2.MAP_3_WRAPPING_MARK, level2.MAP_3_SCROLLING_MARK, level2.MAP_3_ACTORS)
setUpMap2_4: setUpMap(level2.MAP_4_ADDRESS, level2.MAP_4_WIDTH, level2.MAP_4_DELTA_X, level2.MAP_4_WRAPPING_MARK, level2.MAP_4_SCROLLING_MARK, level2.MAP_4_ACTORS)
setUpMap2_5: setUpMap(level2.MAP_5_ADDRESS, level2.MAP_5_WIDTH, level2.MAP_5_DELTA_X, level2.MAP_5_WRAPPING_MARK, level2.MAP_5_SCROLLING_MARK, level2.MAP_5_ACTORS)

setUpMap3_1: setUpMap(level3.MAP_1_ADDRESS, level3.MAP_1_WIDTH, level3.MAP_1_DELTA_X, level3.MAP_1_WRAPPING_MARK, level3.MAP_1_SCROLLING_MARK, level3.MAP_1_ACTORS)
setUpMap3_2: setUpMap(level3.MAP_2_ADDRESS, level3.MAP_2_WIDTH, level3.MAP_2_DELTA_X, level3.MAP_2_WRAPPING_MARK, level3.MAP_2_SCROLLING_MARK, level3.MAP_2_ACTORS)
setUpMap3_3: setUpMap(level3.MAP_3_ADDRESS, level3.MAP_3_WIDTH, level3.MAP_3_DELTA_X, level3.MAP_3_WRAPPING_MARK, level3.MAP_3_SCROLLING_MARK, level3.MAP_3_ACTORS)
setUpMap3_4: setUpMap(level3.MAP_4_ADDRESS, level3.MAP_4_WIDTH, level3.MAP_4_DELTA_X, level3.MAP_4_WRAPPING_MARK, level3.MAP_4_SCROLLING_MARK, level3.MAP_4_ACTORS)
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

// print memory map summary
.macro memSummary(name, address) {
  .print name + " = " + address + " ($" + toHexString(address, 4) + ")"
}
.macro memSummaryWithSize(name, address, size) {
  .print name + " = $" + toHexString(address, 4) + " - $" + toHexString(address + size - 1, 4) + " (" + size + " bytes)"
}

.print ""
.print "Memory summary:"
.print "---------------"

memSummary("     Start address", start)

memSummaryWithSize("    total PRG size", start, endOfTRex - start)
memSummaryWithSize("PRG size w/o music", start, sfxEnd - start)

memSummaryWithSize("      video page 0", SCREEN_PAGE_ADDR_0, 1024)
memSummaryWithSize("      video page 1", SCREEN_PAGE_ADDR_1, 1024)
memSummaryWithSize("     level chargen", CHARGEN_ADDR, 2048)
memSummaryWithSize("           sprites", SPRITE_ADDR, endOfSprites - beginOfSprites)


memSummaryWithSize("       tile colors", tileColors, 256)
memSummaryWithSize("      mapOffsetsLo", mapOffsetsLo, 12)
memSummaryWithSize("      mapOffsetsHi", mapOffsetsHi, 12)
memSummaryWithSize("  tiles definition", tileDefinition, 4*256)

memSummaryWithSize(" music player&data", music.init, music.size)

.print ""
.print "Free memory summary:"
.print "--------------------"

.print "free memory for uncrunched PRG left: " + ($CFFF - endOfTRex) + " bytes"
.print "free memory for PRG left:            " + (SCREEN_PAGE_ADDR_0 - sfxEnd) + " bytes"
.print "free memory for music left:          " + ($FFFF - 6 - (music.init + music.size)) + " bytes"
.print "free memory for sprites left:        " + (tileColors - (SPRITE_ADDR + endOfSprites - beginOfSprites)) + " bytes"

.print ""
.print "Assertions:"
.print "-----------"

.assert "Code and video ram does not overlap", sfxEnd <= SCREEN_PAGE_ADDR_0, true
.assert "Sprites and tiles data does not overlap", tileColors >= SPRITE_ADDR + endOfSprites - beginOfSprites, true
.assert "Music start address mismatch", music.init, MUSIC_START_ADDR

.print ""
