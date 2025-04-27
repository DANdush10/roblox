local Workspace = game:GetService("Workspace")
local TreeRegions = {}
-- player stuff
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local HRP = Player.Character:WaitForChild("HumanoidRootPart")
-- remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientIsDragging = ReplicatedStorage.Interaction.ClientIsDragging
local chopRemote = ReplicatedStorage.Interaction.RemoteProxy
-- changes, basically just a global variable that needs to be accessed from some spots
local LooseTreeModel = nil
-- "database" for axe stats
local AxeClasses = ReplicatedStorage.AxeClasses
--for the gui, i wanna update it so instead of tree regions(like biomes) its tree types
local TreeDictionary = {}
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
        --debug
        print(tostring(child:WaitForChild("Owner").Value), Player.Name)
        print(#(tostring(child:WaitForChild("Owner").Value)), #(Player.Name))

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

    return lowestWoodSecObject

end

local function grabTree(Tree,OrgPlayerPos)

    print("Grabbing Tree...")
    local args = 
    {
        [1] = Tree
    }
    Tree.PrimaryPart = Tree:WaitForChild("WoodSection")
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

local function chopTree(Tree, OrgPlayerPos)

    local Tool = Player.Backpack:FindFirstChild("Tool")
    if Tool then
        Tool.Parent = Player.Character
    else
        print("Tool Not Found")
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
            grabTree(LooseTreeModel, OrgPlayerPos)
            connection:Disconnect()
        else
            print("Not My tree :(")
        end
    end)
    repeat

        chopRemote:FireServer(unpack(args))
        task.wait(axeStats.SwingCooldown)

    until not(Tree:FindFirstChild("CutEvent"))

end


local function getTree(Tree)

    local OrgPlayerPos = HRP.CFrame
    chopTree(Tree,OrgPlayerPos)

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
            local OrgPlayerPos = HRP.CFrame
            getTree(tree, OrgPlayerPos)
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
    menuFrame.Size = UDim2.new(0, 150, 0, 80)
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
                            print("Inserting")
                            table.insert(Trees, Tree)
                        end
                    end
                end
            end
        end
        print("added", tostring(#Trees), "trees to dictionary")
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
    for i,v in pairs(TreeDictionary) do
        print(i,v)
    end
    print("Printed")
    RenameTreeRegions()
end

getTreeTypes()