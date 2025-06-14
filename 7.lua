local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local bot = Players.LocalPlayer
local controllerUserId = 7089838125
local verticalOffset = 20
local followInterval = 0.5

local controller = nil
local followConnection = nil
local spinConnection = nil
local isFlinging = false
local lockedY = nil

-- Get HumanoidRootPart
local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

-- Tween bot to X/Z of target, keeping Y locked
local function tweenToXZ(pos)
	local root = getRoot(bot)
	local targetPos = Vector3.new(pos.X, lockedY or root.Position.Y, pos.Z)
	local tween = TweenService:Create(root, TweenInfo.new(followInterval), {CFrame = CFrame.new(targetPos)})
	tween:Play()
end

-- Loop-follow X/Z of controller (not Y)
local function startFollowLoop()
	if followConnection then return end
	followConnection = RunService.Heartbeat:Connect(function()
		if not isFlinging and controller and controller.Character then
			local ctrlRoot = getRoot(controller)
			tweenToXZ(ctrlRoot.Position)
		end
	end)
end

-- Stop following
local function stopFollowLoop()
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
end

-- Fling (crazy spin)
local function startFling()
	local root = getRoot(bot)
	spinConnection = RunService.RenderStepped:Connect(function()
		root.CFrame = root.CFrame * CFrame.Angles(math.rad(30), math.rad(30), math.rad(30))
	end)
end

-- Stop flinging
local function stopFling()
	if spinConnection then
		spinConnection:Disconnect()
	end
	spinConnection = nil
	isFlinging = false
	startFollowLoop()
end

-- Handle .f TargetName command
local function handleFCommand(targetName)
	local target = Players:FindFirstChild(targetName)
	if not target or target == bot then return end

	isFlinging = true
	stopFollowLoop()

	local targetRoot = getRoot(target)
	tweenToXZ(targetRoot.Position)
	startFling()

	local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Wait()
	end

	stopFling()

	-- Return to locked position under controller
	if controller and controller.Character then
		local ctrlRoot = getRoot(controller)
		tweenToXZ(ctrlRoot.Position)
	end
end

-- Setup .f command listener
local function listenToController()
	controller.Chatted:Connect(function(msg)
		local toMe = msg:find(bot.Name)
		local target = msg:match("^%.f%s+(%w+)$")
		if toMe and target then
			handleFCommand(target)
		end
	end)
end

-- Called when controller is found
local function setupController(player)
	controller = player

	-- Wait for controller's character
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	local ctrlRoot = getRoot(player)

	-- Drop below once, and lock that Y
	local botRoot = getRoot(bot)
	local finalPos = ctrlRoot.Position - Vector3.new(0, verticalOffset, 0)
	local tween = TweenService:Create(botRoot, TweenInfo.new(1), {CFrame = CFrame.new(finalPos)})
	tween:Play()
	tween.Completed:Wait()

	-- ✅ COMBO: Freeze bot physics
	local botHumanoid = bot.Character and bot.Character:FindFirstChildOfClass("Humanoid")
	if botHumanoid then
		botHumanoid.PlatformStand = true
	end
	botRoot.Anchored = true

	-- Lock Y from now on
	lockedY = finalPos.Y
	startFollowLoop()
	listenToController()
end

-- Watch for controller
for _, p in ipairs(Players:GetPlayers()) do
	if p.UserId == controllerUserId then
		setupController(p)
	end
end

Players.PlayerAdded:Connect(function(p)
	if p.UserId == controllerUserId then
		setupController(p)
	end
end)
