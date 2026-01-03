--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--// Queue on teleport (executor compatibility)
local queueteleport = missing(
    "function",
    queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
)

--// Notification helper
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 6
        })
    end)
end

--// Check for Bermuda Zone
local function findBermudaZone()
    local zones = workspace:FindFirstChild("Zones")
    if not zones then return nil end

    local zone = zones:FindFirstChild("bermuda_zone")
    if not zone then return nil end

    if zone:IsA("BasePart") then
        return zone.Position
    elseif zone:IsA("Model") and zone.PrimaryPart then
        return zone.PrimaryPart.Position
    end

    return nil
end

--// Teleport character to position
local function teleportCharacter(position)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
end

--// Server hop logic
local function serverHop()
    local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local response = HttpService:JSONDecode(game:HttpGet(url))

    for _, server in ipairs(response.data) do
        if server.playing < server.maxPlayers then
            queueteleport([[
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Oreuss/bermuda_finder/refs/heads/main/main.lua"))()
            ]])
            TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            return
        end
    end

    warn("No available servers found, retrying...")
end

--// Main logic
task.spawn(function()
    task.wait(2)

    local zonePosition = findBermudaZone()
    if zonePosition then
        notify("Bermuda Zone Found", "Teleporting to location...")
        teleportCharacter(zonePosition)
    else
        notify("Bermuda Zone Not Found", "Server hopping...")
        serverHop()
    end
end)
