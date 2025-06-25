local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125

local followConnection
local alignPosition, yourAttachment, targetAttachment
local currentTargetPlayer

-- Enable noclip
local function enableNoclip(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

-- Disable noclip
local function disableNoclip(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
end

-- Start following with proper AlignPosition setup
local function startPhysicsFollow(targetPlayer)
	if followConnection then followConnection:Disconnect() end
	if alignPosition then alignPosition:Destroy() alignPosition = nil end
	if yourAttachment then yourAttachment:Destroy() yourAttachment = nil end
	if targetAttachment then targetAttachment:Destroy() targetAttachment = nil end

	currentTargetPlayer = targetPlayer

	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:WaitForChild("HumanoidRootPart")
	enableNoclip(myChar)

	local targetChar = targetPlayer.Character
	if not targetChar then return end
	local targetRoot = targetChar:WaitForChild("HumanoidRootPart")

	-- Create attachment on self
	yourAttachment = Instance.new("Attachment")
	yourAttachment.Name = "YourFollowAttachment"
	yourAttachment.Parent = myRoot

	-- Create attachment on target
	targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "TargetFollowAttachment"
	targetAttachment.Position = Vector3.new(0, -1.5, 0)
	targetAttachment.Parent = targetRoot

	-- Create AlignPosition between the two attachments
	alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "FollowAlign"
	alignPosition.Attachment0 = yourAttachment
	alignPosition.Attachment1 = targetAttachment
	alignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
	alignPosition.RigidityEnabled = false
	alignPosition.ReactionForceEnabled = true
	alignPosition.MaxForce = 50000
	alignPosition.Responsiveness = 50
	alignPosition.Parent = myRoot
end

-- Stop following
local function stopFollowing()
	if followConnection then followConnection:Disconnect() followConnection = nil end
	if alignPosition then alignPosition:Destroy() alignPosition = nil end
	if yourAttachment then yourAttachment:Destroy() yourAttachment = nil end
	if targetAttachment then targetAttachment:Destroy() targetAttachment = nil end

	local myChar = LocalPlayer.Character
	if myChar then
		disableNoclip(myChar)
	end

	currentTargetPlayer = nil
end

-- Command handling
local function connectChatted(player)
	player.Chatted:Connect(function(msg)
		if player.UserId ~= TARGET_USER_ID then return end

		local username = msg:match("^%.F%s+(%S+)")
		if username then
			local targetPlayer = Players:FindFirstChild(username)
			if targetPlayer then
				startPhysicsFollow(targetPlayer)
			end
		end

		if msg:lower() == ".stop" then
			stopFollowing()
		end
	end)
end

-- Respawn re-hook
LocalPlayer.CharacterAdded:Connect(function()
	if currentTargetPlayer then
		task.wait(1)
		startPhysicsFollow(currentTargetPlayer)
	end
end)

-- Controller chat hook
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
