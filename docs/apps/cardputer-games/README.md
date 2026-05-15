# Cardputer Games

## Overview

Cardputer Games is the standalone arcade catalog app. It boots into a compact launcher with 53 tiny offline games mapped to a shared Cardputer-friendly game canvas.

## What It Does

- 53 built-in games across arcade, racing, motion, shooter, puzzle, board, reflex, and skill categories.
- Shared 128x64 logical game canvas scaled onto the Cardputer ADV display.
- Keyboard-first play with Button A support and short procedural sound cues.
- Offline-only game runtime with no network setup or cloud dependency.
- Quick pick-up-and-play sessions from the Cypher OS app catalog.

## Controls

- Move/navigate: arrow keys, `WASD`, or `HJKL`.
- Launch/action: `Enter`, `Space`, or Button A.
- Mute toggle: `m`.
- Exit a game: `Delete`, `q`, or `Tab`.

## SD And Runtime Files

- Cypher OS app binary: `/cypher-puter/apps/cardputer-games.bin`.
- No SD save system is required for the current standalone game catalog.

## Return To Cypher OS

Exit controls return from individual games to the Cardputer Games launcher. Use Cypher OS app return support if exposed by the packaged build to go back to the OS launcher.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/cardputer-games
- GAME_CATALOG.md from /Users/cypher/Documents/GitHub/cardputer-games

## Built-In Game Catalog

### Cypher-Gamer Game Catalog

This catalog lists the 53 games currently registered in `src/games/Games.cpp`.
All games run inside the Cardputer launcher, use the shared `128x64` game
canvas, and support the common exit keys: `Delete`, `q`, or `Tab`.

## Shared Controls

| Action | Keys |
| --- | --- |
| Move / navigate | Arrow keys, `WASD`, or `HJKL` |
| Action / select | `Enter`, `Space`, or Button A |
| Mute toggle | `m` |
| Exit game | `Delete`, `q`, or `Tab` |

## Arcade

| Game | Quick detail |
| --- | --- |
| Pong | Classic paddle rally. Move left/right and keep the ball alive as long as possible. |
| Snake | Turn through the arena, eat food, grow longer, and avoid crashing into yourself. |
| Breakout | Slide the paddle, bounce the ball, and clear the brick wall. |
| Flappy Pico | Tap through narrow gaps in a small side-scrolling flyer challenge. |
| Dino Runner | Jump over incoming hazards in a compact endless-runner loop. |
| Jetpack | Hold action to control lift and thread through a scrolling tunnel. |
| Dodge Rain | Move away from falling hazards and survive the storm. |
| Catch Star | Catch falling stars before they slip past you. |
| Basket Catch | Slide the basket under falling targets for points. |
| Balloon Pop | Catch or pop falling balloon targets before they escape. |
| Cave Flyer | Fly through cave gaps with careful tap-and-hold control. |
| Tunnel Run | Stay centered through a fast scrolling tunnel. |
| Wall Bounce | Catch the bouncing target and avoid letting it get away. |
| Gravity Flip | Flip gravity to dodge obstacles from both floor and ceiling. |
| Platform Hop | Time jumps between platforms in a tiny runner course. |
| Brick Drop | Catch the right falling pieces while managing the drop speed. |

## Racing And Motion

| Game | Quick detail |
| --- | --- |
| Full Speed | High-speed driving. Steer left/right and avoid crashing as speed climbs. |
| Lane Racer | Shift lanes to avoid blockers and keep the run going. |
| Traffic Dodge | Weave through traffic in a tight three-lane road challenge. |
| Ski Slalom | Pass through gates while carving down the course. |
| Boat Slalom | Navigate water lanes and slalom gates without clipping obstacles. |
| Rail Runner | Stay on the open rail and dodge sudden lane hazards. |
| Road Drift | Thread through gates while the road pushes your timing. |

## Skill

| Game | Quick detail |
| --- | --- |
| Lunar Module | Steer and thrust carefully for a soft landing instead of a crash. |

## Shooter

| Game | Quick detail |
| --- | --- |
| Asteroids | Aim through moving space rocks and clear as many targets as possible. |
| Invaders | Defend against descending targets with a compact arcade-shooter rhythm. |
| Missile Cmd | Intercept incoming missiles with wide defensive blasts. |
| Turret Def | Hold the line from a fixed turret against approaching threats. |
| UFO Defender | Track and shoot traveling UFO targets before they cross the screen. |
| Meteor Blast | Blast meteors with tighter shots and careful timing. |

## Puzzle

| Game | Quick detail |
| --- | --- |
| Lights Out | Toggle tiles until the whole light grid is cleared. |
| Minefield | Probe the grid, infer safe spaces, and avoid hidden mines. |
| Sokoban | Push boxes into place without trapping yourself. |
| Sliding | Reorder the sliding puzzle tiles into the solved layout. |
| Memory | Flip cards, remember positions, and match every pair. |
| Simon | Repeat the growing pattern from memory. |
| Mastermind | Guess the hidden code using feedback from each attempt. |
| Number Guess | Narrow the number with higher/lower clues. |
| 2048 | Swipe tiles in four directions, merge matching numbers, and chase the 2048 tile. |
| Flood Fill | Change regions to flood the board into one color. |
| Box Push | A second box-pushing challenge built on the Sokoban-style rules. |
| Laser Mirror | Rotate or route mirrors so the laser reaches the target. |

## Board

| Game | Quick detail |
| --- | --- |
| Tic Tac Toe | Place marks on the 3x3 board and beat the simple opponent logic. |
| Connect Four | Drop pieces into columns and connect four before the board fills. |
| Nim | Take from the pile and leave your opponent the losing move. |
| Dots Boxes | Draw lines, complete boxes, and claim more squares than the opponent. |

## Reflex

| Game | Quick detail |
| --- | --- |
| Reaction | Wait for the signal, then hit action as fast as possible. |
| Quick Draw | React to the go signal without jumping too early. |
| Stop Bar | Stop the moving bar on the target zone. |
| Stack Tower | Time each layer and build the tallest clean stack you can. |
| Lock Pick | Hit the sweet spot to open the lock. |
| Pixel Whack | Chase the target pixel and strike before it moves. |
| Pulse Match | Match the pulse timing as closely as possible. |
