#import "_segments.asm"
#import "common/lib/invoke.asm"

.filenamespace c64lib

.label ACT_MAX_SIZE = 4

.segment Code

/*
 * Add new visible actor. Fetch free sprite number from the stack.
 *
 * In:
 *      PushB: code
 *      PushW: x
 *      PushB: y
 *      PushB: speed
 * Out:
 *      X slot index
 * Mod:
 *      A, X
 */
act_add: {
  ldx #0
  loop:
    cpx #ACT_MAX_SIZE
    beq end
    lda act_code,x
    beq found
    inx
    jmp loop
  found:
    invokeStackBegin(returnPtr)
    pla
    sta act_speed,x
    pla
    sta act_xHi,x
    pla
    sta act_xLo,x
    pla
    sta act_code,x
    invokeStackEnd(returnPtr)
  end:
    ldy act_stackPtr
    lda act_spriteStack,y
    sta act_sprite,x
    dey
    sta act_stackPtr
    rts
  // local vars
  returnPtr: .word 0
}

/*
 * Remove visible actor. Return sprite number to the stack.
 *
 * In:  X - number of actor to be removed: 0..ACT_MAX_SIZE-1
 * Mod:
 *      Y, A
 */
act_remove: {
  // release sprite number
    lda act_stackPtr
    tay
    iny
    lda act_sprite,x
    sta act_spriteStack,y
    sty act_stackPtr
  // remove actor
  loop:
    lda act_code + 1,x
    beq clearLast
    sta act_code,x
    lda act_xLo + 1,x
    sta act_xLo,x
    lda act_xHi + 1,x
    sta act_xHi,x
    lda act_y + 1,x
    sta act_y,x
    lda act_speed + 1,x
    sta act_speed,x
    lda act_sprite + 1,x
    sta act_sprite,x
    inx
    cpx #ACT_MAX_SIZE
  bne loop
    dex
  clearLast:
    lda #0
    sta act_code,x
  rts
}

/*
 * Remove all actors, reset sprite number stack.
 *
 * Mod: A, X
 */
act_reset: {
  ldx #0
  lda #0
  loop:
    sta act_code,x
    inx
    cpx #ACT_MAX_SIZE
  bne loop
  // reset sprite number stack
  lda #4
  sta act_spriteStack
  lda #5
  sta act_spriteStack + 1
  lda #6
  sta act_spriteStack + 2
  lda #7
  sta act_spriteStack + 3
  lda #3
  sta act_stackPtr
  rts
}

.segment Data

act_code:         .fill ACT_MAX_SIZE, 0
act_xLo:          .fill ACT_MAX_SIZE, 0
act_xHi:          .fill ACT_MAX_SIZE, 0
act_y:            .fill ACT_MAX_SIZE, 0
act_speed:        .fill ACT_MAX_SIZE, 0
act_sprite:       .fill ACT_MAX_SIZE, 0
act_spriteStack:  .fill ACT_MAX_SIZE, 0
act_stackPtr:     .byte 0
