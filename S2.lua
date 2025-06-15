local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125

local activeWeld = nil
local currentTargetPlayer = nil

-- Disable collisions on all parts in your character
local function makeNonCollidable(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
end

-- Attach the local player to target's HumanoidRootPart
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

	-- Remove old weld
	if activeWeld then
		activeWeld:Destroy()
	end

	-- Move to target position
	myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2.5, 0)

	-- Create weld
	activeWeld = Instance.new("WeldConstraint")
	activeWeld.Part0 = myRoot
	activeWeld.Part1 = targetRoot
	activeWeld.Parent = myRoot

	makeNonCollidable(myChar)

	print("✅ Attached to " .. targetPlayer.Name)

	-- Store the target for auto reattach
	currentTargetPlayer = targetPlayer
end

-- Detach (called on .stop)
local function detach()
	if activeWeld then
		activeWeld:Destroy()
		activeWeld = nil
	end
	currentTargetPlayer = nil
	print("🧷 Detached")
end

-- Listen to controller chat
local function connectChatted(player)
	player.Chatted:Connect(function(msg)
		if player.UserId ~= TARGET_USER_ID then return end

		local username = msg:match("^%.F%s+(%S+)")
		if username then
			local target = Players:FindFirstChild(username)
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
		-- Small delay to ensure character loads
		task.wait(1)
		attachToPlayer(currentTargetPlayer)
	end
end)

-- Connect to controller's chat
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
