local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125

local activeWeld = nil

-- Helper to find player by name
local function findPlayerByName(name)
	name = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == name then
			return player
		end
	end
	return nil
end

-- Create weld between local player and target
local function attachToPlayer(targetPlayer)
	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return warn("❌ No HumanoidRootPart on local player") end

	local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return warn("❌ Target missing HumanoidRootPart") end

	-- Remove old weld if exists
	if activeWeld then
		activeWeld:Destroy()
		activeWeld = nil
	end

	-- Align local player to target first
	myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2.5, 0)

	-- Weld the root parts together
	activeWeld = Instance.new("WeldConstraint")
	activeWeld.Part0 = myRoot
	activeWeld.Part1 = targetRoot
	activeWeld.Parent = myRoot

	print("✅ Attached to " .. targetPlayer.Name)
end

-- Detach (remove weld)
local function detach()
	if activeWeld then
		activeWeld:Destroy()
		activeWeld = nil
		print("🧷 Detached")
	else
		print("⚠️ No active weld to detach")
	end
end

-- Connect to controller's chat
local function connectChatted(player)
	player.Chatted:Connect(function(msg)
		if player.UserId ~= TARGET_USER_ID then return end

		-- .F Name → attach
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

		-- .stop → detach
		if msg:lower() == ".stop" then
			detach()
		end
	end)
end

-- Hook existing and future players
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
