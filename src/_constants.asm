#importonce
.filenamespace c64lib

// ---- game state constants ----
.label GAME_STATE_LIVE = 1
.label GAME_STATE_KILLED = 2
.label GAME_STATE_GAME_OVER = 3
.label GAME_STATE_LEVEL_END_SEQUENCE = 4
.label GAME_STATE_NEXT_LEVEL = 5
.label GAME_STATE_GAME_FINISHED = 6

// ---- data model constants ----
.label MAP_HEIGHT = 12
.label MAP_CHARSET_OFFSET = 64

// ---- misc ----
.label MAX_DELAY = 10
