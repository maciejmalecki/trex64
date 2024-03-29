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
#import "_segments.asm"
#import "_zero_page.asm"
#import "_constants.asm"
#import "delays.asm"
#importonce

.filenamespace c64lib

.var music = LoadSid("music/trex2.sid")

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
  jsr music.init
  rts
}

fadeOutMusic: {
  lda #FADE_OUT_TUNE
  jsr initSound
  rts
}

setupSounds: {
  lda #0
  sta z_sfxChannel
  rts
}

playMusic: {
  debugBorderEnd()
  lda z_ntsc
  beq doPlay
    ldx z_ntscMusicCtr
    inx
    stx z_ntscMusicCtr
    cpx #6
    bne doPlay
    ldx #0
    stx z_ntscMusicCtr
    debugBorderStart()
    rts
  doPlay:
    jsr music.play
  debugBorderStart()
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

playSplash: {
  lda #<sfxSplushDeath
  ldy #>sfxSplushDeath
  jmp playSfx
}

playBurn: {
  lda #<sfxBurnDeath
  ldy #>sfxBurnDeath
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

sfxSplushDeath: {
  .label HI = $d0
  .label LO = $c5
  .label LEN = 6
  .label WAVEFORM = $80

  .byte $a5, $c8 // ADSR
  .byte $00
  .byte LO, WAVEFORM + 1, HI
  .for (var i = 0; i < LEN; i++) {
    .byte HI, HI
  }
  .byte LO, WAVEFORM, HI
  .for (var i = 0; i < 2*LEN; i++) {
    .byte LO, LO
  }
  .byte $00
}

sfxBurnDeath: {
  .label HI = $ea
  .label LO = $e9
  .label LEN = 4
  .label WAVEFORM = $80

  .byte $95, $c8 // ADSR
  .byte $00
  .byte LO, WAVEFORM + 1, HI
  .for (var i = 0; i < LEN; i++) {
    .byte LO, HI
  }
  .byte LO, WAVEFORM, HI
  .for (var i = 0; i < 2*LEN; i++) {
    .byte LO, HI
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
