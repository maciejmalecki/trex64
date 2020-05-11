#importonce

.macro @actorDef(code, xPos, yPos, speed) {
  .byte code
  .byte xPos
  .byte yPos
  .byte speed
}

.macro @actorDefEnd() {
  .byte $ff
}
