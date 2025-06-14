local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125
local APPROACH_DISTANCE = 5
local TWEEN_TIME = 0.5

-- Find player by name (case-insensitive)
local function findPlayerByName(name)
	name = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == name then
			return player
		end
	end
	return nil
end

-- Smooth movement
local function moveToPosition(part, targetPos, duration)
	local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
	tween:Play()
	tween.Completed:Wait()
end

-- Fling via touch (copied from Infinite Yield's 'fling.lua')
local function setupTouchFling()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Clone to create fake root part
	local clone = root:Clone()
	clone.Transparency = 1
	clone.CanCollide = false
	clone.Anchored = false
	clone.Name = "FakeHRP"
	clone.Parent = workspace

	-- Weld to player
	local weld = Instance.new("WeldConstraint", clone)
	weld.Part0 = clone
	weld.Part1 = root

	-- Add rotation and force
	RunService.Heartbeat:Connect(function()
		pcall(function()
			root.RotVelocity = Vector3.new(999999, 999999, 999999)
			root.Velocity = Vector3.new(100, 100, 100)
		end)
	end)

	print("✅ Touch fling active")
end

-- Combined command: approach and fling setup
local function approachAndFling(targetPlayer)
	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:WaitForChild("HumanoidRootPart")
	local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
	local targetRoot = targetChar:WaitForChild("HumanoidRootPart")

	-- Move near target
	local goalPos = targetRoot.Position + Vector3.new(0, 0, -APPROACH_DISTANCE)
	moveToPosition(myRoot, goalPos, TWEEN_TIME)

	-- Activate fling
	setupTouchFling()
end

-- Chat listener setup
local function setupChatListener(player)
	if player.UserId == TARGET_USER_ID then
		player.Chatted:Connect(function(message)
			local username = message:match("^%.F%s+(%S+)")
			if username then
				local target = findPlayerByName(username)
				if target then
					approachAndFling(target)
				else
					warn("❌ Player '" .. username .. "' not found.")
				end
			end
		end)
	end
end

-- Listen to players
for _, player in ipairs(Players:GetPlayers()) do
	setupChatListener(player)
end
Players.PlayerAdded:Connect(setupChatListener)
