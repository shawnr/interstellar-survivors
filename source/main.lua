-- Interstellar Survivors
-- A Vampire Survivors-style auto-shooter roguelike for Playdate

-- Import Playdate CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

-- Local references for performance
local gfx <const> = playdate.graphics
local timer <const> = playdate.timer

-- Import game modules
import "lib/constants"
import "lib/class"
import "lib/utils"
import "managers/input_manager"
import "managers/game_manager"
import "managers/audio_manager"
import "managers/save_manager"

-- Import data files
import "data/tools_data"
import "data/bonus_items_data"
import "data/episodes_data"
import "data/research_specs_data"
import "data/grant_funding_data"

-- Import systems
import "systems/upgrade_system"
import "systems/research_spec_system"

-- Import UI
import "ui/upgrade_selection"
import "ui/story_panel"
import "ui/episode_select"
import "ui/research_specs_screen"
import "ui/database_screen"
import "ui/grant_funding_screen"
import "ui/tool_select"

-- Import entities
import "entities/entity"
import "entities/station"
import "entities/tool"
import "entities/projectile"
import "entities/mob"
import "entities/collectible"

-- Import all MOBs
-- Episode 1
import "entities/mobs/asteroid"
import "entities/mobs/greeting_drone"
import "entities/mobs/silk_weaver"
-- Episode 2
import "entities/mobs/survey_drone"
import "entities/mobs/efficiency_monitor"
-- Episode 3
import "entities/mobs/probability_fluctuation"
import "entities/mobs/paradox_node"
-- Episode 4
import "entities/mobs/debris_chunk"
import "entities/mobs/defense_turret"
-- Episode 5
import "entities/mobs/debate_drone"
import "entities/mobs/citation_platform"

-- Import bosses
import "entities/bosses/cultural_attache"
import "entities/bosses/productivity_liaison"
import "entities/bosses/improbability_engine"
import "entities/bosses/chomper"
import "entities/bosses/distinguished_professor"

-- Import all tools
import "entities/tools/rail_driver"
import "entities/tools/frequency_scanner"
import "entities/tools/tractor_pulse"
import "entities/tools/thermal_lance"
import "entities/tools/cryo_projector"
import "entities/tools/emp_burst"
import "entities/tools/probe_launcher"
import "entities/tools/repulsor_field"
import "entities/tools/modified_mapping_drone"
import "entities/tools/singularity_core"
import "entities/tools/plasma_sprayer"
import "entities/tools/tesla_coil"
import "entities/tools/micro_missile_pod"
import "entities/tools/phase_disruptor"

-- Import other entities
import "entities/salvage_drone"

-- Import scenes
import "scenes/gameplay_scene"

-- Initialize game on load
local function initialize()
    -- Set refresh rate to 30fps
    playdate.display.setRefreshRate(30)

    -- Initialize managers
    InputManager:init()
    SaveManager:init()
    GameManager:init()
    AudioManager:init()

    -- Initialize systems
    UpgradeSystem:init()
    UpgradeSelection:init()
    StoryPanel:init()
    EpisodeSelect:init()
    ResearchSpecsScreen:init()
    DatabaseScreen:init()
    GrantFundingScreen:init()
    ResearchSpecSystem:init()

    -- Set up Playdate system menu
    local menu = playdate.getSystemMenu()

    menu:addMenuItem("Main Menu", function()
        -- Return to episode select (acts as main menu)
        if GameManager.currentState == GameManager.states.GAMEPLAY then
            GameplayScene:exit()
        end
        GameManager:setState(GameManager.states.EPISODE_SELECT)
    end)

    menu:addMenuItem("Research", function()
        -- Show research specs screen
        GameManager:setState(GameManager.states.RESEARCH_SPECS, { fromState = GameManager.currentState })
    end)

    menu:addMenuItem("Settings", function()
        -- Pass current state so settings can return here
        GameManager:setState(GameManager.states.SETTINGS, { fromState = GameManager.currentState })
    end)

    -- Start at title screen
    GameManager:setState(GameManager.states.TITLE)
end

-- Save game data when app terminates
function playdate.gameWillTerminate()
    SaveManager:flush()
end

-- Save game data when device sleeps
function playdate.deviceWillSleep()
    SaveManager:flush()
end

-- Main update loop (called 30 times per second)
function playdate.update()
    -- Update timers
    timer.updateTimers()

    -- Process input
    InputManager:update()

    -- Update current scene
    if GameManager.currentScene then
        GameManager.currentScene:update()
    end

    -- Draw background BEFORE sprites (if scene has one)
    if GameManager.currentScene and GameManager.currentScene.drawBackground then
        GameManager.currentScene:drawBackground()
    end

    -- Update all sprites (handles drawing automatically)
    gfx.sprite.update()

    -- Draw any additional UI overlays AFTER sprites
    if GameManager.currentScene and GameManager.currentScene.drawOverlay then
        GameManager.currentScene:drawOverlay()
    end
end

-- Crank callback - forward to input manager
function playdate.cranked(change, acceleratedChange)
    InputManager:onCrank(change, acceleratedChange)
end

-- D-pad callbacks
function playdate.upButtonDown()
    InputManager:onButtonDown("up")
end

function playdate.downButtonDown()
    InputManager:onButtonDown("down")
end

function playdate.leftButtonDown()
    InputManager:onButtonDown("left")
end

function playdate.rightButtonDown()
    InputManager:onButtonDown("right")
end

-- A/B button callbacks
function playdate.AButtonDown()
    InputManager:onButtonDown("a")
end

function playdate.BButtonDown()
    InputManager:onButtonDown("b")
end

-- Initialize the game
initialize()
