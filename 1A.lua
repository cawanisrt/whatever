local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local TARGET_USER_ID = 7089838125
local APPROACH_DISTANCE = 5 -- studs from target before flinging
local TWEEN_TIME = 0.5

-- Find player by case-insensitive name
local function findPlayerByName(name)
	name = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == name then
			return player
		end
	end
	return nil
end

-- Spin/fling logic
local function spinFling(root)
	root.Velocity = Vector3.new(9e7, 9e7, 9e7)
	root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
end

-- Tween to position
local function moveToPosition(part, targetPos, duration)
	local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
	tween:Play()
	tween.Completed:Wait()
end

-- Main logic: go to target, then fling
local function approachAndFling(targetPlayer)
	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:WaitForChild("HumanoidRootPart")
	local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
	local targetRoot = targetChar:WaitForChild("HumanoidRootPart")

	-- Smooth approach
	local goalPos = targetRoot.Position + Vector3.new(0, 0, -APPROACH_DISTANCE)
	moveToPosition(myRoot, goalPos, TWEEN_TIME)

	-- Double-check distance
	if (myRoot.Position - targetRoot.Position).Magnitude <= APPROACH_DISTANCE + 1 then
		spinFling(myRoot)
		print("✅ Spun on " .. targetPlayer.Name)
	else
		warn("❌ Too far from target to fling.")
	end
end

-- Listen for .F commands
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

-- Attach listener
for _, player in ipairs(Players:GetPlayers()) do
	setupChatListener(player)
end
Players.PlayerAdded:Connect(setupChatListener)
