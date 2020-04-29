# T-Rex 64
A Commodore 64 version of offline mode jumping dinosaur single button game ;-) Work in progress...

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CircleCI](https://circleci.com/gh/maciejmalecki/trex64/tree/develop.svg?style=svg)](https://circleci.com/gh/maciejmalecki/trex64/tree/develop)

## How to build
All you need to build it is to have Java (JDK) version 8 or higher. Clone the repository, enter it and then run following command:
```bash
gradlew build
```
for Windows systems or
```bash
./gradlew build
```
for Unix-like systems.

## How to run it
You need a Commodore 64 emulator such as Vice (see: https://vice-emu.sourceforge.io/). Once T-Rex 64 is built, go into `src` directory and find `rex.prg` file - this is the one you need to run with Vice:
```bash
x64 rex.prg
```

## How to play
There are currently a few options on title screen but actually only F1 "controls" and F7 "start game" are supported.

By pressing F1 you can toggle control methods: for Joystick port 2 up and fire are used for jumping. For keyboard use Space key for jumping.

Goals of the game: you control running dino. The dino must jump over obstacles (cactuses) otherwise he will die. Run as far as you can.

## Tools

* Charpad
* Spritemate
