-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- Missing helper
function missing(t, f, fallback)
    if type(f) == t then
        return f
    end
    return fallback
end

-- Queue on teleport
local queueteleport = missing(
    "function",
    queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
)

-- Notification helper (with buttons)
local function notifyWithButton(title, text, buttonText, callback)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 10,
            Buttons = {
                {
                    Text = buttonText,
                    Callback = callback
                }
            }
        })
    end)
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 6
        })
    end)
end

-- Find Bermuda VFX
local function findBermudaVFX()
    local vfx = workspace:FindFirstChild("VFX")
    if not vfx then return nil end

    local bermuda = vfx:FindFirstChild("bermudaVFX")
    if not bermuda then return nil end

    if bermuda:IsA("BasePart") then
        return bermuda.Position
    elseif bermuda:IsA("Model") then
        if bermuda.PrimaryPart then
            return bermuda.PrimaryPart.Position
        else
            return bermuda:GetPivot().Position
        end
    end

    return nil
end

-- Teleport character
local function teleportCharacter(position)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
end

-- Server hop (unchanged logic)
local function serverHop()
    local servers = {}
    local req = game:HttpGet(
        "https://games.roblox.com/v1/games/"
        .. PlaceId
        .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
    )

    local body = HttpService:JSONDecode(req)

    if body and body.data then
        for _, v in next, body.data do
            if type(v) == "table"
                and tonumber(v.playing)
                and tonumber(v.maxPlayers)
                and v.playing < v.maxPlayers
                and v.id ~= JobId
            then
                table.insert(servers, v.id)
            end
        end
    end

    if #servers > 0 then
        queueteleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Oreuss/bermuda_finder/refs/heads/main/main.lua"))()
        ]])
        TeleportService:TeleportToPlaceInstance(
            PlaceId,
            servers[math.random(1, #servers)],
            LocalPlayer
        )
    else
        notify("Serverhop", "Couldn't find a server.")
    end
end

-- Main logic
task.spawn(function()
    -- Wait for VFX folder
    local vfx = workspace:WaitForChild("VFX")

    local additionsStarted = false
    local found = false
    local startTime = 0

    local connection
    connection = vfx.ChildAdded:Connect(function()
        if not additionsStarted then
            additionsStarted = true
            startTime = tick()
        end

        local pos = findBermudaVFX()
        if pos then
            found = true
            connection:Disconnect()

            notifyWithButton(
                "Bermuda VFX Found",
                "Bermuda VFX detected in this server.",
                "Teleport",
                function()
                    teleportCharacter(pos)
                end
            )
        end
    end)

    -- Safety timeout after additions start
    while true do
        task.wait(0.1)

        if additionsStarted and not found then
            if tick() - startTime >= 2 then
                connection:Disconnect()
                notify("Bermuda VFX", "Not found, server hopping...")
                task.wait(0.5)
                serverHop()
                break
            end
        end
    end
end)
