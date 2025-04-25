local function main()
-- constant variables
local FarmsFolder = game.Workspace.Farm
local Players = game:GetService("Players")
local ProximityPrompts = Players.LocalPlayer.PlayerGui:WaitForChild("ProximityPrompts")
local MoneyDir = Players.LocalPlayer.leaderstats.Sheckles
local WantedCrop = "Strawberry" -- enter wanted crop here
local BuySeedStock = game:GetService("ReplicatedStorage").GameEvents.BuySeedStock
local SeedNPCCFrame = game.Workspace.NPCS.Sam.Torso.CFrame
local Plant = game:GetService("ReplicatedStorage").GameEvents.Plant_RE
local Backpack = Players.LocalPlayer.Backpack
local Character = Players.LocalPlayer.Character
local FruitStocksDir = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.ScrollingFrame
local FruitStocks = {}
local sellAll = game:GetService("ReplicatedStorage").GameEvents.Sell_Inventory
local Steven = game.Workspace.NPCS.Steven
local HRP = Players.LocalPlayer.Character.HumanoidRootPart

-- prices for some of the fruits
local fruitPrices = {
    Carrot = 10,
    Strawberry = 50,
    Blueberry = 400,
    Tomato = 800
}
local CropsList = {"Bamboo", "Coconut", "Carrot", "Tomato", "Pumpkin", "Apple", "Corn", "Dragon Fruit", "Blueberry", "Mango","Cactus", "Strawberry", "Watermelon"}
-- finds the local player's farm
local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if string.find(v:FindFirstChild("Sign"):FindFirstChild("Core_Part"):FindFirstChild("SurfaceGui"):FindFirstChild("TextLabel").Text, Players.LocalPlayer.DisplayName) then
            return v
        end
    end
return nil
end

-- buys seeds for a specified crop
local function buyCropSeeds(cropName, Money)

    if math.round(Money) > fruitPrices[cropName] - 0.1 then
        local args = 
        {
        [1] = cropName
        }

BuySeedStock:FireServer(unpack(args))
    else
        print("Not Enough Money!")
    end
end


local function plantSeed(SeedType, PlantPosition)
    
    local args = {
        [1] = Vector3.new(PlantPosition.X, 0.1355251669883728, PlantPosition.Z),
        [2] = SeedType
    }
    
    
    Plant:FireServer(unpack(args))
end

local function plantAllSeeds(Location)
    local CurrentTool = Character:FindFirstChildOfClass("Tool")
            if CurrentTool then
                CurrentTool.Parent = Backpack
                task.wait()
            end
            local seeds = {}
            for _,v in pairs(Backpack:GetChildren()) do
                if v:FindFirstChild("Plant_Name") then
                table.insert(seeds,v)
                end
            end
    for _,v in pairs(seeds) do
        
        print("Planting:", v.Plant_Name.Value, "At:", Location.X, 0.13552513718605042, Location.Z)
            
        Character:WaitForChild("Humanoid"):EquipTool(v)
        plantSeed(v.Plant_Name.Value, Location)
        task.wait()
        
    end
end

local function getMoney()
return MoneyDir.Value
end

local function updateCropsStocks(CropsList)
    for i1,StocksName in pairs(FruitStocksDir:GetChildren()) do

        for i2,FruitName in pairs(CropsList) do
            if FruitName == StocksName.Name then
                print("Updated", FruitName,"To:",StocksName.Main_Frame.Stock_Text.Text:match("X(%d+)") )
                FruitStocks[FruitName] = StocksName.Main_Frame.Stock_Text.Text:match("X(%d+)")
            end
        end
    end
end

local function findPlantingLocation(cropName, Plants)
    local cropFolder = Plants:FindFirstChild(cropName)
    if not cropFolder then
        warn("No crop folder found for:", cropName)
        return nil
    end

    local plantingSpot = cropFolder:FindFirstChild("1")
    if not plantingSpot then
        warn("No planting spot found for:", cropName)
        return nil
    end

    return plantingSpot.Position

end

local function getInput()
    local vim = game:GetService('VirtualInputManager')
    input = {
        hold = function(key, time)
            vim:SendKeyEvent(true, key, false, nil)
            task.wait(time)
            vim:SendKeyEvent(false, key, false, nil)
        end,
        press = function(key)
            vim:SendKeyEvent(true, key, false, nil)
        task.wait(0.005)
            vim:SendKeyEvent(false, key, false, nil)
        end
    }
    
    return input
end

local function sellInventory(ORGPlayerPos)
    local NPCPOS = Steven:WaitForChild("HumanoidRootPart").CFrame
    HRP.CFrame = NPCPOS
    task.wait(0.5)
    sellAll:FireServer()
    task.wait(0.5)
    HRP.CFrame = ORGPlayerPos

end
local function loopThroughPhysicalPlants(PhysicalPlants,input)
    for _,v in pairs(PhysicalPlants:GetChildren()) do

        repeat
            HRP.CFrame = ((v:FindFirstChild("Fruits"):GetChildren())[1]:FindFirstChild("1").CFrame)
            input.hold(Enum.KeyCode.E, 30)
        until not(v:FindFirstChild("Fruits"):GetChildren()[1]:FindFirstChild("1"))
    end
end

-- non constant variables(change based on plot)

local PlayerFarm = findPlayerFarm()
local PhysicalPlants = PlayerFarm.Important.Plants_Physical
local PlantingLocation = findPlantingLocation(WantedCrop, PhysicalPlants)
local input = getInput()

-- all the methods i created (plant all the seeds, buy seeds etc) *takes the variable "wantedcrop"* from above

updateCropsStocks(CropsList)
spawn(function()
    
while true do
    
    local InventoryCount = #(Backpack:GetChildren())
    if InventoryCount > 50 then
        local ORGPlayerPos = HRP.CFrame
        sellInventory(ORGPlayerPos)
    end
    wait(5)
end
end)

wait()
local function buyAndPlantSeeds(Money)
    for i,v in pairs(CropsList) do
        if FruitStocks[CropsList[i]] ~= 0 then
            WantedCrop = CropsList[i]
            PlantingLocation = findPlantingLocation(WantedCrop, PhysicalPlants)
            if PlantingLocation then
                for i = 0,FruitStocks[WantedCrop] do
                    buyCropSeeds(WantedCrop, Money)
                    for i = 0,FruitStocks[WantedCrop] do
                        task.wait()
                        plantAllSeeds(PlantingLocation)
                    end
                end
            else
                if FruitStocks[CropsList[i]] == 0 then
                    warn("No Stock for", FruitStocks[CropsList[i]])
                else
                warn("No Planting Location or Found For:",WantedCrop, "Place A Crop Demo Location!")
                end
            end
        end
    end
end

-- main game loop
    print("ran main game loop")
    loopThroughPhysicalPlants(PhysicalPlants, input)
    updateCropsStocks(CropsList)
    local Money = getMoney()
    buyAndPlantSeeds(Money) 
end
spawn(function()
while true do
main()
wait(60*5)
end
end)