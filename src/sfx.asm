#import "_segments.asm"
.filenamespace c64lib
.segment Sfx

.label SFX_CHANNEL = 14

sfxDuck: {
  .label LO = $c0
  .label HI = $c7
  .label WAVEFORM = $10

  .byte $24, $f4 // ADSR
  .byte $00
  .byte LO, WAVEFORM + 1
  .for(var i = LO + 1; i < (LO + HI)/2; i++) {
    .byte i
  }
  .byte (LO + HI)/2, WAVEFORM
  .for(var i =(LO + HI)/2 + 1; i < HI; i++) {
    .byte i
  }
  .byte $00
}

sfxJump: {
  .label PITCH_LO = $b2
  .label PITCH_HI = $c1
  .label WAVEFORM = $10

  .byte $84, $f1 // ADSR
  .byte $00
  .byte PITCH_LO, WAVEFORM + 1
  .for (var i = PITCH_LO; i < (PITCH_LO + PITCH_HI)/2; i++) {
    .byte i
  }
  .byte (PITCH_LO + PITCH_HI)/2, WAVEFORM
  .for (var i = (PITCH_LO + PITCH_HI)/2 + 1; i < PITCH_HI; i++) {
    .byte i
  }
  .byte $00
}

sfxDeath: {
  .label HI = $bf
  .label LO = $b1
  .label STEP = 2
  .label WAVEFORM = $10

  .byte $84, $f1 // ADSR
  .byte $00
  .byte HI, WAVEFORM + 1
  .for (var i = HI; i > (LO + HI)/2; i = i - STEP) {
    .byte i
  }
  .byte (LO + HI)/2, WAVEFORM
  .for (var i = (LO + HI)/2 - 1; i > LO; i = i - STEP) {
    .byte i
  }
  .byte $00
}

sfxSnake: {
  .label HI = $e0
  .label LO = $d0
  .label LEN = 4
  .label WAVEFORM = $80

  .byte $a0, $fa // ADSR
  .byte $00
  .byte LO, WAVEFORM + 1, HI
  .for (var i = 0; i < LEN; i++) {
    .byte LO, HI
  }
  .byte LO, WAVEFORM, HI
  .for (var i = 0; i < LEN; i++) {
    .byte LO, HI
  }
  .byte $00
}

sfxVogel: {
  .label HI = $e0
  .label LO = $d0
  .label LEN = 4
  .label WAVEFORM = $40
  .label PULSE = $08

  .byte $a0, $fa // ADSR
  .byte PULSE
  .byte LO, WAVEFORM + 1, HI
  .for (var i = 0; i < LEN; i++) {
    .byte LO, HI
  }
  .byte LO, WAVEFORM, HI
  .for (var i = 0; i < LEN; i++) {
    .byte LO, HI
  }
  .byte $00
}

sfxScorpio: {
  .label HI = $96
  .label LO = $90
  .label LEN = 6
  .label WAVEFORM = $20
  .label PULSE = $80

  .byte $23, $aa // ADSR
  .byte PULSE
  .byte LO, WAVEFORM + 1, HI
  .for (var i = 0; i < LEN; i++) {
    .byte LO, HI
  }
  .byte LO, WAVEFORM, HI
  .for (var i = 0; i < LEN; i++) {
    .byte LO, HI
  }
  .byte $00
}

sfxLanding: {
  .label PITCH = $90
  .label LEN = 3
  .label WAVEFORM = $80

  .byte $33, $44 // ADSR
  .byte $00
  .byte PITCH, WAVEFORM + 1
  .fill LEN, PITCH
  .byte PITCH, WAVEFORM
  .fill LEN, PITCH
  .byte $00
}

sfxEnd:
