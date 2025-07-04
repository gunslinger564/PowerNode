PWR = PWR or {}


-- thanks to multiple generators mod, much more organised than me


function PWR.removeNode(x,y,z)
    local moddata = GetNodeData()
    if x and y and z then
        for k,v in pairs(moddata.ActiveNodes)do
            if v.x == x and v.y == y and v.z == z then
                table.remove(moddata.ActiveNodes,k)
                if isClient() then
                        sendClientCommand(getPlayer(), 'PWRNODE', "REMOVENODE", {x=x, y=y, z=z})
                end
                break
            end
        end
    end
end


function PWR.getNode(x, y, z)
    local globalModData = GetNodeData()
    for k, v in pairs(globalModData.ActiveNodes) do
        if v then
            if v.x == x and v.y == y and v.z == z then
                print("PWR.getNode node found returning...")
                return v
            end
        end
    end
    return false
end
local function dataContains(x,y,z,data)
    for _,d in pairs(data)do
        if d.x == x and d.y == y and d.z == z then
            return true
        end
    end

end

function PWR.modifyNode(x,y,z,args)
    local n = PWR.getNode(x, y, z)
    if n then
        if args then
            for i,d in pairs(args)do
                n[i] = d
            end
        end
    end
    if isClient() then
        sendClientCommand(getPlayer(), 'PWRNODE', 'UPDATEDATA', n)
    end
end



function PWR.addNode(x,y,z,args)
    if x and y and z then
        local moddata = GetNodeData()
        if dataContains(x,y,z,moddata.ActiveNodes) then return end
        local entry = {}
        entry.x = x
        entry.y = y
        entry.z = z
        entry.state = false
        entry.powereditems = {}
        if args then
            for i,d in pairs(args)do
                entry[i] = d
            end
        end

      --  entry.generatorTotal = PWR.findGenerator(gen.x,gen.y,gen.z):getTotalPowerUsing()

        table.insert(moddata.ActiveNodes, entry)
        if isClient() then
            sendClientCommand(getPlayer(), 'PWRNODE', 'ADDNODE', entry)
        end
    end
end