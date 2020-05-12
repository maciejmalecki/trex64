#importonce

.macro @actorDef(code, xPos, yPos, speed, color) {
  .byte code
  .byte xPos
  .byte yPos
  .byte speed
  .byte color
}

.macro @actorDefEnd() {
  .byte $ff
}
