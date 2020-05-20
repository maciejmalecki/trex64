#import "_segments.asm"
.filenamespace c64lib
.segment Sfx

.label SFX_CHANNEL = 14

sfxLanding: {
  .label PITCH = $90
  .byte $44, $66
  .byte $00
  .byte PITCH, $81
  .fill 3, PITCH
  .byte PITCH, $80
  .fill 3, PITCH
  .byte $00
}

sfxDuck:
  .byte $24, $44
  .byte $00
  .byte $c0, $11, $c1, $c2
  .byte $c3, $10, $c4, $c5, $c6
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

sfxSnake: {
  .label PITCH_HI = $e0
  .label PITCH_LO = $d0

  .byte $f5, $a5
  .byte $00
  .byte PITCH_LO, $81, PITCH_HI
  .for (var i = 0; i < 4; i++) {
    .byte PITCH_LO, PITCH_HI
  }
  .byte PITCH_LO, $80
  .byte $00
}

sfxEnd:
