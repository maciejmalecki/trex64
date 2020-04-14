#import "../../_segments.asm"
#import "../../_constants.asm"
.filenamespace level1

.var _charsetData = LoadBinary("charset.bin")
.var _tileData = LoadBinary("tiles.bin")
.var _tileColorsData = LoadBinary("colors.bin")
.var _mapData = LoadBinary("map.bin")

// level meta data
.label MAP_WIDTH = _mapData.getSize() / c64lib.MAP_HEIGHT
.label MAP_ADDRESS = _map

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
_map: .fill _mapData.getSize(), _mapData.get(i)
_colors: .fill _tileColorsData.getSize(), _tileColorsData.get(i)
_tiles:
  .fill _tileData.getSize() / 4, _tileData.get(i*4) + c64lib.MAP_CHARSET_OFFSET
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 1) + c64lib.MAP_CHARSET_OFFSET
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 2) + c64lib.MAP_CHARSET_OFFSET
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 3) + c64lib.MAP_CHARSET_OFFSET
