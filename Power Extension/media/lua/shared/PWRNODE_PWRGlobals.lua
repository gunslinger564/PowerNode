PWR = PWR or {}

function PWR.Debug(txt)
   --[[] if isDebugEnabled() then
        txt = tostring(txt)
        print("PWRNODE_PWR.Debug: "..txt)
    end--]]
end


--returns the cable color as a string
--- @param cable IsoObject
--- @return string
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
--- @param color string
--- @return integer
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

--checks a split in cables to keep data on side that has a generator
local function networkHasGenerator(startX, startY, startZ, generatorData, color)
   -- if not generatorData then return false end
    local visited = {}
    local queue = {{x = startX, y = startY, z = startZ}}
   -- local gen = PWR.findGenerator(generatorData.x, generatorData.y, generatorData.z)
   -- local scoords
   -- if gen then
  --     scoords = gen:getModData().switch
   -- end
   -- local switch
   -- if scoords then
   -- switch = PWR.findSwitch({scoords[1],scoords[2],scoords[3]})
   -- end
   -- if not switch then return end
   --- if (gen and not gen:isConnected() == true ) or not gen then return false end
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local key = current.x .. "," .. current.y .. "," .. current.z
        
        if not visited[key] then
            visited[key] = true
            local switch = PWR.findSwitch({current.x,current.y,current.z})
            if switch then
                local gdata = switch:getModData().generator
                local gen = PWR.findGenerator(gdata.x,gdata.y,gdata.z)
                if gen and gen:isConnected() then
                    return switch:getModData().generator
                end
            end
            -- Check if we've reached the switch position

            
            -- Check all six directions
            local directions = {
                {0, 1, 0}, {0, -1, 0}, {1, 0, 0}, {-1, 0, 0}
            }
            
            for _, dir in ipairs(directions) do
                local nx, ny, nz = current.x + dir[1], current.y + dir[2], current.z + dir[3]
                local neighborCable = PWR.findCable({nx, ny, nz})
                
                if neighborCable ~= nil and neighborCable[color] ~= nil then
                    table.insert(queue, {x = nx, y = ny, z = nz})
                end
            end
        end
    end
    --return false
end

--move generator data through extension cords
local function propagateGeneratorData(startX, startY, startZ, generatorData, color, disconnect)
    -- If disconnecting, first check if this network still has generator access
    local stillHasGenerator = networkHasGenerator(startX, startY, startZ, generatorData, color)
    if disconnect and stillHasGenerator then
            -- This network still has access to the generator, don't remove data
            return
    end
    generatorData = generatorData or stillHasGenerator
    local visited = {}
    local queue = {{x = startX, y = startY, z = startZ}}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local key = current.x .. "," .. current.y .. "," .. current.z
        if not visited[key] then
            local ccable = PWR.findCable({current.x, current.y, current.z})
            if ccable and ccable[color] and stillHasGenerator then
                ccable[color]:getModData().generator = generatorData
            end
            visited[key] = true
            
            local directions = {
                {0, 1, 0}, {0, -1, 0}, {1, 0, 0}, {-1, 0, 0}
            }
            
            for _, dir in ipairs(directions) do
                local nx, ny, nz = current.x + dir[1], current.y + dir[2], current.z + dir[3]
                local neighborCable = PWR.findCable({nx, ny, nz})
                
                if neighborCable and neighborCable[color] then
                    neighborCable = neighborCable[color]
                    local node = PWR.findNode({nx, ny, nz})
                    if generatorData then generatorData.color = color end
                    
                    if disconnect then
                        neighborCable:getModData().generator = nil
                    else
                        neighborCable:getModData().generator = generatorData
                    end

                    if node ~= nil then
                        local vn = PWR.getNode(nx, ny, nz)
                        if disconnect and generatorData then
                            local ndata = node:getModData().generator or {}
                            for i,tbl in pairs(ndata)do
                                if tbl.x == generatorData.x and tbl.y == generatorData.y and tbl.z == generatorData.z then
                                    table.remove(ndata,i)
                                end
                            end
                            node:getModData().generator = ndata
                        elseif generatorData then
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

