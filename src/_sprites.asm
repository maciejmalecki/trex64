#importonce
.filenamespace c64lib

// player
.label PLAYER_SPRITE_TOP_OVL = 0
.label PLAYER_SPRITE_TOP = 1
.label PLAYER_SPRITE_BOTTOM_OVL = 2
.label PLAYER_SPRITE_BOTTOM = 3
.label PLAYER_COL = $0  // overlay color
.label DEATH_COL  = $0  // overlay color
.label PLAYER_COL0 = $5 // multi individual
.label DEATH_COL0 = $1  // multi individual
.label PLAYER_COL1 = $9 // multi color 0
.label PLAYER_COL2 = $8 // multi color 1
.label PLAYER_X = 80
.label PLAYER_Y = 164
.label PLAYER_BOTTOM_Y = PLAYER_Y + 21
// animation phases
.label ANIMATION_WALK = 1
.label ANIMATION_JUMP_UP = 2
.label ANIMATION_JUMP_DOWN = 3
.label ANIMATION_DELAY = 4
