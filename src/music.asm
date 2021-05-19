#import "chipset/lib/vic2.asm"
#import "_segments.asm"
#import "_zero_page.asm"
#importonce

.filenamespace c64lib

.var music = LoadSid("music/consultant.sid")

.label musicLocation = music.location
.label musicSize = music.size

.segment Music
musicData:
                      .fill music.size, music.getData(i)
endOfMusicData:

.segment Code
// Initialize music player.
initSound: {
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  rts
}

setupSounds: {
  lda #0
  sta z_sfxChannel
  rts
}

playMusic: {
  debugBorderStart()
  jsr music.play
  debugBorderEnd()
  rts
}

playJump: {
  lda #<sfxJump
  ldy #>sfxJump
  jmp playSfx
}

playDuck: {
  lda #<sfxDuck
  ldy #>sfxDuck
  jmp playSfx
}

playDeath: {
  lda #<sfxDeath
  ldy #>sfxDeath
  jmp playSfx
}

playLanding: {
  lda #<sfxLanding
  ldy #>sfxLanding
  jmp playEnemy
}

playSfx: {
  ldx #14
  jsr music.init + 6
  rts
}

playSnake: {
  lda #<sfxSnake
  ldy #>sfxSnake
  jmp playEnemy
}

playVogel: {
  lda #<sfxVogel
  ldy #>sfxVogel
  jmp playEnemy
}

playScorpio: {
  lda #<sfxScorpio
  ldy #>sfxScorpio
  jmp playEnemy
}

playEnemy: {
  ldx z_sfxChannel
  beq !+
    ldx #0
    stx z_sfxChannel
    jmp play
  !:
    ldx #7
    stx z_sfxChannel
  play:
  jsr music.init + 6
  rts
}

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