--set generator data and sprite for cables
--- @param obj IsoObject
--- @param disconnect boolean
--- @return nil
function PWR.onCablePlaced(obj, disconnect)
    if not obj then return end
    PWR.Debug("PWR.onCablePlaced run")
    local x, y, z = obj:getX(), obj:getY(), obj:getZ()
    local newCable = obj
    local directions = {
        {0, -1, 0},
        {0, 1, 0},
        {1, 0, 0},
        {-1, 0, 0}
    }
    local generatorData = obj:getModData().generator
    local color = PWR.getColor(obj)
    
    -- Find generator data from neighbors
    if not generatorData then
        for _, dir in ipairs(directions) do
            local nx, ny, nz = x + dir[1], y + dir[2], z + dir[3]
            local neighborCable
            local cables = PWR.findCable({nx, ny, nz})
            if cables and cables[color] then
                neighborCable = cables[color]
            end
            if neighborCable then
                local data = neighborCable:getModData().generator
                if data ~= nil and type(data) == "table" then
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
    end
    
        if generatorData then generatorData.color = color end
        local node = PWR.findNode({x, y, z})
        
        if disconnect == true then
            --newCable:getModData().generator = nil
            if node ~= nil and generatorData and node:getModData().generator then
                for i, d in pairs(node:getModData().generator)do
                    if d.x == generatorData.x and d.y == generatorData.y and d.z == generatorData.z then
                        table.remove(node:getModData().generator,i)
                    end
                end
                node:transmitModData()
            end
            
        elseif generatorData then
            if node ~= nil then
                node:getModData().generator = node:getModData().generator or {}
                if not genAdded(node:getModData().generator, generatorData) then
                    table.insert(node:getModData().generator, generatorData)
                    node:transmitModData()
                end
            end
            newCable:getModData().generator = generatorData
            newCable:transmitModData()
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
            obj:getModData().generator = nil
        else
            -- Normal propagation when connecting
            propagateGeneratorData(x, y, z, generatorData, color, disconnect)
        end

end

--finds and attaches nearby switch to a generator
--- @param gen IsoGenerator
--- @return nil
function PWR.findGenSwitch(gen)
   -- print("PWR.findGenSwitch run")
    local x,y,z = gen:getX(),gen:getY(),gen:getZ()
    local switch
    local maxX,maxY,minX,minY = x+2,y+2,x-2,y-2
    for n = minX,maxX do
        if switch then break end
        for m = minY,maxY do
            if switch then break end
            switch = PWR.findSwitch({n,m,z})
           -- print("searching square "..n.." "..m.." "..z)
            
        end
    end
    if switch ~= nil then
      --  print("switch found adding moddata")
        switch:getModData().generator = {x = x,y = y,z = z}
        gen:getModData().switch = {switch:getX(),switch:getY(),switch:getZ()}
        gen:transmitModData()
        switch:transmitModData()
        local cord = PWR.findCable(gen:getModData().switch)
        if cord ~= nil then
            for _, cable in pairs(cord)do
                cable:getModData().generator = {x = x,y = y,z = z}
                PWR.connectCable(cable)
            end
        end
    end
end


--returns generator object at given coordinates
---@param x integer
---@param y integer
---@param z integer
---@return IsoGenerator
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

--returns powernode object at the given coordinates
---@param x integer
---@param y integer
---@param z integer
---@param pick string
local function findPowerObject(x,y,z,pick)
   -- print("findPowerObject run")
    local function getTileNum(str)
        if str == nil then return end
        local num = string.match(str, "_(.*)")
       -- print("tile number found "..num)
        return tonumber(num)
    end
    local square = getSquare(x,y,z)
    local cables
    if square then
       -- print("square found iterating objects")
        for i=0,square:getObjects():size()-1 do
            local obj = square:getObjects():get(i)
            if obj then
                local tex = obj:getTextureName()
               -- if tex then print("texture "..tex.." found")end
                if tex and not tex:contains("Cords") and tex:contains("PowerNodesTiles") then
                    local num = getTileNum(tex)
                    if num ~= nil then
                    --    print("tile number not nil")
                        if num <= 3 and pick == "SWITCH" then
                         --   print("returning switch object")
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


--sorts coordinates for other functions
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

--takes in a table of coordinates and returns a node at that location
---@param location table
---@return IsoObject
function PWR.findNode(location)
    PWR.Debug("PWR.findNode run")
    local coords = sortCoords(location)
    if coords then
        return findPowerObject(coords[1],coords[2],coords[3],"NODE")
    end
end

---@param location table
---@return table
function PWR.findCable(location)
    PWR.Debug("PWR.findCable run")
    local coords = sortCoords(location)
    if coords then
        return findPowerObject(coords[1],coords[2],coords[3],"CABLE")
    end
end

