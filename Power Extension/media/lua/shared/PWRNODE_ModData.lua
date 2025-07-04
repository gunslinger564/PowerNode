--PWR.ModData = {}
Nodedata = {}
local function InitModData(isNewGame)

    local modData = ModData.getOrCreate("NodeData")

    if isClient() then
        ModData.request("NodeData")
    end

    modData.ActiveNodes = modData.ActiveNodes or {}
    modData.ActiveChunks = modData.ActiveChunks or {}

    --PWR.ModData = modData
    Nodedata = modData

end

local function LoadModData(key, modData)
    if isClient() then
        if key and key == "NodeData" and modData then
            --PWR.ModData = modData
            Nodedata = modData
        end
    end
end

function TransmitNodeData()
    ModData.transmit("NodeData")
end

function GetNodeData()
    --[[
    if isClient() then
        ModData.request("NodeData")
        Nodedata = ModData.getOrCreate("NodeData")
    end--]]
    return Nodedata
end



Events.OnInitGlobalModData.Add(InitModData)
Events.OnReceiveGlobalModData.Add(LoadModData)