#importonce
.filenamespace c64lib

// ZERO page
.label z_x = 2                // $02,$03
.label z_y = 4                // $04,$05
.label z_width = 6            // $06
.label z_height = 7           // $07
.label z_map = 8              // $08, $09
.label z_phase = 10           // $0A
.label z_listPtr = 11         // $0B
.label z_displayListPtr = 12  // $0C,$0D
.label z_deltaX = 14          // $0E
.label z_acc0 = 15            // $0F
.label z_startingLevel = 16   // $10
.label z_mode = 17            // $11
.label z_delay = 18           // $12
.label z_animationPhase = 19  // $13
.label z_animationFrame = 20  // $14
.label z_yPos = 21            // $15
.label z_jumpFrame = 22       // $16
.label z_collisionTile = 23   // $17
.label z_delayCounter = 24    // $18
.label z_worldCounter = 25    // $19
.label z_levelCounter = 26    // $1A
.label z_gameState = 27       // $1B
.label z_lives = 28           // $1C
.label z_score = 29           // $1D,$1E,$1F
.label z_scoreDelay = 32      // $20
.label z_xPos = 33            // $21
.label z_gameConfig = 35      // $22

// keyboard handling
.label z_previousKeys = 36    // $23
.label z_currentKeys = 37     // $24

.label z_wrappingMark = 38    // $25
