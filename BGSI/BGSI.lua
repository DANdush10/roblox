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

-- dict for eggs(filled w/function)
local eggsDict = {}
--flag for shouldBlowBubbles
local shouldBlowBubbles = false
local shouldSell = false
local repeatStatus = false
local notDoneTweening = false
-- variable for the gum gui element
local BubbleCountGUI = PlayerGUI.ScreenGui.HUD.Left.Currency.Bubble.Frame.Label
-- tp positions
local tpPositions = {
    ["Sell"] = Workspace.Worlds:WaitForChild("The Overworld").Sell.Root.CFrame,
    ["Spawn"] = Workspace.Worlds:WaitForChild("The Overworld").SpawnLocation.CFrame
}

local function getTweenDurationFromSpeed(Part,Speed)
    local distance = (Part.Position - HRP.Position).Magnitude
    print("Speed:",distance / Speed)
    return distance / Speed
end

local function TP(tpCFrame, tpBack)
    if notDoneTweening then return end
    notDoneTweening = true
    local tweenInfo1 = TweenInfo.new(
        getTweenDurationFromSpeed(tpCFrame, 20),
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
        )

    local Pos = tpPositions["Spawn"] + Vector3.new(0,2,0)
    local tweenInfo2 = TweenInfo.new(
        getTweenDurationFromSpeed(Pos, 20),
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
        )
    local tween1 = TS:Create(HRP, tweenInfo1, {CFrame = tpCFrame})
    tween1:Play()
    tween1.Completed:Wait()
    if tpBack then
        local tween2 = TS:Create(HRP, tweenInfo2, {CFrame = Pos})
        tween2:Play()
        tween2.Completed:Wait()
    end
    notDoneTweening = false
end

local function buyEggAndEquipBest(eggName,eggCFrame, shouldRepeat)

    local args = {
        [1] = "HatchEgg",
        [2] = eggName,
        [3] = 1
    }
    TP(eggCFrame, false)
    if shouldRepeat then
        repeat
        ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer(unpack(args))
        task.wait(1)
        until not repeatStatus
    else
        ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer(unpack(args))
    end
    ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("EquipBestPets")
end
local function getEggs()
    for i,v in pairs(Workspace.Rendered:GetChildren()) do
        if v.Name == "Chunker" then
            if #v:GetChildren() > 0 then
                for _,name in pairs(v:GetChildren()) do
                    if not(name.Name == "Coming Soon") and name:FindFirstChild("Root") then
                        eggsDict[name.Name] = name.Root.CFrame
                    end
                end
            end 
        end
    end
end

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


local function Sell(tpCFrame)
    if notDoneTweening then return end
    notDoneTweening = true
    local Pos = tpPositions["Spawn"] + Vector3.new(0,2,0)
    local tween1 = TS:Create(HRP, TweenInfo.new(getTweenDurationFromSpeed(tpCFrame, 25)), {CFrame = tpCFrame})
    tween1:Play()
    tween1.Completed:Wait()
    ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("SellBubble")
    local tween2 = TS:Create(HRP, TweenInfo.new(getTweenDurationFromSpeed(Pos, 25)), {CFrame = Pos})
    tween2:Play()
    tween2.Completed:Wait()
    notDoneTweening = false
end



task.spawn(function()  
    while true do
        if shouldBlowBubbles then
            blowBubble()
            
            if shouldSell then
                if isBackpackFull() then
                    Sell(tpPositions["Sell"])
                    wait(1)
                end
            end    
        end
        task.wait(0.1)
    end
end)
-- gui stuff(chatgpt :>)

