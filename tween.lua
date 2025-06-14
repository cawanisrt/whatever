local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local targetUserId = 7089838125 -- Controller
local verticalOffset = 20
local followInterval = 0.5 -- how often to tween (in seconds)

-- Helper to get HumanoidRootPart safely
local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

-- Main looped tween follow
local function followUnderLoop(controller)
	task.spawn(function()
		while controller and controller.Parent do
			local success = pcall(function()
				local controllerRoot = getRoot(controller)
				local myRoot = getRoot(localPlayer)

				if controllerRoot and myRoot then
					local targetPosition = controllerRoot.Position - Vector3.new(0, verticalOffset, 0)

					local tweenInfo = TweenInfo.new(followInterval, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local tween = TweenService:Create(myRoot, tweenInfo, { CFrame = CFrame.new(targetPosition) })
					tween:Play()
				end
			end)
			task.wait(followInterval)
		end
	end)
end

-- Wait for controller and start following
local function tryStartFollowing()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == targetUserId then
			player.CharacterAdded:Connect(function()
				wait(1)
				followUnderLoop(player)
			end)
			if player.Character then
				followUnderLoop(player)
			end
		end
	end
end

-- Listen for the controller joining later
Players.PlayerAdded:Connect(function(player)
	if player.UserId == targetUserId then
		player.CharacterAdded:Connect(function()
			wait(1)
			followUnderLoop(player)
		end)
	end
end)

-- Initial attempt
tryStartFollowing()

