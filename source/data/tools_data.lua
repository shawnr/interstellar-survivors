-- Tools Data
-- All tool definitions from the design document

ToolsData = {
    rail_driver = {
        id = "rail_driver",
        name = "Rail Driver",
        description = "Kinetic launcher. Dmg: 3",
        imagePath = "images/tools/tool_rail_driver",
        iconPath = "images/tools/tool_rail_driver",
        projectileImage = "images/tools/tool_rail_driver_projectile",
        baseDamage = 3,
        fireRate = 1.5,
        projectileSpeed = 8,
        pattern = "straight",
        damageType = "physical",
        unlockCondition = "start",  -- Available from start
        pairsWithBonus = "alloy_gears",
        upgradedName = "Rail Cannon",
        upgradedImagePath = "images/tools/tool_rail_cannon",
        upgradedDamage = 8,
        upgradedSpeed = 10,
    },

    frequency_scanner = {
        id = "frequency_scanner",
        name = "Frequency Scanner",
        description = "Disperses gas clouds. Dmg: 4",
        imagePath = "images/tools/tool_frequency_scanner",
        iconPath = "images/tools/tool_frequency_scanner",
        projectileImage = "images/tools/tool_frequency_scanner_beam",
        baseDamage = 4,
        fireRate = 0.8,
        projectileSpeed = 12,
        pattern = "straight",
        damageType = "frequency",
        unlockCondition = "start",
        pairsWithBonus = "expanded_dish",
        upgradedName = "Harmonic Disruptor",
        upgradedImagePath = "images/tools/tool_harmonic_disruptor",
        upgradedDamage = 10,
    },

    tractor_pulse = {
        id = "tractor_pulse",
        name = "Tractor Pulse",
        description = "Pulls collectibles. No dmg",
        imagePath = "images/tools/tool_tractor_pulse",
        iconPath = "images/tools/tool_tractor_pulse",
        projectileImage = "images/tools/tool_tractor_effect",
        baseDamage = 0,
        fireRate = 0.5,
        projectileSpeed = 6,
        pattern = "cone",
        damageType = "none",
        unlockCondition = "start",
        pairsWithBonus = "magnetic_coils",
        upgradedName = "Gravity Well",
        upgradedImagePath = "images/tools/tool_gravity_well",
    },

    thermal_lance = {
        id = "thermal_lance",
        name = "Thermal Lance",
        description = "Heat beam. Dmg: 5",
        imagePath = "images/tools/tool_thermal_lance",
        iconPath = "images/tools/tool_thermal_lance",
        projectileImage = "images/tools/tool_thermal_beam",
        baseDamage = 5,
        fireRate = 0.4,
        projectileSpeed = 0,  -- Instant beam
        pattern = "beam",
        damageType = "thermal",
        unlockCondition = "episode_1",
        pairsWithBonus = "cooling_vents",
        upgradedName = "Plasma Cutter",
        upgradedImagePath = "images/tools/tool_plasma_cutter",
        upgradedDamage = 12,
    },

    cryo_projector = {
        id = "cryo_projector",
        name = "Cryo Projector",
        description = "Slows enemies. Dmg: 1",
        imagePath = "images/tools/tool_cryo_projector",
        iconPath = "images/tools/tool_cryo_projector",
        projectileImage = "images/tools/tool_cryo_particle",
        baseDamage = 1,
        fireRate = 0.7,
        projectileSpeed = 7,
        pattern = "spread",
        damageType = "cold",
        unlockCondition = "episode_2",
        pairsWithBonus = "compressor_unit",
        upgradedName = "Absolute Zero",
        upgradedImagePath = "images/tools/tool_absolute_zero",
        upgradedDamage = 3,
    },

    emp_burst = {
        id = "emp_burst",
        name = "EMP Burst",
        description = "Disables mechs. Dmg: 2",
        imagePath = "images/tools/tool_emp_burst",
        iconPath = "images/tools/tool_emp_burst",
        projectileImage = "images/tools/tool_emp_effect",
        baseDamage = 2,
        fireRate = 0.3,
        projectileSpeed = 0,  -- Instant radial
        pattern = "radial",
        damageType = "electric",
        unlockCondition = "episode_3",
        pairsWithBonus = "capacitor_bank",
        upgradedName = "Ion Storm",
        upgradedImagePath = "images/tools/tool_ion_storm",
        upgradedDamage = 5,
    },

    probe_launcher = {
        id = "probe_launcher",
        name = "Probe Launcher",
        description = "Homing probes. Dmg: 1/tick",
        imagePath = "images/tools/tool_probe_launcher",
        iconPath = "images/tools/tool_probe_launcher",
        projectileImage = "images/tools/tool_probe",
        baseDamage = 1,
        fireRate = 0.6,
        projectileSpeed = 5,
        pattern = "homing",
        damageType = "analysis",
        unlockCondition = "episode_4",
        pairsWithBonus = "probe_swarm",
        upgradedName = "Drone Carrier",
        upgradedImagePath = "images/tools/tool_drone_carrier",
        upgradedDamage = 2,
    },

    repulsor_field = {
        id = "repulsor_field",
        name = "Repulsor Field",
        description = "Pushes enemies. No dmg",
        imagePath = "images/tools/tool_repulsor_field",
        iconPath = "images/tools/tool_repulsor_field",
        projectileImage = "images/tools/tool_repulsor_wave",
        baseDamage = 0,
        fireRate = 0.2,
        projectileSpeed = 0,  -- Instant radial
        pattern = "radial",
        damageType = "force",
        unlockCondition = "episode_5",
        pairsWithBonus = "field_amplifier",
        upgradedName = "Shockwave Generator",
        upgradedImagePath = "images/tools/tool_shockwave_gen",
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

return ToolsData
