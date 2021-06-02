#import "../../_segments.asm"
#import "../../_constants.asm"
#import "../../_level-utils.asm"
.filenamespace level1

.var _charsetData = LoadBinary("levels/level1/charset.bin")
.var _tileData = LoadBinary("levels/level1/tiles.bin")
.var _tileColorsData = LoadBinary("levels/level1/colors.bin")
.var _map1Data = LoadBinary("levels/level1/map-1.bin")
.var _map2Data = LoadBinary("levels/level1/map-2.bin")
.var _map3Data = LoadBinary("levels/level1/map-3.bin")
.var _map4Data = LoadBinary("levels/level1/map-4.bin")
.var _map5Data = LoadBinary("levels/level1/map-5.bin")

// level meta data
.label MAP_1_WIDTH = _map1Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_1_ADDRESS = _map1
.label MAP_1_DELTA_X = 1<<5 // x2
.label MAP_1_WRAPPING_MARK = 0
.label MAP_1_SCROLLING_MARK = 6
.label MAP_1_ACTORS = _map1Actors
.label MAP_1_OBSTACLES_MARK = %11000000

.label MAP_2_WIDTH = _map2Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_2_ADDRESS = _map2
.label MAP_2_DELTA_X = 1<<5 // x2
.label MAP_2_WRAPPING_MARK = 0
.label MAP_2_SCROLLING_MARK = 6
.label MAP_2_ACTORS = _map2Actors
.label MAP_2_OBSTACLES_MARK = %11000000

.label MAP_3_WIDTH = _map3Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_3_ADDRESS = _map3
.label MAP_3_DELTA_X = 1<<5 // x4 (x4 = 1<<6)
.label MAP_3_WRAPPING_MARK = 0
.label MAP_3_SCROLLING_MARK = 6 // (x4 = 4)
.label MAP_3_ACTORS = _map3Actors
.label MAP_3_OBSTACLES_MARK = %11000000

.label MAP_4_WIDTH = _map4Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_4_ADDRESS = _map4
.label MAP_4_DELTA_X = 1<<5 // x4 (x4 = 1<<6)
.label MAP_4_WRAPPING_MARK = 0
.label MAP_4_SCROLLING_MARK = 6 // (x4 = 4)
.label MAP_4_ACTORS = _map4Actors
.label MAP_4_OBSTACLES_MARK = %11000000

.label MAP_5_WIDTH = _map5Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_5_ADDRESS = _map5
.label MAP_5_DELTA_X = 1<<6 // x4 (x4 = 1<<6)
.label MAP_5_WRAPPING_MARK = 0
.label MAP_5_SCROLLING_MARK = 4 // (x4 = 4)
.label MAP_5_ACTORS = _map5Actors
.label MAP_5_OBSTACLES_MARK = %11000000

.label CHARSET_SIZE = _charsetData.getSize()/8
.label CHARSET_ADDRESS = _charset

.label TILES_SIZE = _tileData.getSize()/4
.label TILES_COLORS_ADDRESS = _colors
.label TILES_ADDRESS = _tiles

.label BORDER_COLOR = 0
.label BG_COLOR_0 = 11
.label BG_COLOR_1 = 8
.label BG_COLOR_2 = 10

// level data
.segment Charsets
_charset: .fill _charsetData.getSize(), _charsetData.get(i)

.segment LevelData
// level 1-1
_map1: .fill _map1Data.getSize(), _map1Data.get(i)
_map1Actors:
  actorDef(c64lib.EN_VOGEL, 80, 76, $40, BLACK)
  actorDefEnd()
// level 1-2
_map2: .fill _map2Data.getSize(), _map2Data.get(i)
_map2Actors:
  actorDef(c64lib.EN_VOGEL, 43, 76, $40, WHITE)
  actorDef(c64lib.EN_SNAKE, 70, 182, $30, LIGHT_GREEN)
  actorDef(c64lib.EN_VOGEL, 91, 141, $40, WHITE)
  actorDefEnd()
// level 1-3
_map3: .fill _map3Data.getSize(), _map3Data.get(i)
_map3Actors:
  actorDef(c64lib.EN_VOGEL, 25, 76, $40, WHITE)
  actorDef(c64lib.EN_SCORPIO, 43, 182, $30, BLACK)
  actorDef(c64lib.EN_SCORPIO, 80, 182, $30, BLACK)
  actorDef(c64lib.EN_SCORPIO, 99, 182, $30, BLACK)
  actorDef(c64lib.EN_VOGEL, 100, 76, $40, WHITE)
  actorDefEnd()
// level 1-4
_map4: .fill _map4Data.getSize(), _map4Data.get(i)
_map4Actors:
  actorDefEnd()
// level 1-5
_map5: .fill _map5Data.getSize(), _map5Data.get(i)
_map5Actors:
  actorDefEnd()
_colors: .fill _tileColorsData.getSize(), _tileColorsData.get(i)
_tiles:
  .fill _tileData.getSize() / 4, _tileData.get(i*4)
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 1)
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 2)
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 3)

