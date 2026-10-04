--========================================================
-- SPOOKY / SINISTER TREE FINDER
-- CENTERED UI + TREE DETAILS + TELEPORT BUTTON
--========================================================

----------------------------------------------------------
-- CONFIG
----------------------------------------------------------

local SCRIPT_URL =
    "https://raw.githubusercontent.com/georgemakriniotis-droid/Spook-finder/refs/heads/main/SpookyFinder.lua"

getgenv().webhook = "-"

----------------------------------------------------------
-- SERVICES
----------------------------------------------------------

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceID = game.PlaceId

----------------------------------------------------------
-- VARIABLES
----------------------------------------------------------

local foundAnything = ""
local AllIDs = {}

local stopped = false
local foundTree = nil
local foundTreeName = nil
local foundTreeClass = nil

----------------------------------------------------------
-- UI CLEANUP
----------------------------------------------------------

pcall(function()
    local old = CoreGui:FindFirstChild("SpookyFinderUI")

    if old then
        old:Destroy()
    end
end)

----------------------------------------------------------
-- CREATE UI
----------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpookyFinderUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(380, 270)

-- Start in the middle of the screen
Main.Position = UDim2.new(0.5, -190, 0.5, -135)

Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(65, 65, 75)
Stroke.Thickness = 1
Stroke.Parent = Main

----------------------------------------------------------
-- TITLE / DRAG HANDLE
----------------------------------------------------------

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 32)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "Spooky Tree Finder"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = Main

----------------------------------------------------------
-- STATUS
----------------------------------------------------------

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.fromOffset(10, 38)
Status.BackgroundTransparency = 1
Status.Text = "● Script is working"
Status.TextColor3 = Color3.fromRGB(80, 255, 120)
Status.TextSize = 15
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local ServerStatus = Instance.new("TextLabel")
ServerStatus.Name = "ServerStatus"
ServerStatus.Size = UDim2.new(1, -20, 0, 23)
ServerStatus.Position = UDim2.fromOffset(10, 64)
ServerStatus.BackgroundTransparency = 1
ServerStatus.Text = "Scanning current server..."
ServerStatus.TextColor3 = Color3.fromRGB(175, 175, 185)
ServerStatus.TextSize = 12
ServerStatus.Font = Enum.Font.Gotham
ServerStatus.TextXAlignment = Enum.TextXAlignment.Left
ServerStatus.Parent = Main

----------------------------------------------------------
-- TREE INFORMATION
----------------------------------------------------------

local TreeInfo = Instance.new("TextLabel")
TreeInfo.Name = "TreeInfo"
TreeInfo.Size = UDim2.new(1, -20, 0, 112)
TreeInfo.Position = UDim2.fromOffset(10, 91)
TreeInfo.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
TreeInfo.BorderSizePixel = 0
TreeInfo.Text = "No target tree found yet.\nThe script will continue searching."
TreeInfo.TextColor3 = Color3.fromRGB(220, 220, 230)
TreeInfo.TextSize = 13
TreeInfo.Font = Enum.Font.Gotham
TreeInfo.TextXAlignment = Enum.TextXAlignment.Left
TreeInfo.TextYAlignment = Enum.TextYAlignment.Top
TreeInfo.TextWrapped = true
TreeInfo.Parent = Main

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 7)
InfoCorner.Parent = TreeInfo

local InfoPadding = Instance.new("UIPadding")
InfoPadding.PaddingLeft = UDim.new(0, 9)
InfoPadding.PaddingRight = UDim.new(0, 7)
InfoPadding.PaddingTop = UDim.new(0, 7)
InfoPadding.Parent = TreeInfo

----------------------------------------------------------
-- TELEPORT BUTTON
----------------------------------------------------------

local TeleportButton = Instance.new("TextButton")
TeleportButton.Name = "TeleportToTree"
TeleportButton.Size = UDim2.new(1, -20, 0, 42)
TeleportButton.Position = UDim2.fromOffset(10, 214)
TeleportButton.BackgroundColor3 = Color3.fromRGB(60, 110, 75)
TeleportButton.BorderSizePixel = 0
TeleportButton.Text = "TELEPORT TO TREE"
TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportButton.TextSize = 14
TeleportButton.Font = Enum.Font.GothamBold
TeleportButton.Visible = false
TeleportButton.Parent = Main

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = TeleportButton

----------------------------------------------------------
-- UI HELPER FUNCTIONS
----------------------------------------------------------

local function SetStatus(message, good)
    Status.Text = "● " .. message

    Status.TextColor3 = good
        and Color3.fromRGB(80, 255, 120)
        or Color3.fromRGB(255, 90, 90)
end

local function SetServerStatus(message)
    ServerStatus.Text = message
end

----------------------------------------------------------
-- DRAGGABLE UI
-- Drag the window using its title bar.
----------------------------------------------------------

