


local function sendCommand(command,args)
    if not isServer() then return end
    local players = getOnlinePlayers()
    for i = 0 ,players:size()-1 do
        local p = players:get(i)
        sendServerCommand(p,"PWRNODE",command,args)
    end
end

--another copied from multiple generators
function PWRNODE_UPDATE()
    print("pwrnode update run")

    if isClient() then return end
    
    local modData = GetNodeData()
    local nodes = modData.ActiveNodes
    if nodes ~= nil then

        PWR.squareSkipCache = {}
        local multi

        local function isNodeGen(gen,n)
            for _,d in pairs(n.generator) do
                if d.x == gen.x and d.y == gen.y and d.z == gen.z then
                    return true
                end
            end
        end



        if getActivatedMods():contains("MultipleGenerators") == true then
             require"MGVirtualGenerator"
            multi = VirtualGenerator.GetAll()
        end
        for k1,n in pairs(nodes) do
            n.poweredItems = n.poweredItems or {}
            local square = getSquare(n.x,n.y,n.z)
            if square then
                if n.state then
                    n.poweredItems = PWR.getSurroundingPoweredItems(n.x,n.y,n.z)
                    if multi ~= nil then
                        for k2,generator in pairs(multi)do
                                if generator.state then
                                    for _, item1 in pairs(generator.poweredItems)do
                                        item1.div = 1
                                        if k1 ~= k2 and math.abs(generator.x - n.x) <41 and math.abs(generator.y - n.y) < 41 then
                                            if not isNodeGen(generator,n) then
                                                for _,item2 in pairs(n.poweredItems)do
                                                    if item1.x == item2.x and item1.y == item2.x and item1.z == item2.z then
                                                        item2.div = item2.div +1
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                        end
                    end
                end
            end
        end
        local fuelConsumption = getSandboxOptions():getOptionByName("GeneratorFuelConsumption"):getValue()
        

local function findDuplicates(tables)
    local seen = {}
    for i, t in ipairs(tables) do
        local key
        if t.x and t.y and t.z then
            key = t.x .. "," .. t.y .. "," .. t.z
        elseif t.bank then
            key = t.bank.x .. "," .. t.bank.y .. "," .. t.bank.z
        end
        if seen[key] then
            table.remove(tables,i)
        else
            seen[key] = i
        end
    end
