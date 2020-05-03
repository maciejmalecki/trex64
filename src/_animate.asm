#importonce

.filenamespace c64lib

.label ANI_CTRL_ENABLE = $01
.label ANI_CTRL_LOOP = $02

.struct AniConfig  {
  page0,
  page1,
  control,
  sequenceLo,
  sequenceHI,
  frames,
  speedCounters
}
