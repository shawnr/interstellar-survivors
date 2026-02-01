-- Audio Manager
-- Handles music and sound effects

local snd <const> = playdate.sound

AudioManager = {
    -- Sound effect cache
    sfx = {},

    -- Music players
    currentMusic = nil,
    musicVolume = 0.7,
    sfxVolume = 1.0,

    -- Mute states
    musicMuted = false,
    sfxMuted = false,
}

function AudioManager:init()
    -- Pre-load commonly used sound effects
    self:loadSFX("tool_rail_driver", "sounds/sfx_tool_rail_driver")
    self:loadSFX("tool_frequency_scanner", "sounds/sfx_tool_frequency_scanner")
    self:loadSFX("tool_tractor_pulse", "sounds/sfx_tool_tractor_pulse")
    self:loadSFX("tool_thermal_lance", "sounds/sfx_tool_thermal_lance")
    self:loadSFX("tool_cryo_projector", "sounds/sfx_tool_cryo_projector")
    self:loadSFX("tool_emp_burst", "sounds/sfx_tool_emp_burst")
    self:loadSFX("tool_probe_launcher", "sounds/sfx_tool_probe_launcher")
    self:loadSFX("tool_repulsor_field", "sounds/sfx_tool_repulsor_field")

    self:loadSFX("mob_hit", "sounds/sfx_mob_hit")
    self:loadSFX("mob_destroyed", "sounds/sfx_mob_destroyed")
    self:loadSFX("station_hit", "sounds/sfx_station_hit")
    self:loadSFX("station_destroyed", "sounds/sfx_station_destroyed")
    self:loadSFX("shield_hit", "sounds/sfx_shield_hit")

    self:loadSFX("collectible_get", "sounds/sfx_collectible_get")
    self:loadSFX("collectible_rare", "sounds/sfx_collectible_rare")

    self:loadSFX("level_up", "sounds/sfx_level_up")
    self:loadSFX("wave_start", "sounds/sfx_wave_start")
    self:loadSFX("card_select", "sounds/sfx_card_select")
    self:loadSFX("card_confirm", "sounds/sfx_card_confirm")

    self:loadSFX("boss_warning", "sounds/sfx_boss_warning")
    self:loadSFX("boss_hit", "sounds/sfx_boss_hit")
    self:loadSFX("boss_defeated", "sounds/sfx_boss_defeated")

    self:loadSFX("menu_select", "sounds/sfx_menu_select")
    self:loadSFX("menu_confirm", "sounds/sfx_menu_confirm")
    self:loadSFX("panel_advance", "sounds/sfx_panel_advance")

    -- Load saved volume settings
    if SaveManager then
        self.musicVolume = SaveManager:getSetting("musicVolume", 0.7)
        self.sfxVolume = SaveManager:getSetting("sfxVolume", 1.0)
    end

    print("AudioManager initialized")
end

-- Load a sound effect
function AudioManager:loadSFX(name, path)
    local sample = snd.sampleplayer.new(path)
    if sample then
        self.sfx[name] = sample
    else
        print("WARNING: Failed to load SFX: " .. path)
    end
end

-- Play a sound effect
function AudioManager:playSFX(name, volume)
    if self.sfxMuted then return end

    local sfx = self.sfx[name]
    if sfx then
        -- Multiply the base volume by the global sfxVolume setting
        local baseVolume = volume or 1.0
        local finalVolume = baseVolume * self.sfxVolume
        sfx:setVolume(finalVolume)
        sfx:play()
    end
end

-- Play music
function AudioManager:playMusic(path, loop)
    print("AudioManager:playMusic called with path: " .. path)
    if self.musicMuted then
        print("Music is muted, returning")
        return
    end

    -- Stop current music
    self:stopMusic()

    -- Load and play new music
    print("Loading music file...")
    local player = snd.fileplayer.new(path)
    if player then
        print("Music file loaded successfully")
        player:setVolume(self.musicVolume)
        print("Volume set to: " .. self.musicVolume)
        if loop ~= false then
            player:setLoopRange(0)  -- Loop entire track
        end
        player:play(loop ~= false and 0 or 1)
        self.currentMusic = player
        print("Music playback started")
    else
        print("WARNING: Failed to load music: " .. path)
    end
end

-- Stop current music
function AudioManager:stopMusic()
    if self.currentMusic then
        self.currentMusic:stop()
        self.currentMusic = nil
    end
end

-- Pause music
function AudioManager:pauseMusic()
    if self.currentMusic then
        self.currentMusic:pause()
    end
end

-- Resume music
function AudioManager:resumeMusic()
    if self.currentMusic and not self.musicMuted then
        self.currentMusic:play()
    end
end

-- Set music volume (0-1)
function AudioManager:setMusicVolume(volume)
    self.musicVolume = Utils.clamp(volume, 0, 1)
    if self.currentMusic then
        self.currentMusic:setVolume(self.musicVolume)
    end
end

-- Set SFX volume (0-1)
function AudioManager:setSFXVolume(volume)
    self.sfxVolume = Utils.clamp(volume, 0, 1)
end

-- Toggle music mute
function AudioManager:toggleMusicMute()
    self.musicMuted = not self.musicMuted
    if self.musicMuted then
        self:pauseMusic()
    else
        self:resumeMusic()
    end
end

-- Toggle SFX mute
function AudioManager:toggleSFXMute()
    self.sfxMuted = not self.sfxMuted
end

return AudioManager
