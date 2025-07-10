
    local itemList = {
    "PowerNodes.OrangeExtensionCord",
    "PowerNodes.YellowExtensionCord",
    "PowerNodes.GreenExtensionCord",
    "PowerNodes.RedExtensionCord",
    "PowerNodes.BlueExtensionCord",

    }

    local locations = {
    "DrugShackTools",
    "CrateTools",
    "EngineerTools",
    "FactoryLockers",
    "GarageTools",
    "GigamartTools",
    "JanitorTools",
    "MechanicShelfTools",
    "MetalShopTools",
    "ToolStoreMisc",
    "ToolStoreTools",
    }

    local insert = table.insert
    local list = ProceduralDistributions.list
    
    local function addItems(dist,loot)
        for i = 1, #loot do
            insert(dist,loot[i])
        end
    end
    for _,i in pairs(itemList)do
        for _,x in pairs(locations)do
            addItems(list[x].items,{i,2.0,})
        end
    end

