


PWRRadius = 20

PWR = PWR or {}

local function getTileNum(str)
    if not str:contains("PowerNodesTiles") then return end
    if str:contains("PowerNodesTiles_Cords_") then return end
    if str == nil then return end
    local num = string.match(str, "_(.*)")
    if num then
        return tonumber(num)
    end
end

local function lookAroundForCables(obj,color)
    local x,y,z = obj:getX(),obj:getY(),obj:getZ()
    local n,s,w,e = {x,y-1,z},{x,y+1,z},{x-1,y,z},{x+1,y,z}
    local cw,ce,cn,cs = PWR.findCable(w),PWR.findCable(e),PWR.findCable(n),PWR.findCable(s)
    local dir = {WEST = cw,EAST = ce,NORTH = cn,SOUTH = cs}
    local tbl = {}
    for d, t in pairs(dir)do
        if t[color] then
            tbl[d] = t[color]
             -- print(color.." cable found "..d.." of placed cable")
        end
    end
    return tbl
end



local function findPowerBank(x,y,z)
    if not (x and y and z) or not getActivatedMods():contains("ISA_41") then return end
    local PbSystem = require "Powerbank/ISAPowerbankSystem_server"
    if PbSystem then
        local powerBank = PbSystem.instance:getLuaObjectAt(x,y,z)
        if powerBank then
            print("power bank found returning coordinates")
            return {x = x,y = y,z = z}
        end
    end
end


local cTiles = "PowerNodesTiles_Cords_"
local function setCables(cable,type)
    if cable == nil or type == nil then return end
    local color = PWR.getColor(cable)
    local tbl = lookAroundForCables(cable,color)
    local s,n = PWR.findSwitch(cable:getSquare()),PWR.findNode(cable:getSquare())
    local mod = PWR.getMod(color)
    if s == nil and n == nil then
        if type == "NORTH" then
            if tbl["EAST"] and tbl["WEST"] and tbl["NORTH"] then
                cable:setSpriteFromName(cTiles..(mod+9))
            elseif tbl["EAST"] and  tbl["WEST"] then
                cable:setSpriteFromName(cTiles..(mod+6))
            elseif tbl["EAST"] and  tbl["NORTH"] then
                cable:setSpriteFromName(cTiles..(mod+10))
            elseif tbl["WEST"] and  tbl["NORTH"] then
                cable:setSpriteFromName(cTiles..(mod+7))
            elseif tbl["EAST"] then
                cable:setSpriteFromName(cTiles..(mod+4))
            elseif tbl["WEST"] then
                cable:setSpriteFromName(cTiles..(mod+2))
            else
                cable:setSpriteFromName(cTiles..(mod+3))
            end
        elseif type == "SOUTH" then
            if tbl["EAST"] and tbl["WEST"] and tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+9))
            elseif tbl["EAST"] and  tbl["WEST"] then
                cable:setSpriteFromName(cTiles..(mod+8))
            elseif tbl["EAST"] and  tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+10))
            elseif tbl["WEST"] and  tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+7))
            elseif tbl["EAST"] then
                cable:setSpriteFromName(cTiles..(mod+5))
            elseif tbl["WEST"] then
                cable:setSpriteFromName(cTiles..(mod+1))
            else
                cable:setSpriteFromName(cTiles..(mod+3))
            end
        elseif type == "WEST" then
            if tbl["NORTH"] and tbl["SOUTH"] and tbl["WEST"] then
                cable:setSpriteFromName(cTiles..(mod+9))
            elseif tbl["NORTH"] and tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+10))
            elseif tbl["NORTH"] and tbl["WEST"] then
                cable:setSpriteFromName(cTiles..(mod+8))
            elseif tbl["WEST"] and tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+6))
            elseif tbl["NORTH"] then
                cable:setSpriteFromName(cTiles..(mod+5))
            elseif tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+4))
            else
                cable:setSpriteFromName(cTiles..mod)
                
            end
        elseif type == "EAST" then
            if tbl["NORTH"] and tbl["SOUTH"] and tbl["EAST"] then
                cable:setSpriteFromName(cTiles..(mod+9))
            elseif tbl["NORTH"] and tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+7))
            elseif tbl["NORTH"] and tbl["EAST"] then
                cable:setSpriteFromName(cTiles..(mod+8))
            elseif tbl["SOUTH"] and tbl["EAST"] then
                cable:setSpriteFromName(cTiles..(mod+6))
            elseif tbl["NORTH"] then
                cable:setSpriteFromName(cTiles..(mod+1))
                
            elseif tbl["SOUTH"] then
                cable:setSpriteFromName(cTiles..(mod+2))
                
            else
                cable:setSpriteFromName(cTiles..mod)
            end
        end
        if cable and isClient() then
            cable:transmitUpdatedSpriteToServer()
        end
    elseif s then
        PWR.setSwitchCable(tbl,s,mod,cable)
    elseif n then
        PWR.setNodeCable(tbl,n,cable,mod)
    end
