#import "../../_segments.asm"
.filenamespace level1

.label MAP_WIDTH = 240
.label MAP_ADDRESS = _level1Map
.label CHARSET_SIZE = 128
.label CHARSET_ADDRESS = _level1Charset

.segment Charsets
_level1Charset: .import binary "level-1-charset.bin"

.segment LevelData
_level1Map: .import binary "level-1-map.bin"
