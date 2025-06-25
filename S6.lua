local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125

local followConnection
local noclipConnection
local currentTargetPlayer

-- Enable noclip (disable collisions)
local function enableNoclip(model)
	noclipConnection = RunService.Stepped:Connect(function()
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
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

-- Start following and float when needed
local function startTweenFollow(targetPlayer)
	if followConnection then followConnection:Disconnect() end
	if noclipConnection then noclipConnection:Disconnect() end

	currentTargetPlayer = targetPlayer
	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:WaitForChild("HumanoidRootPart")
	local humanoid = myChar:FindFirstChildOfClass("Humanoid")

	local targetChar = targetPlayer.Character
	if not targetChar then return end
	local targetRoot = targetChar:WaitForChild("HumanoidRootPart")

	enableNoclip(myChar)

	followConnection = RunService.Heartbeat:Connect(function()
		if not targetRoot or not myRoot then return end

		-- Follow with offset
		local goal = {}
		goal.CFrame = targetRoot.CFrame * CFrame.new(0, -1.5, 0)
		TweenService:Create(myRoot, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), goal):Play()

		-- Check if target is flying/floating
		local yVelocity = math.abs(targetRoot.Velocity.Y)
		local yDifference = targetRoot.Position.Y - myRoot.Position.Y
		local airborne = yVelocity > 5 or yDifference > 3

		if humanoid then
			humanoid.PlatformStand = airborne
		end
	end)
end

-- Stop following
local function stopFollowing()
	if followConnection then followConnection:Disconnect() followConnection = nil end
	if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
	currentTargetPlayer = nil

	local myChar = LocalPlayer.Character
	if myChar then
		disableNoclip()
		local humanoid = myChar:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

-- Listen for chat commands from the controller
local function connectChatted(player)
	player.Chatted:Connect(function(msg)
		if player.UserId ~= TARGET_USER_ID then return end

		local username = msg:match("^%.F%s+(%S+)")
		if username then
			local targetPlayer = Players:FindFirstChild(username)
			if targetPlayer then
				startTweenFollow(targetPlayer)
			end
		end

		if msg:lower() == ".stop" then
			stopFollowing()
		end
	end)
end

-- Reapply follow after death
LocalPlayer.CharacterAdded:Connect(function()
	if currentTargetPlayer then
		task.wait(1)
		startTweenFollow(currentTargetPlayer)
	end
end)

-- Hook to controller's chat
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
