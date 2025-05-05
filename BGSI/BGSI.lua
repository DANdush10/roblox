-- services and stuff
local Workspace = game:GetService("Workspace")
local Players= game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGUI = Player.PlayerGui
local Character = Player.Character
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid =  Character:WaitForChild("Humanoid")
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--flag for shouldBlowBubbles
local shouldBlowBubbles = true
local shouldSell = true
local notDoneTweening = false
-- variable for the gum gui element
local BubbleCountGUI = PlayerGUI.ScreenGui.HUD.Left.Currency.Bubble.Frame.Label
-- tp positions
local tpPositions = {
    ["Sell"] = Workspace.Worlds:WaitForChild("The Overworld").Sell.Root.CFrame,
    ["Spawn"] = Workspace.Worlds:WaitForChild("The Overworld").SpawnLocation.CFrame
}

local function isBackpackFull()
    local richText = BubbleCountGUI.Text

    local cleanText = richText:gsub("<[^>]->", "")

    cleanText = cleanText:gsub(",", ""):gsub("%s+", "")

    local x, y = string.match(cleanText, "(%d+)/(%d+)")

    local result = {
        amount = tonumber(x),
        storage = tonumber(y)
    }

    return result.amount == result.storage
end


local function blowBubble()


ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("BlowBubble")
end

local function getTweenDurationFromSpeed(Part,Speed)
    local distance = (Part.Position - HRP.Position).Magnitude
    print("Got Duration!:", distance/Speed)
    return distance / Speed
end

local function TP(tpCFrame, tpBack)
    if notDoneTweening then return end
    notDoneTweening = true
    local Pos = tpPositions["Spawn"] + Vector3.new(0,2,0)
    local tween1 = TS:Create(HRP, TweenInfo.new(getTweenDurationFromSpeed(tpCFrame, 50)), {CFrame = tpCFrame})
    tween1:Play()
    tween1.Completed:Wait()
    if tpBack then
        local tween2 = TS:Create(HRP, TweenInfo.new(getTweenDurationFromSpeed(Pos, 50)), {CFrame = Pos})
        tween2:Play()
        tween2.Completed:Wait()
    end
    notDoneTweening = false
end

task.spawn(function()  
    local PosBefore = HRP.CFrame
    while shouldBlowBubbles do
        blowBubble()
        
        if shouldSell then
            if isBackpackFull() then
                print("Selling")
                TP(tpPositions["Sell"], true)
                wait(1)
            end
        end
        task.wait(0.1)
    end
    HRP.CFrame = PosBefore
end)