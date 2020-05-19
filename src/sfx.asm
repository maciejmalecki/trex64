#import "_segments.asm"
.filenamespace c64lib
.segment Data

.label SFX_CHANNEL = 14

sfxLanding:
  .byte $24, $00
  .byte $00
  .byte $a0, $81
  .for (var i = 0; i < 10; i++) {
    .byte $a0
  }
  .byte $00

sfxJump:
  .byte $84, $81 // AD, SR
  .byte $04      // pulse width
  .byte $b2, $11
  .for (var i = $b2; i < $c1; i++) {
    .byte i
  }
  .byte $00

sfxDeath:
  .byte $84, $81 // ad, sr
  .byte $08
  .byte $c1, $11
  .for (var i = $bf; i > $b2; i = i-2) {
    .byte i
  }
  .byte $00
