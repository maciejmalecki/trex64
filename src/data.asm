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
txt_originalConcept:  .text "based on google chrome easter egg"; .byte $ff
// title screen menu
txt_menu:             .text "    f1        f3        f5 world 1-"; .byte $ff
txt_controlsJoy:      .text "joy 2"; .byte $ff
txt_controlsKey:      .text "keys "; .byte $ff
txt_soundMus:         .text "music"; .byte $ff
txt_soundFx:          .text "fx   "; .byte $ff
txt_startGame:        incText("hit fire or space to start", 64); .byte $ff
// title credits
txt_page_0_0:         incText("the lockdown studio presents", 64); .byte $ff

txt_page_1_0:         incText("t-rex  64", 64); .byte $ff
txt_page_1_1:         incText(" preview", 64); .byte $ff

txt_page_2_0:         incText("graphics:          zuza malecka", 64); .byte $ff
txt_page_2_1:         incText("                    ola malecka", 64); .byte $ff
txt_page_2_2:         incText("                 maciej malecki", 64); .byte $ff

txt_page_3_0:         incText(" music & sfx:   maciej malecki", 64); .byte $ff

txt_page_4_0:         incText("    code:     maciej malecki", 64); .byte $ff

txt_page_5_0:         incText("              how to play?", 64); .byte $ff
txt_page_5_1:         incText("use fire or up to jump and down to duck", 64); .byte $ff
txt_page_5_2:         incText("or space/cbm respectively when on keys", 64); .byte $ff

// level start screen
txt_entering:         incText("world  0-0", 64); .byte $ff
txt_getReady:         incText("get ready!", 64); .byte $ff
// end game screen
txt_endGame1:         incText("congratulations!", 64); .byte $ff
txt_endGame2:         incText("you have finished the game", 64); .byte $ff
txt_fullGame0:        .text "in the full game:"; .byte $ff
txt_fullGame1:        .text "more levels"; .byte $ff
txt_fullGame2:        .text "more worlds"; .byte $ff
txt_fullGame3:        .text "more enemies"; .byte $ff
txt_fullGame4:        .text "better music"; .byte $ff
txt_fullGame5:        .text "and still for free!"; .byte $ff
txt_pressAnyKey:      incText("hit the button", 64); .byte $ff
// color cycles
colorCycle1:          .byte GREY, GREY, LIGHT_GREY, WHITE, WHITE, LIGHT_GREY, GREY, GREY, BLACK, $ff
colorCycle2:          .byte BLACK, LIGHT_RED, RED, LIGHT_RED, YELLOW, WHITE, YELLOW, YELLOW, BLACK, $ff
fadeIn:               .byte BLACK, DARK_GREY, GREY, LIGHT_GREY, WHITE, $ff
fadeOut:              .byte WHITE, LIGHT_GREY, GREY, DARK_GREY, BLACK, $ff
