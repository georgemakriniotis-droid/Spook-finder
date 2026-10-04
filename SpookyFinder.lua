--========================================================
-- SPOOKY / SINISTER TREE FINDER
--========================================================

-- PUT YOUR RAW GITHUB URL HERE
local SCRIPT_URL = "https://raw.githubusercontent.com/georgemakriniotis-droid/Spook-finder/main/SpookyFinder.lua"

getgenv().webhook = "-"

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceID = game.PlaceId

--========================================================
-- VARIABLES
--========================================================

local foundAnything = ""
local AllIDs = {}

local Tree = nil
local Tree2 = nil

local TeleportCheck = false
local stopped = false

--========================================================
-- UI
--========================================================

pcall(function()
    local old = CoreGui:FindFirstChild("SpookyFinderUI")
    if old then
        old:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpookyFinderUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 110)
Main.Position = UDim2.new(0, 25, 0, 150)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(70, 70, 80)
Stroke.Thickness = 1
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 32)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "Spooky Tree Finder"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 30)
Status.Position = UDim2.new(0, 10, 0, 40)
Status.BackgroundTransparency = 1
Status.Text = "● Script is working"
Status.TextColor3 = Color3.fromRGB(80, 255, 120)
Status.TextSize = 16
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local ServerStatus = Instance.new("TextLabel")
ServerStatus.Size = UDim2.new(1, -20, 0, 25)
ServerStatus.Position = UDim2.new(0, 10, 0, 72)
ServerStatus.BackgroundTransparency = 1
ServerStatus.Text = "Scanning server..."
ServerStatus.TextColor3 = Color3.fromRGB(170, 170, 180)
ServerStatus.TextSize = 12
ServerStatus.Font = Enum.Font.Gotham
ServerStatus.TextXAlignment = Enum.TextXAlignment.Left
ServerStatus.Parent = Main

local function SetStatus(text, good)
    Status.Text = "● " .. text

    if good then
        Status.TextColor3 = Color3.fromRGB(80, 255, 120)
    else
        Status.TextColor3 = Color3.fromRGB(255, 90, 90)
    end
end

--========================================================
-- DRAGGING
--========================================================

local dragging = false
local dragStart = nil
local startPosition = nil

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

    if not dragging then
        return
    end

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

--========================================================
-- SERVER HISTORY
--========================================================

local actualHour = os.date("!*t").hour

local loadedFile = pcall(function()
    AllIDs = HttpService:JSONDecode(
        readfile("NotSameServers.json")
    )
end)

if not loadedFile or type(AllIDs) ~= "table" then
    AllIDs = {actualHour}
end

if tonumber(AllIDs[1]) ~= actualHour then

    AllIDs = {actualHour}

    pcall(function()
        delfile("NotSameServers.json")
    end)
end

local function SaveIDs()

    pcall(function()
        writefile(
            "NotSameServers.json",
            HttpService:JSONEncode(AllIDs)
        )
    end)
end

local function IsAlreadyUsed(serverID)

    for i = 2, #AllIDs do

        if tostring(AllIDs[i]) == tostring(serverID) then
            return true
        end
    end

    return false
end

--========================================================
-- TELEPORT RELAUNCH
--========================================================
-- This is the important fix.
-- The queue is installed BEFORE any teleport happens.

local queueTeleport =
    queue_on_teleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)

if queueTeleport then

    LocalPlayer.OnTeleport:Connect(function(state)

        if state == Enum.TeleportState.Started
            and not TeleportCheck then

            TeleportCheck = true

            local code =
                string.format(
                    "loadstring(game:HttpGet(%q))()",
                    SCRIPT_URL
                )

            pcall(function()
                queueTeleport(code)
            end)
        end
    end)

else

    SetStatus("queue_on_teleport unavailable", false)
    ServerStatus.Text = "Relaunch may not work with this executor."
end

--========================================================
-- FIND TREES
--========================================================

local function FindTrees()

    local normalTree = nil
    local neonTree = nil

    for _, region in ipairs(workspace:GetChildren()) do

        if region.Name == "TreeRegion" then

            for _, tree in ipairs(region:GetChildren()) do

                local treeClass = tree:FindFirstChild("TreeClass")
                local woodSection = tree:FindFirstChild("WoodSection")
                local owner = tree:FindFirstChild("Owner")

                if treeClass
                    and woodSection
                    and owner then

                    -- Only unowned trees
                    if owner.Value == nil then

                        if treeClass.Value == "Spooky" then

                            if not normalTree then
                                normalTree = tree
                            end

                        elseif treeClass.Value == "SpookyNeon" then

                            if not neonTree then
                                neonTree = tree
                            end
                        end
                    end
                end
            end
        end
    end

    return normalTree, neonTree
end

--========================================================
-- SIZE
--========================================================

local function GetTreeSize(tree)

    if not tree then
        return 0
    end

    local wood = tree:FindFirstChild("WoodSection")

    if not wood then
        return 0
    end

    return wood.Size.Y / (
        1 / (
            wood.Size.X
            * wood.Size.Z
        )
    )
end

--========================================================
-- WEBHOOK
--========================================================