---@param location table
---@return IsoObject
function PWR.findSwitch(location)
   -- print("PWR.findSwitch run")
    local coords = sortCoords(location)
    if coords then
        return findPowerObject(coords[1],coords[2],coords[3],"SWITCH")
    end
end

--return table of chunks in the power range
---@param cx integer
---@param cy integer
---@param cz integer
---@return table
function PWR.getChunks(cx,cy,cz)
    local world = getWorld()
    PWR.Debug("PWR.getChunks run")
    local sSquare = getSquare(cx,cy,cz)
    if not sSquare then return end
    local sChunk = sSquare:getChunk()
    local sCSquare = sChunk:getGridSquare(5,5,cz) --find the center of the chunk
    if not sCSquare then return end
    cx,cy = sCSquare:getX(),sCSquare:getY()
    local chunks = {}
    local r = SandboxVars.PWRNODE.chunk * 10
    if r == 0 then
        table.insert(chunks,sChunk)
        return chunks
    end
    local function chunkDone(chunk)
        if not chunk then return end
        for _,c in pairs(chunks)do
            if c == chunk then return true end
        end
    end
    --increment by 10, each center of chunk is 10 squares apart.
    for z = cz-2, cz+2 do
        for x = cx-r,cx+r,10 do
            for y = cy-r,cy+r,10 do
                --if not(IsoUtils.DistanceToSquared(x + 0.5, y + 0.5, cx + 0.5, cy + 0.5) > 400) then
                    local sq = getSquare(x,y,z)
                    if sq then
                        local chunk = sq:getChunk()
                        if chunkDone(chunk) then
                        else
                            table.insert(chunks,chunk)
                        end
                    elseif not sq and world:isValidSquare(x,y,z) then
                    --    print("not all square loaded making table of missing squares")
                        PWR.SquaresToLoad = PWR.SquaresToLoad or {}
                        PWR.SquaresToLoad[x.." "..y.." "..z] = {cx,cy,z}
                    end
               -- end
            end
        end
    end
    return chunks
end

--tells chunks there is a generator in the nodes position or removes it based on command
---@param node IsoObject
---@param command string
---@param sync boolean
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

local function sendCommand(command,args)
    if not isServer() then return end
        local players = getOnlinePlayers()
    for i = 0 ,players:size()-1 do
        local p = players:get(i)
        sendServerCommand(p,"PWRNODE",command,args)
    end
end


--sets colored node overlays based on what cables are connected to it and if they are powered
---@param node IsoObject
function PWR.setNodeOverlays(node)
    if not node then return end
    if isServer() then
       local args = {x = node:getX(),y = node:getY(),z = node:getZ()}
        sendCommand("UPDATEOVERLAY",args)
        return
    end
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

--shuts down node power
---@param args table
function PWR.shutDown(args)
    if not args then return end
    print("PWR.shutDown run")
    local node = PWR.findNode({args.x,args.y,args.z})
    if not node then return end
    if not getActivatedMods():contains("MultipleGenerators") then
        local gdata = args.generator
        local powered = args.realTotalPower
        local gen
        if gdata then
            gen = PWR.findGenerator(gdata.x,gdata.y,gdata.z)
        end
        if gen then
            local genTotalPower = gen:getTotalPowerUsing()
            local total = genTotalPower - powered
            gen:setTotalPowerUsing(total)
        end
    end

    PWR.setChunks({args.x,args.y,args.z},"SHUTDOWN",true)
    node:getModData().status = "OFF"
    node:transmitModData()
   -- node:RemoveAttachedAnims()
    PWR.setNodeOverlays(node)
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

--turns on node power
---@param args table
function PWR.TurnON(args)
  --  print("PWR.TurnON run")
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

--toggles node based on state
---@param node IsoObject
---@param s string
function PWR.toggle(node,s)
   -- local player = getPlayer()  
    --local onCompleteFunc = function()
      --  player:faceThisObject(node)
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
   -- end
   -- local action = ISWalkToTimedAction:new(player, node:getSquare())
   -- action:setOnComplete(onCompleteFunc,"","","","")
   -- ISTimedActionQueue.add(action)

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


local function inActiveChunks(square,chunks)
    local chunk = square:getChunk()
    for _,c in pairs(chunks)do
        if c == chunk then return true end
    end
end


--only used by server,or single player client, finds all powered items in generator radius
---@param cx integer
---@param cy integer
---@param cz integer
function PWR.getSurroundingPoweredItems(cx,cy,cz)
    local chunks = PWR.getChunks(cx,cy,cz)
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
                            if square and inActiveChunks(square,chunks) == true then
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
