local Workspace = game:GetService("Workspace")
-- player stuff
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local HRP = Player.Character:WaitForChild("HumanoidRootPart")
-- remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientIsDragging = ReplicatedStorage.Interaction.ClientIsDragging
local chopRemote = ReplicatedStorage.Interaction.RemoteProxy
local PlayerChatted = ReplicatedStorage.NPCDialog.PlayerChatted
-- changes, basically just a global variable that needs to be accessed from some spots
local LooseTreeModel = nil
-- "database" for axe stats
local AxeClasses = ReplicatedStorage.AxeClasses
--for the gui, i wanna update it so instead of tree regions(like biomes) its tree types
local TreeDictionary = {}
-- spawn location reference
local spawn = Workspace:FindFirstChild("Region_Main"):FindFirstChild("SpawnLocation")
--store positions for reference:
local StoresPositions = {
    Logic = {
        Counter = Workspace.Stores.LogicStore.Counter,
        NPC = Workspace.Stores.LogicStore.Lincoln
    },
    WoodRUs = {
        Counter = Workspace.Stores.WoodRUs.Counter,
        NPC = Workspace.Stores.WoodRUs.Thom
    },
    Art = {
        Counter = Workspace.Stores.FineArt.Counter,
        NPC = Workspace.Stores.FineArt.Timothy
    },
    Shack = {
        Counter = Workspace.Stores.ShackShop.Counter,
        NPC = Workspace.Stores.ShackShop.Bob
    },
    Car = {
        Counter = Workspace.Stores.CarStore.Counter,
        NPC = Workspace.Stores.CarStore.Jenny
    },
    Furniture = {
        Counter = Workspace.Stores.FurnitureStore.Counter,
        NPC = Workspace.Stores.FurnitureStore.Corey
    }
}

--steps when buying items:
local steps = {
    [1] = "Initiate",
    [2] = "ConfirmPurchase",
    [3] = "EndChat"
}
-- gets the axe's stats by using the moduleScript inside axeclasses
local function getAxeStats(Name)

    local AxeStats = require(AxeClasses:FindFirstChild("AxeClass_"..Name)).new()

    return AxeStats

end

local function getTreeSize(Tree)
    local totalVolume = 0
    for _,v in pairs(Tree:GetChildren()) do
        if v.Name == "WoodSection" then
            local size = v.Size
            local volume = size.X * size.Y * size.Z
            totalVolume += volume
        end
    end
    return totalVolume
end

local function isMyTree(TreeType, child) -- ?

    if tostring(child:WaitForChild("Owner").Value) == Player.Name then 

        return true

    else 
        return false
    end

end

local function getLowestWoodSec(Tree)

    local lowestWoodSecObject = nil
    local lowestWoodSecY = math.huge
    for _,v in pairs(Tree:GetChildren()) do
        if v.Name == "WoodSection" then
            if v.Position.Y < lowestWoodSecY then
                lowestWoodSecObject = v
                lowestWoodSecY = v.Position.Y
            end

        end

    end
    if lowestWoodSecObject then
    return lowestWoodSecObject
    else
        print("lowest wood sec not found")
        return nil
    end
end

local function grabTree(Tree,OrgPlayerPos)

    print("Grabbing Tree...")
    local args = 
    {
        [1] = Tree
    }
    Tree.PrimaryPart = getLowestWoodSec(Tree)
    HRP.CFrame = Tree.PrimaryPart.CFrame
    for i = 1,100 do
        ClientIsDragging:FireServer(unpack(args))
        task.wait()
    end

    task.wait(0.1)
    for i = 1,60 do
        Tree.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
        Tree:PivotTo(OrgPlayerPos + Vector3.new(0,20,0))
        task.wait() 
    end
    HRP.CFrame = OrgPlayerPos + Vector3.new(0,20,0)

end

local function getBestAxe()
    local bestAxeDPS = 0
    local bestAxe = nil
    for _,Tool in pairs(Player.ToolFolder:GetChildren()) do
        local axeStats = getAxeStats(tostring(Tool.Value))
        print(tostring(axeStats.Damage/axeStats.SwingCooldown), "DPS")
        if axeStats.Damage/axeStats.SwingCooldown > bestAxeDPS then
            bestAxe = Tool
            bestAxeDPS = axeStats.Damage/axeStats.SwingCooldown
        end
    end
    return bestAxe