end
        local function checkCables(x,y,z,data)
            local cables = PWR.findCable({x,y,z})
            local tmp = {}
            if cables then
                for color,tbl in pairs(cables)do
                    for i,d in pairs(data)do
                        if d.color == color then
                            tmp[i] = d
                        end
                    end
                end
            end
            data = tmp
        end



        local function checkGens(obj)
            local data = obj.generator
            local c = 0
            for i,d in pairs(data)do
                local gen
                if d.bank then
                    local PbSystem = require "Powerbank/ISAPowerbankSystem_server"
                    local powerBank = PbSystem.instance:getLuaObjectAt(d.bank.x,d.bank.y,d.bank.z)
                    if powerBank and powerBank.on and powerBank.charge and powerBank.charge > 0 then
                        c = c +1
                    end
                else
                    gen = PWR.findGenerator(d.x,d.y,d.z)
                    if not gen then
                        table.remove(obj.generator,i)
                    elseif gen and gen:isActivated() then
                        c = c +1
                    end
                end

            end
            return c
        end


        for _, obj in pairs(nodes)do
            if obj.state then
                local node = PWR.findNode({obj.x,obj.y,obj.z})
                
                if not node then
                    PWR.removeNode(obj.x,obj.y,obj.z)
                else
                    --local nsq = node:getSquare()
                   -- if nsq and not nsq:haveElectricity() then
                     --   obj.toggle = true
                    --    PWR.updateData(obj)
                  --  end
                    PWR.setNodeOverlays(node)
                    checkCables(obj.x,obj.y,obj.z,obj.generator)
                    findDuplicates(obj.generator)
                    local numGens = checkGens(obj)
                    local groupPoweredItems = {}
                    local total,realTotal = 0.0,0.0
                    if numGens > 0 then
                        for k, item in pairs(obj.poweredItems) do
                            item.div = (item.div + numGens)-1
                            item.realPower = (item.power / item.div)
                            if groupPoweredItems[item.name] then
                                groupPoweredItems[item.name].realPower = groupPoweredItems[item.name].realPower + item.realPower
                                groupPoweredItems[item.name].times = groupPoweredItems[item.name].times + 1
                            else
                                groupPoweredItems[item.name] = item
                                groupPoweredItems[item.name].realPower = item.realPower
                                groupPoweredItems[item.name].times = 1
                            end
                            
                            total = total + item.power
                            realTotal = realTotal + item.realPower
                        end
                        obj.groupPoweredItems = groupPoweredItems
                        obj.realTotalPower = realTotal
                        obj.totalPower = total
                        obj.totalFuelConsumption = (total * fuelConsumption)
                        obj.realTotalFuelConsumption = (realTotal * fuelConsumption)
                        local generators = obj.generator
                        
                        if generators then
                            for _,g in pairs(generators) do
                                if g.bank then
                                    local PbSystem = require "Powerbank/ISAPowerbankSystem_server"
                                    local powerBank = PbSystem.instance:getLuaObjectAt(g.bank.x,g.bank.y,g.bank.z)
                                    if powerBank and powerBank.on and powerBank.charge and powerBank.charge > 0 then
                                        print("bank found adding node to data")
                                        powerBank.node = {x=obj.x,y=obj.y,z=obj.z}
                                        powerBank:saveData(true)
                                    elseif powerBank and (not powerBank.on or powerBank.charge <= 0) then
                                        print("bank found but turned off removing node data")
                                        powerBank.node = nil
                                        powerBank:saveData(true)
                                    end
                                else
                                    print("updating generator at "..g.x.." "..g.y.." "..g.z)
                                    local gen = PWR.findGenerator(g.x,g.y,g.z)
                                    if gen and node then
                                        if gen:isActivated() == true and obj.state == true then
                                                --multiple generator compatability
                                            if multi ~= nil then
                                                print("setting multi generator data")
                                                    local vg = VirtualGenerator.Get(g.x,g.y,g.z)
                                                    if vg then
                                                        print("virtual gen found")
                                                        vg.groupPoweredItems = vg.groupPoweredItems or {}
                                                        for k, item in pairs(groupPoweredItems) do
                                                            if not item.name:contains("(NODE)") then
                                                                item.name = item.name.."(NODE)"
                                                            end
                                                            vg.groupPoweredItems[item.name.."NODE"] = item
                                                        end
                                                        vg.totalPower = vg.totalPower or 0
                                                        vg.totalPower = total + vg.totalPower
                                                        vg.realTotalPower = vg.realTotalPower or 0
                                                        vg.realTotalPower = realTotal + vg.realTotalPower
                                                        vg.totalFuelConsumption = vg.totalFuelConsumption or 0
                                                        vg.totalFuelConsumption = (total * fuelConsumption) + vg.totalFuelConsumption
                                                        vg.realTotalFuelConsumption = vg.realTotalFuelConsumption or 0
                                                        vg.realTotalFuelConsumption = (realTotal * fuelConsumption) + vg.realTotalFuelConsumption

                                                        if not vg.fuel then vg.fuel = 0 end

                                                        local interval = 6
                                                        local hourlyRealConsumptionPercent = realTotal * 100 / (100 / fuelConsumption)
                                                        local intervalRealConsumptionPercent = hourlyRealConsumptionPercent / interval
                                                        vg.fuel = vg.fuel - intervalRealConsumptionPercent
                                                        if vg.fuel < 0 then vg.fuel = 0 end
                                                        local isoGenerator = MGGenerator.GetGenerator(vg.x, vg.y, vg.z)
                                                        if isoGenerator then
                                                            isoGenerator:setFuel(vg.fuel)
                                                            if vg.fuel == 0 then
                                                                if isoGenerator:isActivated() then
                                                                    isoGenerator:setActivated(false)
                                                                end
                                                                vg.state = false
                                                            else
                                                                if not isoGenerator:isActivated() then
                                                                    isoGenerator:setActivated(true)
                                                                end
                                                                vg.state = true
                                                            end
                                                            isoGenerator:transmitModData()
                                                            if not vg.realTotalPowerHistory then
                                                                vg.realTotalPowerHistory = {}
                                                            end
                                                            if #vg.realTotalPowerHistory > 288 then
                                                                table.remove(vg.realTotalPowerHistory, 1)
                                                            end
                                                            if vg.state and vg.realTotalPower then
                                                                table.insert(vg.realTotalPowerHistory, vg.realTotalPower)
                                                            else
                                                                table.insert(vg.realTotalPowerHistory, 0)
                                                            end
                                                        end
                                                    end
                                            else
                                                local genpower = PWR.getSurroundingPoweredItems(g.x,g.y,g.z)
                                                local gentotal = 0.02
                                                for k, item in pairs(genpower) do
                                                    item.realPower = item.power / item.div
                                                    gentotal = gentotal + item.realPower
                                                end
                                                gen:setTotalPowerUsing(gentotal + realTotal)
                                                if isServer() then
                                                    sendCommand("UPDATEGEN",{g,gentotal + realTotal})
                                                end
                                            end
                                        else
                                            if not gen:isActivated() then print("generator not active")end
                                            if not obj.state then print("node not activated") end
                                        end
                                    else
                                        if not gen then print("generator not found")end
                                    end
                                end
                            end
                        end
                    else
                        print("0 generators found turning off node")
                        obj.toggle = true
                        obj.state = false
                        PWR.updateData(obj)
                    end
                end
            else
                local sq = getSquare(obj.x,obj.y,obj.z)
                if sq and sq:haveElectricity() then
                    obj.toggle = true
                    PWR.updateData(obj)
                end
            end
        end
        TransmitNodeData()
    end
end
Events.EveryTenMinutes.Add(PWRNODE_UPDATE)
