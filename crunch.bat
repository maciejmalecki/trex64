call gradlew build
exomizer sfx sys src\rex.prg -o trex64.prg
del trex64.d64
c1541 -format "trex64, 2021" d64 trex64.d64
c1541 -attach trex64.d64 -write trex64.prg trex64