local function initEggsGUI()
    getEggs() -- This populates eggsDict

    local ScreenGui = PlayerGUI:FindFirstChild("AutomationMainGUI")
    if not ScreenGui then return end




    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "EggsGUI"
    Frame.Size = UDim2.new(0, 350, 0, 300)
    Frame.Position = UDim2.new(0.7, -175, 0.5, -150)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BorderSizePixel = 0

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 14)

    local Scroll = Instance.new("ScrollingFrame", Frame)
    Scroll.Size = UDim2.new(1, -20, 1, -20)
    Scroll.Position = UDim2.new(0, 10, 0, 10)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 6
    Scroll.BackgroundTransparency = 1
    Scroll.Name = "EggScroll"
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local ListLayout = Instance.new("UIListLayout", Scroll)
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Header for Egg Name and Repeat Buying labels
    local Header = Instance.new("Frame", Scroll)
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundTransparency = 1

    local EggNameHeader = Instance.new("TextLabel", Header)
    EggNameHeader.Size = UDim2.new(0.6, 0, 1, 0)
    EggNameHeader.Position = UDim2.new(0, 0, 0, 0)
    EggNameHeader.BackgroundTransparency = 1
    EggNameHeader.Text = "Egg Name"
    EggNameHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    EggNameHeader.Font = Enum.Font.Gotham
    EggNameHeader.TextSize = 14
    EggNameHeader.TextXAlignment = Enum.TextXAlignment.Left

    local RepeatBuyingHeader = Instance.new("TextLabel", Header)
    RepeatBuyingHeader.Size = UDim2.new(0.4, 0, 1, 0)
    RepeatBuyingHeader.Position = UDim2.new(0.6, 0, 0, 0)
    RepeatBuyingHeader.BackgroundTransparency = 1
    RepeatBuyingHeader.Text = "Repeat Buying"
    RepeatBuyingHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    RepeatBuyingHeader.Font = Enum.Font.Gotham
    RepeatBuyingHeader.TextSize = 14
    RepeatBuyingHeader.TextXAlignment = Enum.TextXAlignment.Left

    -- Now create the buttons for each egg
    for i, v in pairs(eggsDict) do
        local Entry = Instance.new("Frame", Scroll)
        Entry.Size = UDim2.new(1, 0, 0, 40)  -- Increased height for entries
        Entry.BackgroundTransparency = 1

        -- Egg Button
        local EggButton = Instance.new("TextButton", Entry)
        EggButton.Size = UDim2.new(0.6, -5, 1, 0)
        EggButton.Position = UDim2.new(0, 0, 0, 0)
        EggButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        EggButton.Text = tostring(i)
        EggButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        EggButton.Font = Enum.Font.Gotham
        EggButton.TextSize = 14
        EggButton.BorderSizePixel = 0

        local EggCorner = Instance.new("UICorner", EggButton)
        EggCorner.CornerRadius = UDim.new(0, 10)

        -- Toggle for true/false (starts false)
        local toggleState = false

        -- Handle Egg Button Click
        EggButton.MouseButton1Click:Connect(function()
            -- Your logic for handling egg button
            if toggleState then
                buyEggAndEquipBest(i, v + Vector3.new(0,7,0), toggleState)
                repeatStatus = true
            else
                buyEggAndEquipBest(i, v + Vector3.new(0,7,0), toggleState)
            end
        end)



        local Toggle = Instance.new("TextButton", Entry)
        Toggle.Size = UDim2.new(0.4, -5, 1, 0)
        Toggle.Position = UDim2.new(0.6, 5, 0, 0)
        Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Toggle.Text = tostring(toggleState)
        Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        Toggle.Font = Enum.Font.Gotham
        Toggle.TextSize = 14
        Toggle.BorderSizePixel = 0

        local ToggleCorner = Instance.new("UICorner", Toggle)
        ToggleCorner.CornerRadius = UDim.new(0, 10)

        Toggle.MouseButton1Click:Connect(function()
            toggleState = not toggleState
            repeatStatus = not repeatStatus
            Toggle.Text = tostring(toggleState)
            print("Toggle for", i, "is now", toggleState)
        end)
    end
end




