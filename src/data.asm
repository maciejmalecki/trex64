#import "chipset\lib\vic2.asm"
#import "text\lib\text.asm"
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
txt_author:           .text "by zuza, ola & maciek"; .byte $ff
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
txt_entering:         incText("world  0-0", 64); .byte $ff
txt_getReady:         incText("get ready!", 64); .byte $ff
// end game screen
txt_endGame1:         .text "congratulations!"; .byte $ff
txt_endGame2:         .text "you have finished the game"; .byte $ff
txt_pressAnyKey:      .text "hit the button"; .byte $ff
// color cycles
colorCycle1:          .byte GREY, GREY, LIGHT_GREY, WHITE, WHITE, LIGHT_GREY, GREY, GREY, BLACK, $ff
colorCycle2:          .byte BLACK, LIGHT_RED, RED, LIGHT_RED, YELLOW, WHITE, YELLOW, YELLOW, BLACK, $ff
