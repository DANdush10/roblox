local Workspace = game:GetService("Workspace")
local TreeRegions = {}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local HRP = Player.Character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientIsDragging = ReplicatedStorage.Interaction.ClientIsDragging
local AxeClasses = ReplicatedStorage.AxeClasses
local chopRemote = ReplicatedStorage.Interaction.RemoteProxy
local LooseTreeModel = nil
local function getAxeStats(Name)
local AxeStats = require(AxeClasses:FindFirstChild("AxeClass_"..Name)).new()
return AxeStats
end

local function isMyTree(TreeType, child) -- ?
if tostring(child:WaitForChild("Owner").Value) == Player.Name then return true

else return false
end
end
local function filterThroughWoodSection(Tree)
    local biggestWoodSec = nil
    local biggestWoodSize = 0
    for _,v in pairs(Tree:GetChildren()) do
        if v.Name == "WoodSection" then
            if v.Size > biggestWoodSize then
                biggestWoodSec = v
                biggestWoodSize = v.Size
            end
        end
    end
    return biggestWoodSec
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

HRP.CFrame = Tree.WoodSection.CFrame


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


local function initTreeGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TreeRegionGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0, 20, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Collapse button
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 24, 0, 24)
    collapseBtn.Position = UDim2.new(1, -28, 0, 4)
    collapseBtn.Text = "◀"
    collapseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 16
    collapseBtn.Parent = mainFrame

    local collapseCorner = Instance.new("UICorner")
    collapseCorner.CornerRadius = UDim.new(1, 0)
    collapseCorner.Parent = collapseBtn

    -- ScrollFrame for buttons
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated later
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame

    -- Add region buttons
    for _, region in pairs(TreeRegions) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 40)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.TextColor3 = Color3.fromRGB(230, 230, 230)
        button.Font = Enum.Font.Arial
        button.TextSize = 16
        button.Text = region.Name
        button.AutoButtonColor = false
        button.Parent = scrollFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = button

        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end)
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)

        -- Click handler (custom logic placeholder)
        button.MouseButton1Click:Connect(function()
            local Tree = region:FindFirstChild("Model")
            getTree(Tree)
        end)
    end

    -- Update scroll canvas size properly
    task.wait() -- ensure layout has been calculated
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)

    -- Collapse toggle logic
    local collapsed = false
    collapseBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        if collapsed then
            scrollFrame.Visible = false
            mainFrame.Size = UDim2.new(0, 40, 0, 40)
            collapseBtn.Text = "▶"
        else
            scrollFrame.Visible = true
            mainFrame.Size = UDim2.new(0, 300, 0, 400)
            collapseBtn.Text = "◀"
        end
    end)
end



local function RenameTreeRegions()
    for i,v in pairs(Workspace:GetChildren()) do
        if v.Name == "TreeRegion" then
            if v:FindFirstChild("Model") then
                if v:FindFirstChild("Model"):FindFirstChild("TreeClass") then
                    v.Name = v:FindFirstChild("Model"):FindFirstChild("TreeClass").Value
                    table.insert(TreeRegions, v)
            
                end
            end
        end
    end
    initTreeGUI()
end
RenameTreeRegions()