end

local function getToolByName(ToolName)
    for _,Tool in pairs(Player.Backpack:GetChildren()) do
        if Tool:FindFirstChild("ToolName") then -- if its axe
            if tostring(Tool.ToolName.Value) == ToolName then-- if its the tool then return it
                return Tool
            end
        end
    end
    return nil
end

local function chopTree(Tree, OrgPlayerPos)
    local Tool
    local backpackCount = #Player.Backpack:GetChildren()
    Tool = Player.Backpack:FindFirstChild("Tool")
    if backpackCount <= 2 then
        if Tool then
            Tool.Parent = Player.Character
        else
            print("No Tool?")
        end
    else
        local ToolName = tostring(getBestAxe().Value)
        print("ToolName:",ToolName)
        Tool = getToolByName(ToolName)

        Tool.Parent = Player.Character
    end
    local axeStats = getAxeStats(Player.Character.Tool:WaitForChild("ToolName").Value)
    local args = 
    {
        [1] = 
        Tree.CutEvent,
        [2] = 
        {
        ["tool"] = Player.Character.Tool,
        ["height"] = 0.3,
        ["faceVector"] = Vector3.new(1, 0, 0),
        ["sectionId"] = 1,
        ["hitPoints"] = axeStats.Damage,
        ["cooldown"] = axeStats.SwingCooldown,
        ["cuttingClass"] = "Axe"
        }
    }

    HRP.CFrame = getLowestWoodSec(Tree).CFrame + Vector3.new(0,3,0)


    local connection
    connection = Workspace.LogModels.ChildAdded:Connect(function(child)
        if isMyTree(Tree, child) then
            print(" Tree Found!")
            LooseTreeModel = child
            task.wait()
            Tool.Parent = Player.Backpack
            grabTree(LooseTreeModel, OrgPlayerPos)
            connection:Disconnect()
        end
    end)
    repeat

        chopRemote:FireServer(unpack(args))
        task.wait(axeStats.SwingCooldown)

    until not(Tree:FindFirstChild("CutEvent"))

end

local function getShopItems()
    local shopItems = {}
    for _,Items in pairs(Workspace.Stores:GetChildren()) do
        if Items.Name == "ShopItems" then
            for _,Item in pairs(Items:GetChildren()) do
                shopItems[tostring(Item:WaitForChild("BoxItemName").Value)] = Item
            end
        end
    end
    return shopItems
end

--steps:
--1: Initiate
--2: ConfirmPurchase
--3: EndChat
-- Script generated by SimpleSpy - credits to exx#9394

--[[local args = {
    [1] = {
        ["Character"] = workspace.Stores.WoodRUs.Thom,
        ["Name"] = "Thom",
        ["ID"] = 7,
        ["Dialog"] = workspace.Stores.WoodRUs.Thom.Dialog
    },
    [2] = "ConfirmPurchase"
}

game:GetService("ReplicatedStorage").NPCDialog.PlayerChatted:InvokeServer(unpack(args))
--]]

local function getShopType(item)
    local closestStore = nil
    local closestDistance = math.huge  

    local itemCFrame = item:FindFirstChild("Main").CFrame

    for storeName, storeData in pairs(StoresPositions) do
        if storeData.Counter then
            local storeCFrame = storeData.Counter.CFrame
            local distance = (itemCFrame.Position - storeCFrame.Position).Magnitude
            
            if distance < closestDistance then
                closestDistance = distance
                closestStore = storeName  
            end
        end
    end

    return closestStore
end