local function SendWebhook(tree, treeName)

    if not getgenv().webhook
        or getgenv().webhook == ""
        or getgenv().webhook == "-" then

        return
    end

    local wood = tree:FindFirstChild("WoodSection")

    if not wood then
        return
    end

    local size = GetTreeSize(tree)

    local pos = wood.Position

    local teleportScript =
        string.format(
            "game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(%.3f, %.3f, %.3f)",
            pos.X,
            pos.Y,
            pos.Z
        )

    local joinScript =
        string.format(
            'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)',
            PlaceID,
            game.JobId
        )

    local data = {
        ["content"] = "",
        ["username"] = treeName .. " Finder",

        ["embeds"] = {

            {

                ["title"] = treeName .. " Found!",
                ["description"] =
                    "Size **"
                    .. tostring(size)
                    .. "** "
                    .. treeName,

                ["type"] = "rich",

                ["footer"] = {
                    ["text"] = os.date("%c")
                },

                ["fields"] = {

                    {
                        ["name"] = "**Join Script**",

                        ["value"] =
                            "```lua\n"
                            .. joinScript
                            .. "\n```",

                        ["inline"] = true
                    },

                    {
                        ["name"] = "**Auto Claimer**",

                        ["value"] =
                            '```lua\nloadstring(game:HttpGet("https://pastebin.com/raw/uaK9gH1s"))()\n```',

                        ["inline"] = false
                    },

                    {
                        ["name"] = "**Teleport Script**",

                        ["value"] =
                            "```lua\n"
                            .. teleportScript
                            .. "\n```",

                        ["inline"] = false
                    }
                }
            }
        }
    }

    local requestFunction =
        http_request
        or request
        or (syn and syn.request)
        or HttpPost

    if not requestFunction then
        return
    end

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

--========================================================
-- GET SERVER
--========================================================

local function GetServer()

    local Site

    if foundAnything == "" then

        Site = HttpService:JSONDecode(

            game:HttpGet(
                "https://games.roblox.com/v1/games/"
                .. PlaceID
                .. "/servers/Public?sortOrder=Asc&limit=100"
            )
        )

    else

        Site = HttpService:JSONDecode(

            game:HttpGet(
                "https://games.roblox.com/v1/games/"
                .. PlaceID
                .. "/servers/Public?sortOrder=Asc&limit=100&cursor="
                .. foundAnything
            )
        )
    end

    if Site.nextPageCursor
        and Site.nextPageCursor ~= "null" then

        foundAnything = Site.nextPageCursor

    else

        foundAnything = ""
    end

    for _, server in ipairs(Site.data or {}) do

        local ID = tostring(server.id)

        if tonumber(server.maxPlayers)
            > tonumber(server.playing) then

            if not IsAlreadyUsed(ID) then
                return ID
            end
        end
    end

    return nil
end

--========================================================
-- START
--========================================================

repeat
    task.wait()
until game:IsLoaded()

task.wait(2)

SetStatus("Script is working", true)
ServerStatus.Text = "Scanning current server..."

--========================================================
-- MAIN LOOP
--========================================================

while not stopped do

    --====================================================
    -- SCAN CURRENT SERVER
    --====================================================

    Tree, Tree2 = FindTrees()

    --====================================================
    -- SINISTER / NEON FOUND
    --====================================================

    if Tree2 ~= nil then

        stopped = true

        SetStatus(
            "SINISTER WOOD FOUND!",
            true
        )

        ServerStatus.Text =
            "Server hopping stopped."

        SendWebhook(
            Tree2,
            "Sinister Wood"
        )

        break
    end

    --====================================================
    -- NORMAL SPOOK FOUND
    --====================================================

    if Tree ~= nil then

        stopped = true

        SetStatus(
            "SPOOK WOOD FOUND!",
            true
        )

        ServerStatus.Text =
            "Server hopping stopped."

        SendWebhook(
            Tree,
            "Spook Wood"
        )

        break
    end

    --====================================================
    -- NOTHING FOUND
    --====================================================

    SetStatus(
        "Script is working",
        true
    )

    ServerStatus.Text =
        "No tree found • Finding server..."

    local ServerID = nil

    -- Try server pages until we find one
    repeat

        local success, result = pcall(function()
            return GetServer()
        end)

        if success then
            ServerID = result
        end

        if not ServerID then

            foundAnything = ""

            ServerStatus.Text =
                "Refreshing server list..."

            task.wait(1)
        end

    until ServerID ~= nil or stopped

    --====================================================
    -- STOP IF SOMETHING CHANGED
    --====================================================

    if stopped then
        break
    end

    --====================================================
    -- SAVE SERVER
    --====================================================

    table.insert(
        AllIDs,
        ServerID
    )

    SaveIDs()

    --====================================================
    -- TELEPORT
    --====================================================
    -- OnTeleport above will queue this script BEFORE
    -- the teleport actually happens.

    SetStatus(
        "Server hopping...",
        true
    )

    ServerStatus.Text =
        "Teleporting to new server..."

    pcall(function()

        TeleportService:TeleportToPlaceInstance(
            PlaceID,
            ServerID,
            LocalPlayer
        )

    end)

    -- The current script will end when teleport succeeds.
    break
end
