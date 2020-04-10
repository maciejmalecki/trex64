.label _JUMP_TABLE_LENGTH = 14
.label _JUMP_LINEAR_LENGTH = 17
.label _GRAVITY_FACTOR = 3

.function _polyJump(i) {
  .return (pow(_JUMP_TABLE_LENGTH / 2, 2) - pow(_JUMP_TABLE_LENGTH / 2 - i, 2)) / _GRAVITY_FACTOR
}

.function _linearJump(i) {
  .return i * _polyJump(1)
}

.macro generateJumpTable() {
  .fill _JUMP_LINEAR_LENGTH, _linearJump(i)
  .fill _JUMP_TABLE_LENGTH, _linearJump(_JUMP_LINEAR_LENGTH) + _polyJump(i)
  .fill _JUMP_LINEAR_LENGTH, _linearJump(_JUMP_LINEAR_LENGTH - i)
  .byte 0
  .byte $ff
}