local function buyItem(Item)
    local looseItem = nil
    local OrgPlayerPos = HRP.CFrame
    HRP.CFrame = Item.Main.CFrame
    local Store = getShopType(Item)
    local Counter = StoresPositions[Store].Counter
    local NPC = StoresPositions[Store].NPC
    -- the logic for grab tree
    local args =
    {
        [1] = Item
    }
    for i = 1,100 do
        ClientIsDragging:FireServer(unpack(args))
        task.wait()
    end

    task.wait(0.1)
    for i = 1,60 do
        Item.Main.Velocity = Vector3.new(0, 0, 0)
        Item:PivotTo(Counter.CFrame+Vector3.new(0,2,0))
        task.wait() 
    end
    HRP.CFrame = NPC.HumanoidRootPart.CFrame
    for j = 7,15 do
        for i = 1,3 do
            print("Running for j:", j, " and i:", i) 
            local args2 = 
            {
                {
                    ["Character"] = NPC,
                    ["Name"] = tostring(NPC.Name),
                    ["ID"] = j,
                    ["Dialog"] = NPC.Dialog
                },
                
                steps[i]
            }
            print("Arguments:", args2)
            PlayerChatted:InvokeServer(unpack(args2))
            task.wait(0.2)
            local connection
            connection = Workspace.PlayerModels.ChildAdded:Connect(function(child)
                if not looseItem and tostring(child:WaitForChild("Owner").Value) == tostring(Player.Name) then
                    print("got item")
                        looseItem = child
                        print(child.Name)
                        connection:Disconnect()
                end
            end)
        end
    end
    
    local looseItemARGS =
    {
        [1] = looseItem
    }

    HRP.CFrame = OrgPlayerPos
    for i = 1,100 do
        ClientIsDragging:FireServer(unpack(looseItemARGS))
        task.wait()
    end

    task.wait(0.1)
    for i = 1,60 do
        looseItem.Main.Velocity = Vector3.new(0, 0, 0)
        looseItem:PivotTo(OrgPlayerPos+Vector3.new(0,5,0))
        task.wait() 
    end
end


local function getTree(Tree)

    local OrgPlayerPos = HRP.CFrame
    chopTree(Tree,OrgPlayerPos)

end

local function getPlayerBases()
    local PlayerBasesDict = {}
    for _,v in pairs(Workspace:FindFirstChild("Properties"):GetChildren()) do
        if v.Owner.Value then
            PlayerBasesDict[tostring(v.Owner.Value)] = v.OriginSquare.CFrame
        end
    end
    return PlayerBasesDict
end

function initShopGUI()
    -- Create the shop GUI screen
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Player:WaitForChild("PlayerGui")

    -- Main Frame for the Shop
    local shopFrame = Instance.new("Frame")
    shopFrame.Size = UDim2.new(0, 300, 0, 400)
    shopFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    shopFrame.BorderSizePixel = 0
    shopFrame.Active = true
    shopFrame.Draggable = true
    shopFrame.Parent = screenGui

    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 12)
    shopCorner.Parent = shopFrame

    -- ScrollFrame for displaying items
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -40)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = shopFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)  -- Space between buttons
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame


    -- Get the items from the getShopItems function
    local shopItems = getShopItems()  -- Assuming this returns a dictionary

    -- Iterate through the dictionary and create buttons for each item
    for i, v in pairs(shopItems) do
        -- Create a button for each item
        local itemButton = Instance.new("TextButton")
        itemButton.Size = UDim2.new(1, -20, 0, 40)
        itemButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        itemButton.TextColor3 = Color3.fromRGB(230, 230, 230)
        itemButton.Font = Enum.Font.GothamBold
        itemButton.TextSize = 18
        itemButton.Text = i  -- The item's name (text) will be used here
        itemButton.AutoButtonColor = false
        itemButton.Parent = scrollFrame

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = itemButton

        -- Button click handler (for future use with item purchasing)
        itemButton.MouseButton1Click:Connect(function()
            -- Handle the click event (e.g., process the item purchase later)
            print("Item selected: " .. i)  -- Placeholder action, replace with actual functionality
            buyItem(v)
        end)
    end
end


