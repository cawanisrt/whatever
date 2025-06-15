local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125

local activeWeld = nil
local currentTargetPlayer = nil
local noclipConnection = nil

-- Enable noclip loop
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

-- Attach local player to target
local function attachToPlayer(targetPlayer)
	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)
	if not myRoot then
		warn("❌ No HumanoidRootPart on local player")
		return
	end

	local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
	local targetRoot = targetChar:WaitForChild("HumanoidRootPart", 5)
	if not targetRoot then
		warn("❌ Target missing HumanoidRootPart")
		return
	end

	if activeWeld then
		activeWeld:Destroy()
	end

	myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2.5, 0)

	activeWeld = Instance.new("WeldConstraint")
	activeWeld.Part0 = myRoot
	activeWeld.Part1 = targetRoot
	activeWeld.Parent = myRoot

	enableNoclip(myChar)

	currentTargetPlayer = targetPlayer
	print("✅ Attached and noclipped to " .. targetPlayer.Name)
end

-- Detach from player
local function detach()
	if activeWeld then
		activeWeld:Destroy()
		activeWeld = nil
	end
	disableNoclip()
	currentTargetPlayer = nil
	print("🧷 Detached")
end

-- Listen to controller's commands
local function connectChatted(player)
	player.Chatted:Connect(function(msg)
		if player.UserId ~= TARGET_USER_ID then return end

		local username = msg:match("^%.F%s+(%S+)")
		if username then
			local target = findPlayerByName(username)
			if target then
				attachToPlayer(target)
			else
				warn("❌ Player not found: " .. username)
			end
			return
		end

		if msg:lower() == ".stop" then
			detach()
		end
	end)
end

-- Reattach after respawn
LocalPlayer.CharacterAdded:Connect(function()
	if currentTargetPlayer and currentTargetPlayer:IsDescendantOf(Players) then
		task.wait(1)
		attachToPlayer(currentTargetPlayer)
	end
end)

-- Hook into the controller’s chat
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