end

function PWR.setNodeCable(cbls,node,cable,mod)
    local x,y,z = node:getX(),node:getY(),node:getZ()
    local tex = node:getTextureName()
    local num = string.match(tex, "_(.*)")
    local newSprite
    local pmod = 0
    num = tonumber(num)
    local choice = {
        ["NORTH"] = {[4] = 35,[5] = 36,[6] = 42,[7] = 46},
        ["SOUTH"] = {[4] = 33,[5] = 38,[6] = 41,[7] = 45},
        ["EAST"] = {[4] = 34,[5] = 39,[6] = 43,[7] = 47},
        ["WEST"] = {[4] = 32,[5] = 37,[6] = 40,[7] = 44},
    }
    local count = 0
    for i,d in pairs(cbls) do
        count = count+1
    end
    if cbls.NORTH then
        setCables(cbls.NORTH,"NORTH")
        pmod = choice.NORTH[num]
    elseif cbls.SOUTH then
        setCables(cbls.SOUTH,"SOUTH")
        pmod = choice.SOUTH[num]
    elseif cbls.EAST then
        setCables(cbls.EAST,"EAST")
        pmod = choice.EAST[num]
    elseif cbls.WEST then
        pmod = choice.WEST[num]
        setCables(cbls.WEST,"WEST")
    end
    if count > 0 then
        newSprite = cTiles..(mod + pmod)
    else
        newSprite = cTiles..(mod + choice.NORTH[num])
    end
    if newSprite ~= nil then
        if count <=1 then
            cable:setSpriteFromName(newSprite)
        else
            cable:setOverlaySprite(newSprite)
        end
        cable:transmitUpdatedSpriteToServer()
    end
    local vn = PWR.getNode(x,y,z)
    if not vn and node:getModData().generator ~= nil then
        PWR.addNode(x,y,z,{generator = node:getModData().generator})
    elseif vn and node:getModData().generator ~= nil then
        vn.generator = node:getModData().generator
        sendClientCommand(getPlayer(),"PWRNODE",'UPDATEDATA',vn)
    end
end


function PWR.setSwitchCable(cbls,switch,mod,cable,color)
        local tex = switch:getTextureName()
        local newSprite
        local num = string.match(tex, "_(.*)")
        num = tonumber(num)
        local pmod = 0

        local choice = {
                ["NORTH"] = {[0] = 13,[1] = 16,[2] = 21,[3] = 27},
                ["SOUTH"] = {[0] = 14,[1] = 18,[2] = 24,[3] = 20},
                ["EAST"] = {[0] = 12,[1] = 17,[2] = 26,[3] = 22},
                ["WEST"] = {[0] = 11,[1] = 15,[2] = 25,[3] = 19},
        }
        local count = 0
        for _,d in pairs(cbls)do
            count = count +1
        end
        if cbls.NORTH then
            setCables(cbls.NORTH,"NORTH")
            pmod = choice.NORTH[num]
        elseif cbls.SOUTH then
            setCables(cbls.SOUTH,"SOUTH")
            pmod = choice.SOUTH[num]
        elseif cbls.EAST then
            setCables(cbls.EAST,"EAST")
            pmod = choice.EAST[num]
        elseif cbls.WEST then
            pmod = choice.WEST[num]
            setCables(cbls.WEST,"WEST")
        end
        if count > 0 then
            newSprite = cTiles..(mod + pmod)
        else
            newSprite = cTiles..(mod + choice.NORTH[num])
        end
        if newSprite then
            if count <= 1 then
                cable:setSpriteFromName(newSprite)
            else
                cable:setOverlaySprite(newSprite)
            end
            cable:getModData().generator = switch:getModData().generator or {}
            cable:getModData().generator.color = color
            cable:transmitModData()
            cable:transmitUpdatedSpriteToServer()
        end
