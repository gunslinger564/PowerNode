PWR = PWR or {}

function PWR.Debug(txt)
   --[[] if isDebugEnabled() then
        txt = tostring(txt)
        print("PWRNODE_PWR.Debug: "..txt)
    end--]]
end

function PWR.getColor(cable)
    local tex
    if instanceof(cable,"IsoObject") then
        tex = cable:getTextureName()
    elseif type(cable) == "string" then
        tex = cable
    end
    if tex then
        local num = string.match(tex, "(%d+)$")
        num = tonumber(num)
        if num < 48 then
            return "orange"
        elseif num >=48 and num < 96 then
            return "yellow"
        elseif num >= 96 and num < 144 then
            return "green"
        elseif num >= 144 and num < 192 then
            return "red"
        elseif num >= 192 then
            return "blue"
        end
    end
end

--returns tile number modifier from the color
function PWR.getMod(color)
    local pick = {
    ["orange"] = 0,
    ["yellow"] = 48,
    ["green"] = 96,
    ["red"] = 144,
    ["blue"] = 192,
    }
    if not pick[color] then return 0 end
    return pick[color]
end

local function genAdded(data,gen)
    for _,g in pairs(data)do
        if g.x == gen.x and g.y == gen.y and g.z == gen.z then return true end
    end
end


local function networkHasGenerator(startX, startY, startZ, generatorData, color)
    local visited = {}
    local queue = {{x = startX, y = startY, z = startZ}}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local key = current.x .. "," .. current.y .. "," .. current.z
        
        if not visited[key] then
            visited[key] = true
            local gen = PWR.findGenerator(generatorData.x, generatorData.y, generatorData.z)
            if gen then gen = gen:getModData().switch end
            -- Check if we've reached the generator position
            if gen and current.x == gen[1] and current.y == gen[2] and current.z == gen[3] then
                -- Verify the generator still exists
                local switch = PWR.findSwitch({gen[1], gen[2], gen[3]})
                if switch ~= nil then
                    return true
                end
            end
            
            -- Check all six directions
            local directions = {
                {0, 0, 1}, {0, 0, -1}, {0, 1, 0}, {0, -1, 0}, {1, 0, 0}, {-1, 0, 0}
            }
            
            for _, dir in ipairs(directions) do
                local nx, ny, nz = current.x + dir[1], current.y + dir[2], current.z + dir[3]
                local neighborCable = PWR.findCable({nx, ny, nz})
                
                if neighborCable and neighborCable[color] then
                    table.insert(queue, {x = nx, y = ny, z = nz})
                end
            end
        end
    end
    
    return false
end

-- Modified propagation function that only removes data if no generator access
local function propagateGeneratorData(startX, startY, startZ, generatorData, color, disconnect)
    -- If disconnecting, first check if this network still has generator access
    if disconnect then
        local stillHasGenerator = networkHasGenerator(startX, startY, startZ, generatorData, color)
        if stillHasGenerator then
            -- This network still has access to the generator, don't remove data
            return
        end
    end
    
    local visited = {}
    local queue = {{x = startX, y = startY, z = startZ}}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local key = current.x .. "," .. current.y .. "," .. current.z
        
        if not visited[key] then
            visited[key] = true
            
            -- Check all six directions
            local directions = {
                {0, 0, 1}, {0, 0, -1}, {0, 1, 0}, {0, -1, 0}, {1, 0, 0}, {-1, 0, 0}
            }
            
            for _, dir in ipairs(directions) do
                local nx, ny, nz = current.x + dir[1], current.y + dir[2], current.z + dir[3]
                local neighborCable = PWR.findCable({nx, ny, nz})
                
                if neighborCable and neighborCable[color] then
                    neighborCable = neighborCable[color]
                    local node = PWR.findNode({nx, ny, nz})
                    generatorData.color = color
                    
                    if disconnect then
                        neighborCable:getModData().generator = nil
                    else
                        neighborCable:getModData().generator = generatorData
                    end

                    if node ~= nil then
                        local vn = PWR.getNode(nx, ny, nz)
                        if disconnect then
                            local ndata = node:getModData().generator
                            for i,tbl in pairs(ndata)do
                                if tbl.x == generatorData.x and tbl.y == generatorData.y and tbl.z == generatorData.z then
                                    table.remove(ndata,i)
                                end
                            end

                            node:getModData().generator = ndata
                        else
                            node:getModData().generator = node:getModData().generator or {}
                            if not genAdded(node:getModData().generator, generatorData) then
                                table.insert(node:getModData().generator, generatorData)
                            end
                        end
                        if not vn then
                            vn = PWR.addNode(nx, ny, nz,{generator = node:getModData().generator})
                        else
                            vn.generator = node:getModData().generator
                            if isClient() then
                                sendClientCommand(getPlayer(), 'PWRNODE', 'UPDATEDATA', vn)
                            end
                        end
                        node:transmitModData()
                    end
                    table.insert(queue, {x = nx, y = ny, z = nz})
                    neighborCable:transmitModData()
                end
            end
        end
    end
