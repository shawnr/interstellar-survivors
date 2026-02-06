# Data-Oriented Design Analysis for Mob System

## Current Architecture (Object-Oriented)

Each mob is a Lua object/table with ~25+ properties:
```lua
mob = {
    -- Core state (hot path)
    x, y,              -- position
    active,            -- is alive
    health, maxHealth, -- HP
    damage,            -- collision damage
    speed,             -- movement speed
    cachedRadius,      -- collision radius
    emits,             -- is shooter type

    -- Shooter-specific
    range,             -- orbit distance
    orbitAngle,        -- current orbit position
    orbitDirection,    -- CW or CCW
    evading, evadeTimer, evadeDirection,

    -- Animation
    animImageTable, currentFrame, frameTime, frameDuration, frameCount,

    -- Health bar
    showHealthBar, healthBarTimer,

    -- Reference data
    data, mobType, targetX, targetY,

    -- Sprite system (inherited from Entity)
    -- ...many more properties
}
```

### Current Hot Path Costs

**Per-frame operations for 24 mobs:**
1. **Collision detection** (~300 checks/frame):
   - `mob.x`, `mob.y` - 2 table lookups × 300 = 600 lookups
   - `mob.active` - 1 lookup × 300 = 300 lookups
   - `mob.cachedRadius` - 1 lookup × 300 = 300 lookups
   - `mob.damage` - occasional lookup

2. **Movement updates** (24 mobs):
   - `mob.x`, `mob.y`, `mob.speed`, `mob.targetX`, `mob.targetY` = 5 lookups × 24 = 120 lookups
   - `mob.emits` to branch behavior = 24 lookups
   - Shooter-specific: `mob.range`, `mob.orbitAngle`, etc.

3. **Grid building** (24 mobs):
   - `mob.x`, `mob.y`, `mob.active` = 3 lookups × 24 = 72 lookups

**Total estimate: 1500+ table lookups per frame in hot paths**

---

## Data-Oriented Alternative

### Parallel Arrays Structure

```lua
MobSystem = {
    -- Core arrays (indices 1 to MAX_MOBS)
    x = {},              -- number[]
    y = {},              -- number[]
    active = {},         -- boolean[]
    health = {},         -- number[]
    damage = {},         -- number[]
    speed = {},          -- number[]
    cachedRadius = {},   -- number[]
    isShooter = {},      -- boolean[]

    -- Shooter-specific arrays
    range = {},          -- number[]
    orbitAngle = {},     -- number[]
    orbitDirection = {}, -- number[] (1 or -1)

    -- Sprite references (still need for rendering)
    sprites = {},        -- Sprite[]

    -- Management
    count = 0,           -- active mob count
    freeSlots = {},      -- recycled indices
}
```

### Optimized Hot Paths

**Collision detection:**
```lua
-- Current (OOP)
for i = 1, mobCount do
    local mob = mobs[i]
    if mob and mob.active then
        local dx = proj.x - mob.x
        local dy = proj.y - mob.y
        -- 4 table lookups per mob
    end
end

-- DOD version
local mobX = MobSystem.x
local mobY = MobSystem.y
local mobActive = MobSystem.active
local mobRadius = MobSystem.cachedRadius

for i = 1, MobSystem.count do
    if mobActive[i] then
        local dx = projX - mobX[i]
        local dy = projY - mobY[i]
        -- Direct array access, no table lookups
        -- Arrays are contiguous in memory = better cache hits
    end
end
```

### Expected Benefits

1. **~40-60% faster hot paths** from:
   - Eliminated table hash lookups
   - Better cache locality (contiguous arrays)
   - Fewer Lua table operations

2. **Memory layout optimization**:
   - Hot data (x, y, active) packed together
   - Cold data (animation, health bar) separate

3. **SIMD-like patterns** possible:
   - Process position updates in bulk
   - Batch collision checks

---

## Trade-offs & Challenges

### Significant Refactoring Required

1. **Sprite system integration**: Sprites are still objects
   - Need to sync `sprites[i].x` with `MobSystem.x[i]`
   - Or skip sprite positions, use custom draw

