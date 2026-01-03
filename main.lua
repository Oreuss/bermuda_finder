--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

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

--// Find Bermuda Zone
local function findBermudaZone()
    local zones = workspace:FindFirstChild("Zones")
	print(zones)
    if not zones then return nil end

    local zone = zones:FindFirstChild("bermuda_zone")
	print(zone)
    if not zone then return nil end

    if zone:IsA("BasePart") then
        return zone.Position
    elseif zone:IsA("Model") then
        if zone.PrimaryPart then
            return zone.PrimaryPart.Position
        else
            return zone:GetPivot().Position
        end
    end

    return nil end

--// Teleport character to zone
local function teleportCharacter(position)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
end

--// Server hop (YOUR logic)
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

--// Main logic
task.spawn(function()
    task.wait(5)
    local zonePosition = findBermudaZone()
    if zonePosition then
        notify("Bermuda Zone Found", "Teleporting to location...")
        teleportCharacter(zonePosition)
    else
        notify("Bermuda Zone", "Not found, server hopping...")
		task.wait(1)
        serverHop()
    end
end)
