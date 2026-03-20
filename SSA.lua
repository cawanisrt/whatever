local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

-- GANTI LINK DI BAWAH INI DENGAN LINK RAW GITHUB KAMU!
local GITHUB_COMMAND_URL = "https://raw.githubusercontent.com/cawanisrt/whatever/refs/heads/main/command.txt"

local followConnection, orbitConnection, flingConnection, noclipConnection
local orbitAngle = 0
local followTarget = nil
local lastCommand = ""

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
            if Character then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = nil
    end
end

local function getPlayerByName(name)
    name = name:gsub("%s+", "") -- hapus spasi
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Name:lower():sub(1, #name) == name:lower() then
            return plr
        end
    end
    return nil
end

-- FUNGSI UTAMA EKSEKUSI COMMAND
local function executeCommand(msg)
    msg = msg:lower()
    print("Mengeksekusi: " .. msg)

    if msg:sub(1, 3) == ".s " then
        stopAll()
        local plr = getPlayerByName(msg:sub(4))
        if plr then
            followTarget = plr
            toggleNoclip(true)
            followConnection = RunService.Heartbeat:Connect(function()
                if followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = followTarget.Character.HumanoidRootPart
                    local desiredCFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)
                    HRP.CFrame = HRP.CFrame:Lerp(desiredCFrame, 0.2)
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
                    orbitAngle = orbitAngle + dt * 3
                    local offset = CFrame.new(math.cos(orbitAngle) * 7, 2, math.sin(orbitAngle) * 7)
                    HRP.CFrame = plr.Character.HumanoidRootPart.CFrame * offset
                end
            end)
        end

    elseif msg:sub(1, 2) == ".w" then
        if msg:find("true") then
            stopAll()
            toggleNoclip(true)
            flingConnection = RunService.Heartbeat:Connect(function()
                HRP.Velocity = Vector3.new(9999, 9999, 9999) -- Kecepatan fling
                HRP.RotVelocity = Vector3.new(9999, 9999, 9999)
            end)
        else
            stopAll()
            toggleNoclip(false)
        end

    elseif msg == ".stop" then
        stopAll()
        toggleNoclip(false)
    end
end

-- LOOPING CEK GITHUB TIAP 3 DETIK
task.spawn(function()
    print("Bot Remote Control Aktif...")
    while task.wait(3) do
        local success, content = pcall(function()
            -- Tambah parameter acak (?t=...) biar nggak kena cache (data lama)
            return HttpService:GetAsync(GITHUB_COMMAND_URL .. "?t=" .. os.time())
        end)

        if success and content ~= lastCommand and content ~= "" then
            lastCommand = content
            executeCommand(content)
        elseif not success then
            warn("Gagal mengambil data dari GitHub. Pastikan Link Raw benar!")
        end
    end
end)
