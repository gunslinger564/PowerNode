

if isServer() then return end
local genRange,multigens,isa = {},{},{}
local mods = getActivatedMods()
genRange.active =  mods:contains("GenRange")
multigens.active = mods:contains("MultipleGenerators")
isa.active = mods:contains("ISA_41")
local isShowing
if genRange.active then
    require"ISGeneratorInfoWindow_patch"
    --make copy of genRange mod table
    for i,v in pairs(GeneratorRange)do
        genRange[i] = v
    end
end
if multigens.active then
    require"MGUI/MGGeneratorInfoWindow"
    require"ISUI/ISPanel"
    function MGGeneratorInfoWindow:update()
       ISPanel.update(self)
        --[[local player = getPlayer()
        local dist = math.sqrt(math.pow(player:getX() - self.generator:getX(), 2) + math.pow(player:getY() - self.generator:getY(), 2))
        if dist > 21 then self:removeFromUIManager() end--]]
    end
end

PWR = PWR or {}

local function showRange(node,isactive,player)
    local nx,ny = node:getX(),node:getY()
    local function autoRemove()
            local x,y = player:getX(),player:getY()
            if isShowing ~= nil then
                if IsoUtils.DistanceTo(nx,ny,x,y) > 20 then
                    isShowing = nil
                    genRange.ClearRender(true)
                end
            elseif isShowing == nil then
                Events.EveryOneMinute.Remove(autoRemove)
            end
    end
    if isShowing == nil then
        genRange.Render(node, isactive)
        isShowing = true
        Events.EveryOneMinute.Add(autoRemove)

    else
        genRange.ClearRender(true)
        isShowing = nil
    end
end
--[[
local function multiGenInfo(player,gen)
    local ui = multigens.mginfo:new(0, 0, 300, 300, player, gen)
    ui:initialise()
    ui:addToUIManager()
end--]]







local function OnFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    local node
    local generator
    for _, obj in pairs(worldObjects) do
        local tex = obj:getTextureName()
        if tex ~= nil and tex:contains("PowerNodesTiles") and not tex:contains("PowerNodesTiles_Cords") then
            --print("power node tile in context")
            local num = string.match(tex, "_(.*)")
            num = tonumber(num)
            -- print("tilenumber ".. num)
            if num >= 4 and num <= 7 then
                node = obj
                break
            --  print("node found in context")
            end
        end
    end
    if node ~= nil then
        local x,y,z = node:getX(),node:getY(),node:getZ()
        local vn = PWR.getNode(x,y,z)
        local gen = node:getModData().generator
        if not vn then
            PWR.addNode(x,y,z,{generator = gen,state = node:getModData().status == "ON"})
            vn = PWR.getNode(x,y,z)
            --sendClientCommand(getSpecificPlayer(playerNum), 'PWRNODE', 'UPDATE',{})
        end
    
        if gen then
            local genInfoOption
            local rangeOption
            local toggleOption
            local genInfoMenu
            if #gen > 1 then
                genInfoOption = context:addOption("Node's Generators")
                genInfoMenu = context:getNew(context)
                context:addSubMenu(genInfoOption,genInfoMenu)
            end
            for i,tbl in pairs(gen)do
                local g = PWR.findGenerator(tbl.x,tbl.y,tbl.z)
                if multigens.active then
                    local vg = VirtualGenerator.Get (tbl.x,tbl.y,tbl.z)
                    if g and g:isConnected() and not vg then
                        local fuel = g:getFuel()
                        VirtualGenerator.Add (x, y, z, fuel)
                        sendClientCommand(getSpecificPlayer(playerNum), 'mg_commands', 'update_generators', {sync=false})
                    end
                end
                local powerBank
                if isa.active and tbl.bank and not g then
                    local PbSystem = require "Powerbank/ISAPowerbankSystem_server"
                    powerBank = PbSystem.instance:getLuaObjectAt(tbl.bank.x,tbl.bank.y,tbl.bank.z)
                end
                if ((g ~= nil and g:isActivated() == true)or powerBank and powerBank.on) and not toggleOption then
                    local choice =  "Turn on Node"
                    if node:getModData().status == "ON" then
                        choice = "Turn off Node"
                    end
                    toggleOption = context:addOption(choice,node,PWR.toggle,node:getModData().status)
                end
                if genRange.active and not rangeOption then
                    rangeOption = context:addOption("Toggle node Range",node,showRange,node:getModData().status == "ON",getSpecificPlayer(playerNum))
                end
                if isa.active then
                    isa = require "ISAUtilities"
                end
                if powerBank and genInfoMenu then
                    local solar = require "ISAUtilities"
                    genInfoMenu:addOption(getText(tbl.color.." Power Bank"), playerNum, isa.StatusWindow.OnOpenPanel, getSquare(tbl.bank.x,tbl.bank.y,tbl.bank.z))
                elseif powerBank then
                    context:addOption("Node's Power Bank info", playerNum, isa.StatusWindow.OnOpenPanel, getSquare(tbl.bank.x,tbl.bank.y,tbl.bank.z))
                end
                if g and genInfoMenu then
                    if not genInfoMenu:getOptionFromName(tbl.color.." Generator") then
                        if multigens.active then
                                genInfoMenu:addOption(tbl.color.." Generator", getSpecificPlayer(playerNum), MGOnInfoGenerator2,g)
                        else
                                genInfoMenu:addOption(tbl.color.." Generator",ISGeneratorInfoAction:new(getSpecificPlayer(playerNum), g), ISGeneratorInfoAction.perform);
                        end
                    end
                elseif g and not genInfoMenu and not genInfoOption then
                    if not context:getOptionFromName("Node's Generator info") then
                        if multigens.active then
                                genInfoOption = context:addOption("Node's Generator info", getSpecificPlayer(playerNum), MGOnInfoGenerator2,g)
                        else
                            genInfoOption = context:addOption("Node's Generator info",ISGeneratorInfoAction:new(getSpecificPlayer(playerNum), g), ISGeneratorInfoAction.perform);
                        end
                    end
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)