end


local function sortThisCable(cable,cbls,mod)
    local tex
        if cbls.NORTH and cbls.SOUTH and cbls.EAST and cbls.WEST then
                setCables(cbls.NORTH,"NORTH")
                setCables(cbls.SOUTH,"SOUTH")
                setCables(cbls.EAST,"EAST")
                setCables(cbls.WEST,"WEST")
                tex = cTiles..(mod + 9)
            cable:setSpriteFromName(tex)
        elseif cbls.NORTH and cbls.SOUTH and cbls.EAST then
                setCables(cbls.NORTH,"NORTH")
                setCables(cbls.SOUTH,"SOUTH")
                setCables(cbls.EAST,"EAST")
                tex = cTiles..(mod + 10)
            cable:setSpriteFromName(tex)
        elseif cbls.NORTH and cbls.SOUTH and cbls.WEST then
                setCables(cbls.NORTH,"NORTH")
                setCables(cbls.SOUTH,"SOUTH")
                setCables(cbls.WEST,"WEST")
                tex = cTiles..(mod + 7)
            cable:setSpriteFromName(tex)
        elseif cbls.NORTH and cbls.EAST and cbls.WEST then
                setCables(cbls.NORTH,"NORTH")
                setCables(cbls.EAST,"EAST")
                setCables(cbls.WEST,"WEST")
                tex = cTiles..(mod + 8)
            cable:setSpriteFromName(tex)
        elseif cbls.SOUTH and cbls.EAST and cbls.WEST then
                setCables(cbls.SOUTH,"SOUTH")
                setCables(cbls.EAST,"EAST")
                setCables(cbls.WEST,"WEST")
                tex = cTiles..(mod + 6)
            cable:setSpriteFromName(tex)
        elseif (cbls.SOUTH or cbls.NORTH) and cbls.WEST == nil and cbls.EAST == nil then
            if cbls.SOUTH then
                setCables(cbls.SOUTH,"SOUTH")
            end
            if cbls.NORTH then
                setCables(cbls.NORTH,"NORTH")
            end
                tex = cTiles..(mod + 3)
            cable:setSpriteFromName(tex)
        elseif (cbls.WEST or cbls.EAST) and cbls.NORTH == nil and cbls.SOUTH == nil then
            if cbls.WEST then
                setCables(cbls.WEST,"WEST")
            end
            if cbls.EAST then
                setCables(cbls.EAST,"EAST")
            end
                tex = cTiles..mod
            cable:setSpriteFromName(tex)
        elseif (cbls.NORTH and cbls.WEST) and cbls.EAST == nil and cbls.SOUTH == nil then
                if cbls.NORTH then
                    setCables(cbls.NORTH,"NORTH")
                end
                if cbls.WEST then
                    setCables(cbls.WEST,"WEST")
                end
                tex = cTiles..(mod + 1)
            cable:setSpriteFromName(tex)
        elseif (cbls.NORTH and cbls.EAST) and cbls.SOUTH == nil and cbls.WEST == nil then
                setCables(cbls.NORTH,"NORTH")
                setCables(cbls.EAST,"EAST")
                tex = cTiles..(mod + 5)
            cable:setSpriteFromName(tex)
        elseif (cbls.SOUTH and cbls.WEST) and cbls.NORTH == nil and cbls.EAST == nil then
                setCables(cbls.SOUTH,"SOUTH")
                setCables(cbls.WEST,"WEST")
                tex = cTiles..(mod + 2)
            cable:setSpriteFromName(tex)
        elseif (cbls.SOUTH and cbls.EAST) and cbls.NORTH == nil and cbls.WEST == nil then
                setCables(cbls.SOUTH,"SOUTH")
                setCables(cbls.EAST,"EAST")
                tex = cTiles..(mod + 4)
            cable:setSpriteFromName(tex)
        end
        if isClient() then cable:transmitUpdatedSpriteToServer(); end
        return tex
end



