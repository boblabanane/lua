-- Made by: unauth0rised (on discord)
-- Requiring the client item module which returns a table that contains the input function which is what we're going to be hooking onto
local clientItemModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)

-- Accessing the input function
local inputFunc = clientItemModule.Input

-- Hooking onto the input function and replacing it with our own function that contains a varag
-- A varag is a variable argument its used to represent an infinite amount of arguments
local old; old = hookfunction(inputFunc, function(...)
    -- Packing the varag into a table so we're able to index it
    local args = {...}

    -- Checking if the first arg of the input function is a table
    if type(args[1]) == "table" then
       
        -- Accessing the info table which contains gun properties, such as its recoil, spread, bullet speed and shot cooldown
        args[1].Info.ShootRecoil = 0
        args[1].Info.ShootSpread = 0
        args[1].Info.ProjectileSpeed = 99999999
        args[1].Info.QuickShotCooldown = 0
    end

    -- Returning the original input function so we don't overwrite it which can cause the game to crash
    return old(...)
end)
local replicated_storage = game.GetService(game, "ReplicatedStorage");
local players = game.GetService(game, "Players");

local camera = workspace.CurrentCamera;
local utility = require(replicated_storage.Modules.Utility);

local get_players = function() -- this is dumb asf, feel free to modify.
    local entities = {};

    for _, child in workspace.GetChildren(workspace) do
        if child.FindFirstChildOfClass(child, "Humanoid") then
            table.insert(entities, child);
        elseif child.Name == "HurtEffect" then
            for _, hurt_player in child.GetChildren(child) do
                if (hurt_player.ClassName ~= "Highlight") then
                    table.insert(entities, hurt_player);
                end
            end
        end
    end
    return entities
end
local get_closest_player = function()
    local closest, closest_distance = nil, math.huge;
    local character = players.LocalPlayer.Character;

    if (character == nil) then
        return;
    end

    for _, player in get_players() do
        if (player == players.LocalPlayer) then
            continue;
        end

        if (not player:FindFirstChild("HumanoidRootPart")) then
            continue;
        end

        local position, on_screen = camera.WorldToViewportPoint(camera, player.HumanoidRootPart.Position);

        if (on_screen == false) then
            continue;
        end

        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2);
        local distance = (center - Vector2.new(position.X, position.Y)).Magnitude;

        if (distance > closest_distance) then
            continue;
        end

        closest = player;
        closest_distance = distance;
    end
    return closest;
end

local old = utility.Raycast; utility.Raycast = function(...)
    local arguments = {...};

    if (#arguments > 0 and arguments[4] == 999) then
        local closest = get_closest_player();

        if (closest) then
            arguments[3] = closest.Head.Position;
        end
    end
    return old(table.unpack(arguments));
end
--// super trash RIVALS esp 

local settings = {
    enabled = true,
    teamCheck = false,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local wtf = {}

function esp(player)
    if not settings.enabled then return end
    if settings.teamCheck and player.Team == Players.LocalPlayer.Team then return end
    if player == Players.LocalPlayer then return end

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local Box = Drawing.new("Square")
    Box.Color = Color3.new(1, 0, 0)
    Box.Thickness = 2
    Box.Transparency = 1
    Box.Filled = false

    local tracer = Drawing.new("Line")
    tracer.Color = Color3.new(1, 0, 0)
    tracer.Thickness = 1
    tracer.Transparency = 1

    local name = Drawing.new("Text")
    name.Text = player.Name
    name.Color = Color3.new(1, 1, 1)
    name.Size = 20
    name.Center = true
    name.Outline = true
    name.Transparency = 1

    wtf[player] = {box = Box, tracer = tracer, name = name}

    local function loop()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            Box.Visible = false
            tracer.Visible = false
            name.Visible = false
            return
        end

        local hrpPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position)
        if onScreen then
            local top = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position + Vector3.new(0, 3, 0))
            local bottom = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))
            local size = Vector2.new(math.abs(top.X - bottom.X) * 1.5, math.abs(top.Y - bottom.Y) * 1.5)
            Box.Size = size
            Box.Position = Vector2.new(hrpPosition.X - size.X / 2, hrpPosition.Y - size.Y / 2)
            Box.Visible = true

            tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
            tracer.To = Vector2.new(hrpPosition.X, hrpPosition.Y)
            tracer.Visible = true

            name.Position = Vector2.new(hrpPosition.X, hrpPosition.Y - size.Y / 2 - 20)
            name.Visible = true
        else
            Box.Visible = false
            tracer.Visible = false
            name.Visible = false
        end
    end

    RunService.RenderStepped:Connect(loop)
end

function remove(player)
    if wtf[player] then
        wtf[player].box:Remove()
        wtf[player].tracer:Remove()
        wtf[player].name:Remove()
        wtf[player] = nil
    end
end

function add(player)
    player.CharacterAdded:Connect(function(character)
        esp(player)
    end)
    player.CharacterRemoving:Connect(function(character)
        remove(player)
    end)
    if player.Character then
        esp(player)
    end
end

Players.PlayerAdded:Connect(add)

for _, player in pairs(Players:GetPlayers()) do
    add(player)
end

function toggle(state)
    settings.enabled = state
    if not state then
        for _, player in pairs(Players:GetPlayers()) do
            remove(player)
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                esp(player)
            end
        end
    end
end

function this_is_stupid(state)
    settings.teamCheck = state
end
