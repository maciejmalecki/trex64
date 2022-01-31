import com.github.c64lib.retroassembler.domain.AssemblerType

plugins {
    id("com.github.c64lib.retro-assembler") version "1.5.2"
}

retroProject {
    dialect = AssemblerType.KickAssembler
    dialectVersion = "5.24"
    libDirs = arrayOf(".ra/deps/c64lib", "build/charpad", "build/spritepad", "build/goattracker")
    includes = arrayOf("src/rex.asm")

    libFromGitHub("c64lib/common", "0.3.0")
    libFromGitHub("c64lib/chipset", "0.3.0")
    libFromGitHub("c64lib/text", "develop")
    libFromGitHub("c64lib/copper64", "develop")
}

preprocess {
    // music
    goattracker {
      getInput().set(file("src/music/trex.sng"))
      getUseBuildDir().set(true)
      music {
        getOutput().set(file("music/trex.sid"))
        bufferedSidWrites = true
        sfxSupport = true
        storeAuthorInfo = true
        playerMemoryLocation = 0xF5
      }
    }
    goattracker {
      getInput().set(file("src/music/trex2.sng"))
      getUseBuildDir().set(true)
      music {
        getOutput().set(file("music/trex2.sid"))
        bufferedSidWrites = true
        sfxSupport = true
        storeAuthorInfo = true
        playerMemoryLocation = 0xF5
      }
    }
    // game font
    charpad {
      getInput().set(file("src/charset/charset.ctm"))
      getUseBuildDir().set(true)
      getCtm8PrototypeCompatibility().set(true)
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
    // world 1
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
              bottom = 12
              interleaver {
                output = file("levels/level1/map-1.bin")
              }
              interleaver {
              }
            }
            map {
              top = 12
              bottom = 24
              right = 135
              interleaver {
                output = file("levels/level1/map-2.bin")
              }
              interleaver {
              }
            }
            map {
              top = 24
              right = 162
              bottom = 36
              interleaver {
                output = file("levels/level1/map-3.bin")
              }
              interleaver {
              }
            }
            map {
              top = 36
              bottom = 48
              right = 163
              interleaver {
                output = file("levels/level1/map-4.bin")
              }
              interleaver {
              }
            }
            map {
              top = 48
              interleaver {
                output = file("levels/level1/map-5.bin")
              }
              interleaver {
              }
            }
        }
    }
    // world 2
    charpad {
        getInput().set(file("src/levels/level2/charpad.ctm"))
        getUseBuildDir().set(true)
        outputs {
            meta {
              dialect = AssemblerType.KickAssembler
              output = file("levels/level2/meta.asm")
              namespace = "level2"
            }
            charset {
              output = file("levels/level2/charset.bin")
            }
            charsetMaterials {
              output = file("levels/level2/materials.bin")
            }
            tiles {
              interleaver {
                output = file("levels/level2/tiles.bin")
              }
              interleaver {
              }
            }
            tileColours {
              output = file("levels/level2/colors.bin")
            }
            map {
              right = 135
              bottom = 12
              interleaver {
                output = file("levels/level2/map-1.bin")
              }
              interleaver {
              }
            }
            map {
              right = 135
              top = 12
              bottom = 24
              interleaver {
                output = file("levels/level2/map-2.bin")
              }
              interleaver {
              }
            }
            map {
              right = 135
              top = 24
              bottom = 36
              interleaver {
                output = file("levels/level2/map-3.bin")
              }
              interleaver {
              }
            }
            map {
              right = 135
              top = 36
              bottom = 48
              interleaver {
                output = file("levels/level2/map-4.bin")
              }
              interleaver {
              }
            }
            map {
              top = 48
              interleaver {
                output = file("levels/level2/map-5.bin")
              }
              interleaver {
              }
            }
        }
    }
    // world 3
    charpad {
        getInput().set(file("src/levels/level3/charpad.ctm"))
        getUseBuildDir().set(true)
        outputs {
            meta {
              dialect = AssemblerType.KickAssembler
              output = file("levels/level3/meta.asm")
              namespace = "level3"
            }
            charset {
              output = file("levels/level3/charset.bin")
            }
            charsetMaterials {
              output = file("levels/level3/materials.bin")
            }
            tiles {
              interleaver {
                output = file("levels/level3/tiles.bin")
              }
              interleaver {
              }
            }
            tileColours {
              output = file("levels/level3/colors.bin")
            }
            map {
              right = 135
              bottom = 12
              interleaver {
                output = file("levels/level3/map-1.bin")
              }
              interleaver {
              }
            }
            map {
              right = 135
              top = 12
              bottom = 24
              interleaver {
                output = file("levels/level3/map-2.bin")
              }
              interleaver {
              }
            }
            map {
              right = 135
              top = 24
              bottom = 36
              interleaver {
                output = file("levels/level3/map-3.bin")
              }
              interleaver {
              }
            }
            map {
              top = 36
              interleaver {
                output = file("levels/level3/map-4.bin")
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
