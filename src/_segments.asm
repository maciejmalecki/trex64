#importonce
.filenamespace c64lib

.segmentdef Code [start=$0810]
.segmentdef Data [startAfter="Code"]
.segmentdef LevelData [startAfter="Data"]
.segmentdef Charsets [startAfter="LevelData"]
.segmentdef Sprites [startAfter="Charsets"]
.segmentdef AuxGfx [startAfter="Sprites"]
.segmentdef Sfx [startAfter="AuxGfx"]
.segmentdef Music [startAfter="Sfx"]