end

-- Modified onCablePlaced function
function PWR.onCablePlaced(obj, disconnect)
    PWR.Debug("PWR.onCablePlaced run")
    local x, y, z = obj:getX(), obj:getY(), obj:getZ()
    local newCable = obj
    local directions = {
        {0, -1, 0},
        {0, 1, 0},
        {1, 0, 0},
        {-1, 0, 0}
    }
    local generatorData = nil
    local color = PWR.getColor(obj)
    
    -- Find generator data from neighbors
    for _, dir in ipairs(directions) do
        local nx, ny, nz = x + dir[1], y + dir[2], z + dir[3]
        local neighborCable
        local cables = PWR.findCable({nx, ny, nz})
        if cables and cables[color] then
            neighborCable = cables[color]
        end
        if neighborCable then
            local data = neighborCable:getModData().generator
            if data ~= nil then
                local gen
                if data.bank then
                    local PbSystem = require "Powerbank/ISAPowerbankSystem_server"
                    gen = PbSystem.instance:getLuaObjectAt(data.bank.x,data.bank.y,data.bank.z)
                else
                    gen = PWR.findGenerator(data.x, data.y, data.z)
                end
                if gen ~= nil then
                    generatorData = neighborCable:getModData().generator
                else
                    neighborCable:getModData().generator = nil
                end
                break
            end
        end
    end
    
    if generatorData then
        generatorData.color = color
        local node = PWR.findNode({x, y, z})
        
        if disconnect == true then
            --newCable:getModData().generator = nil
            if node ~= nil then
                node:getModData().generator = nil
            end
        else
            if node ~= nil then
                node:getModData().generator = node:getModData().generator or {}
                if not genAdded(node:getModData().generator, generatorData) then
                    table.insert(node:getModData().generator, generatorData)
                end
            end
            newCable:getModData().generator = generatorData
        end
        
        newCable:transmitModData()
        if node ~= nil then
            node:transmitModData()
        end
        
        -- Propagate to all connected networks
        if disconnect then
            -- When disconnecting, we need to check each connected network separately
            for _, dir in ipairs(directions) do
                local nx, ny, nz = x + dir[1], y + dir[2], z + dir[3]
                local cables = PWR.findCable({nx, ny, nz})
                if cables and cables[color] then
                    -- Check this network independently
                    propagateGeneratorData(nx, ny, nz, generatorData, color, disconnect)
                end
            end
        else
            -- Normal propagation when connecting
            propagateGeneratorData(x, y, z, generatorData, color, disconnect)
        end
    end
end

function PWR.findGenerator(x,y,z)
    
        local nx,ny,nz = x,y,z
        if type(x) == "table" then
            nx,ny,nz = x[1],x[2],x[3]
        end
        if nx and ny and nz then
            local square = getSquare(nx,ny,nz)
            if square then
                return square:getGenerator()
            end
        end
