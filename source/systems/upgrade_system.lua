-- Upgrade System
-- Manages tool and bonus item selection, application, and upgrades

UpgradeSystem = {
    -- Currently owned bonus items (by id)
    ownedBonusItems = {},

    -- Available pools for selection
    availableTools = {},
    availableBonusItems = {},

    -- Episode context (affects what's available)
    currentEpisode = 1,
}

function UpgradeSystem:init()
    self:reset()
end

function UpgradeSystem:reset()
    self.ownedBonusItems = {}
    self:refreshAvailablePools()
end

-- Set current episode (affects unlock conditions)
function UpgradeSystem:setEpisode(episodeNum)
    self.currentEpisode = episodeNum
    self:refreshAvailablePools()
end

-- Refresh available tool and bonus item pools based on current unlock state
function UpgradeSystem:refreshAvailablePools()
    self.availableTools = {}
    self.availableBonusItems = {}

    -- Get all tools that are unlocked for current episode
    for id, data in pairs(ToolsData) do
        if type(data) == "table" and data.id then
            if self:isUnlocked(data.unlockCondition) then
                table.insert(self.availableTools, data)
            end
        end
    end

    -- Get all bonus items that are unlocked and not owned
    for id, data in pairs(BonusItemsData) do
        if type(data) == "table" and data.id then
            if self:isUnlocked(data.unlockCondition) and not self.ownedBonusItems[id] then
                table.insert(self.availableBonusItems, data)
            end
        end
    end

    print("Available tools: " .. #self.availableTools .. ", bonus items: " .. #self.availableBonusItems)
end

-- Check if an unlock condition is met
function UpgradeSystem:isUnlocked(condition)
    if condition == "start" then
        return true
    elseif condition == "episode_1" then
        return self.currentEpisode >= 1
    elseif condition == "episode_2" then
        return self.currentEpisode >= 2
    elseif condition == "episode_3" then
        return self.currentEpisode >= 3
    elseif condition == "episode_4" then
        return self.currentEpisode >= 4
    elseif condition == "episode_5" then
        return self.currentEpisode >= 5
    elseif condition == "all_episodes" then
        -- Requires completing all episodes - check save data
        -- TODO: Check SaveManager for completion
        return false
    end
    return false
end

-- Get random selection of tools and bonus items for level up
-- Returns: tools (array), bonusItems (array)
function UpgradeSystem:getUpgradeOptions(station)
    local toolOptions = {}
    local bonusOptions = {}

    -- Get tools the station doesn't already have (or that can be upgraded)
    local eligibleTools = {}
    for _, toolData in ipairs(self.availableTools) do
        -- Check if station already has this tool
        local hasTool = false
        local canUpgrade = false

        for _, equippedTool in ipairs(station.tools) do
            if equippedTool.data.id == toolData.id then
                hasTool = true
                -- Check if it can be upgraded (has matching bonus item)
                if not equippedTool.isUpgraded and toolData.pairsWithBonus then
                    if self.ownedBonusItems[toolData.pairsWithBonus] then
                        canUpgrade = true
                    end
                end
                break
            end
        end

        -- Add to eligible if station doesn't have it or can upgrade it
        if not hasTool then
            table.insert(eligibleTools, {
                data = toolData,
                isUpgrade = false
            })
        elseif canUpgrade then
            table.insert(eligibleTools, {
                data = toolData,
                isUpgrade = true
            })
        end
    end

    -- Randomly select up to 2 tools
    self:shuffleArray(eligibleTools)
    for i = 1, math.min(2, #eligibleTools) do
        local option = eligibleTools[i]
        local displayData = {
            id = option.data.id,
            name = option.isUpgrade and option.data.upgradedName or option.data.name,
            description = option.isUpgrade and "UPGRADE!" or option.data.description,
            iconPath = option.isUpgrade and option.data.upgradedImagePath or option.data.iconPath,
            isUpgrade = option.isUpgrade,
            originalData = option.data
        }
        table.insert(toolOptions, displayData)
    end

    -- Get bonus items not yet owned
    local eligibleBonus = {}
    for _, bonusData in ipairs(self.availableBonusItems) do
        if not self.ownedBonusItems[bonusData.id] then
            table.insert(eligibleBonus, bonusData)
        end
    end

    -- Randomly select up to 2 bonus items
    self:shuffleArray(eligibleBonus)
    for i = 1, math.min(2, #eligibleBonus) do
        table.insert(bonusOptions, eligibleBonus[i])
    end

    return toolOptions, bonusOptions
end

-- Apply a tool selection
function UpgradeSystem:applyToolSelection(toolData, station)
    if toolData.isUpgrade then
        -- Find and upgrade existing tool
        for _, tool in ipairs(station.tools) do
            if tool.data.id == toolData.originalData.id then
                local bonusId = toolData.originalData.pairsWithBonus
                local bonusData = BonusItemsData.get(bonusId)
                if bonusData then
                    tool:upgrade(bonusData)
                    print("Upgraded tool: " .. tool.data.id .. " to " .. toolData.name)
                end
                return true
            end
        end
    else
        -- Attach new tool
        local toolClass = self:getToolClass(toolData.originalData.id)
        if toolClass then
            local newTool = toolClass()
            station:attachTool(newTool)
            print("Attached new tool: " .. toolData.name)
            return true
        end
    end
    return false
end

-- Apply a bonus item selection
function UpgradeSystem:applyBonusSelection(bonusData, station)
    -- Mark as owned
    self.ownedBonusItems[bonusData.id] = true

    -- Apply effect to station
    self:applyBonusEffect(bonusData, station)

    -- Check if this bonus pairs with any equipped tool for upgrade
    if bonusData.pairsWithTool then
        for _, tool in ipairs(station.tools) do
            if tool.data.id == bonusData.pairsWithTool and not tool.isUpgraded then
                tool:upgrade(bonusData)
                print("Auto-upgraded tool " .. tool.data.id .. " with " .. bonusData.id)
            end
        end
    end

    -- Remove from available pool
    self:refreshAvailablePools()

    print("Applied bonus item: " .. bonusData.name)
    return true
end

-- Apply bonus item effect to station/tools
function UpgradeSystem:applyBonusEffect(bonusData, station)
    local effect = bonusData.effect
    local value = bonusData.effectValue

    if effect == "max_health" then
        station.maxHealth = station.maxHealth * (1 + value)
        station.health = station.health * (1 + value)

    elseif effect == "rotation_speed" then
        station.rotationBonus = (station.rotationBonus or 0) + value

    elseif effect == "fire_rate" then
        -- Apply to all tools
        for _, tool in ipairs(station.tools) do
            tool.fireRateBonus = (tool.fireRateBonus or 0) + value
            tool:recalculateStats()
        end
        -- Store for future tools
        station.globalFireRateBonus = (station.globalFireRateBonus or 0) + value

    elseif effect == "sensor_range" then
        station.sensorRange = (station.sensorRange or 0) + value

    elseif effect == "rp_bonus" then
        station.rpBonus = (station.rpBonus or 0) + value

    elseif effect == "health_regen" then
        station.healthRegen = (station.healthRegen or 0) + value

    elseif effect == "accuracy" then
        -- Apply to all tools
        for _, tool in ipairs(station.tools) do
            tool.accuracyBonus = (tool.accuracyBonus or 0) + value
        end
        station.globalAccuracyBonus = (station.globalAccuracyBonus or 0) + value

    elseif effect == "ram_resistance" then
        station.ramResistance = (station.ramResistance or 0) + value

    -- Tool-specific effects
    elseif effect == "damage_physical" then
        self:applyDamageBonus(station, "physical", value)

    elseif effect == "damage_frequency" then
        self:applyDamageBonus(station, "frequency", value)

    elseif effect == "damage_thermal" then
        self:applyDamageBonus(station, "thermal", value)

    elseif effect == "damage_electric" then
        self:applyDamageBonus(station, "electric", value)

    elseif effect == "tractor_range" then
        self:applyToolBonus(station, "tractor_pulse", "rangeBonus", value)

    elseif effect == "slow_duration" then
        self:applyToolBonus(station, "cryo_projector", "slowDurationBonus", value)

    elseif effect == "extra_probes" then
        self:applyToolBonus(station, "probe_launcher", "extraProbes", value)

    elseif effect == "push_force" then
        self:applyToolBonus(station, "repulsor_field", "pushForceBonus", value)
    end
end

-- Apply damage bonus to tools of specific damage type
function UpgradeSystem:applyDamageBonus(station, damageType, value)
    for _, tool in ipairs(station.tools) do
        if tool.data.damageType == damageType then
            tool.damageBonus = (tool.damageBonus or 0) + value
            tool:recalculateStats()
        end
    end
    -- Store for future tools
    station.damageBonus = station.damageBonus or {}
    station.damageBonus[damageType] = (station.damageBonus[damageType] or 0) + value
end

-- Apply bonus to specific tool type
function UpgradeSystem:applyToolBonus(station, toolId, property, value)
    for _, tool in ipairs(station.tools) do
        if tool.data.id == toolId then
            tool[property] = (tool[property] or 0) + value
            if tool.recalculateStats then
                tool:recalculateStats()
            end
        end
    end
    -- Store for future tools
    station.toolBonuses = station.toolBonuses or {}
    station.toolBonuses[toolId] = station.toolBonuses[toolId] or {}
    station.toolBonuses[toolId][property] = (station.toolBonuses[toolId][property] or 0) + value
end

-- Get tool class by ID
function UpgradeSystem:getToolClass(toolId)
    -- Map tool IDs to their classes
    local toolClasses = {
        rail_driver = RailDriver,
        frequency_scanner = FrequencyScanner,
        tractor_pulse = TractorPulse,
        thermal_lance = ThermalLance,
        cryo_projector = CryoProjector,
        emp_burst = EMPBurst,
        probe_launcher = ProbeLauncher,
        repulsor_field = RepulsorField,
    }
    return toolClasses[toolId]
end

-- Fisher-Yates shuffle
function UpgradeSystem:shuffleArray(arr)
    for i = #arr, 2, -1 do
        local j = math.random(i)
        arr[i], arr[j] = arr[j], arr[i]
    end
end

return UpgradeSystem
