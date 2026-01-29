-- Episodes Data
-- Story content and configuration for each episode

EpisodesData = {
    [1] = {
        id = 1,
        title = "Spin Cycle",
        tagline = "They just want to be friends. Aggressively.",
        startingMessage = "WELCOME COMMITTEE INBOUND",
        backgroundPath = "images/episodes/ep1/bg_ep1",

        -- Intro panels (shown before gameplay)
        introPanels = {
            {
                imagePath = "images/episodes/ep1/ep1_intro_1",
                text = "Mission: Collect samples from an uplift project that got out of hand. Spiders. Very smart spiders. Nothing ever goes wrong with spiders."
            },
            {
                imagePath = "images/episodes/ep1/ep1_intro_2",
                text = "Update: The spiders have spotted us. They're very excited. They're sending gifts. The gifts are approaching at ramming speed."
            },
            {
                imagePath = "images/episodes/ep1/ep1_intro_3",
                text = "Revised mission: Collect samples. Survive the welcome party. Do NOT insult their poetry. Apparently the last research team did that."
            },
        },

        -- Ending panels (shown after boss defeat)
        endingPanels = {
            {
                imagePath = "images/episodes/ep1/ep1_ending_1",
                text = "Sample collection complete. We've catalogued 847 cultural artifacts, including one epic poem about a fly. It's 11,000 verses long."
            },
            {
                imagePath = "images/episodes/ep1/ep1_ending_2",
                text = "A spider named Maserati has stowed away in the sample bay. She claims diplomatic immunity. She's also reorganized our filing system."
            },
            {
                imagePath = "images/episodes/ep1/ep1_ending_3",
                text = "Research Spec unlocked: Their silk has remarkable tensile properties. Maserati is very smug about this."
            },
        },

        -- Research spec unlocked by completing this episode
        researchSpecUnlock = "silk_weave_plating",

        -- Unlock condition
        unlockCondition = "start",  -- Available from start
    },

    [2] = {
        id = 2,
        title = "Productivity Review",
        tagline = "Your feedback is important to us.",
        startingMessage = "QUARTERLY TARGETS: MANDATORY",
        backgroundPath = "images/episodes/ep2/bg_ep2",

        introPanels = {
            {
                imagePath = "images/episodes/ep2/ep2_intro_1",
                text = "Mission: Survey a derelict corporate station. The AI is still running. It has opinions about our efficiency metrics."
            },
            {
                imagePath = "images/episodes/ep2/ep2_intro_2",
                text = "The station's performance management system has flagged us as 'underperforming assets.' It's sending motivational feedback. At high velocity."
            },
            {
                imagePath = "images/episodes/ep2/ep2_intro_3",
                text = "Revised mission: Survive the quarterly review. All feedback will be noted in our permanent record."
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep2/ep2_ending_1",
                text = "Performance review complete. We've been rated 'exceeds expectations' after vigorous negotiation."
            },
            {
                imagePath = "images/episodes/ep2/ep2_ending_2",
                text = "The corporate AI has agreed to a consulting arrangement. It has many suggestions for optimizing our operations."
            },
            {
                imagePath = "images/episodes/ep2/ep2_ending_3",
                text = "Research Spec unlocked: Their efficiency algorithms are ruthless but effective. Productivity up 500%."
            },
        },

        researchSpecUnlock = "efficiency_protocols",
        unlockCondition = "episode_1",
    },

    [3] = {
        id = 3,
        title = "Whose Idea Was This?",
        tagline = "Reality is more of a suggestion.",
        startingMessage = "PROBABILITY: OPTIONAL",
        backgroundPath = "images/episodes/ep3/bg_ep3",

        introPanels = {
            {
                imagePath = "images/episodes/ep3/ep3_intro_1",
                text = "Mission: Investigate an anomalous region where the laws of physics have become 'optional.' Someone divided by zero. We're here to yell at them."
            },
            {
                imagePath = "images/episodes/ep3/ep3_intro_2",
                text = "Update: Local probability is not functioning correctly. Our sensors keep detecting things that shouldn't exist. They're very insistent about existing anyway."
            },
            {
                imagePath = "images/episodes/ep3/ep3_intro_3",
                text = "Revised mission: Navigate the impossible. Don't think too hard about the physics. The physics don't appreciate scrutiny."
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep3/ep3_ending_1",
                text = "Probability field stabilized. We've convinced local reality to follow the rules again. It's sulking but compliant."
            },
            {
                imagePath = "images/episodes/ep3/ep3_ending_2",
                text = "We've recovered the original experiment logs. Turns out someone tried to calculate the exact position AND momentum of a burrito. Ambitious but inadvisable."
            },
            {
                imagePath = "images/episodes/ep3/ep3_ending_3",
                text = "Research Spec unlocked: We've learned to harness probability fluctuations. Things might happen. Or might not. It's complicated."
            },
        },

        researchSpecUnlock = "probability_shield",
        unlockCondition = "episode_2",
    },

    [4] = {
        id = 4,
        title = "Garbage Day",
        tagline = "One civilization's apocalypse is another's opportunity.",
        startingMessage = "SALVAGE RIGHTS: CONTESTED",
        backgroundPath = "images/episodes/ep4/bg_ep4",

        introPanels = {
            {
                imagePath = "images/episodes/ep4/ep4_intro_1",
                text = "Salvage mission. This debris field dates back to a war nobody remembers. One civilization's apocalypse is another's research opportunity."
            },
            {
                imagePath = "images/episodes/ep4/ep4_intro_2",
                text = "Scans show valuable materials, active defense systems, and one extremely large life sign. The life sign is circling us. Casually."
            },
            {
                imagePath = "images/episodes/ep4/ep4_intro_3",
                text = "Objective: Collect salvage. Avoid the turrets. Make friends with whatever that thing is. It looks lonely. Also hungry."
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep4/ep4_ending_1",
                text = "Salvage complete. We've recovered alloys that predate most known civilizations. Also, we've made a friend."
            },
            {
                imagePath = "images/episodes/ep4/ep4_ending_2",
                text = "The creature followed us to the edge of the debris field, then stopped. It made a sound. Acoustics says it might have been 'goodbye.' Or 'indigestion.'"
            },
            {
                imagePath = "images/episodes/ep4/ep4_ending_3",
                text = "Research Spec unlocked: The ancient alloys have remarkable properties. We've named them 'Chompite' in honor of our new friend."
            },
        },

        researchSpecUnlock = "ancient_alloys",
        unlockCondition = "episode_3",
    },

    [5] = {
        id = 5,
        title = "Academic Standards",
        tagline = "Peer review can be brutal. Literally.",
        startingMessage = "ATTENDANCE: MANDATORY",
        backgroundPath = "images/episodes/ep5/bg_ep5",

        introPanels = {
            {
                imagePath = "images/episodes/ep5/ep5_intro_1",
                text = "Welcome to the Interspecies Research Symposium. Today's sessions include 'Is Time Real?' and 'Tentacles: A Reappraisal.' Attendance is mandatory."
            },
            {
                imagePath = "images/episodes/ep5/ep5_intro_2",
                text = "Reminder: What looks like aggression may be enthusiastic agreement. What looks like agreement may be a prelude to aggression. Read the room."
            },
            {
                imagePath = "images/episodes/ep5/ep5_intro_3",
                text = "Your job: Collect proceedings. Facilitate exchange. Avoid the Vorthian delegation - they debate with their ships."
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep5/ep5_ending_1",
                text = "Conference concluded. Fourteen collaborative papers drafted. Only three diplomatic incidents. The organizing committee is calling this 'a qualified success.'"
            },
            {
                imagePath = "images/episodes/ep5/ep5_ending_2",
                text = "The Distinguished Professor has revised their opinion of our research from 'derivative' to 'merely obvious.' We're choosing to see this as progress."
            },
            {
                imagePath = "images/episodes/ep5/ep5_ending_3",
                text = "Research Spec unlocked: Cross-species collaboration yields unexpected insights. Also unexpected bruises."
            },
        },

        researchSpecUnlock = "peer_review",
        unlockCondition = "episode_4",
    },
}

-- Get episode data by ID
function EpisodesData.get(episodeId)
    return EpisodesData[episodeId]
end

-- Get list of unlocked episodes
function EpisodesData.getUnlocked()
    local unlocked = {}
    for id, data in ipairs(EpisodesData) do
        -- Check if episode is unlocked via SaveManager
        if SaveManager and SaveManager:isEpisodeUnlocked(id) then
            table.insert(unlocked, data)
        elseif data.unlockCondition == "start" then
            -- Episode 1 is always unlocked
            table.insert(unlocked, data)
        end
    end
    return unlocked
end

return EpisodesData
