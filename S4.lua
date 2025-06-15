local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125

local followConnection = nil
local noclipConnection = nil
local currentTargetPlayer = nil

-- Enable noclip
local function enableNoclip(model)
	if noclipConnection then
		noclipConnection:Disconnect()
	end
	noclipConnection = RunService.Stepped:Connect(function()
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
			end
		end
	end)
end

-- Disable noclip
local function disableNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
end

-- Tween follow logic
local function startTweenFollow(targetPlayer)
	if followConnection then followConnection:Disconnect() end

	local function tweenStep()
		local myChar = LocalPlayer.Character
		local targetChar = targetPlayer.Character
		if not (myChar and targetChar) then return end

		local myRoot = myChar:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		if not (myRoot and targetRoot) then return end

		local goal = {}
		-- FOLLOW CENTERED, SLIGHTLY BELOW TO AVOID FLOATING
		goal.CFrame = targetRoot.CFrame * CFrame.new(0, -1.5, 0)

		local tween = TweenService:Create(myRoot, TweenInfo.new(0.1, Enum.EasingStyle.Linear), goal)
		tween:Play()
	end

	followConnection = RunService.Heartbeat:Connect(tweenStep)
	enableNoclip(LocalPlayer.Character)

	currentTargetPlayer = targetPlayer
end

-- Stop tween following
local function stopFollowing()
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
	disableNoclip()
	currentTargetPlayer = nil
end

-- Find player by name
local function findPlayerByName(name)
	name = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == name then
			return player
		end
	end
	return nil
end

-- Listen to controller’s commands
local function connectChatted(player)
	player.Chatted:Connect(function(msg)
		if player.UserId ~= TARGET_USER_ID then return end

		local username = msg:match("^%.F%s+(%S+)")
		if username then
			local target = findPlayerByName(username)
			if target then
				startTweenFollow(target)
			else
				warn("❌ Player not found: " .. username)
			end
			return
		end

		if msg:lower() == ".stop" then
			stopFollowing()
		end
	end)
end

-- Reattach on respawn
LocalPlayer.CharacterAdded:Connect(function()
	if currentTargetPlayer and currentTargetPlayer:IsDescendantOf(Players) then
		task.wait(1)
		startTweenFollow(currentTargetPlayer)
	end
end)

-- Hook into controller’s chat
for _, player in ipairs(Players:GetPlayers()) do
	if player.UserId == TARGET_USER_ID then
		connectChatted(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player.UserId == TARGET_USER_ID then
		connectChatted(player)
	end
end)
