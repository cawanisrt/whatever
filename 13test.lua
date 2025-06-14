local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local botRoot = character:WaitForChild("HumanoidRootPart")

local controllerUserId = 7089838125
local controller = nil
local spinConnection = nil
local followConnection = nil
local currentTarget = nil

-- Utility: Get the root part of a player
local function getRoot(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- Start spinning
local function startFling()
	if spinConnection then spinConnection:Disconnect() end
	spinConnection = RunService.RenderStepped:Connect(function()
		botRoot.CFrame = botRoot.CFrame * CFrame.Angles(math.rad(45), math.rad(45), math.rad(45))
	end)
end

-- Stop spinning
local function stopFling()
	if spinConnection then spinConnection:Disconnect() end
	spinConnection = nil
end

-- Return below controller and anchor
local function returnToController()
	if not controller then return end
	local ctrlRoot = getRoot(controller)
	if not ctrlRoot then return end

	local targetCFrame = ctrlRoot.CFrame * CFrame.new(0, -20, 0)
	botRoot.Anchored = true

	local tween = TweenService:Create(botRoot, TweenInfo.new(0.5, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
	tween:Play()
end

-- Follow target and fling
local function handleFCommand(targetName)
	print("handleFCommand called for:", targetName)

	local target = Players:FindFirstChild(targetName)
	if not target then
		warn("Player not found")
		return
	end

	local targetChar = target.Character
	if not targetChar then
		warn("Target has no character")
		return
	end

	local targetHead = targetChar:FindFirstChild("Head")
	if not targetHead then
		warn("Target has no head")
		return
	end

	-- 🔓 Unanchor for movement and spin
	botRoot.Anchored = false
	botRoot.CFrame = targetHead.CFrame + Vector3.new(0, 3, 0)
	botRoot.Velocity = Vector3.new(100, 100, 100)

	startFling()
	currentTarget = target

	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if targetHum then
		targetHum.Died:Connect(function()
			print("Target died. Returning to controller.")
			currentTarget = nil
			stopFling()
			returnToController()
		end)
	end
end

-- Loop tween under controller
local function startFollowingController()
	if not controller then return end
	local ctrlRoot = getRoot(controller)
	if not ctrlRoot then return end

	if followConnection then followConnection:Disconnect() end

	followConnection = RunService.RenderStepped:Connect(function()
		if currentTarget then return end -- Pause follow if flinging
		local targetCFrame = ctrlRoot.CFrame * CFrame.new(0, -20, 0)
		if not botRoot.Anchored then
			botRoot.Anchored = true
		end
		local tween = TweenService:Create(botRoot, TweenInfo.new(0.25, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
		tween:Play()
	end)
end

-- Setup controller
local function setupController(p)
	controller = p
	print("Controller found:", controller.Name)

	controller.Chatted:Connect(function(msg)
		print("Message received:", msg)

		local targetName = msg:match("^%.f%s+(%w+)$")
		if targetName then
			print("Attempting to fling:", targetName)
			handleFCommand(targetName)
		elseif msg == ".stop" then
			print("Stopping fling")
			currentTarget = nil
			stopFling()
			botRoot.Anchored = true
			returnToController()
		end
	end)

	startFollowingController()
end

-- Find controller in-game
for _, p in pairs(Players:GetPlayers()) do
	if p.UserId == controllerUserId then
		setupController(p)
	end
end

Players.PlayerAdded:Connect(function(p)
	if p.UserId == controllerUserId then
		setupController(p)
	end
end)
