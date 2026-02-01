-- Tools Data
-- All tool definitions from the design document

ToolsData = {
    rail_driver = {
        id = "rail_driver",
        name = "Rail Driver",
        description = "Kinetic launcher. Dmg: 8",
        imagePath = "images/tools/tool_rail_driver",
        iconPath = "images/tools/tool_rail_driver",
        projectileImage = "images/tools/tool_rail_driver_projectile",
        baseDamage = 8,
        fireRate = 2.0,
        projectileSpeed = 10,
        pattern = "straight",
        damageType = "physical",
        unlockCondition = "start",  -- Available from start
        pairsWithBonus = "alloy_gears",
        upgradedName = "Rail Cannon",
        upgradedImagePath = "images/tools/tool_rail_cannon",
        upgradedDamage = 20,
        upgradedSpeed = 12,
        -- Per-level scaling (level 1 = base, levels 2-4 scale these multipliers)
        damagePerLevel = 4,      -- +4 damage per level
        fireRatePerLevel = 0.3,  -- +0.3 fire rate per level
    },

    frequency_scanner = {
        id = "frequency_scanner",
        name = "Frequency Scanner",
        description = "Disperses gas clouds. Dmg: 10",
        imagePath = "images/tools/tool_frequency_scanner",
        iconPath = "images/tools/tool_frequency_scanner",
        projectileImage = "images/tools/tool_frequency_scanner_beam",
        baseDamage = 10,
        fireRate = 1.2,
        projectileSpeed = 14,
        pattern = "straight",
        damageType = "frequency",
        unlockCondition = "start",
        pairsWithBonus = "expanded_dish",
        upgradedName = "Harmonic Disruptor",
        upgradedImagePath = "images/tools/tool_harmonic_disruptor",
        upgradedDamage = 25,
        damagePerLevel = 5,
        fireRatePerLevel = 0.2,
    },

    tractor_pulse = {
        id = "tractor_pulse",
        name = "Tractor Pulse",
        description = "Pulls collectibles. No dmg",
        imagePath = "images/tools/tool_tractor_pulse",
        iconPath = "images/tools/tool_tractor_pulse",
        projectileImage = "images/tools/tool_tractor_effect",
        baseDamage = 0,
        fireRate = 0.8,
        projectileSpeed = 8,
        pattern = "cone",
        damageType = "none",
        unlockCondition = "start",
        pairsWithBonus = "magnetic_coils",
        upgradedName = "Gravity Well",
        upgradedImagePath = "images/tools/tool_gravity_well",
        -- Tractor doesn't do damage but range increases per level
        rangePerLevel = 15,
    },

    thermal_lance = {
        id = "thermal_lance",
        name = "Thermal Lance",
        description = "Heat beam. Dmg: 12",
        imagePath = "images/tools/tool_thermal_lance",
        iconPath = "images/tools/tool_thermal_lance",
        projectileImage = "images/tools/tool_thermal_beam",
        baseDamage = 12,
        fireRate = 0.6,
        projectileSpeed = 0,  -- Instant beam
        pattern = "beam",
        damageType = "thermal",
        unlockCondition = "episode_1",
        pairsWithBonus = "cooling_vents",
        upgradedName = "Plasma Cutter",
        upgradedImagePath = "images/tools/tool_plasma_cutter",
        upgradedDamage = 30,
        damagePerLevel = 6,
        fireRatePerLevel = 0.15,
    },

    cryo_projector = {
        id = "cryo_projector",
        name = "Cryo Projector",
        description = "Slows enemies. Dmg: 4",
        imagePath = "images/tools/tool_cryo_projector",
        iconPath = "images/tools/tool_cryo_projector",
        projectileImage = "images/tools/tool_cryo_particle",
        baseDamage = 4,
        fireRate = 1.0,
        projectileSpeed = 8,
        pattern = "spread",
        damageType = "cold",
        unlockCondition = "episode_2",
        pairsWithBonus = "compressor_unit",
        upgradedName = "Absolute Zero",
        upgradedImagePath = "images/tools/tool_absolute_zero",
        upgradedDamage = 10,
        damagePerLevel = 2,
        fireRatePerLevel = 0.25,
    },

    emp_burst = {
        id = "emp_burst",
        name = "EMP Burst",
        description = "Disables mechs. Dmg: 6",
        imagePath = "images/tools/tool_emp_burst",
        iconPath = "images/tools/tool_emp_burst",
        projectileImage = "images/tools/tool_emp_effect",
        baseDamage = 6,
        fireRate = 0.5,
        projectileSpeed = 0,  -- Instant radial
        pattern = "radial",
        damageType = "electric",
        unlockCondition = "episode_3",
        pairsWithBonus = "capacitor_bank",
        upgradedName = "Ion Storm",
        upgradedImagePath = "images/tools/tool_ion_storm",
        upgradedDamage = 15,
        damagePerLevel = 3,
        fireRatePerLevel = 0.1,
    },

    probe_launcher = {
        id = "probe_launcher",
        name = "Probe Launcher",
        description = "Homing probes. Dmg: 5/tick",
        imagePath = "images/tools/tool_probe_launcher",
        iconPath = "images/tools/tool_probe_launcher",
        projectileImage = "images/tools/tool_probe",
        baseDamage = 5,
        fireRate = 0.8,
        projectileSpeed = 6,
        pattern = "homing",
        damageType = "analysis",
        unlockCondition = "episode_4",
        pairsWithBonus = "probe_swarm",
        upgradedName = "Drone Carrier",
        upgradedImagePath = "images/tools/tool_drone_carrier",
        upgradedDamage = 12,
        damagePerLevel = 2,
        fireRatePerLevel = 0.2,
    },

    repulsor_field = {
        id = "repulsor_field",
        name = "Repulsor Field",
        description = "Pushes enemies. Dmg: 3",
        imagePath = "images/tools/tool_repulsor_field",
        iconPath = "images/tools/tool_repulsor_field",
        projectileImage = "images/tools/tool_repulsor_wave",
        baseDamage = 3,
        fireRate = 0.4,
        projectileSpeed = 0,  -- Instant radial
        pattern = "radial",
        damageType = "force",
        unlockCondition = "episode_5",
        pairsWithBonus = "field_amplifier",
        upgradedName = "Shockwave Generator",
        upgradedImagePath = "images/tools/tool_shockwave_gen",
        damagePerLevel = 2,
        fireRatePerLevel = 0.1,
    },

    -- Modified Mapping Drone (Murderbot Diaries reference - ART/Perihelion)
    -- Heat-seeking missile that targets the highest HP enemy
    modified_mapping_drone = {
        id = "modified_mapping_drone",
        name = "Mapping Drone",
        description = "Seeks highest HP. Dmg: 18",
        imagePath = "images/tools/tool_mapping_drone",
        iconPath = "images/tools/tool_mapping_drone",
        projectileImage = "images/tools/tool_mapping_drone_missile",
        baseDamage = 18,
        fireRate = 0.5,  -- Slow fire rate, but high damage
        projectileSpeed = 4,  -- Slower than normal, but homes in
        pattern = "homing_priority",  -- Special: targets highest HP
        damageType = "explosive",
        unlockCondition = "episode_2",  -- Unlocked in Episode 2
        pairsWithBonus = "targeting_matrix",
        upgradedName = "Perihelion Strike",
        upgradedImagePath = "images/tools/tool_mapping_drone",  -- Same sprite for now
        upgradedDamage = 35,
        damagePerLevel = 8,
        fireRatePerLevel = 0.1,
    },

    -- Singularity Core - orbital gravity weapon
    singularity_core = {
        id = "singularity_core",
        name = "Singularity Core",
        description = "Orbital gravity orb. Dmg: 6/tick",
        imagePath = "images/tools/tool_singularity_core",
        iconPath = "images/tools/tool_singularity_core",
        projectileImage = "images/tools/tool_singularity_orb",
        baseDamage = 6,
        fireRate = 0.3,  -- Spawns orb every 3.3 seconds
        projectileSpeed = 0,  -- Orbital, doesn't fly away
        pattern = "orbital",
        damageType = "gravity",
        unlockCondition = "episode_3",
        pairsWithBonus = "graviton_lens",
        upgradedName = "Black Hole Generator",
        upgradedImagePath = "images/tools/tool_singularity_core",
        upgradedDamage = 12,
        damagePerLevel = 3,
        fireRatePerLevel = 0.05,
    },

    -- Plasma Sprayer - short range cone attack
    plasma_sprayer = {
        id = "plasma_sprayer",
        name = "Plasma Sprayer",
        description = "Cone spray. Dmg: 3x5",
        imagePath = "images/tools/tool_plasma_sprayer",
        iconPath = "images/tools/tool_plasma_sprayer",
        projectileImage = "images/tools/tool_plasma_droplet",
        baseDamage = 3,
        fireRate = 1.5,  -- Fast spray
        projectileSpeed = 8,
        pattern = "cone",
        damageType = "plasma",
        unlockCondition = "episode_1",
        pairsWithBonus = "fuel_injector",
        upgradedName = "Inferno Cannon",
        upgradedImagePath = "images/tools/tool_plasma_sprayer",
        upgradedDamage = 6,
        damagePerLevel = 1,
        fireRatePerLevel = 0.3,
        projectilesPerShot = 5,  -- Fires 5 droplets
        spreadAngle = 45,  -- 45 degree cone
    },

    -- Tesla Coil - chain lightning
    tesla_coil = {
        id = "tesla_coil",
        name = "Tesla Coil",
        description = "Chain lightning. Dmg: 8",
        imagePath = "images/tools/tool_tesla_coil",
        iconPath = "images/tools/tool_tesla_coil",
        projectileImage = "images/tools/tool_lightning_bolt",
        baseDamage = 8,
        fireRate = 0.8,
        projectileSpeed = 20,  -- Fast lightning
        pattern = "chain",
        damageType = "electric",
        unlockCondition = "episode_3",
        pairsWithBonus = "arc_capacitors",
        upgradedName = "Storm Generator",
        upgradedImagePath = "images/tools/tool_tesla_coil",
        upgradedDamage = 16,
        damagePerLevel = 4,
        fireRatePerLevel = 0.15,
        chainTargets = 2,  -- Chains to 2 additional targets
    },

    -- Micro-Missile Pod - burst fire missiles
    micro_missile_pod = {
        id = "micro_missile_pod",
        name = "Micro-Missile Pod",
        description = "3-missile burst. Dmg: 4x3",
        imagePath = "images/tools/tool_micro_missile_pod",
        iconPath = "images/tools/tool_micro_missile_pod",
        projectileImage = "images/tools/tool_micro_missile",
        baseDamage = 4,
        fireRate = 0.6,
        projectileSpeed = 7,
        pattern = "burst",
        damageType = "explosive",
        unlockCondition = "episode_2",
        pairsWithBonus = "guidance_module",
        upgradedName = "Swarm Launcher",
        upgradedImagePath = "images/tools/tool_micro_missile_pod",
        upgradedDamage = 8,
        damagePerLevel = 2,
        fireRatePerLevel = 0.1,
        missilesPerBurst = 3,
        burstSpread = 15,  -- Degrees spread between missiles
    },

    -- Phase Disruptor - piercing beam
    phase_disruptor = {
        id = "phase_disruptor",
        name = "Phase Disruptor",
        description = "Piercing beam. Dmg: 15",
        imagePath = "images/tools/tool_phase_disruptor",
        iconPath = "images/tools/tool_phase_disruptor",
        projectileImage = "images/tools/tool_phase_beam",
        baseDamage = 15,
        fireRate = 0.4,  -- Slow but powerful
        projectileSpeed = 15,
        pattern = "piercing",
        damageType = "phase",
        unlockCondition = "episode_4",
        pairsWithBonus = "phase_modulators",
        upgradedName = "Dimensional Rift",
        upgradedImagePath = "images/tools/tool_phase_disruptor",
        upgradedDamage = 30,
        damagePerLevel = 7,
        fireRatePerLevel = 0.08,
        maxPierceTargets = 99,  -- Hits all enemies in path
    },
}

-- Get tools available at game start
function ToolsData.getStarterTools()
    local starters = {}
    for id, data in pairs(ToolsData) do
        if type(data) == "table" and data.unlockCondition == "start" then
            table.insert(starters, id)
        end
    end
    return starters
end

-- Get tool by ID
function ToolsData.get(id)
    return ToolsData[id]
end

-- Calculate stats for a tool at a specific level (1-4)
function ToolsData.getStatsAtLevel(id, level)
    local data = ToolsData[id]
    if not data then return nil end

    level = math.max(1, math.min(4, level or 1))
    local levelBonus = level - 1

    return {
        damage = data.baseDamage + (data.damagePerLevel or 0) * levelBonus,
        fireRate = data.fireRate + (data.fireRatePerLevel or 0) * levelBonus,
        range = 100 + (data.rangePerLevel or 0) * levelBonus,  -- Base range 100
    }
end

return ToolsData
