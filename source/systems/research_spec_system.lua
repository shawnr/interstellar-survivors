-- Research Spec System
-- Manages research specs and applies their effects

ResearchSpecSystem = {
    -- Currently equipped specs
    equippedSpecs = {},

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
        bonusFrequency = 0,     -- Bonus item frequency increase
    },
}

function ResearchSpecSystem:init()
    -- Load equipped specs from save
    self:loadEquipped()
    Utils.debugPrint("ResearchSpecSystem initialized")
end

-- Get maximum number of specs that can be equipped
function ResearchSpecSystem:getMaxEquipped()
    -- Creative mode: no limit
    if SaveManager:isDebugFeatureEnabled("unlockAllResearchSpecs") then
        return 99
    end
    -- Base: 4 specs
    local base = 4
    -- Expanded Memory grant funding: L1=6, L2=7, L3=8, L4=9
    local memoryLevel = SaveManager:getGrantFundingLevel("expanded_memory")
    if memoryLevel > 0 then
        return base + 1 + memoryLevel  -- 5+1=6, 5+2=7, 5+3=8, 5+4=9
    end
    return base
end

function ResearchSpecSystem:loadEquipped()
    self.equippedSpecs = {}

    local unlockedIds = SaveManager:getUnlockedResearchSpecs()
    local maxEquipped = self:getMaxEquipped()

    -- Check for saved equipped selection
    local savedEquipped = SaveManager:getEquippedResearchSpecs()
    if savedEquipped then
        -- Use saved selection, but filter to only unlocked specs and respect limit
        local unlockedSet = {}
        for _, id in ipairs(unlockedIds) do
            unlockedSet[id] = true
        end
        for _, specId in ipairs(savedEquipped) do
            if unlockedSet[specId] and #self.equippedSpecs < maxEquipped then
                self.equippedSpecs[#self.equippedSpecs + 1] = specId
            end
        end
    else
        -- Auto-equip first N unlocked specs
        for i, specId in ipairs(unlockedIds) do
            if i <= maxEquipped then
                self.equippedSpecs[#self.equippedSpecs + 1] = specId
            end
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
        bonusFrequency = 0,
    }

    -- Apply each equipped spec
    for _, specId in ipairs(self.equippedSpecs) do
        local spec = ResearchSpecsData.get(specId)
        if spec and spec.effect then
            self:applyEffect(spec.effect)
        end
    end

    Utils.debugPrint("Research bonuses recalculated")
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
    elseif effect.type == "bonus_frequency" then
        self.bonuses.bonusFrequency = self.bonuses.bonusFrequency + effect.value
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
    if #self.equippedSpecs >= self:getMaxEquipped() then
        return false
    end

    -- Check if unlocked
    if not SaveManager:isResearchSpecUnlocked(specId) then
        return false
    end

    self.equippedSpecs[#self.equippedSpecs + 1] = specId
    self:recalculateBonuses()
    SaveManager:saveEquippedSpecs(self.equippedSpecs)
    return true
end

-- Unequip a spec
function ResearchSpecSystem:unequipSpec(specId)
    for i, id in ipairs(self.equippedSpecs) do
        if id == specId then
            table.remove(self.equippedSpecs, i)
            self:recalculateBonuses()
            SaveManager:saveEquippedSpecs(self.equippedSpecs)
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

function ResearchSpecSystem:getBonusFrequency()
    return self.bonuses.bonusFrequency
end

return ResearchSpecSystem
