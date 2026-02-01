-- Bonus Items Data
-- All bonus item definitions from the design document

BonusItemsData = {
    -- Tool upgrade items
    alloy_gears = {
        id = "alloy_gears",
        name = "Alloy Gears",
        description = "+25% physical dmg",
        iconPath = "images/bonus_items/bonus_alloy_gears",
        effect = "damage_physical",
        effectValue = 0.25,
        pairsWithTool = "rail_driver",
        upgradesTo = "Rail Cannon",
        unlockCondition = "start",
    },

    expanded_dish = {
        id = "expanded_dish",
        name = "Expanded Dish",
        description = "+25% frequency dmg",
        iconPath = "images/bonus_items/bonus_expanded_dish",
        effect = "damage_frequency",
        effectValue = 0.25,
        pairsWithTool = "frequency_scanner",
        upgradesTo = "Harmonic Disruptor",
        unlockCondition = "start",
    },

    magnetic_coils = {
        id = "magnetic_coils",
        name = "Magnetic Coils",
        description = "Tractor range +50%",
        iconPath = "images/bonus_items/bonus_magnetic_coils",
        effect = "tractor_range",
        effectValue = 0.5,
        pairsWithTool = "tractor_pulse",
        upgradesTo = "Gravity Well",
        unlockCondition = "start",
    },

    cooling_vents = {
        id = "cooling_vents",
        name = "Cooling Vents",
        description = "+25% thermal dmg",
        iconPath = "images/bonus_items/bonus_cooling_vents",
        effect = "damage_thermal",
        effectValue = 0.25,
        pairsWithTool = "thermal_lance",
        upgradesTo = "Plasma Cutter",
        unlockCondition = "episode_1",
    },

    compressor_unit = {
        id = "compressor_unit",
        name = "Compressor Unit",
        description = "Slow duration +50%",
        iconPath = "images/bonus_items/bonus_compressor_unit",
        effect = "slow_duration",
        effectValue = 0.5,
        pairsWithTool = "cryo_projector",
        upgradesTo = "Absolute Zero",
        unlockCondition = "episode_2",
    },

    capacitor_bank = {
        id = "capacitor_bank",
        name = "Capacitor Bank",
        description = "+25% electric dmg",
        iconPath = "images/bonus_items/bonus_capacitor_bank",
        effect = "damage_electric",
        effectValue = 0.25,
        pairsWithTool = "emp_burst",
        upgradesTo = "Ion Storm",
        unlockCondition = "episode_3",
    },

    probe_swarm = {
        id = "probe_swarm",
        name = "Probe Swarm",
        description = "+2 probes per shot",
        iconPath = "images/bonus_items/bonus_probe_swarm",
        effect = "extra_probes",
        effectValue = 2,
        pairsWithTool = "probe_launcher",
        upgradesTo = "Drone Carrier",
        unlockCondition = "episode_4",
    },

    field_amplifier = {
        id = "field_amplifier",
        name = "Field Amplifier",
        description = "Push force +50%",
        iconPath = "images/bonus_items/bonus_field_amplifier",
        effect = "push_force",
        effectValue = 0.5,
        pairsWithTool = "repulsor_field",
        upgradesTo = "Shockwave Generator",
        unlockCondition = "episode_5",
    },

    -- General passive items
    reinforced_hull = {
        id = "reinforced_hull",
        name = "Reinforced Hull",
        description = "+20% max health",
        iconPath = "images/bonus_items/bonus_reinforced_hull",
        effect = "max_health",
        effectValue = 0.2,
        pairsWithTool = nil,
        unlockCondition = "start",
    },

    emergency_thrusters = {
        id = "emergency_thrusters",
        name = "Emergency Thrusters",
        description = "+25% projectile speed",
        iconPath = "images/bonus_items/bonus_emergency_thrusters",
        effect = "projectile_speed",
        effectValue = 0.25,
        pairsWithTool = nil,
        unlockCondition = "start",
    },

    overclocked_capacitors = {
        id = "overclocked_capacitors",
        name = "Overclocked Caps",
        description = "+15% fire rate (all)",
        iconPath = "images/bonus_items/bonus_overclocked_caps",
        effect = "fire_rate",
        effectValue = 0.15,
        pairsWithTool = nil,
        unlockCondition = "episode_1",
    },

    rapid_repair = {
        id = "rapid_repair",
        name = "Rapid Repair",
        description = "Faster HP regen (-1s tick)",
        iconPath = "images/bonus_items/bonus_extended_sensors",  -- Reuse icon
        effect = "regen_speed",
        effectValue = 1,  -- Seconds to reduce regen interval
        pairsWithTool = nil,
        unlockCondition = "episode_2",
        effectPerLevel = 0.5,  -- -0.5s per level (5s -> 4s -> 3.5s -> 3s -> 2.5s)
    },

    scrap_collector = {
        id = "scrap_collector",
        name = "Scrap Collector",
        description = "+15% RP from MOBs",
        iconPath = "images/bonus_items/bonus_scrap_collector",
        effect = "rp_bonus",
        effectValue = 0.15,
        pairsWithTool = nil,
        unlockCondition = "episode_3",
    },

    backup_generator = {
        id = "backup_generator",
        name = "Backup Generator",
        description = "Regen 1 HP/5 sec",
        iconPath = "images/bonus_items/bonus_backup_generator",
        effect = "health_regen",
        effectValue = 1,  -- HP per 5 seconds
        pairsWithTool = nil,
        unlockCondition = "episode_4",
    },

    targeting_computer = {
        id = "targeting_computer",
        name = "Targeting Computer",
        description = "+10% accuracy",
        iconPath = "images/bonus_items/bonus_targeting_computer",
        effect = "accuracy",
        effectValue = 0.1,
        pairsWithTool = nil,
        unlockCondition = "episode_5",
    },

    ablative_coating = {
        id = "ablative_coating",
        name = "Ablative Coating",
        description = "-15% ram damage",
        iconPath = "images/bonus_items/bonus_ablative_coating",
        effect = "ram_resistance",
        effectValue = 0.15,
        pairsWithTool = nil,
        unlockCondition = "all_episodes",
    },

    shield_capacitor = {
        id = "shield_capacitor",
        name = "Shield Capacitor",
        description = "Upgrades shield",
        iconPath = "images/bonus_items/bonus_shield_capacitor",
        effect = "shield_upgrade",
        effectValue = 1,  -- Upgrades shield by 1 level
        pairsWithTool = nil,
        unlockCondition = "start",
        -- Per-level scaling
        effectPerLevel = 1,  -- Each level adds another shield upgrade
    },

    quantum_stabilizer = {
        id = "quantum_stabilizer",
        name = "Quantum Stabilizer",
        description = "-10% all damage",
        iconPath = "images/bonus_items/bonus_quantum_stabilizer",
        effect = "damage_reduction",
        effectValue = 0.1,
        pairsWithTool = nil,
        unlockCondition = "episode_2",
        effectPerLevel = 0.05,  -- +5% per additional level
    },

    power_relay = {
        id = "power_relay",
        name = "Power Relay",
        description = "+10% all damage",
        iconPath = "images/bonus_items/bonus_power_relay",
        effect = "damage_boost",
        effectValue = 0.1,
        pairsWithTool = nil,
        unlockCondition = "episode_1",
        effectPerLevel = 0.05,  -- +5% per additional level
    },

    -- Targeting Matrix - pairs with Modified Mapping Drone
    targeting_matrix = {
        id = "targeting_matrix",
        name = "Targeting Matrix",
        description = "+30% homing accuracy",
        iconPath = "images/bonus_items/bonus_targeting_matrix",
        effect = "homing_accuracy",
        effectValue = 0.3,
        pairsWithTool = "modified_mapping_drone",
        upgradesTo = "Perihelion Strike",
        unlockCondition = "episode_2",
        effectPerLevel = 0.15,
    },

    -- BrainBuddy - neuro-implant augmentation for improved targeting
    brain_buddy = {
        id = "brain_buddy",
        name = "BrainBuddy",
        description = "+15% accuracy, +10% fire rate",
        iconPath = "images/bonus_items/bonus_brain_buddy",
        effect = "brain_buddy",  -- Custom combined effect
        effectValue = 0.15,  -- Base accuracy bonus
        pairsWithTool = nil,
        unlockCondition = "episode_3",
        effectPerLevel = 0.08,  -- +8% accuracy per level
    },

    -- Tool-pairing bonuses for new tools

    -- Graviton Lens - pairs with Singularity Core
    graviton_lens = {
        id = "graviton_lens",
        name = "Graviton Lens",
        description = "+50% orbital range",
        iconPath = "images/bonus_items/bonus_graviton_lens",
        effect = "orbital_range",
        effectValue = 0.5,
        pairsWithTool = "singularity_core",
        upgradesTo = "Black Hole Generator",
        unlockCondition = "episode_3",
        effectPerLevel = 0.25,
    },

    -- Fuel Injector - pairs with Plasma Sprayer
    fuel_injector = {
        id = "fuel_injector",
        name = "Fuel Injector",
        description = "+25% plasma damage",
        iconPath = "images/bonus_items/bonus_fuel_injector",
        effect = "damage_plasma",
        effectValue = 0.25,
        pairsWithTool = "plasma_sprayer",
        upgradesTo = "Inferno Cannon",
        unlockCondition = "episode_1",
        effectPerLevel = 0.12,
    },

    -- Arc Capacitors - pairs with Tesla Coil
    arc_capacitors = {
        id = "arc_capacitors",
        name = "Arc Capacitors",
        description = "+1 chain target",
        iconPath = "images/bonus_items/bonus_arc_capacitors",
        effect = "chain_targets",
        effectValue = 1,
        pairsWithTool = "tesla_coil",
        upgradesTo = "Storm Generator",
        unlockCondition = "episode_3",
        effectPerLevel = 1,
    },

    -- Guidance Module - pairs with Micro-Missile Pod
    guidance_module = {
        id = "guidance_module",
        name = "Guidance Module",
        description = "+2 missiles per burst",
        iconPath = "images/bonus_items/bonus_guidance_module",
        effect = "missiles_per_burst",
        effectValue = 2,
        pairsWithTool = "micro_missile_pod",
        upgradesTo = "Swarm Launcher",
        unlockCondition = "episode_2",
        effectPerLevel = 1,
    },

    -- Phase Modulators - pairs with Phase Disruptor
    phase_modulators = {
        id = "phase_modulators",
        name = "Phase Modulators",
        description = "+25% phase damage",
        iconPath = "images/bonus_items/bonus_phase_modulators",
        effect = "damage_phase",
        effectValue = 0.25,
        pairsWithTool = "phase_disruptor",
        upgradesTo = "Dimensional Rift",
        unlockCondition = "episode_4",
        effectPerLevel = 0.12,
    },

    -- General passive bonuses

    -- Critical Matrix - adds critical hit system
    critical_matrix = {
        id = "critical_matrix",
        name = "Critical Matrix",
        description = "+15% crit chance (2x dmg)",
        iconPath = "images/bonus_items/bonus_critical_matrix",
        effect = "crit_chance",
        effectValue = 0.15,
        pairsWithTool = nil,
        unlockCondition = "episode_2",
        effectPerLevel = 0.08,
    },

    -- Salvage Drone - auto-collect RP, converts 25% to health
    salvage_drone = {
        id = "salvage_drone",
        name = "Salvage Drone",
        description = "Collects RP, 25% heals ship",
        iconPath = "images/bonus_items/bonus_salvage_drone",
        effect = "auto_collect",
        effectValue = 60,  -- Pixel radius
        pairsWithTool = nil,
        unlockCondition = "episode_1",
        effectPerLevel = 20,  -- +20px per level
    },

    -- Kinetic Absorber - HP on kills
    kinetic_absorber = {
        id = "kinetic_absorber",
        name = "Kinetic Absorber",
        description = "+1 HP per 10 kills",
        iconPath = "images/bonus_items/bonus_kinetic_absorber",
        effect = "hp_on_kill",
        effectValue = 10,  -- Kills needed for 1 HP
        pairsWithTool = nil,
        unlockCondition = "episode_3",
        effectPerLevel = -2,  -- Reduces kills needed (10, 8, 6, 4)
    },

    -- Rapid Loader - cooldown reduction on kill
    rapid_loader = {
        id = "rapid_loader",
        name = "Rapid Loader",
        description = "-20% cooldown on kill",
        iconPath = "images/bonus_items/bonus_rapid_loader",
        effect = "cooldown_on_kill",
        effectValue = 0.2,
        pairsWithTool = nil,
        unlockCondition = "episode_4",
        effectPerLevel = 0.1,
    },

    -- Multi-Spectrum Rounds - damage per tool
    multi_spectrum_rounds = {
        id = "multi_spectrum_rounds",
        name = "Multi-Spectrum",
        description = "+5% dmg per tool equipped",
        iconPath = "images/bonus_items/bonus_multi_spectrum_rounds",
        effect = "damage_per_tool",
        effectValue = 0.05,
        pairsWithTool = nil,
        unlockCondition = "episode_5",
        effectPerLevel = 0.025,
    },
}

-- Get bonus items available at game start
function BonusItemsData.getStarterItems()
    local starters = {}
    for id, data in pairs(BonusItemsData) do
        if type(data) == "table" and data.unlockCondition == "start" then
            table.insert(starters, id)
        end
    end
    return starters
end

-- Get bonus item by ID
function BonusItemsData.get(id)
    return BonusItemsData[id]
end

-- Calculate effect value for a bonus item at a specific level (1-4)
function BonusItemsData.getEffectAtLevel(id, level)
    local data = BonusItemsData[id]
    if not data then return nil end

    level = math.max(1, math.min(4, level or 1))
    local levelBonus = level - 1

    local effectPerLevel = data.effectPerLevel or (data.effectValue * 0.5)  -- Default: +50% per level
    return data.effectValue + effectPerLevel * levelBonus
end

return BonusItemsData
