#importonce
.filenamespace c64lib

// ---- game state constants ----
.label GAME_STATE_LIVE = 1
.label GAME_STATE_KILLED = 2
.label GAME_STATE_GAME_OVER = 3
.label GAME_STATE_LEVEL_END_SEQUENCE = 4
.label GAME_STATE_NEXT_LEVEL = 5
.label GAME_STATE_GAME_FINISHED = 6

// ---- enemy and power ups constants ----
.label EN_VOGEL = 1
.label EN_SCORPIO = 2
.label EN_SNAKE = 3

// ---- data model constants ----
.label MAP_HEIGHT = 12
.label MAP_CHARSET_OFFSET = 64

// ---- game config ----
.label CFG_CONTROLS = %00000001
.label CFG_SOUND = %00000010

// ---- dashboard ----
.label DASHBOARD_Y = 50
.label DASHBOARD_LEFT_X = 34
.label DASHBOARD_RIGHT_X = 4
.label DASHBOARD_RIGHT_SPC = 2

// ---- misc ----
.label MAX_DELAY = 10

// ---- keyboard ----
// title screen
.label KEY_F1 = %00010000
.label KEY_F3 = %00100000
.label KEY_F5 = %01000000
.label KEY_F7 = %00001000
.label KEY_FUNCTION_MASK = KEY_F1 + KEY_F3 + KEY_F5 + KEY_F7
// level, ingame, end game
.label KEY_SPACE = %00010000
.label KEY_COMMODORE = %00100000
.label KEY_INGAME_MASK = KEY_SPACE + KEY_COMMODORE