local dragging = false
local dragStart = nil
local startPosition = nil

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
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

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

----------------------------------------------------------
-- SERVER HISTORY
----------------------------------------------------------

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

-- Avoid immediately selecting the server we are currently in.
if game.JobId ~= "" and not IsServerUsed(game.JobId) then
    table.insert(AllIDs, game.JobId)
    SaveIDs()
end

----------------------------------------------------------
-- TREE SIZE
-- Uses the same X * Y * Z size calculation.
----------------------------------------------------------

local function GetTreeSize(tree)
    if not tree then
        return 0
    end

    local wood = tree:FindFirstChild("WoodSection")

    if not wood then
        return 0
    end

    return wood.Size.X * wood.Size.Y * wood.Size.Z
end

----------------------------------------------------------
-- DISPLAY FOUND TREE DETAILS
----------------------------------------------------------

local function ShowFoundTree(tree, displayName)
    local wood = tree and tree:FindFirstChild("WoodSection")

    if not wood then
        return
    end

    foundTree = tree
    foundTreeName = displayName

    local treeClass = tree:FindFirstChild("TreeClass")
    foundTreeClass = treeClass and treeClass.Value or "Unknown"

    local size = GetTreeSize(tree)
    local dimensions = wood.Size
    local position = wood.Position

    TreeInfo.Text = string.format(
        "TREE FOUND: %s\n" ..
        "Type: %s\n" ..
        "Size (X × Y × Z): %.2f\n" ..
        "Dimensions: %.2f × %.2f × %.2f\n" ..
        "Position: %.1f, %.1f, %.1f",
        displayName,
        tostring(foundTreeClass),
        size,
        dimensions.X,
        dimensions.Y,
        dimensions.Z,
        position.X,
        position.Y,
        position.Z
    )

    TreeInfo.TextColor3 = Color3.fromRGB(255, 240, 185)

    TeleportButton.Visible = true
    TeleportButton.Text = "TELEPORT TO TREE"
    TeleportButton.BackgroundColor3 = Color3.fromRGB(60, 135, 80)
end

----------------------------------------------------------
-- TELEPORT TO FOUND TREE
----------------------------------------------------------

TeleportButton.Activated:Connect(function()
    if not foundTree or not foundTree.Parent then
        SetStatus("Tree is no longer available!", false)
        SetServerStatus("The saved tree reference is invalid.")
        TeleportButton.Visible = false
        return
    end

    local wood = foundTree:FindFirstChild("WoodSection")

    if not wood then
        SetStatus("WoodSection not found!", false)
        return
    end

    local character = LocalPlayer.Character

    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end

    local root = character:FindFirstChild("HumanoidRootPart")
        or character:WaitForChild("HumanoidRootPart", 5)

    if not root then
        SetStatus("Character root not found!", false)
        return
    end

    -- Move to a point just above the tree's WoodSection.
    local targetPosition = wood.Position
        + Vector3.new(0, wood.Size.Y / 2 + 5, 0)

    local ok, err = pcall(function()
        root.CFrame = CFrame.new(targetPosition)
    end)

    if ok then
        SetStatus("Teleported to " .. tostring(foundTreeName), true)
        SetServerStatus(string.format(
            "Location: %.1f, %.1f, %.1f",
            targetPosition.X,
            targetPosition.Y,
            targetPosition.Z
        ))
    else
        SetStatus("Teleport failed!", false)
        SetServerStatus(tostring(err))
    end
end)

----------------------------------------------------------
-- TELEPORT QUEUE
-- Uses the one-argument queue method confirmed working
-- by your first test.
----------------------------------------------------------

local queueTeleport =
    queue_on_teleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)

local function QueueRelaunch()
    if not SCRIPT_URL
        or SCRIPT_URL == ""
        or SCRIPT_URL == "-"
        or string.find(SCRIPT_URL, "YOUR_USERNAME", 1, true) then

        SetStatus("Script URL is missing!", false)
        SetServerStatus("Set SCRIPT_URL to your real raw GitHub URL.")
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

    local success, err = pcall(function()
        queueTeleport(source)
    end)

    if not success then
        SetStatus("Queue failed!", false)
        SetServerStatus(tostring(err))
        warn("[SpookyFinder] Queue error:", err)
        return false
    end

    SetStatus("Script queued", true)
    SetServerStatus("Relaunch prepared for the next server.")

    return true
end

----------------------------------------------------------
-- FIND TREES IN CURRENT SERVER
----------------------------------------------------------

local function FindTrees()
    local normalTree = nil
    local neonTree = nil

    for _, region in ipairs(workspace:GetChildren()) do
        if region.Name == "TreeRegion" then
            for _, tree in ipairs(region:GetChildren()) do

                local treeClass = tree:FindFirstChild("TreeClass")
                local woodSection = tree:FindFirstChild("WoodSection")
                local owner = tree:FindFirstChild("Owner")

                if treeClass and woodSection and owner then
                    -- Only unclaimed trees.
                    if owner.Value == nil then

                        if treeClass.Value == "Spooky" then
                            normalTree = normalTree or tree

                        elseif treeClass.Value == "SpookyNeon" then
                            neonTree = neonTree or tree
                        end
                    end
                end
            end
        end
    end

    return normalTree, neonTree
