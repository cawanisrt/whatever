local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local bot = Players.LocalPlayer
local controllerUserId = 7089838125
local offsetBelow = Vector3.new(0, -20, 0)
local spinningConnection = nil
local currentTarget = nil

-- Get HumanoidRootPart of any player
local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

-- Tween the bot to a position (XY only or XYZ if wanted)
local function tweenToPosition(pos)
	local root = getRoot(bot)
	local currentPos = root.Position
	local newPos = Vector3.new(pos.X, currentPos.Y, pos.Z) -- Keep bot's Y fixed
	local tween = TweenService:Create(root, TweenInfo.new(0.5), {CFrame = CFrame.new(newPos)})
	tween:Play()
	tween.Completed:Wait()
end

-- Start flinging (crazy spin)
local function startFlinging()
	local root = getRoot(bot)
	spinningConnection = RunService.RenderStepped:Connect(function()
		root.CFrame = root.CFrame * CFrame.Angles(math.rad(30), math.rad(30), math.rad(30))
	end)
end

-- Stop flinging
local function stopFlinging()
	if spinningConnection then
		spinningConnection:Disconnect()
		spinningConnection = nil
	end
end

-- Return to controller (X/Z follow only, Y locked)
local function returnToController(controller)
	local controllerRoot = getRoot(controller)
	local pos = controllerRoot.Position + offsetBelow
	tweenToPosition(pos)
end

-- Handle .f messages
local function handleCommandMessage(controller, message)
	local targetName = message:match("^%.f%s+(%w+)$")
	if targetName then
		local target = Players:FindFirstChild(targetName)
		if target and target ~= bot then
			currentTarget = target
			local targetRoot = getRoot(target)

			-- Go to target
			tweenToPosition(targetRoot.Position)
			startFlinging()

			-- Watch for death
			local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Died:Wait()
				stopFlinging()
				returnToController(controller)
				currentTarget = nil
			end
		end
	end
end

-- Listen to private messages from controller
local function setupPrivateMessageListener(controller)
	controller.Chatted:Connect(function(msg)
		local toMe = msg:find(bot.Name)
		if toMe then
			handleCommandMessage(controller, msg)
		end
	end)
end

-- Setup when controller is available
local function waitForController()
	for _, player in pairs(Players:GetPlayers()) do
		if player.UserId == controllerUserId then
			local controller = player
			controller.CharacterAdded:Connect(function()
				task.wait(1)
				returnToController(controller)
			end)

			-- Initial follow if already loaded
			if controller.Character then
				task.wait(1)
				returnToController(controller)
			end

			setupPrivateMessageListener(controller)
		end
	end
end

-- Listen for controller joining
Players.PlayerAdded:Connect(function(player)
	if player.UserId == controllerUserId then
		player.CharacterAdded:Connect(function()
			task.wait(1)
			returnToController(player)
		end)
		setupPrivateMessageListener(player)
	end
end)

-- Initialize
waitForController()
