local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local TARGET_USER_ID = 7089838125
local APPROACH_DISTANCE = 5

-- Helper to find player by name (case-insensitive)
local function findPlayerByName(name)
	name = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == name then
			return player
		end
	end
	return nil
end

-- Teleport near the target player
local function teleportToTarget(targetPlayer)
	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return warn("❌ Your character has no HumanoidRootPart") end

	local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return warn("❌ Target has no HumanoidRootPart") end

	myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 0, -APPROACH_DISTANCE)
	print("✅ Teleported near " .. targetPlayer.Name)
end

-- Wait safely for the chat system to exist
local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if not chatEvents then
	warn("❌ DefaultChatSystemChatEvents not found. Default chat might be disabled.")
	return
end

-- Listen for private (whisper) messages
chatEvents:WaitForChild("OnMessageDoneFiltering").OnClientEvent:Connect(function(data)
	if data.FromSpeaker and data.OriginalChannel == "Whisper" then
		print("📨 Whisper received from", data.FromSpeaker, ":", data.Message)

		local fromPlayer = Players:FindFirstChild(data.FromSpeaker)
		if fromPlayer and fromPlayer.UserId == TARGET_USER_ID then
			local username = data.Message:match("^%.F%s+(%S+)")
			if username then
				local target = findPlayerByName(username)
				if target then
					teleportToTarget(target)
				else
					warn("❌ Player not found: " .. username)
				end
			else
				print("⚠️ Whisper command format not matched.")
			end
		else
			print("❌ Ignored message: wrong sender.")
		end
	end
end)
