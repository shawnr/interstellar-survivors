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

    extended_sensors = {
        id = "extended_sensors",
        name = "Extended Sensors",
        description = "See collectibles early",
        iconPath = "images/bonus_items/bonus_extended_sensors",
        effect = "sensor_range",
        effectValue = 2,  -- seconds early
        pairsWithTool = nil,
        unlockCondition = "episode_2",
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

return BonusItemsData