end

local function findPowerObject(x,y,z,pick)
    local function getTileNum(str)
        if str == nil then return end
        local num = string.match(str, "_(.*)")
        return tonumber(num)
    end
    local square = getSquare(x,y,z)
    local cables
    if square then
        for i=0,square:getObjects():size()-1 do
            local obj = square:getObjects():get(i)
            if obj then
                local tex = obj:getTextureName()
                if tex and tex:contains("PowerNodesTiles") and not tex:contains("PowerNodesTiles_Cords") then
                    local num = getTileNum(tex)
                    if num ~= nil then
                        if num<= 3 and pick == "SWITCH" then
                            return obj
                        elseif num >= 4 and num <= 7 and pick == "NODE" then
                            return obj
                        end
                    end
                elseif tex and tex:contains("PowerNodesTiles_Cords") and pick == "CABLE" then
                   local color = PWR.getColor(obj)
                    cables = cables or {}
                    cables[color] = obj
                end
            end
        end
        return cables
    end
    
end
local function sortCoords(location)
    PWR.Debug("sortCoords run")
    local x,y,z
    if instanceof(location,"IsoGridSquare")then
        x,y,z = location:getX(),location:getY(),location:getZ()
    elseif type(location) == "table" then
        x,y,z = location[1],location[2],location[3]
    end
    if x and y and z then
    return {x,y,z} end
end

function PWR.findNode(location)
    PWR.Debug("PWR.findNode run")
    local coords = sortCoords(location)
    if coords then
        return findPowerObject(coords[1],coords[2],coords[3],"NODE")
    end
end

function PWR.findCable(location)
    PWR.Debug("PWR.findCable run")
    local coords = sortCoords(location)
    if coords then
        return findPowerObject(coords[1],coords[2],coords[3],"CABLE")
    end
end

function PWR.findSwitch(location)
    PWR.Debug("PWR.findSwitch run")
    local coords = sortCoords(location)
    if coords then
        return findPowerObject(coords[1],coords[2],coords[3],"SWITCH")
    end
end


--return table of chunks in the power range
function PWR.getChunks(cx,cy,cz)
    PWR.Debug("PWR.getChunks run")
    local chunks = {}
    local r = PWRRadius or 20
    local function chunkDone(chunk)
        if not chunk then return end
        for _,c in pairs(chunks)do
            if c == chunk then return true end
        end
    end
    local world = getWorld()
    for x = cx-r,cx+r do
        for y = cy-r,cy+r do
            if not(IsoUtils.DistanceToSquared(x + 0.5, y + 0.5, cx + 0.5, cy + 0.5) > 400) then
                local sq = getSquare(x,y,cz)
                if sq then
                    local chunk = sq:getChunk()
                    if chunkDone(chunk) then
                    else
                        table.insert(chunks,chunk)
                    end
                elseif not sq and world:isValidSquare(x,y,cz) then
                    print("not all square loaded making table of missing squares")
                    PWR.SquaresToLoad = PWR.SquaresToLoad or {}
                    PWR.SquaresToLoad[x.." "..y.." "..cz] = {cx,cy,cz}
                end
            end
        end
    end
    return chunks
end

function PWR.setChunks(node,command,sync)
    PWR.Debug("PWR.setChunks run")
    if command == nil then return end
    local gx,gy,gz = node[1],node[2],node[3]
    local chunks =  PWR.getChunks(gx,gy,gz)
    if chunks == nil then return end
    if sync then
       -- sendClientCommand(getPlayer(),"PWRNODE","CHECKPWR",{command,{x = gx,y = gy,z = gz}})
    end
    for _,chunk in pairs(chunks)do
        if command == "TURNON" then
            chunk:addGeneratorPos(gx,gy,gz)
        elseif command == "SHUTDOWN" then
            chunk:removeGeneratorPos(gx,gy,gz)
        end
    end
    --node:getModData().chunks = chunks
    return chunks
