#import "../../_segments.asm"
.filenamespace level1

// level meta data
.label MAP_WIDTH = 240
.label MAP_ADDRESS = _map
.label CHARSET_SIZE = 128
.label CHARSET_ADDRESS = _charset
.label BORDER_COLOR = 14
.label BG_COLOR_0 = 6
.label BG_COLOR_1 = 15
.label BG_COLOR_2 = 14

.segment Charsets
_charset: .import binary "level-1-charset.bin"

.segment LevelData
_map: .import binary "level-1-map.bin"
