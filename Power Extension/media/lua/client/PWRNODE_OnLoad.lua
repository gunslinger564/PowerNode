local function OnLoad()
    local modData = GetNodeData()
    if modData and modData.ActiveNodes then
        for _,d in pairs(modData.ActiveNodes) do
            local sq = getSquare(d.x,d.y,d.z)
            if d.state and sq then
                local node = PWR.findNode(sq)
                if node then
                    PWR.TurnON(d)
                end
            end
        end
    end
end

Events.OnLoad.Add(OnLoad)