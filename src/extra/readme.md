T-REX 64 Instruction
====================

Running the game
----------------
The T-Rex 64 game is distributed as a ZIP archive containing following
files:

- `trex.prg` an executable, suitable for running on emulators or by using DMA method via EF3/1541U etc.,
- `trex.d64` an 1541 disk image that can be run via SD2IEC, 1541U or real 1541 disk drive.

One can run T-REX on Vice with following command:

    x64 trex.prg

When using disk method, the game can be loaded and run with typical method:

    LOAD"*",8
    RUN

Title screen options
--------------------
Once game is run, there are few options that can be configured on title screen:

- control method (F1) - can be choosen between Joystick in port 2 or Keyboard,
- music or effects only (F3) - whether in-game music should be played or effects only,
- starting level (F5) - one can select between levels 1-1, 1-2 and 1-3 to start the game with.

No matter of control method, game can be started with either FIRE in Joy 2 or SPACE.

Playing the game
----------------


Compatibility
-------------
This is a single file game thus it is expected to be compatible with any storage method including:

- tape,
- any cbm disk drive (although only a 1541 disk image is provided in the release bundle),
- cartridge in EasyFlash format.

This game has been optimized to work on both PAL and NTSC machines.
However, the oldest NTSC models are not supported (the 64 cycles per scan line models).
There is a single executable, the NTSC/PAL variant is automatically detected by the software.

Please note, that the gameplay on NTSC is somewhat faster but this just makes the game more challenging.
The gameplay has been tuned for NTSC speed.
