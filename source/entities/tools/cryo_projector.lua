-- Cryo Projector Tool
-- Slows enemies with cold damage

class('CryoProjector').extends(Tool)

CryoProjector.DATA = {
    id = "cryo_projector",
    name = "Cryo Projector",
    description = "Slows enemies. Dmg: 1",
    imagePath = "images/tools/tool_cryo_projector",
    iconPath = "images/tools/tool_cryo_projector",
    projectileImage = "images/tools/tool_cryo_particle",

    baseDamage = 1,
    fireRate = 0.7,
    projectileSpeed = 7,
    pattern = "spread",
    damageType = "cold",

    pairsWithBonus = "compressor_unit",
    upgradedName = "Absolute Zero",
    upgradedImagePath = "images/tools/tool_absolute_zero",
    upgradedDamage = 3,
}

function CryoProjector:init()
    CryoProjector.super.init(self, CryoProjector.DATA)
    self.spreadCount = 3
    self.spreadAngle = 15
    self.slowDurationBonus = 0
end

function CryoProjector:fire()
    local firingAngle = self.station:getSlotFiringAngle(self.slotIndex)
    local offsetDist = 12
    local dx, dy = Utils.angleToVector(firingAngle)
    local fireX = self.x + dx * offsetDist
    local fireY = self.y + dy * offsetDist

    -- Fire spread pattern
    local startAngle = firingAngle - self.spreadAngle
    local angleStep = self.spreadAngle * 2 / (self.spreadCount - 1)

    for i = 1, self.spreadCount do
        local angle = startAngle + (i - 1) * angleStep
        self:createProjectile(fireX, fireY, angle)
    end
end

function CryoProjector:upgrade(bonusItem)
    local success = CryoProjector.super.upgrade(self, bonusItem)
    if success then
        self.spreadCount = 5
        self.spreadAngle = 20
    end
    return success
end
