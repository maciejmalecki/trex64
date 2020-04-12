#import "../../_segments.asm"
.filenamespace level1

.var _tileData = LoadBinary("level-1-tiles.bin")

// level meta data
.label MAP_WIDTH = 240
.label MAP_ADDRESS = _map

.label CHARSET_SIZE = 128
.label CHARSET_ADDRESS = _charset

.label TILES_SIZE = _tileData.getSize()/4
.label TILES_COLORS_ADDRESS = _colors
.label TILES_ADDRESS = _tiles

.label BORDER_COLOR = 14
.label BG_COLOR_0 = 6
.label BG_COLOR_1 = 15
.label BG_COLOR_2 = 14

// level data
.segment Charsets
_charset: .import binary "level-1-charset.bin"

.segment LevelData
_map: .import binary "level-1-map.bin"
_colors: .import binary "level-1-tiles-colors.bin"
_tiles:
  .fill _tileData.getSize() / 4, _tileData.get(i*4) + 64
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 1) + 64
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 2) + 64
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 3) + 64

