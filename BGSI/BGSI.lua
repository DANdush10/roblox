-- services and stuff
local Workspace = game:GetService("Workspace")
local Players= game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGUI = Player.PlayerGui
local Character = Player.Character
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid =  Character:WaitForChild("Humanoid")
local TS = game:GetService("TweenService")
local ReplicatedStorge = game:GetService("ReplicatedStorage")
--flag for shouldBlowBubbles
local shouldBlowBubbles = true
local shouldSell = true
-- variable for the gum gui element
local BubbleCountGUI = PlayerGUI.ScreenGui.HUD.Left.Currency.Bubble.Frame.Label
-- tp positions
local tpPositions = {
    ["Sell"] = Workspace.Worlds:WaitForChild("The Overworld").Sell.Root.CFrame,
    ["Spawn"] = Workspace.Worlds:WaitForChild("The Overworld")
}

local function isBackpackFull()

local richText = BubbleCountGUI.Text

local cleanText = richText:gsub("<[^>]->", "") 

-- Extract x and y from "x / y"
local x, y = string.match(cleanText, "(%d+)%s*/%s*(%d+)")--chatgpt excel ahh

local result = {
    amount = tonumber(x),
    storage = tonumber(y)
}

    
    if result.amount == result.storage then
        return true
    else
        return false
    end
end

local function blowBubble()

local args = {
    [1] = "BlowBubble"
}

ReplicatedStorge.Shared.Framework.Network.Remote.Event:FireServer(unpack(args))
end

local function TP(tpCFrame, tpBack)
    local Pos = HRP.CFrame
    local tween1 = TS:Create(HRP, TweenInfo.new(0.5), {CFrame = tpCFrame})
    tween1:Play()
    task.wait(0.5)
    if tpBack then
        local tween2 = TS:Create(HRP, TweenInfo.new(0.5), {CFrame = Pos})
        tween2:Play()
    end
end

spawn(function()  
    while shouldBlowBubbles do
        blowBubble()
        task.wait()
        if shouldSell then
            if isBackpackFull() then
                print("Selling")
                TP(tpPositions["Sell"], true)
                wait(1)
            end
        end
    end
end)