end

----------------------------------------------------------
-- WEBHOOK
----------------------------------------------------------

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

    local teleportScript = string.format(
        "game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(%.3f, %.3f, %.3f)",
        pos.X,
        pos.Y,
        pos.Z
    )

    local joinScript = string.format(
        'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)',
        PlaceID,
        game.JobId
    )

    local data = {
        content = "",
        username = treeName .. " Finder",

        embeds = {{
            title = treeName .. " Found!",
            description = "Size **" .. tostring(size) .. "** " .. treeName,

            footer = {
                text = os.date("%c")
            },

            fields = {
                {
                    name = "**Join Script**",
                    value = "```lua\n" .. joinScript .. "\n```",
                    inline = false
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

    if not requestFunction then
        warn("[SpookyFinder] No HTTP request function found.")
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

----------------------------------------------------------
-- GET NEXT SERVER
----------------------------------------------------------

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

        local success, site = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if not success or not site or not site.data then
            return nil, "request_error"
        end

        for _, server in ipairs(site.data) do
            local id = tostring(server.id)

            if tonumber(server.playing) < tonumber(server.maxPlayers)
                and not IsServerUsed(id) then

                foundAnything = site.nextPageCursor or ""

                if foundAnything == "null" then
                    foundAnything = ""
                end

                return id
            end
        end

        local nextCursor = site.nextPageCursor

        if nextCursor and nextCursor ~= "" and nextCursor ~= "null" then
            foundAnything = nextCursor
        else
            foundAnything = ""
            return nil, "exhausted"
        end
    end
end

----------------------------------------------------------
-- WAIT FOR GAME
----------------------------------------------------------

repeat
    task.wait()
until game:IsLoaded()

task.wait(2)

----------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------

SetStatus("Script is working", true)
SetServerStatus("Scanning current server...")

while not stopped do

    ------------------------------------------------------
    -- SCAN CURRENT SERVER
    ------------------------------------------------------

    local normalTree, neonTree = FindTrees()

    ------------------------------------------------------
    -- SINISTER / NEON FOUND
    ------------------------------------------------------

    if neonTree then
        stopped = true

        ShowFoundTree(neonTree, "Sinister Wood")

        SetStatus("SINISTER WOOD FOUND!", true)
        SetServerStatus("Server hopping stopped. Use the button to teleport.")

        SendWebhook(neonTree, "Sinister Wood")

        break
    end

    ------------------------------------------------------
    -- NORMAL SPOOK FOUND
    ------------------------------------------------------

    if normalTree then
        stopped = true

        ShowFoundTree(normalTree, "Spook Wood")

        SetStatus("SPOOK WOOD FOUND!", true)
        SetServerStatus("Server hopping stopped. Use the button to teleport.")

        SendWebhook(normalTree, "Spook Wood")

        break
    end

    ------------------------------------------------------
    -- NO TREE: FIND ANOTHER SERVER
    ------------------------------------------------------

    SetStatus("Script is working", true)
    SetServerStatus("No tree found • Finding server...")

    local serverID
    local findError

    while not serverID and not stopped do
        serverID, findError = GetNextServer()

        if not serverID then
            if findError == "exhausted" then
                -- Start another search cycle without immediately
                -- returning to the current server.
                AllIDs = { actualHour }

                if game.JobId ~= "" then
                    table.insert(AllIDs, game.JobId)
                end

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

    if stopped then
        break
    end

    ------------------------------------------------------
    -- SAVE SERVER
    ------------------------------------------------------

    table.insert(AllIDs, serverID)
    SaveIDs()

    ------------------------------------------------------
    -- QUEUE BEFORE TELEPORTING
    ------------------------------------------------------

    SetStatus("Preparing server hop...", true)
    SetServerStatus("Queueing relaunch before teleport...")

    if not QueueRelaunch() then
        -- Do not hop if the relaunch could not be queued.
        break
    end

    task.wait(0.5)

    ------------------------------------------------------
    -- TELEPORT
    ------------------------------------------------------

    SetStatus("Server hopping...", true)
    SetServerStatus("Teleporting to the next server...")

    local teleportOK, teleportError = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            PlaceID,
            serverID,
            LocalPlayer
        )
    end)

    if teleportOK then
        -- The queued script is expected to run in the new server.
        break
    end

    SetStatus("Teleport failed!", false)
    SetServerStatus(tostring(teleportError))

    warn("[SpookyFinder] Teleport error:", teleportError)

    task.wait(2)
end
