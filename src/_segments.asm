#importonce
.filenamespace c64lib

.segmentdef Code [start=$0810]
.segmentdef Data [startAfter="Code"]
.segmentdef LevelData [startAfter="Data"]
.segmentdef Sprites [startAfter="LevelData"]
.segmentdef Charsets [startAfter="Sprites"]
