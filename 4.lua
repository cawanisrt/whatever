local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local bot = Players.LocalPlayer
local controllerUserId = 7089838125
local offset = Vector3.new(0, -20, 0)
local followInterval = 0.5

local isFlinging = false
local spinConnection = nil
local followLoopConnection = nil
local currentTarget = nil
local controller = nil

-- Get root
local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

-- Tween bot to position (X/Z only, Y locked)
local function tweenToXZ(pos)
	local root = getRoot(bot)
	local y = root.Position.Y
	local goal = Vector3.new(pos.X, y, pos.Z)
	local tween = TweenService:Create(root, TweenInfo.new(followInterval), {CFrame = CFrame.new(goal)})
	tween:Play()
end

-- Loop follow under controller
local function startFollowLoop()
	if followLoopConnection then return end
	followLoopConnection = RunService.Heartbeat:Connect(function()
		if controller and controller.Character and not isFlinging then
			local controllerRoot = getRoot(controller)
			tweenToXZ(controllerRoot.Position + offset)
		end
	end)
end

-- Stop follow loop
local function stopFollowLoop()
	if followLoopConnection then
		followLoopConnection:Disconnect()
		followLoopConnection = nil
	end
end

-- Start spinning
local function startFling()
	stopFollowLoop()
	isFlinging = true
	local root = getRoot(bot)
	spinConnection = RunService.RenderStepped:Connect(function()
		root.CFrame = root.CFrame * CFrame.Angles(math.rad(30), math.rad(30), math.rad(30))
	end)
end

-- Stop spinning
local function stopFling()
	if spinConnection then
		spinConnection:Disconnect()
	end
	isFlinging = false
	startFollowLoop()
end

-- Process .f command
local function processFCommand(targetName)
	local target = Players:FindFirstChild(targetName)
	if not target or target == bot then return end

	currentTarget = target
	local targetRoot = getRoot(target)
	tweenToXZ(targetRoot.Position)
	startFling()

	-- Wait for death
	local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Wait()
	end

	stopFling()
	currentTarget = nil
end

-- Setup chat listener
local function setupChatListener()
	controller.Chatted:Connect(function(msg)
		local nameInMessage = msg:find(bot.Name)
		local target = msg:match("^%.f%s+(%w+)$")
		if nameInMessage and target then
			processFCommand(target)
		end
	end)
end

-- Init if controller exists
local function trySetupController(player)
	if player.UserId == controllerUserId then
		controller = player
		if controller.Character then
			startFollowLoop()
		end
		controller.CharacterAdded:Connect(function()
			task.wait(1)
			startFollowLoop()
		end)
		setupChatListener()
	end
end

-- Run for already joined players
for _, player in ipairs(Players:GetPlayers()) do
	trySetupController(player)
end

-- Watch for controller joining later
Players.PlayerAdded:Connect(trySetupController)
