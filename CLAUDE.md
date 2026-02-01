# Interstellar Survivors - Development Notes

## Build Instructions

**IMPORTANT: Build filename must be `InterstellarSurvivors.pdx` (no space)**

```bash
cd /Users/shawnr/dev/interstellar-survivors
pdc source InterstellarSurvivors.pdx
```

When building, always:
1. Increment the patch version in `source/lib/constants.lua` and `source/pdxinfo`
2. Keep both files in sync (VERSION/version and BUILD/buildNumber)
3. Use the exact filename `InterstellarSurvivors.pdx`

## Project Overview

A Vampire Survivors-style auto-shooter roguelike for Playdate. Player rotates a space station with the crank; tools auto-fire at enemies. 5 episodes, 7 waves + boss each, level-up upgrades, meta-progression via Research Specs.

## Key Technical Details

### Coordinate System
- Game uses 0°=UP coordinate system
- Sprites are drawn facing RIGHT (0°)
- Apply -90° offset to visual rotation for tools and projectiles to face correctly

### Architecture
- All game objects extend `gfx.sprite`
- Station has 8 attachment slots (positions 0-7 clockwise from top)
- Tools fire constantly at their fire rate, direction locked at fire time
- Object pooling for projectiles (pre-allocate ~50)

## Project Structure

```
source/
├── main.lua                    # Entry point, game loop
├── pdxinfo                     # Playdate metadata (keep version in sync with constants.lua)
├── lib/
│   ├── class.lua               # OOP helper
│   ├── constants.lua           # Game constants (VERSION, BUILD here)
│   └── utils.lua               # Utilities
├── managers/
│   ├── game_manager.lua        # State machine, title screen
│   ├── audio_manager.lua       # Music/SFX
│   ├── save_manager.lua        # playdate.datastore wrapper
│   └── input_manager.lua       # Crank/button abstraction
├── entities/
│   ├── entity.lua              # Base class
│   ├── station.lua             # Player station with rotation
│   ├── tool.lua                # Tool base class
│   ├── tools/                  # 8 tool implementations
│   ├── projectile.lua          # Projectile with object pooling
│   ├── mob.lua                 # MOB base class
│   ├── mobs/                   # Episode-specific MOBs
│   ├── bosses/                 # 5 boss implementations
│   └── collectible.lua         # RP collectibles
├── systems/
│   ├── upgrade_system.lua      # Tool/Bonus item management
│   └── research_spec_system.lua
├── ui/
│   ├── upgrade_selection.lua   # Level-up card picker
│   ├── story_panel.lua         # Intro/outro panels
│   └── episode_select.lua      # Episode selection screen
├── scenes/
│   └── gameplay_scene.lua      # Main game loop
├── data/
│   ├── tools_data.lua          # Tool stats
│   ├── bonus_items_data.lua    # Bonus item definitions
│   ├── episodes_data.lua       # Episode configs and story panels
│   └── research_specs_data.lua # Research spec definitions
└── images/                     # All game sprites
```

## Episodes

| Episode | Title | MOBs | Boss |
|---------|-------|------|------|
| 1 | Spin Cycle | Greeting Drone, Silk Weaver, Asteroid | Cultural Attaché |
| 2 | Productivity Review | Survey Drone, Efficiency Monitor | Productivity Liaison |
| 3 | Whose Idea Was This? | Probability Fluctuation, Paradox Node | Improbability Engine |
| 4 | Garbage Day | Debris Chunk, Defense Turret | Chomper |
| 5 | Academic Standards | Debate Drone, Citation Platform | Distinguished Professor |

## Debug Mode

The game has a Debug Mode toggle in Settings that enables:
- **All episodes unlocked** - Skip episode progression requirements
- **Fast boss spawn** - Boss appears at 1 minute instead of 7 minutes
- **Station invincibility** - Station takes no damage

Normal mode (Debug OFF):
- Episodes unlock sequentially (must complete Episode N to unlock Episode N+1)
- Boss spawns at 7 minutes (420 seconds)
- Station health: 100 HP (per design document)

## Common Issues & Solutions

### StoryPanel rapid advancement
- Button presses can carry over between scenes
- Solution: Added `inputDelay` property (200ms delay before accepting input)

### Sprites showing wrong images
- Check the `imagePath` in the MOB/entity DATA table
- Debug with `print()` statements showing the image path being used

### Tools/projectiles facing sideways
- Sprites are drawn facing RIGHT but game uses 0°=UP
- Apply -90° offset to visual rotation (not firing angle)

### Text not rendering white
- Use `gfx.setImageDrawMode(gfx.kDrawModeFillWhite)` before drawing
- Reset with `gfx.setImageDrawMode(gfx.kDrawModeCopy)` after

### Action text with outline
- Draw text 8 times offset in all directions with FillBlack mode
- Draw white text on top with FillWhite mode

## Design Document

Full game design document is in `/Interstellar Survivors.md`

## Current Version

v0.1.34 (build 35)
