-- Research Specs Data
-- Permanent upgrades unlocked by completing episodes

ResearchSpecsData = {
    -- Episode 1 unlock: Silk Weave Plating
    silk_weave_plating = {
        id = "silk_weave_plating",
        name = "Silk Weave Plating",
        description = "+10% Station Health",
        episodeSource = 1,
        effect = {
            type = "station_health",
            value = 0.10,  -- 10% bonus
        },
    },

    -- Episode 2 unlock: Efficiency Protocols
    efficiency_protocols = {
        id = "efficiency_protocols",
        name = "Efficiency Protocols",
        description = "+5% Fire Rate (all tools)",
        episodeSource = 2,
        effect = {
            type = "fire_rate",
            value = 0.05,  -- 5% faster
        },
    },

    -- Episode 3 unlock: Probability Shield
    probability_shield = {
        id = "probability_shield",
        name = "Probability Shield",
        description = "5% chance to dodge hits",
        episodeSource = 3,
        effect = {
            type = "dodge_chance",
            value = 0.05,  -- 5% dodge
        },
    },

    -- Episode 4 unlock: Ancient Alloys
    ancient_alloys = {
        id = "ancient_alloys",
        name = "Ancient Alloys",
        description = "+15% Station Health",
        episodeSource = 4,
        effect = {
            type = "station_health",
            value = 0.15,  -- 15% bonus
        },
    },

    -- Episode 5 unlock: Peer Review
    peer_review = {
        id = "peer_review",
        name = "Peer Review",
        description = "Bonus Items 10% more frequent",
        episodeSource = 5,
        effect = {
            type = "bonus_frequency",
            value = 0.10,  -- 10% more frequent
        },
    },

    -- Bonus specs (unlocked by other means)
    emergency_reserves = {
        id = "emergency_reserves",
        name = "Emergency Reserves",
        description = "Start with +25 Health",
        episodeSource = nil,  -- Special unlock
        unlockCondition = "total_victories_3",
        effect = {
            type = "starting_health",
            value = 25,
        },
    },

    magnetic_attraction = {
        id = "magnetic_attraction",
        name = "Magnetic Attraction",
        description = "+20% Collectible range",
        episodeSource = nil,
        unlockCondition = "total_deaths_5",  -- Learn from failure
        effect = {
            type = "collect_range",
            value = 0.20,  -- 20% larger range
        },
    },

    veteran_instincts = {
        id = "veteran_instincts",
        name = "Veteran Instincts",
        description = "Start at Level 2",
        episodeSource = nil,
        unlockCondition = "all_episodes_complete",
        effect = {
            type = "starting_level",
            value = 2,
        },
    },
}

-- Get spec by ID
function ResearchSpecsData.get(specId)
    return ResearchSpecsData[specId]
end

-- Get all specs as array
function ResearchSpecsData.getAll()
    local specs = {}
    for id, data in pairs(ResearchSpecsData) do
        if type(data) == "table" and data.id then
            table.insert(specs, data)
        end
    end
    return specs
end

-- Get specs unlocked by a specific episode
function ResearchSpecsData.getByEpisode(episodeId)
    for id, data in pairs(ResearchSpecsData) do
        if type(data) == "table" and data.episodeSource == episodeId then
            return data
        end
    end
    return nil
end

return ResearchSpecsData
