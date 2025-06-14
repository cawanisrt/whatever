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

local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

local function tweenToPos(pos)
	local root = getRoot(bot)
	local targetPos = pos - Vector3.new(0, verticalOffset, 0)
	local tween = TweenService:Create(root, TweenInfo.new(followInterval), {CFrame = CFrame.new(targetPos)})
	tween:Play()
end

local function startFollowLoop()
	if followConnection then return end
	followConnection = RunService.Heartbeat:Connect(function()
		if not isFlinging and controller and controller.Character then
			local ctrlRoot = getRoot(controller)
			tweenToPos(ctrlRoot.Position)
		end
	end)
end

local function stopFollowLoop()
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
end

local function startFling()
	local root = getRoot(bot)
	spinConnection = RunService.RenderStepped:Connect(function()
		root.CFrame = root.CFrame * CFrame.Angles(math.rad(30), math.rad(30), math.rad(30))
	end)
end

local function stopFling()
	if spinConnection then
		spinConnection:Disconnect()
	end
	spinConnection = nil
	isFlinging = false
	startFollowLoop()
end

local function returnToController()
	local botRoot = getRoot(bot)
	local botHumanoid = bot.Character and bot.Character:FindFirstChildOfClass("Humanoid")
	if botHumanoid then
		botHumanoid.PlatformStand = true
	end
	botRoot.Anchored = true

	if controller and controller.Character then
		local ctrlRoot = getRoot(controller)
		botRoot.CFrame = CFrame.new(ctrlRoot.Position - Vector3.new(0, verticalOffset, 0))
	end
end

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
	botRoot.Anchored = false

	local targetChar = target.Character or target.CharacterAdded:Wait()
	local targetRoot = targetChar:WaitForChild("HumanoidRootPart")

	botRoot.CFrame = targetRoot.CFrame
	startFling()

	local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Wait()
	end

	stopFling()
	returnToController()
end

local function listenToController()
	controller.Chatted:Connect(function(msg)
		local targetName = msg:match("^%.f%s+(%w+)$")
		if targetName then
			handleFCommand(targetName)
		elseif msg == ".stop" then
			stopFling()
			returnToController()
		end
	end)
end

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

	botRoot.Anchored = true
	startFollowLoop()
	listenToController()
end

-- Setup on start
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
