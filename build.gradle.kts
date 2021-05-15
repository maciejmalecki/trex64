// buildscript {
//   repositories {
//     mavenLocal()
//   }
//   dependencies {
//     classpath "com.github.c64lib.retro-assembler:com.github.c64lib.retro-assembler.gradle.plugin:1.1.0-SNAPSHOT"
//   }
// }

// apply plugin: "com.github.c64lib.retro-assembler"

plugins {
    id("com.github.c64lib.retro-assembler") version "1.1.0"
}

repositories {
    mavenLocal()
}

retroProject {
    dialect = com.github.c64lib.retroassembler.domain.AssemblerType.KickAssembler
    dialectVersion = "5.20"
    libDirs = arrayOf(".ra/deps/c64lib", "build/charpad")

    libFromGitHub("c64lib/common", "develop")
    libFromGitHub("c64lib/chipset", "develop")
    libFromGitHub("c64lib/text", "develop")
    libFromGitHub("c64lib/copper64", "develop")
}

preprocess {
    charpad {
        getInput().set(file("src/levels/level1/charpad.ctm"))
        getUseBuildDir().set(true)
        outputs {
            charset {
                output = file("levels/level1/charset.bin")
            }
            tiles {
              interleaver {
                output = file("levels/level1/tiles.bin")
              }
              interleaver {
              }
            }
            tileColours {
              output = file("levels/level1/colors.bin")
            }
            map {
              right = 135
              interleaver {
                output = file("levels/level1/map-1.bin")
              }
              interleaver {
              }
            }
            map {
              left = 136
              interleaver {
                output = file("levels/level1/map-2.bin")
              }
              interleaver {
              }
            }
            map {
              left = 136
              interleaver {
                output = file("levels/level1/map-3.bin")
              }
              interleaver {
              }
            }
        }
    }
}