end

function PWR.setNodeOverlays(node)
    if not node then return end
    node:setAttachedAnimSprite(ArrayList.new())
    if node:getModData().status ~= "ON" then return end
    local tex = node:getTextureName()
    local tiled
    if tex:contains("4") then
        tiled = 4
    elseif tex:contains("5") then
        tiled = 5
    end
    if tiled then
        local cables = PWR.findCable({node:getX(),node:getY(),node:getZ()})
        
        if cables then
            local tilenum = {
            [4] = {orange = 0,yellow = 2,green = 4,red = 6,blue = 8},
            [5] = {orange = 1,yellow = 3,green = 5,red = 7,blue = 9},
            }
            
            local count = 0
            for c,obj in pairs(cables)do
                count = count+1
                local g = obj:getModData().generator
                local ison
                if g and g.bank then
                    local PbSystem = require "Powerbank/ISAPowerbankSystem_server"
                    local powerBank = PbSystem.instance:getLuaObjectAt(g.bank.x,g.bank.y,g.bank.z)
                    if powerBank and powerBank.on and powerBank.charge and powerBank.charge > 0 then
                        ison = true
                    end
                elseif g then g = PWR.findGenerator(g.x,g.y,g.z)
                    if g and g:isActivated() then
                        ison = true
                    end
                end
                if ison then
                    local num
                    local tbl = tilenum[tiled]
                    if tbl then num = tbl[c] end
                    if num then
                        node:getAttachedAnimSprite():add(getSprite("PowerNodesTiles_2_"..num):newInstance())
                    end
                end
            end
        end
    end
    node:transmitUpdatedSpriteToServer()
end
function PWR.shutDown(args)
    if not args then return end
    local gdata = args.generator
    local gen
    if gdata then
        gen = PWR.findGenerator(gdata.x,gdata.y,gdata.z)
    end
    local node = PWR.findNode({args.x,args.y,args.z})
    --print("PWR.shutDown run")
    local powered = args.realTotalPower
    if powered and gen and not getActivatedMods():contains("MultipleGenerators") then
        local genTotalPower = gen:getTotalPowerUsing()
        local total = genTotalPower - powered
        gen:setTotalPowerUsing(total)
    end
    PWR.setChunks({args.x,args.y,args.z},"SHUTDOWN",true)
    node:getModData().status = "OFF"
    node:transmitModData()
    node:RemoveAttachedAnims()
    node:transmitUpdatedSpriteToServer()
    local moddata = GetNodeData()
    args.state = false
    for k, n in pairs(moddata.ActiveNodes)do
        if args.x == n.x and args.y == n.y and args.z == n.z then
            table.remove(moddata.ActiveNodes,k)
            table.insert(moddata.ActiveNodes,args)
            break
        end
    end
end


function PWR.TurnON(args)
    print("PWR.TurnON run")
    local moddata = GetNodeData()
    local gdata = args.generator
    local gen
    if gdata and not getActivatedMods():contains("MultipleGenerators") then
        gen = PWR.findGenerator(gdata.x,gdata.y,gdata.z)
        local powered = args.totalPower
        if powered and gen then
            local genTotalPower = gen:getTotalPowerUsing()
            local total = genTotalPower + powered
            gen:setTotalPowerUsing(total)
        end

    end
    
    local node = PWR.findNode({args.x,args.y,args.z})
    args.state = true
    for k, n in pairs(moddata.ActiveNodes)do
        if args.x == n.x and args.y == n.y and args.z == n.z then
            table.remove(moddata.ActiveNodes,k)
            table.insert(moddata.ActiveNodes,args)
            break
        end
    end
    PWR.setChunks({args.x,args.y,args.z},"TURNON",true)
    if node ~= nil then
        node:getModData().status = "ON"
        node:transmitModData()
        PWR.setNodeOverlays(node)
    end
