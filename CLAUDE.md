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

A Vampire Survivors-style auto-shooter roguelike for Playdate. Player rotates a space station with the crank; tools auto-fire at enemies. 5 episodes, 7 waves + boss each, level-up upgrades, meta-progression via Research Specs and Grant Funding.

## Key Technical Details

### Coordinate System
- Game uses 0°=UP coordinate system
- Sprites are drawn facing RIGHT (0°)
- Apply -90° offset to visual rotation for tools and projectiles to face correctly

### Architecture
- Game entities (mobs, projectiles, collectibles, tools, station) are drawn **manually** in `drawOverlay()` — they are NOT in the Playdate sprite system
- `sprite.update()` is skipped entirely during gameplay (`skipSpriteUpdate` flag)
- Background drawn via `image:draw(0,0)`, all entities drawn with `image:draw(x-halfW, y-halfH)` using pre-cached center offsets
- Z-order: collectibles → mobs → station → tools → projectiles → effects → HUD
- All drawn entities use **pre-rotated image caches** (24 steps via `Utils.getRotatedImages`) to avoid expensive runtime `setRotation()` calls
- Station has 8 attachment slots (positions 0-7 clockwise from top)
- Tools fire constantly at their fire rate, direction locked at fire time
- Object pooling for projectiles with swap-and-pop removal
- DOD parallel arrays for hot collision data (mobX[], mobY[], mobActive[])
- Spatial grid for efficient mob lookups (`getMobsNearPosition`)

### Performance Patterns
- Numeric for loops (not ipairs/pairs)
- Squared distance comparisons (avoid sqrt)
- Localized math functions at file top
- Shared module-level functions for projectile behaviors (avoid per-projectile closures/GC pressure)
- Pre-allocated grid cells, lazy grid clearing
- Split collision checks across frames (3-way cycling)
- Pixel-threshold moveTo — skip when pixel position unchanged

## Project Structure

```
source/
├── main.lua                    # Entry point, game loop
├── pdxinfo                     # Playdate metadata (keep version in sync with constants.lua)
├── lib/
│   ├── class.lua               # OOP helper
│   ├── constants.lua           # Game constants (VERSION, BUILD here)
│   └── utils.lua               # Utilities (rotation cache, distance, etc.)
├── managers/
│   ├── game_manager.lua        # State machine, title screen, game over/victory
│   ├── audio_manager.lua       # Music/SFX
│   ├── save_manager.lua        # playdate.datastore wrapper, grant funding
│   ├── input_manager.lua       # Crank/button abstraction
│   └── font_manager.lua        # Font loading and switching
├── entities/
│   ├── entity.lua              # Base class
│   ├── station.lua             # Player station with rotation, shield, damage states
│   ├── tool.lua                # Tool base class (14 tools total)
│   ├── tools/                  # 14 tool implementations
│   ├── projectile.lua          # Projectile with object pooling
│   ├── mob.lua                 # MOB base class
│   ├── mobs/                   # 12 episode-specific MOBs + 1 special (pickup_thief)
│   ├── bosses/                 # 5 boss implementations
│   ├── collectible.lua         # RP collectibles
│   └── pickup.lua              # Pickup items (HP/RP bonus collectibles)
├── systems/
│   ├── upgrade_system.lua      # Tool/Bonus item management, evolution
│   └── research_spec_system.lua
├── ui/
│   ├── upgrade_selection.lua   # Level-up card picker (2 tools + 2 bonus items)
│   ├── story_panel.lua         # Intro/outro panels
│   ├── episode_select.lua      # Episode selection screen
│   ├── database_screen.lua     # In-game encyclopedia
│   └── grant_funding_screen.lua # Meta-progression upgrades
├── scenes/
│   └── gameplay_scene.lua      # Main game loop, collision, spawning, drawing
├── data/
│   ├── tools_data.lua          # Tool stats (14 tools)
│   ├── bonus_items_data.lua    # Bonus item definitions (30 items)
│   ├── episodes_data.lua       # Episode configs and story panels
│   ├── research_specs_data.lua # Research spec definitions (9 specs)
│   └── pickups_data.lua        # 49 pickup item definitions
└── images/                     # All game sprites and pre-processed icons
```

## Episodes

| Episode | Title | MOBs | Boss |
|---------|-------|------|------|
| 1 | Spin Cycle | Greeting Drone, Silk Weaver, Asteroid | Cultural Attache |
| 2 | Productivity Review | Survey Drone, Efficiency Monitor | Productivity Liaison |
| 3 | Whose Idea Was This? | Probability Fluctuation, Paradox Node | Improbability Engine |
| 4 | Garbage Day | Debris Chunk, Trash Blob, Defense Turret | Chomper |
| 5 | Academic Standards | Debate Drone, Citation Platform | Distinguished Professor |

## Debug Mode

The game has a Creative Mode toggle in Settings that enables:
- **All episodes unlocked** - Skip episode progression requirements
- **Fast boss spawn** - Boss appears at 2 minutes instead of 7 minutes
- **Station invincibility** - Station takes no damage
- **Unlock all database** - All database entries visible

Normal mode (Creative OFF):
- Episodes unlock sequentially (must complete Episode N to unlock Episode N+1)
- Boss spawns at 7 minutes (420 seconds)
- Station health: 500 HP

## Station Damage Visuals

- Healthy station graphic: health > 50%
- Damaged graphic 1: health 25%-50%
- Damaged graphic 2: health < 25%
- Thresholds work in both directions (healing restores graphics)

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

v0.1.236 (build 238)
