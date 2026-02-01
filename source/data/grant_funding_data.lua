-- Grant Funding Data
-- Defines upgrade costs and effects for the meta-progression system

GrantFundingData = {
    -- Health: Increases station base health
    health = {
        id = "health",
        name = "Health",
        description = "Increases station base health",
        icon = "health",  -- For UI display
        levels = {
            [1] = { cost = 100,  bonus = 0.10, label = "+10% Health" },
            [2] = { cost = 300,  bonus = 0.25, label = "+25% Health" },
            [3] = { cost = 900,  bonus = 0.50, label = "+50% Health" },
            [4] = { cost = 2700, bonus = 1.00, label = "+100% Health" },
        },
    },

    -- Damage: Increases all damage dealt
    damage = {
        id = "damage",
        name = "Damage",
        description = "Increases all damage dealt to enemies",
        icon = "damage",
        levels = {
            [1] = { cost = 100,  bonus = 0.10, label = "+10% Damage" },
            [2] = { cost = 300,  bonus = 0.25, label = "+25% Damage" },
            [3] = { cost = 900,  bonus = 0.50, label = "+50% Damage" },
            [4] = { cost = 2700, bonus = 1.00, label = "+100% Damage" },
        },
    },

    -- Shields: Increases shield capacity AND reduces cooldown
    shields = {
        id = "shields",
        name = "Shields",
        description = "Improves shield capacity and cooldown",
        icon = "shields",
        levels = {
            [1] = { cost = 100,  capacityBonus = 0.25, cooldownReduction = 0.15, label = "+25% Capacity, -15% Cooldown" },
            [2] = { cost = 300,  capacityBonus = 0.50, cooldownReduction = 0.30, label = "+50% Capacity, -30% Cooldown" },
            [3] = { cost = 900,  capacityBonus = 1.00, cooldownReduction = 0.45, label = "+100% Capacity, -45% Cooldown" },
            [4] = { cost = 2700, capacityBonus = 2.00, cooldownReduction = 0.60, label = "+200% Capacity, -60% Cooldown" },
        },
    },

    -- Research: Increases RP earned (more expensive - helps earn more Grant Funds)
    research = {
        id = "research",
        name = "Research",
        description = "Increases Research Points earned",
        icon = "research",
        levels = {
            [1] = { cost = 400,   bonus = 0.15, label = "+15% RP" },
            [2] = { cost = 1200,  bonus = 0.35, label = "+35% RP" },
            [3] = { cost = 3600,  bonus = 0.65, label = "+65% RP" },
            [4] = { cost = 10800, bonus = 1.00, label = "+100% RP" },
        },
    },
}

-- Get the upgrade cost for a stat at a given level (1-4)
function GrantFundingData.getCost(stat, level)
    local data = GrantFundingData[stat]
    if not data or not data.levels[level] then return 0 end
    return data.levels[level].cost
end

-- Get the total bonus at a given level (cumulative from all previous levels)
function GrantFundingData.getTotalBonus(stat, level)
    local data = GrantFundingData[stat]
    if not data or level < 1 then return 0 end

    -- Return the bonus at that level (bonuses are already cumulative in the definition)
    if data.levels[level] then
        return data.levels[level].bonus or 0
    end
    return 0
end

-- Get shield capacity bonus at level
function GrantFundingData.getShieldCapacityBonus(level)
    if level < 1 then return 0 end
    local data = GrantFundingData.shields
    if data.levels[level] then
        return data.levels[level].capacityBonus or 0
    end
    return 0
end

-- Get shield cooldown reduction at level
function GrantFundingData.getShieldCooldownReduction(level)
    if level < 1 then return 0 end
    local data = GrantFundingData.shields
    if data.levels[level] then
        return data.levels[level].cooldownReduction or 0
    end
    return 0
end

-- Get all stat IDs in display order
function GrantFundingData.getStatOrder()
    return { "health", "damage", "shields", "research" }
end

-- Get data for a stat
function GrantFundingData.get(stat)
    return GrantFundingData[stat]
end

return GrantFundingData
