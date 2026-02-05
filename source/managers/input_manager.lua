-- Input Manager
-- Handles crank input with smoothing and button state tracking

InputManager = {
    -- Crank state
    crankPosition = 0,          -- Current crank position (0-360)
    crankDelta = 0,             -- Change since last frame
    crankAccelerated = 0,       -- Accelerated change
    smoothedCrankDelta = 0,     -- Smoothed delta for game use

    -- Target and current rotation (for smoothing)
    targetRotation = 0,
    currentRotation = 0,

    -- Button states (current frame)
    buttonPressed = {
        up = false,
        down = false,
        left = false,
        right = false,
        a = false,
        b = false
    },

    -- Button just pressed (edge detection)
    buttonJustPressed = {
        up = false,
        down = false,
        left = false,
        right = false,
        a = false,
        b = false
    },

    -- Button just released (edge detection)
    buttonJustReleased = {
        up = false,
        down = false,
        left = false,
        right = false,
        a = false,
        b = false
    },

    -- Previous frame button states (for edge detection)
    previousButtonState = {
        up = false,
        down = false,
        left = false,
        right = false,
        a = false,
        b = false
    },

    -- Crank docked state
    crankDocked = false,
}

function InputManager:init()
    -- Initialize crank position
    self.crankPosition = playdate.getCrankPosition() or 0
    self.crankDocked = playdate.isCrankDocked()
end

function InputManager:update()
    -- Update crank position
    self.crankPosition = playdate.getCrankPosition() or 0
    self.crankDocked = playdate.isCrankDocked()

    -- Get crank change this frame
    local change, accelerated = playdate.getCrankChange()
    self.crankDelta = change or 0
    self.crankAccelerated = accelerated or 0

    -- Apply dead zone
    if math.abs(self.crankDelta) < Constants.CRANK_DEAD_ZONE then
        self.crankDelta = 0
    end

    -- Calculate smoothed rotation
    -- Apply rotation ratio (360 crank = 180 station)
    self.targetRotation = self.targetRotation + (self.crankDelta * Constants.ROTATION_RATIO)

    -- D-pad rotation (for gameplay only, checked by GameManager state)
    -- Up/Right = clockwise, Down/Left = counter-clockwise
    local dpadRotationSpeed = 4.0  -- Degrees per frame
    if GameManager and GameManager.currentState == GameManager.states.GAMEPLAY then
        if playdate.buttonIsPressed(playdate.kButtonRight) or playdate.buttonIsPressed(playdate.kButtonUp) then
            self.targetRotation = self.targetRotation + dpadRotationSpeed
        end
        if playdate.buttonIsPressed(playdate.kButtonLeft) or playdate.buttonIsPressed(playdate.kButtonDown) then
            self.targetRotation = self.targetRotation - dpadRotationSpeed
        end
    end

    -- Smooth interpolation
    self.currentRotation = Utils.lerp(
        self.currentRotation,
        self.targetRotation,
        Constants.ROTATION_SMOOTHING
    )

    -- Calculate smoothed delta for this frame
    self.smoothedCrankDelta = self.crankDelta * Constants.ROTATION_RATIO * Constants.ROTATION_SMOOTHING

    -- Update button states using polling
    local currentButtonState = {
        up = playdate.buttonIsPressed(playdate.kButtonUp),
        down = playdate.buttonIsPressed(playdate.kButtonDown),
        left = playdate.buttonIsPressed(playdate.kButtonLeft),
        right = playdate.buttonIsPressed(playdate.kButtonRight),
        a = playdate.buttonIsPressed(playdate.kButtonA),
        b = playdate.buttonIsPressed(playdate.kButtonB)
    }

    -- Detect edge transitions
    for button, pressed in pairs(currentButtonState) do
        self.buttonPressed[button] = pressed
        self.buttonJustPressed[button] = pressed and not self.previousButtonState[button]
        self.buttonJustReleased[button] = not pressed and self.previousButtonState[button]
        self.previousButtonState[button] = pressed
    end
end

-- Called from main.lua cranked callback
function InputManager:onCrank(change, acceleratedChange)
    -- Additional processing if needed
    -- Most crank handling is done in update() via polling
end

-- Called from main.lua button callbacks
function InputManager:onButtonDown(button)
    -- Callback-based input (backup to polling)
    -- Polling in update() is generally preferred for consistency
end

-- Get the current smoothed rotation value
function InputManager:getRotation()
    return self.currentRotation
end

-- Get the crank delta (for direct use)
function InputManager:getCrankDelta()
    return self.crankDelta
end

-- Get smoothed crank delta (rotation-ratio applied)
function InputManager:getSmoothedDelta()
    return self.smoothedCrankDelta
end

-- Reset rotation to a specific angle
function InputManager:resetRotation(angle)
    angle = angle or 0
    self.targetRotation = angle
    self.currentRotation = angle
end

-- Check if a button was just pressed this frame
function InputManager:justPressed(button)
    return self.buttonJustPressed[button] or false
end

-- Check if a button is currently held
function InputManager:isPressed(button)
    return self.buttonPressed[button] or false
end

-- Check if a button was just released this frame
function InputManager:justReleased(button)
    return self.buttonJustReleased[button] or false
end

-- Check if crank is docked
function InputManager:isCrankDocked()
    return self.crankDocked
end

return InputManager