local function initTeleportGUI()
    local PlayerBases = getPlayerBases()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 180, 0, 160)
    mainFrame.Position = UDim2.new(0, 200, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- "Teleport to Spawn" Button
    local teleportSpawnButton = Instance.new("TextButton")
    teleportSpawnButton.Size = UDim2.new(1, -20, 0, 40)
    teleportSpawnButton.Position = UDim2.new(0, 10, 0, 10)
    teleportSpawnButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    teleportSpawnButton.TextColor3 = Color3.fromRGB(230, 230, 230)
    teleportSpawnButton.Font = Enum.Font.GothamBold
    teleportSpawnButton.TextSize = 18
    teleportSpawnButton.Text = "Teleport to Spawn"
    teleportSpawnButton.AutoButtonColor = false
    teleportSpawnButton.Parent = mainFrame

    local teleportSpawnCorner = Instance.new("UICorner")
    teleportSpawnCorner.CornerRadius = UDim.new(0, 8)
    teleportSpawnCorner.Parent = teleportSpawnButton

    teleportSpawnButton.MouseButton1Click:Connect(function()
        HRP.CFrame = spawn.CFrame
    end)

    -- "TP to Player Base" Button
    local tpPlayerBaseButton = Instance.new("TextButton")
    tpPlayerBaseButton.Size = UDim2.new(1, -20, 0, 40)
    tpPlayerBaseButton.Position = UDim2.new(0, 10, 0, 60)
    tpPlayerBaseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tpPlayerBaseButton.TextColor3 = Color3.fromRGB(230, 230, 230)
    tpPlayerBaseButton.Font = Enum.Font.GothamBold
    tpPlayerBaseButton.TextSize = 18
    tpPlayerBaseButton.Text = "TP to Player Base"
    tpPlayerBaseButton.AutoButtonColor = false
    tpPlayerBaseButton.Parent = mainFrame

    local tpPlayerBaseCorner = Instance.new("UICorner")
    tpPlayerBaseCorner.CornerRadius = UDim.new(0, 8)
    tpPlayerBaseCorner.Parent = tpPlayerBaseButton

    -- "TP to Player" Button
    local tpPlayerButton = Instance.new("TextButton")
    tpPlayerButton.Size = UDim2.new(1, -20, 0, 40)
    tpPlayerButton.Position = UDim2.new(0, 10, 0, 110) -- 60 + 40 + 10 (padding) = 110
    tpPlayerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tpPlayerButton.TextColor3 = Color3.fromRGB(230, 230, 230)
    tpPlayerButton.Font = Enum.Font.GothamBold
    tpPlayerButton.TextSize = 18
    tpPlayerButton.Text = "TP to Player"
    tpPlayerButton.AutoButtonColor = false
    tpPlayerButton.Parent = mainFrame

    local tpPlayerCorner = Instance.new("UICorner")
    tpPlayerCorner.CornerRadius = UDim.new(0, 8)
    tpPlayerCorner.Parent = tpPlayerButton

    -- Frame to hold Player Base buttons (hidden at first)
    local playerBaseFrame = Instance.new("Frame")
    playerBaseFrame.Size = UDim2.new(0, 180, 0, 200)
    playerBaseFrame.Position = UDim2.new(0, 200, 0, 140)
    playerBaseFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    playerBaseFrame.Visible = false
    playerBaseFrame.Parent = screenGui

    local playerBaseCorner = Instance.new("UICorner")
    playerBaseCorner.CornerRadius = UDim.new(0, 12)
    playerBaseCorner.Parent = playerBaseFrame

    local playerListFrame -- forward declaration (so we can destroy it)

    tpPlayerButton.MouseButton1Click:Connect(function()
        -- Destroy previous PlayerListFrame if it exists
        if playerListFrame then
            playerListFrame:Destroy()
            playerListFrame = nil
            return -- Exit early if just clicked to close it
        end
    
        -- Create new PlayerListFrame
        playerListFrame = Instance.new("Frame")
        playerListFrame.Size = UDim2.new(0, 200, 0, 300) -- width, height
        playerListFrame.Position = UDim2.new(0, 250, 0, 60) -- a bit to the right of original buttons
        playerListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        playerListFrame.Parent = mainFrame
    
        local playerListCorner = Instance.new("UICorner")
        playerListCorner.CornerRadius = UDim.new(0, 8)
        playerListCorner.Parent = playerListFrame
    
        local yOffset = 10
    
        for _, player in pairs(Players:GetPlayers()) do
            local playerButton = Instance.new("TextButton")
            playerButton.Name = "PlayerButton"
            playerButton.Size = UDim2.new(1, -20, 0, 40)
            playerButton.Position = UDim2.new(0, 10, 0, yOffset)
            playerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            playerButton.TextColor3 = Color3.fromRGB(230, 230, 230)
            playerButton.Font = Enum.Font.GothamBold
            playerButton.TextSize = 18
            playerButton.Text = player.Name
            playerButton.AutoButtonColor = false
            playerButton.Parent = playerListFrame
    
            local playerCorner = Instance.new("UICorner")
            playerCorner.CornerRadius = UDim.new(0, 8)
            playerCorner.Parent = playerButton
    
            playerButton.MouseButton1Click:Connect(function()
                HRP.CFrame = player.Character.HumanoidRootPart.CFrame
            end)
    
            yOffset = yOffset + 50
        end
    end)
    
    
    tpPlayerBaseButton.MouseButton1Click:Connect(function()
        playerBaseFrame.Visible = not playerBaseFrame.Visible

        -- Clear old buttons
        for _, child in ipairs(playerBaseFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.Parent = playerBaseFrame

        -- Create a button for each player base
        for playerName, baseCFrame in pairs(PlayerBases) do
            local baseButton = Instance.new("TextButton")
            baseButton.Size = UDim2.new(1, -10, 0, 40)
            baseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            baseButton.TextColor3 = Color3.fromRGB(230, 230, 230)
            baseButton.Font = Enum.Font.GothamBold
            baseButton.TextSize = 16
            baseButton.Text = playerName
            baseButton.Parent = playerBaseFrame
            baseButton.AutoButtonColor = false

            local baseButtonCorner = Instance.new("UICorner")
            baseButtonCorner.CornerRadius = UDim.new(0, 8)
            baseButtonCorner.Parent = baseButton

            baseButton.MouseButton1Click:Connect(function()
                HRP.CFrame = baseCFrame
            end)
        end
    end)
end


local function initRegionGUI(treeList)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RegionDetailGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0, 550, 0, 100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- X button to close the GUI
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -28, 0, 4)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- ScrollFrame for tree list
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame

    -- For each tree in Region
    for _, tree in ipairs(treeList) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 40)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.Text = ""
        button.TextColor3 = Color3.fromRGB(230, 230, 230)
        button.Font = Enum.Font.Arial
        button.TextSize = 16
        button.AutoButtonColor = false
        button.Parent = scrollFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = button

        -- Label for Tree Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
        nameLabel.Font = Enum.Font.Arial
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = tree.TreeClass.Value
        nameLabel.Parent = button

        -- Label for Tree Size
        local sizeLabel = Instance.new("TextLabel")
        sizeLabel.Size = UDim2.new(0.3, 0, 1, 0)
        sizeLabel.Position = UDim2.new(0.65, 0, 0, 0)
        sizeLabel.BackgroundTransparency = 1
        sizeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        sizeLabel.Font = Enum.Font.Arial
        sizeLabel.TextSize = 16
        sizeLabel.TextXAlignment = Enum.TextXAlignment.Right
        sizeLabel.Text = tostring(getTreeSize(tree))
        sizeLabel.Parent = button

        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end)
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)

        button.MouseButton1Click:Connect(function()
            getTree(tree)
        end)
    end

    -- Update scroll canvas size
    task.wait()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end


