#import "../../_segments.asm"

.label LVL1_MAP_WIDTH = 240
.label LVL1_CHARSET_SIZE = 128

.segment Charsets
level1Charset: .import binary "level-1-charset.bin"

.segment LevelData
level1Map: .import binary "level-1-map.bin"

