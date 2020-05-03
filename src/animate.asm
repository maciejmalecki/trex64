#import "_animate.asm"
#import "common/lib/invoke.asm"

.filenamespace c64lib

.struct AniConfig  {
    page0,
    page1,
    control,
    sequenceLo,
    sequenceHI,
    frame
}

/*
 * In:
 *      X - slot index 0..7
 *      A - control byte
 *      pushParam0 - sequenceLo, Hi
 * Mod: A
 */
.macro ani_setAnimation(aniConfig) {
    // store control
    sta aniConfig.control,x
    // init frame
    and #ANIM_CTRL_LOOP
    beq noLoop
        lda #01
        jmp initFrame
    noLoop:
        lda #00
    initFrame:
        sta aniConfig,x
    // store sequence addresses
    invokeStackBegin(ptr)
    pullParamB(sequenceHi)
    pullParamB(sequenceLo)
    lda sequenceLo:#$00
    sta aniConfig.sequenceLo,x
    lda sequenceHi:#$00
    sta aniConfig.sequenceHi,x
    invokeStackEnd(ptr)
    rts
    ptr: .word $0000
}

/*
 * Mod: A, X
 */
.macro ani_animate(aniConfig) {

}