-- DrinkSystem GTA 5 RP Style
-- LocalScript в Tool

local tool = script.Parent
local drinkAnimationObject = tool:WaitForChild("DrinkAnimation")
local drinkSound = tool:WaitForChild("DrinkSound")
local replicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = replicatedStorage:WaitForChild("UniqueMeadDrinkingEventSystem")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local players = game:GetService("Players")

local player = players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isUsing = false
local isEquipped = false
local TARGET_DURATION = 7.0

-- ========================================
-- CONFIG
-- ========================================
local CONFIG = {
	-- Timer colors (GTA 5 RP style - yellow)
	TIMER_COLOR = Color3.fromRGB(255, 200, 50),
	TIMER_BG_COLOR = Color3.fromRGB(20, 20, 25),
	TIMER_BORDER_COLOR = Color3.fromRGB(80, 70, 40),

	-- Green glass effect
	GLASS_COLOR = Color3.fromRGB(80, 200, 100),
	GLASS_DURATION = 1.0,

	-- Animation
	FADE_TIME = 0.3
}

-- ========================================
-- UI CREATION
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DrinkHUD_GTA5"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- Green Glass Effect (ColorCorrection overlay)
local glassFrame = Instance.new("Frame")
glassFrame.Name = "GlassEffect"
glassFrame.Size = UDim2.new(1, 0, 1, 0)
glassFrame.Position = UDim2.new(0, 0, 0, 0)
glassFrame.BackgroundColor3 = CONFIG.GLASS_COLOR
glassFrame.BackgroundTransparency = 1
glassFrame.BorderSizePixel = 0
glassFrame.ZIndex = 50
glassFrame.Parent = screenGui

-- Timer Container (GTA 5 RP style - bottom center)
local timerContainer = Instance.new("Frame")
timerContainer.Name = "TimerContainer"
timerContainer.Size = UDim2.new(0, 200, 0, 50)
timerContainer.Position = UDim2.new(0.5, -100, 0.85, 0)
timerContainer.BackgroundColor3 = CONFIG.TIMER_BG_COLOR
timerContainer.BackgroundTransparency = 0.3
timerContainer.BorderSizePixel = 0
timerContainer.Visible = false
timerContainer.Parent = screenGui

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 4)
timerCorner.Parent = timerContainer

local timerStroke = Instance.new("UIStroke")
timerStroke.Color = CONFIG.TIMER_BORDER_COLOR
timerStroke.Thickness = 1
timerStroke.Parent = timerContainer

-- Action label
local actionLabel = Instance.new("TextLabel")
actionLabel.Name = "ActionLabel"
actionLabel.Size = UDim2.new(1, 0, 0, 18)
actionLabel.Position = UDim2.new(0, 0, 0, 5)
actionLabel.BackgroundTransparency = 1
actionLabel.Text = "DRINKING..."
actionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
actionLabel.TextSize = 11
actionLabel.Font = Enum.Font.GothamBold
actionLabel.Parent = timerContainer

-- Timer text (yellow, GTA style)
local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Size = UDim2.new(1, 0, 0, 22)
timerText.Position = UDim2.new(0, 0, 0, 22)
timerText.BackgroundTransparency = 1
timerText.Text = "7.0"
timerText.TextColor3 = CONFIG.TIMER_COLOR
timerText.TextSize = 20
timerText.Font = Enum.Font.GothamBold
timerText.Parent = timerContainer

-- Progress bar background
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.Size = UDim2.new(0.9, 0, 0, 4)
progressBg.Position = UDim2.new(0.05, 0, 1, -8)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
progressBg.BorderSizePixel = 0
progressBg.Parent = timerContainer

local progressBgCorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(0, 2)
progressBgCorner.Parent = progressBg

-- Progress bar fill (yellow)
local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(1, 0, 1, 0)
progressFill.BackgroundColor3 = CONFIG.TIMER_COLOR
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, 2)
progressFillCorner.Parent = progressFill

-- ========================================
-- FUNCTIONS
-- ========================================
local function tweenProperty(instance, properties, duration)
	local tween = tweenService:Create(
		instance,
		TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		properties
	)
	tween:Play()
	return tween
end

local function showTimer()
	timerContainer.Visible = true
	timerContainer.BackgroundTransparency = 1
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	tweenProperty(timerContainer, {BackgroundTransparency = 0.3}, CONFIG.FADE_TIME)
end

local function hideTimer()
	local tween = tweenProperty(timerContainer, {BackgroundTransparency = 1}, CONFIG.FADE_TIME)
	tween.Completed:Connect(function()
		timerContainer.Visible = false
	end)
end

local function updateTimer(remaining, total)
	local percent = remaining / total
	timerText.Text = string.format("%.1f", remaining)
	progressFill.Size = UDim2.new(percent, 0, 1, 0)

	-- Change color when low time
	if percent < 0.2 then
		timerText.TextColor3 = Color3.fromRGB(100, 255, 100)
		progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	else
		timerText.TextColor3 = CONFIG.TIMER_COLOR
		progressFill.BackgroundColor3 = CONFIG.TIMER_COLOR
	end
end

local function playGlassEffect()
	-- Flash green glass overlay
	glassFrame.BackgroundTransparency = 0.7

	-- Fade in
	tweenProperty(glassFrame, {BackgroundTransparency = 0.5}, 0.2)

	-- Hold then fade out
	task.delay(CONFIG.GLASS_DURATION - 0.3, function()
		tweenProperty(glassFrame, {BackgroundTransparency = 1}, 0.3)
	end)
end

-- ========================================
-- TOOL EVENTS
-- ========================================
tool.Equipped:Connect(function()
	isEquipped = true
end)

tool.Unequipped:Connect(function()
	isEquipped = false
end)

-- ========================================
-- INPUT HANDLING
-- ========================================
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not isEquipped or isUsing then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local character = tool.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

		if humanoid and humanoid.Health > 0 and animator then
			isUsing = true 

			-- Load and adjust animation speed
			local drinkTrack = animator:LoadAnimation(drinkAnimationObject)
			drinkTrack:Play()

			if drinkTrack.Length > 0 then
				local speedMultiplier = drinkTrack.Length / TARGET_DURATION
				drinkTrack:AdjustSpeed(speedMultiplier)
			end

			drinkSound:Play()

			-- Show timer
			showTimer()

			-- Timer countdown
			local startTime = tick()
			local timerConnection
			timerConnection = game:GetService("RunService").RenderStepped:Connect(function()
				local elapsed = tick() - startTime
				local remaining = TARGET_DURATION - elapsed

				if remaining <= 0 then
					timerConnection:Disconnect()
					return
				end

				updateTimer(remaining, TARGET_DURATION)
			end)

			-- Wait for animation to finish
			task.wait(TARGET_DURATION)

			-- Hide timer
			hideTimer()

			-- Play green glass effect
			playGlassEffect()

			-- Wait for glass effect
			task.wait(CONFIG.GLASS_DURATION)

			-- Fire server event
			remoteEvent:FireServer()

			-- Cleanup
			if screenGui then
				screenGui:Destroy()
			end

			-- Destroy tool
			tool:Destroy()
		end
	end
end)

print("[DrinkSystem GTA5 RP] Loaded - Click to drink")
