--========================================================
-- SPOOKY / SINISTER TREE FINDER
--========================================================

---------------- CONFIG ----------------

local SCRIPT_URL =
    "https://raw.githubusercontent.com/georgemakriniotis-droid/Spook-finder/refs/heads/main/SpookyFinder.lua"

getgenv().webhook = "-"

---------------- SERVICES ----------------

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceID = game.PlaceId

---------------- VARIABLES ----------------

local foundAnything = ""
local AllIDs = {}
local stopped = false

---------------- UI ----------------

pcall(function()
    local old = CoreGui:FindFirstChild("SpookyFinderUI")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpookyFinderUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(310, 110)
Main.Position = UDim2.fromOffset(30, 150)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(65, 65, 75)
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 32)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "Spooky Tree Finder"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 30)
Status.Position = UDim2.fromOffset(10, 40)
Status.BackgroundTransparency = 1
Status.Text = "● Script is working"
Status.TextColor3 = Color3.fromRGB(80, 255, 120)
Status.TextSize = 16
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local ServerStatus = Instance.new("TextLabel")
ServerStatus.Size = UDim2.new(1, -20, 0, 25)
ServerStatus.Position = UDim2.fromOffset(10, 73)
ServerStatus.BackgroundTransparency = 1
ServerStatus.Text = "Starting..."
ServerStatus.TextColor3 = Color3.fromRGB(170, 170, 180)
ServerStatus.TextSize = 12
ServerStatus.Font = Enum.Font.Gotham
ServerStatus.TextXAlignment = Enum.TextXAlignment.Left
ServerStatus.Parent = Main

local function SetStatus(message, good)
    Status.Text = "● " .. message
    Status.TextColor3 = good
        and Color3.fromRGB(80, 255, 120)
        or Color3.fromRGB(255, 90, 90)
end

local function SetServerStatus(message)
    ServerStatus.Text = message
end

---------------- DRAGGING ----------------

local dragging = false
local dragStart
local startPosition

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

Main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

---------------- SERVER HISTORY ----------------

local actualHour = os.date("!*t").hour

local loadedFile, fileData = pcall(function()
    return HttpService:JSONDecode(
        readfile("NotSameServers.json")
    )
end)

if loadedFile
    and type(fileData) == "table"
    and tonumber(fileData[1]) == actualHour then

    AllIDs = fileData
else
    AllIDs = { actualHour }
end

local function SaveIDs()
    pcall(function()
        writefile(
            "NotSameServers.json",
            HttpService:JSONEncode(AllIDs)
        )
    end)
end

local function IsServerUsed(serverID)
    for i = 2, #AllIDs do
        if tostring(AllIDs[i]) == tostring(serverID) then
            return true
        end
    end

    return false
end

---------------- QUEUE RELAUNCH ----------------
-- Uses the exact one-argument queue method from Test 1.
-- Called immediately BEFORE the teleport.

local queueTeleport =
    queue_on_teleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)

local function QueueRelaunch()

    if not SCRIPT_URL
        or SCRIPT_URL == ""
        or SCRIPT_URL == "-"
        or SCRIPT_URL == "PASTE_YOUR_RAW_GITHUB_URL_HERE" then

        SetStatus("Script URL is missing!", false)
        SetServerStatus("Set the raw GitHub URL at the top.")
        return false
    end

    if not queueTeleport then
        SetStatus("Queue function unavailable!", false)
        SetServerStatus("queue_on_teleport was not found.")
        return false
    end

    local source = string.format(
        'loadstring(game:HttpGet(%q))()',
        SCRIPT_URL
    )

    local ok, err = pcall(function()
        queueTeleport(source)
    end)

    if not ok then
        SetStatus("Queue failed!", false)
        SetServerStatus(tostring(err))
        warn("[SpookyFinder] Queue error:", err)
        return false
    end

    SetStatus("Script queued", true)
    SetServerStatus("Relaunch prepared.")
    return true
end

---------------- FIND TREES ----------------

local function FindTrees()

    local normalTree = nil
    local neonTree = nil

    for _, region in ipairs(workspace:GetChildren()) do
        if region.Name == "TreeRegion" then

            for _, tree in ipairs(region:GetChildren()) do

                local treeClass = tree:FindFirstChild("TreeClass")
                local woodSection = tree:FindFirstChild("WoodSection")
                local owner = tree:FindFirstChild("Owner")

                if treeClass and woodSection and owner
                    and owner.Value == nil then

                    if treeClass.Value == "Spooky" then
                        normalTree = normalTree or tree

                    elseif treeClass.Value == "SpookyNeon" then
                        neonTree = neonTree or tree
                    end
                end
            end
        end
    end

    return normalTree, neonTree
end

---------------- TREE SIZE ----------------

local function GetTreeSize(tree)
    local wood = tree and tree:FindFirstChild("WoodSection")
    if not wood then return 0 end

    return wood.Size.X * wood.Size.Y * wood.Size.Z
end

---------------- WEBHOOK ----------------

