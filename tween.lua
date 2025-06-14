local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local targetUserId = 7089838125 -- The controller's UserId
local spinning = false
local connection
local verticalOffset = 10
local rotationSpeed = 5

local function getRoot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart")
end

local function stopSpinning()
	spinning = false
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function spinInPlace(part)
	stopSpinning()
	spinning = true
	connection = RunService.RenderStepped:Connect(function()
		if spinning and part and part.Parent then
			part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(rotationSpeed), 0)
		end
	end)
end

local function tweenToPosition(position)
	local myRoot = getRoot(localPlayer)
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(myRoot, tweenInfo, { CFrame = CFrame.new(position) })
	tween:Play()
	tween.Completed:Wait()
end

local function setupControllerLogic(controllerPlayer)
	-- Tween under the controller at startup
	local success, err = pcall(function()
		local controllerRoot = getRoot(controllerPlayer)
		tweenToPosition(controllerRoot.Position - Vector3.new(0, verticalOffset, 0))
	end)
	if not success then
		warn("Failed to tween under controller:", err)
	end

	controllerPlayer.Chatted:Connect(function(msg)
		local targetName = msg:match("^%.f%s+(%w+)$")
		if targetName then
			local foundPlayer = Players:FindFirstChild(targetName)
			if foundPlayer and foundPlayer ~= localPlayer then
				local targetRoot = getRoot(foundPlayer)
				tweenToPosition(targetRoot.Position)
				spinInPlace(getRoot(localPlayer))
			end
			return
		end
		if msg:lower() == ".stop" then
			stopSpinning()
		end
	end)
end

-- Watch for the controller joining
Players.PlayerAdded:Connect(function(player)
	if player.UserId == targetUserId then
		player.CharacterAdded:Connect(function()
			wait(1)
			setupControllerLogic(player)
		end)
	end
end)

-- If the controller is already in the game
for _, player in ipairs(Players:GetPlayers()) do
	if player.UserId == targetUserId then
		if player.Character then
			setupControllerLogic(player)
		else
			player.CharacterAdded:Connect(function()
				wait(1)
				setupControllerLogic(player)
			end)
		end
	end
end
