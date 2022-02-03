# T-Rex 64
A Commodore 64 version of offline mode jumping dinosaur single button game ;-) Work in progress...

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CircleCI](https://circleci.com/gh/maciejmalecki/trex64/tree/master.svg?style=shield)](https://circleci.com/gh/maciejmalecki/trex64/tree/master)
[![CircleCI](https://circleci.com/gh/maciejmalecki/trex64/tree/preview.svg?style=shield)](https://circleci.com/gh/maciejmalecki/trex64/tree/preview)
[![CircleCI](https://circleci.com/gh/maciejmalecki/trex64/tree/develop.svg?style=shield)](https://circleci.com/gh/maciejmalecki/trex64/tree/develop)

Visit the website: https://maciejmalecki.github.io/trex64/

## How to run it
Download `rex.prg` or `rex.d64` file from the website mentioned above or from [GitHub](https://github.com/maciejmalecki/trex64/releases) (look for assets section).

You need a Commodore 64 emulator such as [Vice](https://vice-emu.sourceforge.io/) or, preferably, a real machine.

Run prg file with Vice:
```bash
x64 rex.prg
```

If you want to build T-Rex 64 from sources, go into `src` directory and find `rex.prg` file there.

## How to build
All you need to build it is to have Java (JDK) version 11 or higher. Clone the repository, enter it and then run following command:
```bash
gradlew build
```
for Windows systems or
```bash
./gradlew build
```
for Unix-like systems.

## For crackers

I have nothing against that you crack this title and publish your work on sites like csdb as long as you use any of officially released commits (the ones with semver tag on it: `x.y.z`).
Anything that is published on releases except alpha and beta releases is generally a good choice.

## Tools

The following tools are used to develop T-Rex 64. 
Some of them are needed to work with certain source files. 
The build system itself including Kick Assembler requires Java version 11 or newer.

* [Charpad](https://subchristsoftware.itch.io/charpad-pro)
* [Spritepad](https://subchristsoftware.itch.io/spritepad-pro)
* [Goat Tracker](https://sourceforge.net/projects/goattracker2/)
* [Kick Assembler](http://theweb.dk/KickAssembler/Main.html#frontpage)
* [C64 Debugger](https://sourceforge.net/projects/c64-debugger/)
* [Gradle Retro Assembler Plugin](https://c64lib.github.io/gradle-retro-assembler-plugin/)
