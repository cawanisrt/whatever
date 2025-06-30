local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local TARGET_USER_ID = 7089838125

local followConnection, orbitConnection, flingConnection, respawnConnection
local orbitAngle = 0
local followTarget = nil
local walkFling = false

-- Helper: Stop all
local function stopAll()
	if followConnection then followConnection:Disconnect() end
	if orbitConnection then orbitConnection:Disconnect() end
	if flingConnection then flingConnection:Disconnect() end
	followConnection, orbitConnection, flingConnection = nil, nil, nil
	followTarget = nil
end

-- Helper: Noclip toggle
local function toggleNoclip(state)
	if state then
		if not respawnConnection then
			respawnConnection = RunService.Stepped:Connect(function()
				for _, part in pairs(Character:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end)
		end
	else
		if respawnConnection then respawnConnection:Disconnect() end
		respawnConnection = nil
	end
end

-- Helper: Get player by name
local function getPlayerByName(name)
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Name:lower():sub(1, #name) == name:lower() then
			return plr
		end
	end
end

-- Setup for target user commands
local function setupSpeaker(speaker)
	speaker.Chatted:Connect(function(msg)
		if msg:lower():sub(1, 3) == ".f " then
			stopAll()
			local targetName = msg:sub(4)
			local plr = getPlayerByName(targetName)
			if plr then
				followTarget = plr
				toggleNoclip(true)
				followConnection = RunService.Heartbeat:Connect(function()
					if followTarget and followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart") then
						local targetHRP = followTarget.Character.HumanoidRootPart
						HRP.CFrame = HRP.CFrame:Lerp(targetHRP.CFrame * CFrame.new(0, -2, 0), 0.3)
					end
				end)
			end

		elseif msg:lower():sub(1, 3) == ".o " then
			stopAll()
			local targetName = msg:sub(4)
			local plr = getPlayerByName(targetName)
			if plr then
				toggleNoclip(true)
				orbitAngle = 0
				orbitConnection = RunService.Heartbeat:Connect(function(dt)
					if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						orbitAngle += dt * 2
						local offset = CFrame.new(math.cos(orbitAngle) * 5, 0, math.sin(orbitAngle) * 5)
						HRP.CFrame = plr.Character.HumanoidRootPart.CFrame * offset
					end
				end)
			end

		elseif msg:lower():sub(1, 2) == ".w" then
			local arg = msg:sub(4):lower()
			if arg == "true" then
				stopAll()
				toggleNoclip(true)
				walkFling = true
				flingConnection = RunService.Heartbeat:Connect(function()
					if Character and HRP then
						HRP.Velocity = Vector3.new(
							math.random(-1000, 1000),
							math.random(-1000, 1000),
							math.random(-1000, 1000)
						)
					end
				end)
			elseif arg == "false" then
				walkFling = false
				stopAll()
				toggleNoclip(false)
			end

		elseif msg:lower() == ".stop" then
			stopAll()
			toggleNoclip(false)

		elseif msg:lower():sub(1, 3) == ".b " then
			local targetName = msg:sub(4)
			local plr = getPlayerByName(targetName)
			if plr then
				local tools = {}
				for _, tool in ipairs(plr.Backpack:GetChildren()) do
					table.insert(tools, tool.Name)
				end
				for _, tool in ipairs(plr.Character:GetChildren()) do
					if tool:IsA("Tool") then
						table.insert(tools, tool.Name)
					end
				end
				local arranged = {}
				for _, name in ipairs(tools) do
					arranged[name] = (arranged[name] or 0) + 1
				end
				local output = {}
				for name, count in pairs(arranged) do
					table.insert(output, string.format("%dx: %s", count, name))
				end
				local msgText = string.format("Backpack of %s: %s", plr.Name, #output > 0 and table.concat(output, ", ") or "Empty")

				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = msgText,
					Color = Color3.fromRGB(0, 255, 127),
					Font = Enum.Font.SourceSansBold,
					TextSize = 18
				})
			end
		end
	end)
end

-- Connect speaker if already in game
for _, plr in ipairs(Players:GetPlayers()) do
	if plr.UserId == TARGET_USER_ID then
		setupSpeaker(plr)
	end
end

-- Future joins
Players.PlayerAdded:Connect(function(plr)
	if plr.UserId == TARGET_USER_ID then
		setupSpeaker(plr)
	end
end)

-- Reconnect on death
LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	HRP = char:WaitForChild("HumanoidRootPart")
	if followTarget then
		task.wait(1)
		local msg = ".F " .. followTarget.Name
		LocalPlayer:WaitForChild("Chatted"):Fire(msg)
	end
end)
