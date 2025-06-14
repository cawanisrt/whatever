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

-- Get HumanoidRootPart
local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

-- Tween bot to match target position (with offset)
local function tweenToPos(pos)
	local root = getRoot(bot)
	local targetPos = pos - Vector3.new(0, verticalOffset, 0)
	local tween = TweenService:Create(root, TweenInfo.new(followInterval), {CFrame = CFrame.new(targetPos)})
	tween:Play()
end

-- Loop-follow controller
local function startFollowLoop()
	if followConnection then return end
	followConnection = RunService.Heartbeat:Connect(function()
		if not isFlinging and controller and controller.Character then
			local ctrlRoot = getRoot(controller)
			tweenToPos(ctrlRoot.Position)
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

-- Fling spin
local function startFling()
	local root = getRoot(bot)
	spinConnection = RunService.RenderStepped:Connect(function()
		root.CFrame = root.CFrame * CFrame.Angles(math.rad(30), math.rad(30), math.rad(30))
	end)
end

-- Stop fling spin
local function stopFling()
	if spinConnection then
		spinConnection:Disconnect()
	end
	spinConnection = nil
	isFlinging = false
	startFollowLoop()
end

-- Handle .f Username
local function handleFCommand(targetName)
	local target = Players:FindFirstChild(targetName)
	if not target or target == bot then return end

	isFlinging = true
	stopFollowLoop()

	local botRoot = getRoot(bot)
	local botHumanoid = bot.Character and bot.Character:FindFirstChildOfClass("Humanoid")
	if botHumanoid then
		botHumanoid.PlatformStand = true
	end
	botRoot.Anchored = false -- unanchor to spin freely

	-- Go to target
	local targetRoot = getRoot(target)
	tweenToPos(targetRoot.Position)
	startFling()

	local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Wait()
	end

	stopFling()

	-- Go back under controller
	if controller and controller.Character then
		local ctrlRoot = getRoot(controller)
		tweenToPos(ctrlRoot.Position)
	end

	-- Re-anchor to resume smooth follow
	botRoot.Anchored = true
end

-- Listen for .f commands
local function listenToController()
	controller.Chatted:Connect(function(msg)
		local toMe = msg:find(bot.Name)
		local target = msg:match("^%.f%s+(%w+)$")
		if toMe and target then
			handleFCommand(target)
		end
	end)
end

-- Setup once controller is detected
local function setupController(player)
	controller = player

	if not player.Character then
		player.CharacterAdded:Wait()
	end
	local ctrlRoot = getRoot(player)

	local botRoot = getRoot(bot)
	local finalPos = ctrlRoot.Position - Vector3.new(0, verticalOffset, 0)
	local tween = TweenService:Create(botRoot, TweenInfo.new(1), {CFrame = CFrame.new(finalPos)})
	tween:Play()
	tween.Completed:Wait()

	local botHumanoid = bot.Character and bot.Character:FindFirstChildOfClass("Humanoid")
	if botHumanoid then
		botHumanoid.PlatformStand = true
	end

	botRoot.Anchored = true -- allow Y movement but no physics
	startFollowLoop()
	listenToController()
end

-- Detect controller
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
