
if getActivatedMods():contains("MultipleGenerators") == true then
    require"MGVirtualGenerator"
    require"MGGeneratorInfoWindow"

    local originalRemove = VirtualGenerator.Remove

    function VirtualGenerator.Remove (x, y, z)
        if x and y and z then
            local nodeData = GetNodeData()
            for _,n in pairs(nodeData.ActiveNodes)do
                if n.x == x and n.y == y and n.z == z then
                    if n.removevg then
                        n.removevg = nil
                        break
                    else
                        return
                    end
                end
            end
        end
        originalRemove(x,y,z)
    end
end