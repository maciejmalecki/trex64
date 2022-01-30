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
#import "chipset/lib/vic2.asm"
#import "text/lib/text.asm"
#import "_segments.asm"
#importonce

.filenamespace c64lib

.segment Data
spriteXPosRegisters:
  .byte <SPRITE_0_X; .byte <SPRITE_1_X; .byte <SPRITE_2_X; .byte <SPRITE_3_X
  .byte <SPRITE_4_X; .byte <SPRITE_5_X; .byte <SPRITE_6_X; .byte <SPRITE_7_X
spriteYPosRegisters:
  .byte <SPRITE_0_Y; .byte <SPRITE_1_Y; .byte <SPRITE_2_Y; .byte <SPRITE_3_Y
  .byte <SPRITE_4_Y; .byte <SPRITE_5_Y; .byte <SPRITE_6_Y; .byte <SPRITE_7_Y
// ---- texts ----
// title screen
txt_author:           .text " https://maciejmalecki.github.io/trex64"; .byte $ff
// title screen menu
txt_menu:             .text "    f1        f3        f5 world 1-"; .byte $ff
txt_controlsJoy:      .text "joy 2"; .byte $ff
txt_controlsKey:      .text "keys "; .byte $ff
txt_soundMus:         .text "music"; .byte $ff
txt_soundFx:          .text "fx   "; .byte $ff
txt_startGame:        incText("hit fire or space to start", 64); .byte $ff
// title credits
txt_page_0_0:         incText("the lockdown studio presents", 64); .byte $ff

txt_page_1_0:         incText("a 2022 production", 64); .byte $ff

txt_page_2_0:         incText("t-rex 64", 64); .byte $ff
txt_page_2_1:         incText("pal", 64); .byte $ff
txt_page_2_2:         incText("ntsc", 64); .byte $ff

txt_page_3_0:         incText("inspired by google chrome easter egg", 64); .byte $ff

txt_page_4_0:         incText("graphics:  zuza malecka", 64); .byte $ff
txt_page_4_1:         incText("ola malecka", 64); .byte $ff
txt_page_4_2:         incText("maciej malecki", 64); .byte $ff

txt_page_5_0:         incText("music & sfx:  maciej malecki", 64); .byte $ff
txt_page_5_1:         incText("playroutine:  lasse oorni", 64); .byte $ff

txt_page_6_0:         incText("code:  maciej malecki", 64); .byte $ff

txt_page_7_0:         incText("how to play?", 64); .byte $ff
txt_page_7_1:         incText("use fire or up to jump and down to duck", 64); .byte $ff
txt_page_7_2:         incText("or space/cbm respectively when on keys", 64); .byte $ff

// level start screen
txt_entering:         incText("world  0-0", 64); .byte $ff
txt_getReady:         incText("get ready!", 64); .byte $ff
txt_extraLive:        incText("+1 extra live!", 64); .byte $ff
// end game screen
txt_endGame1:         incText("congratulations!", 64); .byte $ff
txt_endGame2:         incText("you have finished the game", 64); .byte $ff
txt_endGame3:        .text "t-rex has been saved"; .byte $ff
txt_endGame4:        .text "from mass extinction"; .byte $ff
txt_endGame5:        .text "see you in the next"; .byte $ff
txt_endGame6:        .text "game, maybe..."; .byte $ff
txt_pressAnyKey:      incText("hit the button", 64); .byte $ff
// color cycles
colorCycle1:          .byte GREY, GREY, GREY, LIGHT_GREY, WHITE, WHITE, LIGHT_GREY, GREY, GREY, BLACK, $ff
colorCycle2:          .byte BLACK, LIGHT_RED, RED, LIGHT_RED, YELLOW, YELLOW, WHITE, YELLOW, YELLOW, BLACK, $ff
fadeIn:               .byte BLACK, BLACK, DARK_GREY, DARK_GREY, GREY, GREY, LIGHT_GREY, LIGHT_GREY, WHITE, $ff
fadeOut:              .byte WHITE, LIGHT_GREY, LIGHT_GREY, GREY, GREY, DARK_GREY, DARK_GREY, BLACK, BLACK, $ff
