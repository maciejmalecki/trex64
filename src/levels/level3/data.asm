/*
  MIT License

  Copyright (c) 2022 Maciej Malecki

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/
#import "../../_segments.asm"
#import "../../_constants.asm"
#import "../../_level-utils.asm"
#import "levels/level3/meta.asm"
.filenamespace level3

.var _charsetData = LoadBinary("levels/level3/charset.bin")
.var _materialsData = LoadBinary("levels/level3/materials.bin")
.var _tileData = LoadBinary("levels/level3/tiles.bin")
.var _tileColorsData = LoadBinary("levels/level3/colors.bin")
.var _map1Data = LoadBinary("levels/level3/map-1.bin")
.var _map2Data = LoadBinary("levels/level3/map-2.bin")
.var _map3Data = LoadBinary("levels/level3/map-3.bin")
.var _map4Data = LoadBinary("levels/level3/map-4.bin")

// level meta data
.label MAP_1_WIDTH = _map1Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_1_ADDRESS = _map1
.label MAP_1_DELTA_X = 1<<5 // x2
.label MAP_1_WRAPPING_MARK = 0
.label MAP_1_SCROLLING_MARK = 6
.label MAP_1_ACTORS = _map1Actors

.label MAP_2_WIDTH = _map2Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_2_ADDRESS = _map2
.label MAP_2_DELTA_X = 1<<5 // x2
.label MAP_2_WRAPPING_MARK = 0
.label MAP_2_SCROLLING_MARK = 6
.label MAP_2_ACTORS = _map2Actors

.label MAP_3_WIDTH = _map3Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_3_ADDRESS = _map3
.label MAP_3_DELTA_X = 1<<5 // x2
.label MAP_3_WRAPPING_MARK = 0
.label MAP_3_SCROLLING_MARK = 6 // (x4 = 4)
.label MAP_3_ACTORS = _map3Actors

.label MAP_4_WIDTH = _map4Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_4_ADDRESS = _map4
.label MAP_4_DELTA_X = 1<<6 // x2
.label MAP_4_WRAPPING_MARK = 0
.label MAP_4_SCROLLING_MARK = 4 // (x4 = 4)
.label MAP_4_ACTORS = _map4Actors

.label CHARSET_SIZE = _charsetData.getSize()/8
.label CHARSET_ADDRESS = _charset
.label MATERIALS_ADDRESS = _materials

.label TILES_SIZE = _tileData.getSize()/4
.label TILES_COLORS_ADDRESS = _colors
.label TILES_ADDRESS = _tiles

.label BORDER_COLOR = 0
.label BG_COLOR_0 = backgroundColour0
.label BG_COLOR_1 = backgroundColour1
.label BG_COLOR_2 = backgroundColour2

// find animations
.var _rightAnim = 0
.var _bottomAnim = 255;
.for (var i = 0; i < _materialsData.getSize(); i++) {
  .var material = _materialsData.get(i)
  .if ((material & 4) == 4) {
    .if ((material & 2) == 2) {
      .eval _rightAnim = i
    } else {
      .eval _bottomAnim = i
    }
  }
}

.label RIGHT_ANIM_CHAR = _rightAnim
.label BOTTOM_ANIM_CHAR = _bottomAnim

// level data
.segment Charsets
_charset: .fill _charsetData.getSize(), _charsetData.get(i)
.segment Materials
_materials: .fill _materialsData.getSize(), _materialsData.get(i)

.segment LevelData
// level 3-1
_map1: .fill _map1Data.getSize(), _map1Data.get(i)
_map1Actors:
  actorDef(c64lib.EN_VOGEL, 23, 80, $40, LIGHT_RED)
  actorDef(c64lib.EN_VOGEL, 52, 130, $50, LIGHT_RED)
  actorDef(c64lib.EN_VOGEL, 77, 160, $50, LIGHT_RED)
  actorDef(c64lib.EN_VOGEL, 89, 150, $60, LIGHT_RED)
  actorDef(c64lib.EN_SNAKE, 105, 182, $30, LIGHT_GREEN)
  actorDefEnd()
// level 3-2
_map2: .fill _map2Data.getSize(), _map2Data.get(i)
_map2Actors:
  actorDef(c64lib.EN_VOGEL, 23, 100, $40, LIGHT_GREEN)
  actorDef(c64lib.EN_VOGEL, 38, 120, $60, LIGHT_RED)
  actorDef(c64lib.EN_VOGEL, 65, 130, $60, LIGHT_RED)
  actorDef(c64lib.EN_VOGEL, 80, 150, $70, LIGHT_GREEN)
  actorDef(c64lib.EN_SNAKE, 97, 182, $30, LIGHT_GREEN)
  actorDefEnd()
// level 3-3
_map3: .fill _map3Data.getSize(), _map3Data.get(i)
_map3Actors:
  actorDef(c64lib.EN_VOGEL, 19, 150, $60, LIGHT_GREEN)
  actorDef(c64lib.EN_VOGEL, 38, 135, $54, LIGHT_GREEN)
  actorDef(c64lib.EN_VOGEL, 88, 120, $48, LIGHT_GREEN)
  actorDef(c64lib.EN_VOGEL, 105, 130, $55, LIGHT_GREEN)
  actorDefEnd()
// level 3-4
_map4: .fill _map4Data.getSize(), _map4Data.get(i)
_map4Actors:
  actorDef(c64lib.EN_VOGEL, 50, 76, $70, WHITE)
  actorDef(c64lib.EN_VOGEL, 70, 96, $70, LIGHT_RED)
  actorDef(c64lib.EN_VOGEL, 100, 130, $70, YELLOW)
  actorDef(c64lib.EN_VOGEL, 150, 110, $70, LIGHT_RED)
  actorDef(c64lib.EN_VOGEL, 181, 120, $70, LIGHT_RED)
  actorDef(c64lib.EN_SNAKE, 220, 182, $60, LIGHT_GREEN)
  actorDefEnd()
_colors: .fill _tileColorsData.getSize(), _tileColorsData.get(i)
_tiles:
  .fill _tileData.getSize() / 4, _tileData.get(i*4)
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 1)
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 2)
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 3)

