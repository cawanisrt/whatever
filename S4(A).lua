local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TARGET_USER_ID = 7089838125

local followConnection
local alignPosition, followAttachment
local currentTargetPlayer

-- Enable noclip (no collisions)
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

-- Start physics-based follow
local function startPhysicsFollow(targetPlayer)
	if followConnection then followConnection:Disconnect() end
	if alignPosition then alignPosition:Destroy() alignPosition = nil end
	if followAttachment then followAttachment:Destroy() followAttachment = nil end

	currentTargetPlayer = targetPlayer

	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRoot = myChar:WaitForChild("HumanoidRootPart")
	enableNoclip(myChar)

	-- Setup Attachment and AlignPosition
	local attachment = Instance.new("Attachment")
	attachment.Name = "FollowAttachment"
	attachment.Parent = myRoot
	followAttachment = attachment

	local align = Instance.new("AlignPosition")
	align.Name = "FollowAlign"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = false
	align.ReactionForceEnabled = false
	align.MaxForce = math.huge
	align.Responsiveness = 100
	align.Parent = myRoot
	alignPosition = align

	-- Start updating target position every frame
	followConnection = RunService.Heartbeat:Connect(function()
		local targetChar = targetPlayer.Character
		if not targetChar then return end

		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		if not targetRoot then return end

		attachment.Position = targetRoot.Position + Vector3.new(0, -1.5, 0)
	end)
end

-- Stop following
local function stopFollowing()
	if followConnection then followConnection:Disconnect() followConnection = nil end
	if alignPosition then alignPosition:Destroy() alignPosition = nil end
	if followAttachment then followAttachment:Destroy() followAttachment = nil end

	local myChar = LocalPlayer.Character
	if myChar then
		disableNoclip(myChar)
	end

	currentTargetPlayer = nil
end

-- Command listener
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

-- Reapply follow after death
LocalPlayer.CharacterAdded:Connect(function()
	if currentTargetPlayer then
		task.wait(1)
		startPhysicsFollow(currentTargetPlayer)
	end
end)

-- Hook controller chat
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
