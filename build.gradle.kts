import com.github.c64lib.retroassembler.domain.AssemblerType

plugins {
    id("com.github.c64lib.retro-assembler") version "1.4.5"
}

repositories {
     mavenCentral()
}

retroProject {
    dialect = AssemblerType.KickAssembler
    dialectVersion = "5.22"
    libDirs = arrayOf(".ra/deps/c64lib", "build/charpad", "build/spritepad")
    includes = arrayOf("src/rex.asm")

    libFromGitHub("c64lib/common", "develop")
    libFromGitHub("c64lib/chipset", "develop")
    libFromGitHub("c64lib/text", "develop")
    libFromGitHub("c64lib/copper64", "develop")
}

preprocess {
    // game font
    charpad {
      getInput().set(file("src/charset/charset.ctm"))
      getUseBuildDir().set(true)
      outputs {
        meta {
          dialect = AssemblerType.KickAssembler
          output = file("charset/meta.asm")
        }
        charset {
          output = file("charset/charset.bin")
        }
      }
    }
    // title screen
    charpad {
      getInput().set(file("src/charset/game-logo.ctm"))
      getUseBuildDir().set(true)
      outputs {
        meta {
          dialect = AssemblerType.KickAssembler
          includeMode = true
          namespace = "c64lib"
          prefix = "logo_"
          output = file("charset/game-logo-meta.asm")
        }
        charset {
          output = file("charset/game-logo-chars.bin")
        }
        charsetAttributes {
          nybbler {
            loOutput = file("charset/game-logo-attr.bin")
          }
        }
        map {
          right = 40
          bottom = 10
          interleaver {
            output = file("charset/game-logo-map.bin")
          }
          interleaver {
          }
        }
      }
    }
    // level 1
    charpad {
        getInput().set(file("src/levels/level1/charpad.ctm"))
        getUseBuildDir().set(true)
        outputs {
            meta {
              dialect = AssemblerType.KickAssembler
              output = file("levels/level1/meta.asm")
              namespace = "level1"
            }
            charset {
              output = file("levels/level1/charset.bin")
            }
            charsetMaterials {
              output = file("levels/level1/materials.bin")
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
              right = 271
              interleaver {
                output = file("levels/level1/map-2.bin")
              }
              interleaver {
              }
            }
            map {
              left = 272
              right = 434
              interleaver {
                output = file("levels/level1/map-3.bin")
              }
              interleaver {
              }
            }
            map {
              left = 435
              right = 598
              interleaver {
                output = file("levels/level1/map-4.bin")
              }
              interleaver {
              }
            }
            map {
              left = 599
              interleaver {
                output = file("levels/level1/map-5.bin")
              }
              interleaver {
              }
            }
        }
    }
    // sprites
    spritepad {
      getInput().set(file("src/sprites/dashboard.spd"))
      getUseBuildDir().set(true)
      outputs {
        sprites {
          output = file("dashboard.bin")
        }
      }
    }
    spritepad {
      getInput().set(file("src/sprites/dino.spd"))
      getUseBuildDir().set(true)
      outputs {
        sprites {
          output = file("dino.bin")
        }
      }
    }
    spritepad {
      getInput().set(file("src/sprites/game-over.spd"))
      getUseBuildDir().set(true)
      outputs {
        sprites {
          output = file("game-over.bin")
        }
      }
    }
    spritepad {
      getInput().set(file("src/sprites/scorpio.spd"))
      getUseBuildDir().set(true)
      outputs {
        sprites {
          output = file("scorpio.bin")
        }
      }
    }
    spritepad {
      getInput().set(file("src/sprites/snake.spd"))
      getUseBuildDir().set(true)
      outputs {
        sprites {
          output = file("snake.bin")
        }
      }
    }
    spritepad {
      getInput().set(file("src/sprites/vogel.spd"))
      getUseBuildDir().set(true)
      outputs {
        sprites {
          output = file("vogel.bin")
        }
      }
    }
}