end
function PWR.toggle(node,s)
    local mods = getActivatedMods()
    local multigens = {}
    multigens.active = mods:contains("MultipleGenerators")
    local x,y,z = node:getX(),node:getY(),node:getZ()
        local moddata,entry = GetNodeData(),{}
        for k,v in pairs(moddata.ActiveNodes) do
            if v then
                if v.x == x and v.y == y and v.z == z then
                    entry = v
                    if s == "ON" then
                        entry.state = false
                        node:getModData().status = "OFF"
                    else
                        entry.state = true
                        node:getModData().status = "ON"
                        if multigens.active then
                            VirtualGenerator.Add(x, y, z,0)
                        end
                    end
                    node:transmitModData()
                    table.remove(moddata.ActiveNodes, k)
                    table.insert(moddata.ActiveNodes, entry)
                    if isClient() then
                        entry.toggle = true
                        sendClientCommand(getPlayer(), 'PWRNODE', 'UPDATEDATA', entry)
                    elseif isServer() then
                        entry.toggle = true
                        PWR.updateData(entry)
                    else
                        if entry.state == false then
                            PWR.shutDown(entry)
                        else
                            PWR.TurnON(entry)
                        end
                        PWRNODE_UPDATE()
                    end
                        if multigens.active and not entry.state then
                            entry.removevg = true
                            VirtualGenerator.Remove(x, y, z)
                        elseif multigens.active then
                            VirtualGenerator.Add(x, y, z,0)
                        end
                    break
                end
            end
        end
        if isClient() then
            sendClientCommand(getPlayer(),"PWRNODE", "UPDATE", {})
        end
        --if genRange.active and isShowing then
        --    genRange.ClearRender(true)
         --   genRange.Render(node, node:getModData().status == "ON")
        --end
end
local function getPoweredItemName(object)
    local name = getText("IGUI_VehiclePartCatOther")

    local propertyContainer = object:getProperties()
        
    if propertyContainer and propertyContainer:Is("CustomName") then
        local moveableName = "Moveable Object"

        if propertyContainer:Is("GroupName") then
            moveableName = propertyContainer:Val("GroupName") .. " " .. propertyContainer:Val("CustomName")
        else
            moveableName = propertyContainer:Val("CustomName")
        end
    
        name = Translator.getMoveableDisplayName(moveableName)
    end
    if instanceof(object, "IsoLightSwitch") then
        name = getText("IGUI_Lights")
    end
    return name
end
--stolen from multiple generators, thanks!

local vehicles = {}
local function findVehicles(x,y,z)
        local square = getSquare(x,y,z)
        if square then
            local objs = square:getMovingObjects()
            for i=0,objs:size()-1 do
                local obj = objs:get(i)
                if obj and instanceof(obj,"BaseVehicle")then
                    if vehicles[obj:getId()] then return false end
                    local battery = obj:getBattery()
                    if battery and battery:getInventoryItem() then
                        local chargeOld = battery:getInventoryItem():getUsedDelta()
                        if chargeOld >= 1.0 then return false end
                        
	                    local charge = chargeOld
                        charge = math.max(charge + 0.013888889165, 0.0)
                        charge = math.min(charge + 0.013888889165, 1.0)
                        if charge ~= chargeOld then
                            battery:getInventoryItem():setUsedDelta(charge)
                            if VehicleUtils.compareFloats(chargeOld, charge, 2) then
                                obj:transmitPartUsedDelta(battery)
                            end
                        end
                        vehicles[obj:getId()] = true
                        return true
                    end
                end
            end
        end
end

local function sendCommand(command,args)
    if not isServer() then return end
        local players = getOnlinePlayers()
    for i = 0 ,players:size()-1 do
        local p = players:get(i)
        sendServerCommand(p,"PWRNODE",command,args)
    end
end



