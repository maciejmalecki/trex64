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

// player
.label PLAYER_SPRITE_TOP_OVL = 0
.label PLAYER_SPRITE_TOP = 1
.label PLAYER_SPRITE_BOTTOM_OVL = 2
.label PLAYER_SPRITE_BOTTOM = 3
.label PLAYER_COL = $0  // overlay color
.label DEATH_COL = $0  // overlay color
.label PLAYER_COL0 = $5 // multi individual
.label DEATH_COL0 = $1  // multi individual
.label PLAYER_COL1 = $7 // multi color 0
.label PLAYER_COL2 = $8 // multi color 1
.label PLAYER_X = 80
.label PLAYER_Y = 164 + 6
.label PLAYER_BOTTOM_Y = PLAYER_Y + 21
// animation phases
.label ANIMATION_WALK = 1
.label ANIMATION_JUMP_UP = 2
.label ANIMATION_JUMP_DOWN = 3
.label ANIMATION_DELAY = 4
// actors
.label ACT_PLAYER = 0
.label ACT_VOGEL = 1