local function initTreeGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TreeRegionGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    -- Main Menu Frame
    local menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.new(0, 150, 0, 180)
    menuFrame.Position = UDim2.new(0, 20, 0, 20)
    menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    menuFrame.BorderSizePixel = 0
    menuFrame.Active = true
    menuFrame.Draggable = true
    menuFrame.Parent = screenGui

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 12)
    menuCorner.Parent = menuFrame

    -- "Grab Trees" Button
    local grabTreesButton = Instance.new("TextButton")
    grabTreesButton.Size = UDim2.new(1, -20, 0, 40)
    grabTreesButton.Position = UDim2.new(0, 10, 0, 20)
    grabTreesButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    grabTreesButton.TextColor3 = Color3.fromRGB(230, 230, 230)
    grabTreesButton.Font = Enum.Font.GothamBold
    grabTreesButton.TextSize = 18
    grabTreesButton.Text = "Grab Trees"
    grabTreesButton.AutoButtonColor = false
    grabTreesButton.Parent = menuFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = grabTreesButton
    
        -- "Teleport" Button
        local teleportButton = Instance.new("TextButton")
        teleportButton.Size = UDim2.new(1, -20, 0, 40)
        teleportButton.Position = UDim2.new(0, 10, 0, 70) -- below the Grab Trees button
        teleportButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        teleportButton.TextColor3 = Color3.fromRGB(230, 230, 230)
        teleportButton.Font = Enum.Font.GothamBold
        teleportButton.TextSize = 18
        teleportButton.Text = "Teleport"
        teleportButton.AutoButtonColor = false
        teleportButton.Parent = menuFrame
    
        local teleportButtonCorner = Instance.new("UICorner")
        teleportButtonCorner.CornerRadius = UDim.new(0, 8)
        teleportButtonCorner.Parent = teleportButton

    -- Button logic
    teleportButton.MouseButton1Click:Connect(function()
        local teleportGui = PlayerGui:FindFirstChild("TeleportGUI")
        if teleportGui then
            teleportGui:Destroy()
        else
            initTeleportGUI()
        end
    end)


        -- "Buy" Button
    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(1, -20, 0, 40)
    buyButton.Position = UDim2.new(0, 10, 0, 120)  -- Adjusted position based on other buttons
    buyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    buyButton.TextColor3 = Color3.fromRGB(230, 230, 230)
    buyButton.Font = Enum.Font.GothamBold
    buyButton.TextSize = 18
    buyButton.Text = "Buy"
    buyButton.AutoButtonColor = false
    buyButton.Parent = menuFrame
    buyButton.Name = "buyButton"

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = buyButton

        -- Button logic
        buyButton.MouseButton1Click:Connect(function()
            local buyButtonGUI = PlayerGui:FindFirstChild("ShopGUI")
            if buyButtonGUI then
                buyButtonGUI:Destroy()
            else
                initShopGUI()
            end
        end)


    -- === Main Tree Browser GUI ===
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0, 200, 0, 100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- ScrollFrame for tree types
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame

    -- === TreeType buttons ===
    for treeType, treeList in pairs(TreeDictionary) do
        local typeButton = Instance.new("TextButton")
        typeButton.Size = UDim2.new(1, 0, 0, 40)
        typeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        typeButton.TextColor3 = Color3.fromRGB(230, 230, 230)
        typeButton.Font = Enum.Font.Arial
        typeButton.TextSize = 16
        typeButton.Text = tostring(treeType)
        typeButton.AutoButtonColor = false
        typeButton.Parent = scrollFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = typeButton

        typeButton.MouseEnter:Connect(function()
            typeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end)
        typeButton.MouseLeave:Connect(function()
            typeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)

        -- === On click, show models inside this tree type ===
        typeButton.MouseButton1Click:Connect(function()
            initRegionGUI(treeList)
        end)
    end

    task.wait()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)

    -- Grab Trees button toggles mainFrame
    grabTreesButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
end

local function RenameTreeRegions()

    for TreeType,_ in pairs(TreeDictionary) do
        local Trees = {}
        for _,Child in pairs(Workspace:GetChildren()) do
            if Child.Name == "TreeRegion" then
                for _,Tree in pairs(Child:GetChildren()) do
                    local treeClass = Tree:FindFirstChild("TreeClass")
                    if treeClass then
                        if tostring(treeClass.Value) == TreeType then
                            table.insert(Trees, Tree)
                        end
                    end
                end
            end
        end
        TreeDictionary[TreeType] = Trees
    end
    initTreeGUI()

end

local function getTreeTypes()
    for _,TreeRegion in pairs(Workspace:GetChildren()) do
        if TreeRegion.Name == "TreeRegion" then
            if  #(TreeRegion:GetChildren()) ~= 0 then
                for _,Tree in pairs(TreeRegion:GetChildren()) do
                    local treeClass = Tree:FindFirstChild("TreeClass")
                    if treeClass then
                        if not table.find(TreeDictionary, tostring(treeClass.Value)) then
                            TreeDictionary[tostring(treeClass.Value)] = true
                        end
                    end
                end
            end
        end
    end
    RenameTreeRegions()
end

getTreeTypes()