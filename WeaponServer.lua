local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local shootEvent = ReplicatedStorage:WaitForChild("ShootEvent")

local SHOOT_SOUND_ID = "rbxassetid://87706916370116" 
local HIT_SOUND_ID = "rbxassetid://113887541954920" 
local WEAPON_DAMAGE = 2 

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function createTracerBeam(startPos, endPos)
	local holder = Instance.new("Part")
	holder.Name = "StaticTracer"
	holder.Size = Vector3.new(0.05, 0.05, 0.05)
	holder.Transparency = 1
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.Anchored = true
	holder.Position = startPos
	holder.Parent = workspace

	local att0 = Instance.new("Attachment", holder)
	local att1 = Instance.new("Attachment", holder)
	att1.WorldPosition = endPos

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = 0.06
	beam.Width1 = 0.06
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 235, 160)) 
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Parent = holder

	TweenService:Create(beam, TweenInfo.new(0.08), {Width0 = 0, Width1 = 0}):Play()
	Debris:AddItem(holder, 0.08)
end

shootEvent.OnServerEvent:Connect(function(player, barrelPos, cameraOrigin, cameraDirection)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local tool = character and character:FindFirstChildOfClass("Tool")

	if character and character:GetAttribute("IsKnockedOut") then return end

	if head then
		local gunSound = head:FindFirstChild("WeaponShootSound")
		if not gunSound then
			gunSound = Instance.new("Sound")
			gunSound.Name = "WeaponShootSound"
			gunSound.SoundId = SHOOT_SOUND_ID
			gunSound.Volume = 1.4
			gunSound.RollOffMaxDistance = 80 
			gunSound.Parent = head
		end
		gunSound:Play()
	end

	if barrelPos and cameraOrigin and cameraDirection and character and tool then
		raycastParams.FilterDescendantsInstances = {character, tool}

		local serverRaycastResult = workspace:Raycast(cameraOrigin, cameraDirection * 300, raycastParams)
		local hitPosition = serverRaycastResult and serverRaycastResult.Position or (cameraOrigin + cameraDirection * 300)

		if serverRaycastResult and serverRaycastResult.Instance then
			local hitTarget = serverRaycastResult.Instance.Parent
			local targetHumanoid = hitTarget:FindFirstChildOfClass("Humanoid")
			if not targetHumanoid and hitTarget.Parent then
				targetHumanoid = hitTarget.Parent:FindFirstChildOfClass("Humanoid")
			end

			if targetHumanoid and targetHumanoid.Health > 0 then
				targetHumanoid:TakeDamage(WEAPON_DAMAGE)

				local playerGui = player:FindFirstChild("PlayerGui")
				if playerGui then
					local hitSound = playerGui:FindFirstChild("HitmarkerSound")
					if not hitSound then
						hitSound = Instance.new("Sound")
						hitSound.Name = "HitmarkerSound"
						hitSound.SoundId = HIT_SOUND_ID
						hitSound.Volume = 1.2
						hitSound.Parent = playerGui
					end
					hitSound:Play()
				end
			end
		end

		createTracerBeam(barrelPos, hitPosition)
	end
end)
