/*
  MIT License

  Copyright (c) 2021 Maciej Malecki

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
#import "levels/level2/meta.asm"
.filenamespace level2

.var _charsetData = LoadBinary("levels/level2/charset.bin")
.var _materialsData = LoadBinary("levels/level2/materials.bin")
.var _tileData = LoadBinary("levels/level2/tiles.bin")
.var _tileColorsData = LoadBinary("levels/level2/colors.bin")
.var _map1Data = LoadBinary("levels/level2/map-1.bin")
.var _map2Data = LoadBinary("levels/level2/map-2.bin")
.var _map3Data = LoadBinary("levels/level2/map-3.bin")

// level meta data
.label MAP_1_WIDTH = _map1Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_1_ADDRESS = _map1
.label MAP_1_DELTA_X = 1<<5 // x2
.label MAP_1_WRAPPING_MARK = 0
.label MAP_1_SCROLLING_MARK = 6
.label MAP_1_ACTORS = _map1Actors
.label MAP_1_OBSTACLES_MARK = %11100000

.label MAP_2_WIDTH = _map2Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_2_ADDRESS = _map2
.label MAP_2_DELTA_X = 1<<5 // x2
.label MAP_2_WRAPPING_MARK = 0
.label MAP_2_SCROLLING_MARK = 6
.label MAP_2_ACTORS = _map2Actors
.label MAP_2_OBSTACLES_MARK = %11100000

.label MAP_3_WIDTH = _map3Data.getSize() / c64lib.MAP_HEIGHT
.label MAP_3_ADDRESS = _map3
.label MAP_3_DELTA_X = 1<<5 // x2
.label MAP_3_WRAPPING_MARK = 0
.label MAP_3_SCROLLING_MARK = 6 // (x4 = 4)
.label MAP_3_ACTORS = _map3Actors
.label MAP_3_OBSTACLES_MARK = %11100000

.label CHARSET_SIZE = _charsetData.getSize()/8
.label CHARSET_ADDRESS = _charset
.label MATERIALS_ADDRESS = _materials

.label TILES_SIZE = 256//_tileData.getSize()/4
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
_materials: .fill _materialsData.getSize(), _materialsData.get(i)

.segment LevelData
// level 2-1
_map1: .fill _map1Data.getSize(), _map1Data.get(i)
_map1Actors:
  actorDefEnd()
// level 2-2
_map2: .fill _map2Data.getSize(), _map2Data.get(i)
_map2Actors:
  actorDefEnd()
// level 2-3
_map3: .fill _map3Data.getSize(), _map3Data.get(i)
_map3Actors:
  actorDefEnd()
_colors: .fill _tileColorsData.getSize(), _tileColorsData.get(i)
_tiles:
  .fill _tileData.getSize() / 4, _tileData.get(i*4)
  .fill 256 - _tileData.getSize() / 4, 0
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 1)
  .fill 256 - _tileData.getSize() / 4, 0
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 2)
  .fill 256 - _tileData.getSize() / 4, 0
  .fill _tileData.getSize() / 4, _tileData.get(i*4 + 3)
  .fill 256 - _tileData.getSize() / 4, 0

