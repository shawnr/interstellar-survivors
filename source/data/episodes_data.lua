-- Episodes Data
-- Story content and configuration for each episode
-- Text is broken into individual lines as specified in design doc

EpisodesData = {
    [1] = {
        id = 1,
        title = "Spin Cycle",
        tagline = "They just want to be friends. Aggressively.",
        startingMessage = "WELCOME COMMITTEE INBOUND",
        backgroundPath = "images/episodes/ep1/bg_ep1",

        -- Intro panels (shown before gameplay)
        -- Each panel has an image and an array of lines shown one at a time
        introPanels = {
            {
                imagePath = "images/episodes/ep1/ep1_intro_1",
                lines = {
                    "Mission: Collect samples from an uplift project that got out of hand.",
                    "Spiders. Very smart spiders.",
                    "Nothing ever goes wrong with spiders.",
                }
            },
            {
                imagePath = "images/episodes/ep1/ep1_intro_2",
                lines = {
                    "Update: The spiders have spotted us.",
                    "They're very excited. They're sending gifts.",
                    "The gifts are approaching at ramming speed.",
                }
            },
            {
                imagePath = "images/episodes/ep1/ep1_intro_3",
                lines = {
                    "Revised mission: Collect samples, survive welcome party.",
                    "Do NOT insult their poetry.",
                    "Apparently the last research team did that.",
                }
            },
        },

        -- Ending panels (shown after boss defeat)
        endingPanels = {
            {
                imagePath = "images/episodes/ep1/ep1_ending_1",
                lines = {
                    "Sample collection complete: 847 artifacts cataloged...",
                    "...including one epic poem about a fly.",
                    "It's 11,000 verses long.",
                }
            },
            {
                imagePath = "images/episodes/ep1/ep1_ending_2",
                lines = {
                    "A spider named Maserati has stowed away in the sample bay.",
                    "She claims diplomatic immunity.",
                    "She's also reorganized our filing system.",
                }
            },
            {
                imagePath = "images/episodes/ep1/ep1_ending_3",
                lines = {
                    "Research Spec unlocked:",
                    "Their silk has remarkable tensile properties.",
                    "Maserati is very smug about this.",
                }
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
                lines = {
                    "Standard mineral survey. Corporate has assigned consultants...",
                    "...to ensure we meet quarterly research targets.",
                    "This is fine.",
                }
            },
            {
                imagePath = "images/episodes/ep2/ep2_intro_2",
                lines = {
                    "The consultants have arrived.",
                    "They have questions about our 'process' and our 'workflow.'",
                    "They have exploded near the hull.",
                }
            },
            {
                imagePath = "images/episodes/ep2/ep2_intro_3",
                lines = {
                    "New priority: Collect ore samples. Ignore the helpers.",
                    "If a drone asks you to rate your experience...",
                    "...just keep shooting.",
                }
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep2/ep2_ending_1",
                lines = {
                    "Survey complete. Mineral yield: Excellent.",
                    "Consultant survival rate: Unknown.",
                    "We're not tracking that metric.",
                }
            },
            {
                imagePath = "images/episodes/ep2/ep2_ending_2",
                lines = {
                    "Corporate has sent a follow-up survey about the follow-up survey.",
                    "We have filed it appropriately.",
                    "The file is labeled 'dumb'.",
                }
            },
            {
                imagePath = "images/episodes/ep2/ep2_ending_3",
                lines = {
                    "Research Spec unlocked: The drones' targeting software...",
                    "...was actually pretty good. We've repurposed it.",
                    "Don't tell corporate.",
                }
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
                lines = {
                    "The Improbability Drive test was supposed to be contained.",
                    "It was not contained.",
                    "Reality is now 'optional' in this sector.",
                }
            },
            {
                imagePath = "images/episodes/ep3/ep3_intro_2",
                lines = {
                    "Current status: Things are becoming other things.",
                    "Some of those things are hostile.",
                    "One of them is a whale. The whale seems fine.",
                }
            },
            {
                imagePath = "images/episodes/ep3/ep3_intro_3",
                lines = {
                    "Objective: Collect probability particles for study.",
                    "Try not to become something else yourself.",
                    "If you do, please file Form 42-B.",
                }
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep3/ep3_ending_1",
                lines = {
                    "Particles collected. Reality is stabilizing.",
                    "Most things are back to being themselves.",
                    "The sofa remains unexplained.",
                }
            },
            {
                imagePath = "images/episodes/ep3/ep3_ending_2",
                lines = {
                    "Final inventory includes 47 impossible objects...",
                    "...and one cup of tea that appeared exactly when someone needed it.",
                    "Coincidence rate: Improbable.",
                }
            },
            {
                imagePath = "images/episodes/ep3/ep3_ending_3",
                lines = {
                    "Research Spec unlocked: We've learned to predict small impossibilities.",
                    "This should not be possible.",
                    "That's rather the point.",
                }
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
                lines = {
                    "Salvage mission. This debris field dates back...",
                    "...to a war nobody remembers. One civilization's apocalypse...",
                    "...is another's research opportunity.",
                }
            },
            {
                imagePath = "images/episodes/ep4/ep4_intro_2",
                lines = {
                    "Scans show valuable materials, active defense systems,",
                    "...and one (1) extremely large life sign.",
                    "The life sign is circling us. Casually.",
                }
            },
            {
                imagePath = "images/episodes/ep4/ep4_intro_3",
                lines = {
                    "Objective: Collect salvage. Avoid the turrets.",
                    "Make friends with whatever that thing is. It looks lonely.",
                    "Also hungry. But mostly lonely.",
                }
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep4/ep4_ending_1",
                lines = {
                    "Salvage complete. We've recovered alloys...",
                    "...that predate most known civilizations.",
                    "Also, we've made a friend.",
                }
            },
            {
                imagePath = "images/episodes/ep4/ep4_ending_2",
                lines = {
                    "The creature followed us to the edge of the debris field,",
                    "...then stopped. It made a sound. Acoustics says it might...",
                    "...have been 'goodbye.' Or 'indigestion.'",
                }
            },
            {
                imagePath = "images/episodes/ep4/ep4_ending_3",
                lines = {
                    "Research Spec unlocked: The ancient alloys...",
                    "...have remarkable properties.",
                    "We've named them 'Chompite' in honor of our new friend.",
                }
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
                lines = {
                    "Welcome to the Interspecies Research Symposium.",
                    "Today's sessions include 'Is Time Real?' and 'Tentacles: A Reappraisal.'",
                    "Attendance is mandatory.",
                }
            },
            {
                imagePath = "images/episodes/ep5/ep5_intro_2",
                lines = {
                    "Reminder: What looks like aggression may be enthusiastic agreement.",
                    "What looks like agreement may be a prelude to aggression.",
                    "Read the room.",
                }
            },
            {
                imagePath = "images/episodes/ep5/ep5_intro_3",
                lines = {
                    "Your job: Collect proceedings.",
                    "Facilitate exchange.",
                    "Avoid the Vorthian delegation - they debate with their ships.",
                }
            },
        },

        endingPanels = {
            {
                imagePath = "images/episodes/ep5/ep5_ending_1",
                lines = {
                    "Conference concluded. Fourteen collaborative papers drafted.",
                    "Only three diplomatic incidents. The organizing committee...",
                    "...is calling this 'a qualified success.'",
                }
            },
            {
                imagePath = "images/episodes/ep5/ep5_ending_2",
                lines = {
                    "The Distinguished Professor has revised their...",
                    "...opinion of our research from 'derivative' to 'merely obvious.'",
                    "We're choosing to see this as progress.",
                }
            },
            {
                imagePath = "images/episodes/ep5/ep5_ending_3",
                lines = {
                    "Research Spec unlocked: Cross-species collaboration...",
                    "...yields unexpected insights.",
                    "Also unexpected bruises.",
                }
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