2. **Subclass behaviors**: SilkWeaver, bosses have custom logic
   - Need to store behavior type in array
   - Switch statement instead of polymorphism

3. **Spawn/destroy complexity**:
   - Object pooling already helps
   - Index management for free slots

4. **Code maintainability**:
   - Less intuitive than OOP
   - Harder to add new mob types

### Moderate Refactoring (Hybrid Approach)

Keep sprites/objects but extract hot data:

```lua
-- In gameplay_scene.lua
local mobX = {}
local mobY = {}
local mobActive = {}
local mobRadius = {}
local mobSprites = {}  -- original mob objects

-- When spawning:
function GameplayScene:spawnMOB()
    local mob = GreetingDrone(x, y, multipliers)
    local idx = #mobSprites + 1
    mobSprites[idx] = mob
    mobX[idx] = x
    mobY[idx] = y
    mobActive[idx] = true
    mobRadius[idx] = mob.cachedRadius
end

-- Sync after movement:
function GameplayScene:syncMobData()
    for i = 1, #mobSprites do
        local mob = mobSprites[i]
        mobX[i] = mob.x
        mobY[i] = mob.y
        mobActive[i] = mob.active
    end
end

-- Fast collision using arrays:
function GameplayScene:checkCollisions()
    for i = 1, #mobActive do
        if mobActive[i] then
            local dx = projX - mobX[i]
            -- ...
        end
    end
end
```

---

## Recommendation

### Short-term (Low Risk)
Continue with current micro-optimizations:
- ✅ Already done: numeric for loops, localized math, cached properties
- More gains possible: pre-render health bars, reduce anonymous functions

### Medium-term (Medium Risk)
Hybrid DOD for collision hot path only:
- Extract x, y, active, radius to parallel arrays
- Sync after mob updates
- Use arrays in collision detection
- Keep sprites/objects for everything else

**Estimated effort**: 2-3 hours
**Expected gain**: +15-25% collision performance

### Long-term (High Risk)
Full DOD refactor:
- Only if still performance-constrained after other optimizations
- Significant code changes across many files
- Would need extensive testing

**Estimated effort**: 8-16 hours
**Expected gain**: +30-50% overall mob performance

---

## Quick Test: Array Access vs Table Lookup

```lua
-- Benchmark to validate DOD benefits on Playdate
local N = 1000

-- Table lookup style
local mobs = {}
for i = 1, 100 do
    mobs[i] = { x = i, y = i, active = true }
end

local t1 = playdate.getCurrentTimeMilliseconds()
for iter = 1, N do
    for i = 1, 100 do
        local m = mobs[i]
        if m.active then
            local dx = 200 - m.x
            local dy = 120 - m.y
        end
    end
end
local tableTime = playdate.getCurrentTimeMilliseconds() - t1

-- Array style
local mobX, mobY, mobActive = {}, {}, {}
for i = 1, 100 do
    mobX[i], mobY[i], mobActive[i] = i, i, true
end

local t2 = playdate.getCurrentTimeMilliseconds()
for iter = 1, N do
    for i = 1, 100 do
        if mobActive[i] then
            local dx = 200 - mobX[i]
            local dy = 120 - mobY[i]
        end
    end
end
local arrayTime = playdate.getCurrentTimeMilliseconds() - t2

print("Table: " .. tableTime .. "ms, Array: " .. arrayTime .. "ms")
-- Expected: Array ~40-60% faster
```

---

## Files Affected by Full DOD Refactor

1. `source/entities/mob.lua` - Complete rewrite
2. `source/scenes/gameplay_scene.lua` - Collision, spawning, grid
3. `source/entities/mobs/*.lua` - All mob subclasses
4. `source/entities/bosses/*.lua` - All bosses
5. `source/entities/tools/*.lua` - Any tool targeting mobs (missiles)

## Conclusion

The hybrid approach offers the best cost/benefit ratio:
- Focus DOD on collision detection (the hottest path)
- Keep OOP for game logic, rendering, subclasses
- Minimal code disruption, measurable gains