local function addNodeData(cable,node)
    node:getModData().generator = node:getModData().generator or {}
    local ndata,cdata = node:getModData().generator,cable:getModData().generator
    local match
    for _,d in pairs(ndata)do
        if d.bank then
        else
            if d.x == cdata.x and d.y == cdata.y and d.z == cdata.z then
                match = true
            end
        end

    end
    if not match then
        table.insert(node:getModData().generator,cdata)
        node:transmitModData()
    end
end

local function connectCable(obj,remove)
    if obj == nil then return end
    local switch = PWR.findSwitch(obj:getSquare())

    if switch then
        PWR.Debug("switch found in cable square")
    end
    local color = PWR.getColor(obj)
    local mod = PWR.getMod(color)
    local node = PWR.findNode(obj:getSquare())
    local cbls = lookAroundForCables(obj,color)
    sortThisCable(obj,cbls,mod)
    if switch ~= nil then
       -- print("switch found on this square")
        obj:getModData().generator = switch:getModData().generator or {}
        obj:getModData().generator.color = color
        PWR.setSwitchCable(cbls,switch,mod,obj,color)
    elseif node ~= nil then
        addNodeData(obj,node)
        PWR.setNodeCable(cbls,node,obj,mod)
        PWR.setNodeOverlays(node)
    end
    if not remove then
       PWR.onCablePlaced(obj,nil)
    else
        PWR.onCablePlaced(obj,true)
    end
end





local function connectNode(obj)
    local x,y,z = obj:getX(),obj:getY(),obj:getZ()
    local cables = PWR.findCable({x,y,z})
    obj:getModData().generator= obj:getModData().generator or {}
    if cables ~= nil then
        for c,cobj in pairs(cables)do
            connectCable(cobj)
        end
    end
    local gen = obj:getModData().generator
    PWR.addNode(x,y,z,{generator = gen})
   -- sendClientCommand(getPlayer(),"PWRNODE","ADDNODE",{x,y,z})

end

local function connectSwitch(obj)
    local x,y,z = obj:getX(),obj:getY(),obj:getZ()
    local generator
    local maxX,maxY,minX,minY = x+2,y+2,x-2,y-2
    local gens,dist = {},{}

    for n = minX,maxX do
        for m = minY,maxY do
            local gen = PWR.findGenerator(n,m,z)
            local bank = findPowerBank(n,m,z)
            if bank then
                local d = IsoUtils.DistanceTo(x,y,n,m)
                table.insert(dist,d)
                gens[d] = bank
            elseif gen ~= nil then
                local d = IsoUtils.DistanceTo(x,y,n,m)
                table.insert(dist,d)
                gens[d] = gen
            end
        end
    end
    local min = math.min(unpack(dist))
    generator = gens[min]
    if generator ~= nil then
        if instanceof(generator,"IsoGenerator") then
            obj:getModData().generator = {x = generator:getX(),y = generator:getY(),z = generator:getZ()}
            generator:getModData().switch = {x,y,z}
            generator:transmitModData()
            obj:transmitModData()
            local cables = PWR.findCable({x,y,z})
            if cables ~= nil then
                for _, cobj in pairs(cables)do
                    connectCable(cobj)
                end
            end
        else
            local cables = PWR.findCable({x,y,z})
            if cables ~= nil then
                for _, cobj in pairs(cables)do
                    connectCable(cobj)
                end
            end
            obj:getModData().generator = obj:getModData().generator or {}
            obj:getModData().generator.bank = generator
            obj:transmitModData()
        end
    end
end


function PWR.findGenSwitch(gen)
    local x,y,z = gen:getX(),gen:getY(),gen:getZ()
    local switch
    local maxX,maxY,minX,minY = x+2,y+2,x-2,y-2
    for n = minX,maxX do
        for m = minY,maxY do
            switch = PWR.findSwitch(n,m,z)
            if switch then break end
        end
    end
    if switch ~= nil then
        switch:getModData().generator = {x = x,y = y,z = z}
        gen:getModData().switch = {switch:getX(),switch:getY(),switch:getZ()}
        gen:transmitModData()
        switch:transmitModData()
        local cord = PWR.findCable(gen:getModData().switch)
        if cord ~= nil then
            for _, cable in pairs(cord)do
                connectCable(cable)
            end
        end
    end
end


