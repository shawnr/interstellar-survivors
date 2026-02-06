-- Survey Drone MOB (Episode 2)
-- Corporate drone that surveys your productivity

class('SurveyDrone').extends(MOB)

SurveyDrone.DATA = {
    id = "survey_drone",
    name = "Survey Drone",
    description = "Collecting performance metrics",
    imagePath = "images/episodes/ep2/ep2_survey_drone",
    animPath = "images/episodes/ep2/ep2_survey_drone",  -- Animation table
    frameDuration = 0.15,  -- 150ms per frame

    -- Stats
    baseHealth = 6,
    baseSpeed = 1.0,
    baseDamage = 4,
    rpValue = 10,

    -- Collision
    width = 14,
    height = 14,
    range = 1,
    emits = false,
    skipRotation = true,  -- Performance: no rotation updates
}

function SurveyDrone:init(x, y, waveMultipliers)
    SurveyDrone.super.init(self, x, y, SurveyDrone.DATA, waveMultipliers)
end

function SurveyDrone:update(dt)
    SurveyDrone.super.update(self, dt)

    -- Check for station collision
    if self:hasReachedStation() then
        self:onHitStation()
    end
end

function SurveyDrone:onHitStation()
    if GameplayScene and GameplayScene.station then
        GameplayScene.station:takeDamage(self.damage)
    end
    self:onDestroyed()
end