local function SendWebhook(tree, treeName)

    if not getgenv().webhook
        or getgenv().webhook == ""
        or getgenv().webhook == "-" then
        return
    end

    local wood = tree:FindFirstChild("WoodSection")
    if not wood then return end

    local pos = wood.Position

    local teleportScript = string.format(
        "game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(%.3f, %.3f, %.3f)",
        pos.X, pos.Y, pos.Z
    )

    local joinScript = string.format(
        'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)',
        PlaceID, game.JobId
    )

    local data = {
        content = "",
        username = treeName .. " Finder",
        embeds = {{
            title = treeName .. " Found!",
            description = "Size **" .. tostring(GetTreeSize(tree)) ..
                "** " .. treeName,
            type = "rich",
            footer = { text = os.date("%c") },
            fields = {
                {
                    name = "**Join script**",
                    value = "```lua\n" .. joinScript .. "\n```",
                    inline = true
                },
                {
                    name = "**Teleport Script**",
                    value = "```lua\n" .. teleportScript .. "\n```",
                    inline = false
                }
            }
        }}
    }

    local requestFunction =
        http_request
        or request
        or (syn and syn.request)
        or HttpPost

    if not requestFunction then return end

    pcall(function()
        requestFunction({
            Url = getgenv().webhook,
            Body = HttpService:JSONEncode(data),
            Method = "POST",
            Headers = {
                ["content-type"] = "application/json"
            }
        })
    end)
end

---------------- GET NEXT SERVER ----------------
-- Walks through server-list pages instead of repeatedly
-- starting over on the first page.

local function GetNextServer()

    while true do

        local url

        if foundAnything == "" then
            url =
                "https://games.roblox.com/v1/games/"
                .. PlaceID
                .. "/servers/Public?sortOrder=Asc&limit=100"
        else
            url =
                "https://games.roblox.com/v1/games/"
                .. PlaceID
                .. "/servers/Public?sortOrder=Asc&limit=100&cursor="
                .. foundAnything
        end

        local ok, site = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if not ok or not site or not site.data then
            return nil, "request_error"
        end

        for _, server in ipairs(site.data) do

            local id = tostring(server.id)

            if tonumber(server.playing)
                < tonumber(server.maxPlayers)
                and not IsServerUsed(id) then

                foundAnything = site.nextPageCursor or ""
                if foundAnything == "null" then
                    foundAnything = ""
                end

                return id
            end
        end

        local cursor = site.nextPageCursor

        if cursor and cursor ~= "" and cursor ~= "null" then
            foundAnything = cursor
        else
            foundAnything = ""
            return nil, "exhausted"
        end
    end
end

---------------- WAIT FOR GAME ----------------

repeat
    task.wait()
until game:IsLoaded()

task.wait(2)

---------------- MAIN LOOP ----------------

while not stopped do

    SetStatus("Script is working", true)
    SetServerStatus("Scanning current server...")

    local Tree, Tree2 = FindTrees()

    -- Give Sinister/Neon priority
    if Tree2 then
        stopped = true
        SetStatus("SINISTER WOOD FOUND!", true)
        SetServerStatus("Server hopping stopped.")
        SendWebhook(Tree2, "Sinister Wood")
        break
    end

    if Tree then
        stopped = true
        SetStatus("SPOOK WOOD FOUND!", true)
        SetServerStatus("Server hopping stopped.")
        SendWebhook(Tree, "Spook Wood")
        break
    end

    ---------------- NO TREE: FIND SERVER ----------------

    SetServerStatus("No tree found • Finding server...")

    local serverID
    local findError

    while not serverID and not stopped do

        serverID, findError = GetNextServer()

        if not serverID then

            if findError == "exhausted" then
                -- We've reached the end of the server list.
                -- Clear history to allow another search cycle.
                AllIDs = { actualHour }
                SaveIDs()
                foundAnything = ""
                SetServerStatus("Refreshing server list...")
                task.wait(1)

            else
                SetServerStatus("Server list request failed; retrying...")
                task.wait(3)
            end
        end
    end

    if stopped then break end

    table.insert(AllIDs, serverID)
    SaveIDs()

    ---------------- QUEUE FIRST, THEN HOP ----------------

    SetStatus("Preparing server hop...", true)
    SetServerStatus("Queueing script before teleport...")

    if not QueueRelaunch() then
        -- Do not teleport if the relaunch wasn't queued.
        break
    end

    task.wait(0.5)

    SetStatus("Server hopping...", true)
    SetServerStatus("Teleporting to the next server...")

    local teleportStarted = false

    -- Track the teleport only to detect whether it starts.
    -- Queueing itself is done above, before the teleport call.
    local connection = LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started then
            teleportStarted = true
        end
    end)

    local teleportOK, teleportError = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            PlaceID,
            serverID,
            LocalPlayer
        )
    end)

    if teleportOK then
        -- Wait briefly for the teleport to begin.
        for _ = 1, 50 do
            if teleportStarted then break end
            task.wait(0.1)
        end
    end

    connection:Disconnect()

    if teleportStarted then
        -- The queued copy should run in the destination server.
        break
    end

    SetStatus("Teleport did not start", false)
    SetServerStatus(
        teleportOK and "No teleport event detected; retrying."
        or tostring(teleportError)
    )

    task.wait(2)
end