local function OnObjectAdded(object)
    if instanceof(object,"IsoGenerator") then
        PWR.findGenSwitch(object)
        return
    end
    local tex = object:getTextureName()
    if tex and tex:contains("PowerNodesTiles") and not tex:contains("PowerNodesTiles_Cords") then
        local num = getTileNum(tex)
        if num then
            if num <= 3 then
                connectSwitch(object)
            elseif num >= 4 and num <= 7 then
                connectNode(object)
                object:getModData().status = "OFF"
                object:transmitModData()
            end
        end
    elseif tex and tex:contains("PowerNodesTiles_Cords") then
        connectCable(object)
    end
end

Events.OnObjectAdded.Add(OnObjectAdded)

local function OnObjectAboutToBeRemoved(object)
    local tex = object:getTextureName()
    if tex then
        local num = getTileNum(tex)
        local x,y,z = object:getX(),object:getY(),object:getZ()

        if object:getModData().switch ~= nil then
            local switch = PWR.findSwitch(object:getModData().switch)
            if switch then
                switch:getModData().generator = nil
                switch:transmitModData()
                local cables = PWR.findCable({x,y,z})
                if cables ~= nil then
                    local function OnTileRemoved(obj)
                        if obj == object then
                            for _,cable in pairs(cables)do
                                PWR.onCablePlaced(cable,true)
                            end
                            Events.OnTileRemoved.Remove(OnTileRemoved)
                        end
                    end
                    Events.OnTileRemoved.Add(OnTileRemoved)
                end
            end
        elseif object:getModData().generator ~= nil and not tex:contains("PowerNodesTiles_Cords") then
            if num and num <= 3 then
                local data = object:getModData().generator
                if data then
                    local gen =  PWR.findGenerator(data.x,data.y,data.z)
                    if gen then
                        gen:getModData().switch = nil
                        local cables = PWR.findCable({x,y,z})
                        if cables ~= nil then
                            local function OnTileRemoved(obj)
                                if obj == object then
                                    for _,cable in pairs(cables)do
                                        PWR.onCablePlaced(cable,true)
                                    end
                                    Events.OnTileRemoved.Remove(OnTileRemoved)
                                end
                            end
                            Events.OnTileRemoved.Add(OnTileRemoved)
                        end
                    end
                end
            end
        elseif tex ~= nil and tex:contains("PowerNodesTiles_Cords")then
            print ("cable removed, adjusting data")
            local n,s,w,e = {x,y-1,z},{x,y+1,z},{x-1,y,z},{x+1,y,z}
            local cables = {PWR.findCable(w),PWR.findCable(e),PWR.findCable(n),PWR.findCable(s)}
            local node = PWR.findNode({x,y,z})
            local color = PWR.getColor(object)
            local lcables = PWR.findCable({x,y,z})
            if node ~= nil then
                local mdata = object:getModData().generator
                local count = 0
                for c,tbl in pairs(lcables)do
                    count = count+1
                end
                if count <= 1 then
                    PWR.shutDown(PWR.getNode(x,y,z))
                end

                for i,d in pairs(node:getModData().generator)do
                    if d.color == mdata.color and d.x == mdata.x and d.y == mdata.y and d.z == mdata.z then
                        table.remove(node:getModData().generator,i)
                        break
                    end
                end
                local entry = {}
                entry.generator = node:getModData().generator
                PWR.modifyNode(x,y,z,entry)
                PWR.setNodeOverlays(node)
                node:transmitModData()
            end
            local function OnTileRemoved(obj)
                if obj == object then
                    PWR.setNodeOverlays(node)
                    for _, c in pairs(cables)do
                        PWR.onCablePlaced(c,true)
                    end
                    Events.OnTileRemoved.Remove(OnTileRemoved)
                end
            end
            Events.OnTileRemoved.Add(OnTileRemoved)
        end
        if num and num >= 4 and num <= 7 then
                PWR.shutDown(PWR.getNode(x,y,z))
                PWR.removeNode(x,y,z)
                if getActivatedMods():contains("MultipleGenerators") then
                    require"MGVirtualGenerator"
                    VirtualGenerator.Remove(x, y, z)
                end
        end
    end
end

Events.OnObjectAboutToBeRemoved.Add(OnObjectAboutToBeRemoved)
