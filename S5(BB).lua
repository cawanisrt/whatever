local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local TARGET_USER_ID = 7089838125

local followConnection, orbitConnection, flingConnection, noclipConnection
local orbitAngle = 0
local followTarget = nil

local function stopAll()
    if followConnection then followConnection:Disconnect() end
    if orbitConnection then orbitConnection:Disconnect() end
    if flingConnection then flingConnection:Disconnect() end
    if noclipConnection then noclipConnection:Disconnect() end
    followConnection, orbitConnection, flingConnection, noclipConnection = nil, nil, nil, nil
    followTarget = nil
end

local function toggleNoclip(state)
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = nil
    end
end

local function getPlayerByName(name)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Name:lower():sub(1, #name) == name:lower() then
            return plr
        end
    end
end

local function setupSpeaker(speaker)
    speaker.Chatted:Connect(function(msg)
        msg = msg:lower()

        if msg:sub(1, 3) == ".f " then
            stopAll()
            local plr = getPlayerByName(msg:sub(4))
            if plr then
                followTarget = plr
                toggleNoclip(true)
                followConnection = RunService.Heartbeat:Connect(function()
                    if followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart") then
                        local targetHRP = followTarget.Character.HumanoidRootPart

                        -- float 4 studs above the target
                        local desiredCFrame = targetHRP.CFrame * CFrame.new(0, 4, 0)
                        local currentPosition = HRP.Position

                        -- smooth position movement
                        local newPosition = currentPosition:Lerp(desiredCFrame.Position, 0.2)

                        -- face toward the target
                        local direction = (targetHRP.Position - currentPosition).Unit
                        HRP.CFrame = CFrame.new(newPosition, newPosition + direction)

                        -- optional: floating stabilization
                        HRP.Velocity = Vector3.new(0, 2, 0)
                    end
                end)
            end

        elseif msg:sub(1, 3) == ".o " then
            stopAll()
            local plr = getPlayerByName(msg:sub(4))
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

        elseif msg:sub(1, 2) == ".w" then
            local arg = msg:sub(4)
            if arg == "true" then
                stopAll()
                toggleNoclip(true)
                flingConnection = RunService.Heartbeat:Connect(function()
                    HRP.Velocity = Vector3.new(
                        math.random(-1000, 1000),
                        math.random(-1000, 1000),
                        math.random(-1000, 1000)
                    )
                end)
            elseif arg == "false" then
                stopAll()
                toggleNoclip(false)
            end

        elseif msg == ".stop" then
            stopAll()
            toggleNoclip(false)

        elseif msg:sub(1, 3) == ".b " then
            local targetName = msg:sub(4)
            local plr = getPlayerByName(targetName)
            if plr and plr.Character then
                local function safeGetTools(container)
                    local ok, tools = pcall(function()
                        return container:GetChildren()
                    end)
                    return ok and tools or {}
                end

                local tools = {}
                for _, tool in ipairs(safeGetTools(plr.Backpack)) do
                    if tool:IsA("Tool") then
                        table.insert(tools, tool.Name)
                    end
                end
                for _, tool in ipairs(safeGetTools(plr.Character)) do
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
                LocalPlayer:Chat(msgText)
            else
                LocalPlayer:Chat("Could not find player or backpack.")
            end
        end
    end)
end

-- Detect command user
for _, plr in pairs(Players:GetPlayers()) do
    if plr.UserId == TARGET_USER_ID then
        setupSpeaker(plr)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr.UserId == TARGET_USER_ID then
        setupSpeaker(plr)
    end
end)

-- Reapply follow after respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
end)
