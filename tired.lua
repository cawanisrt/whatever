local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local bot = Players.LocalPlayer
local controllerUserId = 7089838125
local verticalOffset = 20
local moveInterval = 3
local roamRadius = 20
local isFlinging = false
local moveLoop = nil
local controller = nil

local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

-- Get a random position within radius
local function getRandomPosition(origin)
	local offset = Vector3.new(
		math.random(-roamRadius, roamRadius),
		0,
		math.random(-roamRadius, roamRadius)
	)
	return origin + offset + Vector3.new(0, 5, 0)
end

-- Roaming tween loop
local function startRoamLoop()
	if moveLoop then return end
	moveLoop = RunService.Heartbeat:Connect(function()
		if isFlinging then return end
		local botRoot = getRoot(bot)
		local targetPos = getRandomPosition(botRoot.Position)
		local tween = TweenService:Create(botRoot, TweenInfo.new(1.5), {
			CFrame = CFrame.new(targetPos)
		})
		tween:Play()
		wait(moveInterval)
	end)
end

local function stopRoamLoop()
	if moveLoop then
		moveLoop:Disconnect()
		moveLoop = nil
	end
end

-- Teleport to a target player by name
local function teleportToPlayer(targetName)
	local target = Players:FindFirstChild(targetName)
	if not target or not target.Character then
		print("Teleport Failed: Player not found or no character.")
		return
	end

	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		print("Teleport Failed: No HumanoidRootPart.")
		return
	end

	local botRoot = getRoot(bot)
	botRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
	print("Teleport Success: Teleported to " .. targetName)
end

-- Listen to controller's chat
local function listenToController()
	controller.Chatted:Connect(function(msg)
		local targetName = msg:match("^%.tp%s+(%w+)$")
		if targetName then
			teleportToPlayer(targetName)
		end
	end)
end

-- Setup controller and bind chat
local function setupController(player)
	controller = player
	if player.Character then
		listenToController()
	else
		player.CharacterAdded:Connect(function()
			listenToController()
		end)
	end
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

-- Start roaming when bot character is ready
if bot.Character then
	startRoamLoop()
else
	bot.CharacterAdded:Connect(startRoamLoop)
end
