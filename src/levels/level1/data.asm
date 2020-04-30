#import "../../_segments.asm"
#import "../../_constants.asm"
.filenamespace level1

.var _charsetData = LoadBinary("charset.bin")
.var _tileData = LoadBinary("tiles.bin")
.var _tileColorsData = LoadBinary("colors.bin")
.var _map1Data = LoadBinary("map-1.bin")
.var _map2Data = LoadBinary("map-2.bin")

// level meta data
.label MAP_1_WIDTH = _map1Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_1_ADDRESS = _map1
.label MAP_1_DELTA_X = 1<<5 // x2
.label MAP_1_WRAPPING_MARK = %00000110

.label MAP_2_WIDTH = _map2Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_2_ADDRESS = _map2
.label MAP_2_DELTA_X = 1<<6 // x4
.label MAP_2_WRAPPING_MARK = %00000100

.label CHARSET_SIZE = _charsetData.getSize()/8
.label CHARSET_ADDRESS = _charset

.label TILES_SIZE = _tileData.getSize()/4
.label TILES_COLORS_ADDRESS = _colors
.label TILES_ADDRESS = _tiles

.label BORDER_COLOR = 11
.label BG_COLOR_0 = 11
.label BG_COLOR_1 = 8
.label BG_COLOR_2 = 10

// level data
.segment Charsets
_charset: .fill _charsetData.getSize(), _charsetData.get(i)

.segment LevelData
_map1: .fill _map1Data.getSize(), _map1Data.get(i)
_map2: .fill _map2Data.getSize(), _map2Data.get(i)
_colors: .fill _tileColorsData.getSize(), _tileColorsData.get(i)
_tiles:
  .fill _tileData.getSize() / 4, _tileData.get(i*4) + c64lib.MAP_CHARSET_OFFSET
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 1) + c64lib.MAP_CHARSET_OFFSET
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 2) + c64lib.MAP_CHARSET_OFFSET
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 3) + c64lib.MAP_CHARSET_OFFSET

