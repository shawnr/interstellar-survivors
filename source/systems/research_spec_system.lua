-- Research Spec System
-- Manages research specs and applies their effects

ResearchSpecSystem = {
    -- Currently equipped specs (max 3)
    equippedSpecs = {},
    maxEquipped = 3,

    -- Cached effect bonuses
    bonuses = {
        stationHealth = 0,      -- Percentage bonus
        fireRate = 0,           -- Percentage bonus
        dodgeChance = 0,        -- Flat percentage
        rpBonus = 0,            -- Percentage bonus
        damageBonus = 0,        -- Percentage bonus
        startingHealth = 0,     -- Flat bonus
        collectRange = 0,       -- Percentage bonus
        startingLevel = 1,      -- Starting level
        startingToolSelect = false,  -- Can select starting tool
    },
}

function ResearchSpecSystem:init()
    -- Load equipped specs from save
    self:loadEquipped()
    print("ResearchSpecSystem initialized")
end

function ResearchSpecSystem:loadEquipped()
    self.equippedSpecs = {}

    -- Get unlocked specs from save manager
    local unlockedIds = SaveManager:getUnlockedResearchSpecs()

    -- For now, auto-equip all unlocked specs (up to max)
    for i, specId in ipairs(unlockedIds) do
        if i <= self.maxEquipped then
            table.insert(self.equippedSpecs, specId)
        end
    end

    -- Recalculate bonuses
    self:recalculateBonuses()
end

function ResearchSpecSystem:recalculateBonuses()
    -- Reset all bonuses
    self.bonuses = {
        stationHealth = 0,
        fireRate = 0,
        dodgeChance = 0,
        rpBonus = 0,
        damageBonus = 0,
        startingHealth = 0,
        collectRange = 0,
        startingLevel = 1,
        startingToolSelect = false,
    }

    -- Apply each equipped spec
    for _, specId in ipairs(self.equippedSpecs) do
        local spec = ResearchSpecsData.get(specId)
        if spec and spec.effect then
            self:applyEffect(spec.effect)
        end
    end

    print("Research bonuses recalculated")
end

function ResearchSpecSystem:applyEffect(effect)
    if effect.type == "station_health" then
        self.bonuses.stationHealth = self.bonuses.stationHealth + effect.value
    elseif effect.type == "fire_rate" then
        self.bonuses.fireRate = self.bonuses.fireRate + effect.value
    elseif effect.type == "dodge_chance" then
        self.bonuses.dodgeChance = self.bonuses.dodgeChance + effect.value
    elseif effect.type == "rp_bonus" then
        self.bonuses.rpBonus = self.bonuses.rpBonus + effect.value
    elseif effect.type == "damage_bonus" then
        self.bonuses.damageBonus = self.bonuses.damageBonus + effect.value
    elseif effect.type == "starting_health" then
        self.bonuses.startingHealth = self.bonuses.startingHealth + effect.value
    elseif effect.type == "collect_range" then
        self.bonuses.collectRange = self.bonuses.collectRange + effect.value
    elseif effect.type == "starting_level" then
        self.bonuses.startingLevel = math.max(self.bonuses.startingLevel, effect.value)
    elseif effect.type == "starting_tool_select" then
        self.bonuses.startingToolSelect = true
    end
end

-- Get all unlocked specs
function ResearchSpecSystem:getUnlockedSpecs()
    local unlocked = {}
    local unlockedIds = SaveManager:getUnlockedResearchSpecs()

    for _, specId in ipairs(unlockedIds) do
        local spec = ResearchSpecsData.get(specId)
        if spec then
            table.insert(unlocked, spec)
        end
    end

    return unlocked
end

-- Check if a spec is equipped
function ResearchSpecSystem:isEquipped(specId)
    for _, id in ipairs(self.equippedSpecs) do
        if id == specId then
            return true
        end
    end
    return false
end

-- Equip a spec (if room available)
function ResearchSpecSystem:equipSpec(specId)
    -- Check if already equipped
    if self:isEquipped(specId) then
        return false
    end

    -- Check if we have room
    if #self.equippedSpecs >= self.maxEquipped then
        return false
    end

    -- Check if unlocked
    if not SaveManager:isResearchSpecUnlocked(specId) then
        return false
    end

    table.insert(self.equippedSpecs, specId)
    self:recalculateBonuses()
    return true
end

-- Unequip a spec
function ResearchSpecSystem:unequipSpec(specId)
    for i, id in ipairs(self.equippedSpecs) do
        if id == specId then
            table.remove(self.equippedSpecs, i)
            self:recalculateBonuses()
            return true
        end
    end
    return false
end

-- Get bonuses for use by other systems
function ResearchSpecSystem:getStationHealthBonus()
    return self.bonuses.stationHealth
end

function ResearchSpecSystem:getFireRateBonus()
    return self.bonuses.fireRate
end

function ResearchSpecSystem:getDodgeChance()
    return self.bonuses.dodgeChance
end

function ResearchSpecSystem:getRPBonus()
    return self.bonuses.rpBonus
end

function ResearchSpecSystem:getDamageBonus()
    return self.bonuses.damageBonus
end

function ResearchSpecSystem:getStartingHealth()
    return self.bonuses.startingHealth
end

function ResearchSpecSystem:getCollectRangeBonus()
    return self.bonuses.collectRange
end

function ResearchSpecSystem:getStartingLevel()
    return self.bonuses.startingLevel
end

function ResearchSpecSystem:canSelectStartingTool()
    return self.bonuses.startingToolSelect
end

return ResearchSpecSystem
