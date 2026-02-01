-- Upgrade System
-- Manages tool and bonus item selection, application, and multi-level upgrades

local MAX_LEVEL = 4  -- Maximum upgrade level for tools and bonus items
local MAX_UNIQUE_TOOLS = 8  -- Maximum unique tool types per episode
local MAX_UNIQUE_ITEMS = 8  -- Maximum unique bonus item types per episode

UpgradeSystem = {
    -- Currently owned bonus items with their levels (by id)
    -- Format: { item_id = level }
    ownedBonusItems = {},

    -- Tool levels (tracked separately, tools are on station)
    -- Format: { tool_id = level }
    toolLevels = {},

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
    self.toolLevels = {}
    self:refreshAvailablePools()
end

-- Set current episode (affects unlock conditions)
function UpgradeSystem:setEpisode(episodeNum)
    self.currentEpisode = episodeNum
    self:refreshAvailablePools()
end

-- Get current level of a tool (0 if not owned)
function UpgradeSystem:getToolLevel(toolId)
    return self.toolLevels[toolId] or 0
end

-- Get current level of a bonus item (0 if not owned)
function UpgradeSystem:getBonusItemLevel(itemId)
    return self.ownedBonusItems[itemId] or 0
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

    -- Get all bonus items that are unlocked
    for id, data in pairs(BonusItemsData) do
        if type(data) == "table" and data.id then
            if self:isUnlocked(data.unlockCondition) then
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
        if SaveManager then
            for i = 1, 5 do
                if not SaveManager:isEpisodeCompleted(i) then
                    return false
                end
            end
            return true
        end
        return false
    end
    return false
end

-- Get random selection of tools and bonus items for level up
-- Returns: tools (array), bonusItems (array)
function UpgradeSystem:getUpgradeOptions(station)
    local toolOptions = {}
    local bonusOptions = {}

    -- Count unique tools owned
    local uniqueToolsOwned = #station.tools

    -- Count unique bonus items owned
    local uniqueBonusItemsOwned = 0
    for _ in pairs(self.ownedBonusItems) do
        uniqueBonusItemsOwned = uniqueBonusItemsOwned + 1
    end

    -- Get tools: either new tools or upgrades for existing ones
    local eligibleTools = {}
    for _, toolData in ipairs(self.availableTools) do
        -- Check if station already has this tool
        local hasTool = false
        local currentLevel = 0

        for _, equippedTool in ipairs(station.tools) do
            if equippedTool.data.id == toolData.id then
                hasTool = true
                currentLevel = equippedTool.level or 1
                break
            end
        end

        -- Can add if station doesn't have it (and under limit), or upgrade if below max level
        if not hasTool then
            -- Only offer new tools if under the unique limit
            if uniqueToolsOwned < MAX_UNIQUE_TOOLS then
                table.insert(eligibleTools, {
                    data = toolData,
                    isNew = true,
                    currentLevel = 0,
                    nextLevel = 1
                })
            end
        elseif currentLevel < MAX_LEVEL then
            table.insert(eligibleTools, {
                data = toolData,
                isNew = false,
                currentLevel = currentLevel,
                nextLevel = currentLevel + 1
            })
        end
    end

    -- Randomly select up to 2 tools
    self:shuffleArray(eligibleTools)
    for i = 1, math.min(2, #eligibleTools) do
        local option = eligibleTools[i]
        local displayData = {
            id = option.data.id,
            type = "tool",
            name = option.data.name,
            description = option.isNew and option.data.description or ("Level " .. option.nextLevel),
            iconPath = option.data.iconPath,
            isNew = option.isNew,
            currentLevel = option.currentLevel,
            nextLevel = option.nextLevel,
            originalData = option.data
        }

        -- Show upgraded name at max level
        if option.nextLevel == MAX_LEVEL and option.data.upgradedName then
            displayData.name = option.data.upgradedName
            if option.data.upgradedImagePath then
                displayData.iconPath = option.data.upgradedImagePath
            end
        end

        -- Add level indicator to name if upgrading
        if not option.isNew then
            displayData.name = displayData.name .. " Lv" .. option.nextLevel
        end

        table.insert(toolOptions, displayData)
    end

    -- Get bonus items: can always re-select to upgrade up to max level
    local eligibleBonus = {}
    for _, bonusData in ipairs(self.availableBonusItems) do
        local currentLevel = self.ownedBonusItems[bonusData.id] or 0

        if currentLevel < MAX_LEVEL then
            -- Only offer new bonus items if under the unique limit
            if currentLevel == 0 then
                if uniqueBonusItemsOwned < MAX_UNIQUE_ITEMS then
                    table.insert(eligibleBonus, {
                        data = bonusData,
                        isNew = true,
                        currentLevel = currentLevel,
                        nextLevel = currentLevel + 1
                    })
                end
            else
                -- Already owned, can upgrade
                table.insert(eligibleBonus, {
                    data = bonusData,
                    isNew = false,
                    currentLevel = currentLevel,
                    nextLevel = currentLevel + 1
                })
            end
        end
    end

    -- Randomly select up to 2 bonus items
    self:shuffleArray(eligibleBonus)
    for i = 1, math.min(2, #eligibleBonus) do
        local option = eligibleBonus[i]
        local displayData = {
            id = option.data.id,
            type = "bonus",
            name = option.data.name,
            description = option.isNew and option.data.description or ("Level " .. option.nextLevel),
            iconPath = option.data.iconPath,
            isNew = option.isNew,
            currentLevel = option.currentLevel,
            nextLevel = option.nextLevel,
            originalData = option.data,
            pairsWithTool = option.data.pairsWithTool  -- For "Helps:" display
        }

        -- Add level indicator if upgrading
        if not option.isNew then
            displayData.name = displayData.name .. " Lv" .. option.nextLevel
        end

        table.insert(bonusOptions, displayData)
    end

    return toolOptions, bonusOptions
end

-- Apply a tool selection
function UpgradeSystem:applyToolSelection(toolData, station)
    if toolData.isNew then
        -- Attach new tool
        local toolClass = self:getToolClass(toolData.originalData.id)
        if toolClass then
            local newTool = toolClass()
            newTool.level = 1
            self.toolLevels[toolData.id] = 1
            station:attachTool(newTool)

            -- Unlock in database
            if SaveManager then
                SaveManager:unlockDatabaseEntry("tools", toolData.id)
            end

            print("Attached new tool: " .. toolData.name .. " (Lv1)")
            return true
        end
    else
        -- Upgrade existing tool
        for _, tool in ipairs(station.tools) do
            if tool.data.id == toolData.originalData.id then
                tool.level = toolData.nextLevel
                self.toolLevels[toolData.id] = toolData.nextLevel
                tool:recalculateStats()
                print("Upgraded tool: " .. toolData.originalData.id .. " to Lv" .. tool.level)

                -- Check if reached max level with matching bonus
                if tool.level >= MAX_LEVEL and toolData.originalData.pairsWithBonus then
                    if self.ownedBonusItems[toolData.originalData.pairsWithBonus] then
                        tool:evolve(toolData.originalData)
                    end
                end

                return true
            end
        end
    end
    return false
end

-- Apply a bonus item selection
-- Note: bonusData may be a display wrapper with originalData, or the actual bonus data
function UpgradeSystem:applyBonusSelection(bonusData, station)
    -- Get the actual bonus data (might be wrapped in displayData from upgrade selection)
    local actualBonusData = bonusData.originalData or bonusData

    local currentLevel = self.ownedBonusItems[actualBonusData.id] or 0
    local newLevel = currentLevel + 1

    -- Unlock in database (only on first acquisition)
    if currentLevel == 0 and SaveManager then
        SaveManager:unlockDatabaseEntry("bonusItems", actualBonusData.id)
    end

    -- Update level
    self.ownedBonusItems[actualBonusData.id] = newLevel

    -- Apply effect (with level scaling)
    self:applyBonusEffect(actualBonusData, station, newLevel)

    -- Check if this bonus pairs with any equipped tool for evolution
    if newLevel >= MAX_LEVEL and actualBonusData.pairsWithTool then
        for _, tool in ipairs(station.tools) do
            if tool.data.id == actualBonusData.pairsWithTool and tool.level >= MAX_LEVEL and not tool.isEvolved then
                tool:evolve(tool.data)
                print("Tool evolved: " .. tool.data.id)
            end
        end
    end

    print("Applied bonus item: " .. actualBonusData.name .. " (Lv" .. newLevel .. ")")
    return true
end

-- Apply bonus item effect to station/tools (with level scaling)
function UpgradeSystem:applyBonusEffect(bonusData, station, level)
    local effect = bonusData.effect
    -- Calculate effect value at this level
    local value = BonusItemsData.getEffectAtLevel(bonusData.id, level)
    -- For upgrades, we need the incremental value (difference from previous level)
    local prevValue = level > 1 and BonusItemsData.getEffectAtLevel(bonusData.id, level - 1) or 0
    local incrementalValue = value - prevValue

    -- On first acquisition, use full value; on upgrade, use incremental
    local applyValue = level == 1 and value or incrementalValue

    if effect == "max_health" then
        local oldMax = station.maxHealth
        station.maxHealth = math.floor(station.maxHealth * (1 + applyValue))
        local healthGain = station.maxHealth - oldMax
        station.health = station.health + healthGain

    elseif effect == "rotation_speed" then
        station.rotationBonus = (station.rotationBonus or 0) + applyValue

    elseif effect == "fire_rate" then
        -- Apply to all tools
        for _, tool in ipairs(station.tools) do
            tool.fireRateBonus = (tool.fireRateBonus or 0) + applyValue
            tool:recalculateStats()
        end
        -- Store for future tools
        station.globalFireRateBonus = (station.globalFireRateBonus or 0) + applyValue

    elseif effect == "regen_speed" then
        -- Reduce health regen interval (faster ticks, minimum 1 second)
        station.healthRegenInterval = math.max(1.0, (station.healthRegenInterval or 5.0) - applyValue)

    elseif effect == "rp_bonus" then
        station.rpBonus = (station.rpBonus or 0) + applyValue

    elseif effect == "health_regen" then
        station.healthRegen = (station.healthRegen or 0) + applyValue

    elseif effect == "accuracy" then
        -- Apply to all tools
        for _, tool in ipairs(station.tools) do
            tool.accuracyBonus = (tool.accuracyBonus or 0) + applyValue
        end
        station.globalAccuracyBonus = (station.globalAccuracyBonus or 0) + applyValue

    elseif effect == "ram_resistance" then
        station.ramResistance = (station.ramResistance or 0) + applyValue

    elseif effect == "projectile_speed" then
        -- Apply to all tools
        for _, tool in ipairs(station.tools) do
            tool.projectileSpeedBonus = (tool.projectileSpeedBonus or 0) + applyValue
        end
        station.globalProjectileSpeedBonus = (station.globalProjectileSpeedBonus or 0) + applyValue

    elseif effect == "shield_upgrade" then
        -- Upgrade station shield
        if station.upgradeShield then
            station:upgradeShield()
        end

    elseif effect == "damage_reduction" then
        station.damageReduction = (station.damageReduction or 0) + applyValue

    elseif effect == "damage_boost" then
        -- Apply to all tools
        for _, tool in ipairs(station.tools) do
            tool.globalDamageBonus = (tool.globalDamageBonus or 0) + applyValue
            tool:recalculateStats()
        end
        station.globalDamageBonus = (station.globalDamageBonus or 0) + applyValue

    -- Tool-specific effects
    elseif effect == "damage_physical" then
        self:applyDamageBonus(station, "physical", applyValue)

    elseif effect == "damage_frequency" then
        self:applyDamageBonus(station, "frequency", applyValue)

    elseif effect == "damage_thermal" then
        self:applyDamageBonus(station, "thermal", applyValue)

    elseif effect == "damage_electric" then
        self:applyDamageBonus(station, "electric", applyValue)

    elseif effect == "tractor_range" then
        self:applyToolBonus(station, "tractor_pulse", "rangeBonus", applyValue)

    elseif effect == "slow_duration" then
        self:applyToolBonus(station, "cryo_projector", "slowDurationBonus", applyValue)

    elseif effect == "extra_probes" then
        self:applyToolBonus(station, "probe_launcher", "extraProbes", applyValue)

    elseif effect == "push_force" then
        self:applyToolBonus(station, "repulsor_field", "pushForceBonus", applyValue)

    elseif effect == "homing_accuracy" then
        -- Apply to mapping drone's homing accuracy
        self:applyToolBonus(station, "modified_mapping_drone", "homingAccuracyBonus", applyValue)

    elseif effect == "brain_buddy" then
        -- BrainBuddy: Combined accuracy + fire rate bonus
        -- Apply accuracy to all tools
        for _, tool in ipairs(station.tools) do
            tool.accuracyBonus = (tool.accuracyBonus or 0) + applyValue
        end
        station.globalAccuracyBonus = (station.globalAccuracyBonus or 0) + applyValue

        -- Also apply 10% fire rate bonus (2/3 of the accuracy value)
        local fireRateBonus = applyValue * 0.67
        for _, tool in ipairs(station.tools) do
            tool.fireRateBonus = (tool.fireRateBonus or 0) + fireRateBonus
            tool:recalculateStats()
        end
        station.globalFireRateBonus = (station.globalFireRateBonus or 0) + fireRateBonus

    -- New tool-pairing effects
    elseif effect == "orbital_range" then
        self:applyToolBonus(station, "singularity_core", "orbitalRangeBonus", applyValue)

    elseif effect == "damage_plasma" then
        self:applyDamageBonus(station, "plasma", applyValue)

    elseif effect == "chain_targets" then
        self:applyToolBonus(station, "tesla_coil", "extraChainTargets", applyValue)

    elseif effect == "missiles_per_burst" then
        self:applyToolBonus(station, "micro_missile_pod", "extraMissiles", applyValue)

    elseif effect == "damage_phase" then
        self:applyDamageBonus(station, "phase", applyValue)

    -- New general passive effects
    elseif effect == "crit_chance" then
        -- Critical hit chance - store on station for tools to use
        station.critChance = (station.critChance or 0) + applyValue

    elseif effect == "auto_collect" then
        -- Spawn a salvage drone to collect RP
        if GameplayScene and not GameplayScene.salvageDrone then
            local drone = SalvageDrone()
            -- Speed: 4 base + 0.5 per level (level 1: 4.5, level 4: 6)
            drone.speed = 4.0 + level * 0.5
            -- Search radius: 200 base + 50 per level (level 1: 250, level 4: 400)
            drone.searchRadius = 200 + level * 50
            drone:add()
            GameplayScene.salvageDrone = drone
            print("Salvage Drone deployed! Speed: " .. drone.speed .. ", Range: " .. drone.searchRadius)
        elseif GameplayScene and GameplayScene.salvageDrone then
            -- Upgrade existing drone
            GameplayScene.salvageDrone.speed = 4.0 + level * 0.5
            GameplayScene.salvageDrone.searchRadius = 200 + level * 50
            print("Salvage Drone upgraded! Speed: " .. GameplayScene.salvageDrone.speed .. ", Range: " .. GameplayScene.salvageDrone.searchRadius)
        end

    elseif effect == "hp_on_kill" then
        -- Store kills needed for HP regen (lower is better)
        station.hpOnKillThreshold = applyValue  -- Overwrites with level-adjusted value
        station.killCounter = station.killCounter or 0

    elseif effect == "cooldown_on_kill" then
        -- Store cooldown reduction percentage
        station.cooldownOnKill = (station.cooldownOnKill or 0) + applyValue

    elseif effect == "damage_per_tool" then
        -- +damage per tool equipped - recalculate all tools
        station.damagePerToolBonus = (station.damagePerToolBonus or 0) + applyValue
        -- Apply to all tools based on tool count
        local toolCount = #station.tools
        local totalBonus = station.damagePerToolBonus * toolCount
        for _, tool in ipairs(station.tools) do
            tool.multiSpectrumBonus = totalBonus
            tool:recalculateStats()
        end
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
        modified_mapping_drone = ModifiedMappingDrone,
        singularity_core = SingularityCore,
        plasma_sprayer = PlasmaSprayer,
        tesla_coil = TeslaCoil,
        micro_missile_pod = MicroMissilePod,
        phase_disruptor = PhaseDisruptor,
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
