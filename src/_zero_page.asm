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
#importonce
.filenamespace c64lib

//#define use_watches

// ZERO page
.label z_x = 2                // $02,$03
.label z_y = 4                // $04,$05
.label z_width = 6            // $06
.label z_height = 7           // $07
.label z_map = 8              // $08,$09
.label z_phase = 10           // $0A

.label z_listPtr = 11         // $0B
.label z_displayListPtr = 12  // $0C,$0D
.label z_deltaX = 14          // $0E

.label z_acc0 = 15            // $0F

.label z_startingLevel = 16   // $10
.label z_mode = 17            // $11; 0 - no jumping, 1 - jumping
.label z_delay = 18           // $12
// keyboard handling
.label z_previousKeys = 19    // $13
.label z_currentKeys = 20     // $14

.label z_yPos = 21            // $15
.label z_jumpFrame = 22       // $16
.label z_delayCounter = 24    // $18
.label z_worldCounter = 25    // $19
.label z_levelCounter = 26    // $1A
.label z_gameState = 27       // $1B
.label z_lives = 28           // $1C
.label z_score = 29           // $1D,$1E,$1F
.label z_scoreDelay = 32      // $20
.label z_xPos = 33            // $21
.label z_gameConfig = 35      // $23

.label z_wrappingMark = 38    // $26
.label z_prevMode = 39        // $27
.label z_yPosTop = 40         // $28
.label z_yPosBottom = 41      // $29
.label z_isDuck = 42          // $2A

// actors
.label z_actorsBase = 43      // $2B,$2C
.label z_spriteEnable = 45    // $2D

// used for movement detection
.label z_oldX = 46            // $2E
.label z_sfxChannel = 47      // $2F

// jump handling
.label z_jumpPhase = 48       // $30; 0 - going up, 1 - peak, 2 - falling down
.label z_jumpLinear = 49      // $31
.label z_scrollingMark = 50   // $32

// obstacles
.label z_bgDeath = 51         // $33
.label z_colorRAMShifted = 52 // $34
.label z_scrollReg = 53       // $35

// background scroller pov
.label z_bgX = 54             // $36, $37
.label z_doGameOver = 56      // $38

// visual effects
.label z_colorCycleDelay = 57 // $39

// high score counter
.label z_hiScoreMark = 58     // $3A, $3B
.label z_hiScore = 60         // $3C, $3D, $3E
.label z_colorCycleDelay2 = 63// $3F

// credits display
.label z_creditsPhase = 64    // $40
.label z_creditsFadeCtr = 65  // $41
.label z_creditsDelayCtr = 66 // $42

// materials pointer
.label z_materialsLo = 67     // $43, $44

// animated background elements
.label z_right_anim_char = 69 // $45, $46
.label z_bottom_anim_char = 71// $47, $48
.label z_anim_delay = 73      // $49

.label z_ntsc = 74            // $4A

// used by sprite multiplexer
.label z_spritesStashed = 127 // $7F
.label z_stashArea = 128      // $80


#if use_watches
  .watch z_x
  .watch z_x+1
  .watch z_phase
  .watch z_deltaX
  .watch z_xPos
  .watch z_acc0
  .watch z_wrappingMark
  .watch z_scrollingMark
  .watch z_colorRAMShifted
#endif