--only used by server
function PWR.getSurroundingPoweredItems(cx,cy,cz)
    local tSquare = getSquare(cx,cy,cz)
    local gen
    --check the square for a generator do not power vehicles if true
    if tSquare then
        gen = tSquare:getGenerator()
    end
    local unPowerd = {}
    local toSend = {}
    local poweredItems = {}
    local p
    toSend.center = {cx,cy,cz}
    toSend.squares = {}
        for z = cz-2, cz+2 do
            for y = cy-20, cy+20 do
                for x = cx-20, cx+20 do
                    if z >= 0 and not (IsoUtils.DistanceToSquared(x + 0.5, y + 0.5, cx + 0.5, cy + 0.5) > 400) then
                    local sid = tostring(x) .. "-" .. tostring(y) .. tostring(z)
                        if not PWR.squareSkipCache[sid] then
                            local square = getSquare(x,y,z)
                            local vehicle
                            if square then
                                if not gen then
                                    vehicle = findVehicles(x,y,z)
                                    
                                    table.insert(toSend.squares,{x,y,z})
                                    if not square:haveElectricity() then
                                       -- if not p then print("squares without power found attempting to add generator position") p = true end
                                        table.insert(unPowerd,square)
                                    end
                                end


                                local objects = square:getObjects()
                                local foundPoweredItem = false
                                for i=0, objects:size()-1 do
                                    local object = objects:get(i)

                                    local name = getPoweredItemName(object)
                                    local power = 0
                                    
                                    local isClothingDryer = instanceof(object, "IsoClothingDryer") and object:isActivated()
                                    local isClothingWasher = instanceof(object, "IsoClothingWasher") and object:isActivated()
                                    local isCombinationWasherDryer = instanceof(object, "IsoCombinationWasherDryer") and object:isActivated()
                                    local isStackedWasherDryer = instanceof(object, "IsoStackedWasherDryer") and (object:isDryerActivated() or object:isWasherActivated())
                                    local isTelevision = instanceof(object, "IsoTelevision") and object:getDeviceData():getIsTurnedOn()
                                    local isRadio = instanceof(object, "IsoRadio") and object:getDeviceData():getIsTurnedOn() and not object:getDeviceData():getIsBatteryPowered()
                                    local isStove = instanceof(object, "IsoStove") and object:Activated()
                                    local isFridge = object:getContainerByType("fridge") ~= nil
                                    local isFreezer = object:getContainerByType("freezer") ~= nil
                                    local isLights = instanceof(object, "IsoLightSwitch") and object:isActivated()

                                    if isClothingDryer then power = 0.09 end
                                    if isClothingWasher then power = 0.09 end
                                    if isCombinationWasherDryer then power = 0.09 end
                                    if isStackedWasherDryer then power = 0.09 end
                                    if isTelevision then power = 0.03 end
                                    if isRadio then power = 0.01 end
                                    
                                    if isStove then
                                        local temp = object:getCurrentTemperature()
                                        power = 0.09 * temp / 100
                                    end

                                    if isFridge and isFreezer then
                                        power = 0.13
                                    elseif isFridge or isFreezer then
                                        power = 0.08
                                    end

                                    if isLights then power = 0.002 end
                                    
                                    if vehicle then
                                        power = power + 0.02
                                        name = "Car Battery"
                                    end
                                    if power > 0 then
                                        table.insert(poweredItems, {name=name, power=power, div=1, x=x, y=y, z=z})
                                        foundPoweredItem = true
                                    end
                                end
                                if foundPoweredItem then
                                    PWR.squareSkipCache[sid] = false
                                else
                                    PWR.squareSkipCache[sid] = true
                                end
                            end
                        else
                            PWR.squareSkipCache[sid] = true
                        end
                    end
                end
            end
        end
        --makes sure the chunks have power
        sendCommand("CHECK",toSend)
        for _,sq in pairs(unPowerd)do
            if not sq:haveElectricity() then
                local chunk = sq:getChunk()
                if chunk then
                    chunk:addGeneratorPos(cx,cy,cz)
                end
            end
        end
            vehicles = {}
        return poweredItems
end