local function createAutomationPopupGUI()
    local ScreenGui = PlayerGUI:FindFirstChild("AutomationMainGUI")
    if not ScreenGui then return end

    local Popup = Instance.new("Frame", ScreenGui)
    Popup.Size = UDim2.new(0, 300, 0, 200)
    Popup.Position = UDim2.new(0.5, -150, 0.5, -100)
    Popup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Popup.BorderSizePixel = 0
    Popup.Name = "AutomationPopup"

    local UICorner = Instance.new("UICorner", Popup)
    UICorner.CornerRadius = UDim.new(0, 14)

    local BlowButton = Instance.new("TextButton", Popup)
    BlowButton.Size = UDim2.new(0.8, 0, 0, 40)
    BlowButton.Position = UDim2.new(0.1, 0, 0.1, 0)
    BlowButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    BlowButton.Text = "Blow: " .. tostring(shouldBlowBubbles)
    BlowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    BlowButton.Font = Enum.Font.Gotham
    BlowButton.TextSize = 14
    BlowButton.BorderSizePixel = 0
    Instance.new("UICorner", BlowButton).CornerRadius = UDim.new(0, 10)

    BlowButton.MouseButton1Click:Connect(function()
        shouldBlowBubbles = not shouldBlowBubbles
        BlowButton.Text = "Blow: " .. tostring(shouldBlowBubbles)
    end)

    local SellButton = Instance.new("TextButton", Popup)
    SellButton.Size = UDim2.new(0.8, 0, 0, 40)
    SellButton.Position = UDim2.new(0.1, 0, 0.4, 0)
    SellButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    SellButton.Text = "Sell: " .. tostring(shouldSell)
    SellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SellButton.Font = Enum.Font.Gotham
    SellButton.TextSize = 14
    SellButton.BorderSizePixel = 0
    Instance.new("UICorner", SellButton).CornerRadius = UDim.new(0, 10)

    SellButton.MouseButton1Click:Connect(function()
        shouldSell = not shouldSell
        SellButton.Text = "Sell: " .. tostring(shouldSell)
    end)

    -- New "Eggs GUI" Button
    local EggsButton = Instance.new("TextButton", Popup)
    EggsButton.Size = UDim2.new(0.8, 0, 0, 40)
    EggsButton.Position = UDim2.new(0.1, 0, 0.7, 0)
    EggsButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    EggsButton.Text = "Open Eggs GUI"
    EggsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    EggsButton.Font = Enum.Font.Gotham
    EggsButton.TextSize = 14
    EggsButton.BorderSizePixel = 0
    Instance.new("UICorner", EggsButton).CornerRadius = UDim.new(0, 10)

    EggsButton.MouseButton1Click:Connect(function()
                -- Destroy old GUI if it exists
        local oldEggsGUI = ScreenGui:FindFirstChild("EggsGUI")
        if oldEggsGUI then
            oldEggsGUI:Destroy()  -- Safely destroy the old EggsGUI
        else
            initEggsGUI()
        end
    end)
end



local function createMainGUI()
    local ScreenGui = Instance.new("ScreenGui", PlayerGUI)
    ScreenGui.Name = "AutomationMainGUI"

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 200, 0, 100)
    Frame.Position = UDim2.new(0, 20, 0, 20)
    Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Frame.BorderSizePixel = 0
    Frame.Name = "MainFrame"
    Frame.ClipsDescendants = true
    Frame.BackgroundTransparency = 0
    Frame.Active = true

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 12)

    local AutomationButton = Instance.new("TextButton", Frame)
    AutomationButton.Size = UDim2.new(1, -20, 0, 40)
    AutomationButton.Position = UDim2.new(0, 10, 0.5, -20)
    AutomationButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    AutomationButton.Text = "Automation"
    AutomationButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutomationButton.Font = Enum.Font.Gotham
    AutomationButton.TextSize = 14
    AutomationButton.BorderSizePixel = 0

    local btnCorner = Instance.new("UICorner", AutomationButton)
    btnCorner.CornerRadius = UDim.new(0, 8)

    AutomationButton.MouseButton1Click:Connect(function()
        if not PlayerGUI.AutomationMainGUI:FindFirstChild("AutomationPopup") then
            createAutomationPopupGUI()
        else
            PlayerGUI.AutomationMainGUI:FindFirstChild("AutomationPopup"):Destroy()
        end
    end)
end


createMainGUI()
