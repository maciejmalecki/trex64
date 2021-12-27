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

// ---- game parameters ----
.label INVINCIBLE = 0

// scoring
.label SCORE_FOR_PROGRESS_DELAY = 5
.label SCORE_FOR_PROGRESS = $0001

// ---- game state constants ----
.label GAME_STATE_LIVE = 1
.label GAME_STATE_KILLED = 2
.label GAME_STATE_GAME_OVER = 3
.label GAME_STATE_LEVEL_END_SEQUENCE = 4
.label GAME_STATE_NEXT_LEVEL = 5
.label GAME_STATE_GAME_FINISHED = 6

// ---- enemy and power ups constants ----
.label EN_VOGEL = 1
.label EN_SCORPIO = 2
.label EN_SNAKE = 3

// ---- data model constants ----
.label MAP_HEIGHT = 12
.label MAP_CHARSET_OFFSET = 64

// ---- game config ----
.label CFG_CONTROLS = %00000001
.label CFG_SOUND = %00000010

// collision detection
.label X_COLLISION_OFFSET = 12 - 24
.label Y_COLLISION_OFFSET = 29 - 50 - 6

// material codes
.label MAT_KILLS         = %1000
.label MAT_ANIMATE       = %0100
.label MAT_ANIMATE_RIGHT = %0010

// ---- dashboard ----
.label DASHBOARD_Y = 50
.label DASHBOARD_LEFT_X = 34
.label DASHBOARD_RIGHT_X = 4
.label DASHBOARD_RIGHT_SPC = 0

// visual effects
.label COLOR_CYCLE_DELAY = 4
.label TITLE_COLOR_CYCLE_DELAY = 3

// title screen layout
.label LOGO_TOP = 1
.label AUTHOR_TOP = 12
.label CREDITS_TOP = 15
.label CREDITS_SIZE = 5
.label MENU_TOP = 22

// credits display handling
.label CREDITS_FADE_IN  = %00000001
.label CREDITS_FADE_OUT = %00000010
.label CREDITS_DISPLAY  = %00000100
.label CREDITS_PAGE_0 = $10
.label CREDITS_PAGE_1 = $20
.label CREDITS_PAGE_2 = $30
.label CREDITS_FADE_DELAY = 4
.label CREDITS_PAGE_DISPLAY_TIME = 200
.label CREDITS_LAST = $80 // -$10

// ---- misc ----
.label MAX_DELAY = 10

// ---- music ----
.label TITLE_TUNE = 5
.label INGAME_TUNE = 0
.label INGAME_SFX_TUNE = 2
.label NEXT_LEVEL_TUNE = 3
.label GAME_OVER_TUNE = 1
.label END_GAME_TUNE = 4
.label MUSIC_START_ADDR = $f500

// ---- keyboard ----
// title screen
.label KEY_F1 = %00010000
.label KEY_F3 = %00100000
.label KEY_F5 = %01000000
.label KEY_F7 = %00001000
.label KEY_FUNCTION_MASK = KEY_F1 + KEY_F3 + KEY_F5 + KEY_F7
// level, ingame, end game
.label KEY_SPACE = %00010000
.label KEY_COMMODORE = %00100000
.label KEY_INGAME_MASK = KEY_SPACE + KEY_COMMODORE
// max level in level selection
.label MAX_LEVEL = 3
