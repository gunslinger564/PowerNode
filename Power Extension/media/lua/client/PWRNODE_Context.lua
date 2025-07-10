

if isServer() then return end
local genRange,multigens,isa = {},{},{}
local mods = getActivatedMods()
genRange.active =  mods:contains("GenRange")
multigens.active = mods:contains("MultipleGenerators")
isa.active = mods:contains("ISA_41")
local isShowing
if genRange.active then

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
                    NodeRange.ClearRender(true)
                end
            elseif isShowing == nil then
                Events.EveryOneMinute.Remove(autoRemove)
            end
    end
    if isShowing == nil then
        NodeRange.Render(node, isactive)
        isShowing = true
        Events.EveryOneMinute.Add(autoRemove)

    else
        NodeRange.ClearRender(true)
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
        local action --= ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())

        if gen then
            local genInfoOption
            local rangeOption
            local toggleOption
            local genInfoMenu
            if #gen > 1 then
                genInfoOption = context:addOption(getText("ContextMenu_NodesGenerators"))
                genInfoMenu = context:getNew(context)
                context:addSubMenu(genInfoOption,genInfoMenu)
            end
            for i,tbl in pairs(gen)do
                local color = tbl.color
                if color then
                    color = color:gsub("^%l", string.upper)
                    color = getText("ContextMenu_"..color)
                end
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
                    local choice =  getText("ContextMenu_TurnOnNode")
                    if node:getModData().status == "ON" then
                        choice = getText("ContextMenu_TurnOffNode")
                    end
                    action = ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())
                    action:setOnComplete(PWR.toggle,node,node:getModData().status,"","")
                    toggleOption = context:addOption(choice,action,ISTimedActionQueue.add)
                    --toggleOption = context:addOption(choice,node,PWR.toggle,node:getModData().status)
                end
                if genRange.active and not rangeOption then
                    rangeOption = context:addOption(getText("ContextMenu_ToggleNodeRange"),node,showRange,node:getModData().status == "ON",getSpecificPlayer(playerNum))
                end
                if isa.active then
                    isa = require "ISAUtilities"
                end
                if powerBank and genInfoMenu then
                    action = ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())
                    action:setOnComplete(isa.StatusWindow.OnOpenPanel,playerNum,getSquare(tbl.bank.x,tbl.bank.y,tbl.bank.z),"","")
                    genInfoMenu:addOption(color.." "..getText("ContextMenu_PowerBank"),action,ISTimedActionQueue.add)
                   -- genInfoMenu:addOption(color.." "..getText("ContextMenu_PowerBank"), playerNum, isa.StatusWindow.OnOpenPanel, getSquare(tbl.bank.x,tbl.bank.y,tbl.bank.z))
                elseif powerBank then
                    action = ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())
                    action:setOnComplete(isa.StatusWindow.OnOpenPanel,playerNum,getSquare(tbl.bank.x,tbl.bank.y,tbl.bank.z),"","")
                    context:addOption(getText("ContextMenu_PowerBankInfo"),action,ISTimedActionQueue.add)
                   -- context:addOption(getText("ContextMenu_PowerBankInfo"), playerNum, isa.StatusWindow.OnOpenPanel, getSquare(tbl.bank.x,tbl.bank.y,tbl.bank.z))
                end


                if g and genInfoMenu then
                    if not genInfoMenu:getOptionFromName(color.." "..getText("ContextMenu_Generator")) then
                        if multigens.active then
                            action = ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())
                                action:setOnComplete(MGOnInfoGenerator2,getSpecificPlayer(playerNum),g,"","")
                               -- genInfoMenu:addOption(color.." "..getText("ContextMenu_Generator"), getSpecificPlayer(playerNum), MGOnInfoGenerator2,g)
                        else
                            action = ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())
                                action:setOnComplete(ISGeneratorInfoAction.perform,ISGeneratorInfoAction:new(getSpecificPlayer(playerNum), g),"","","")
                               -- genInfoMenu:addOption(color.." "..getText("ContextMenu_Generator"),ISGeneratorInfoAction:new(getSpecificPlayer(playerNum), g), ISGeneratorInfoAction.perform);
                        end
                                genInfoMenu:addOption(color.." "..getText("ContextMenu_Generator"),action,ISTimedActionQueue.add)
                    end
                elseif g and not genInfoMenu and not genInfoOption then
                    if not context:getOptionFromName(getText("ContextMenu_NodeGenInfo")) and not context:getOptionFromName(color.." "..getText("ContextMenu_NodeGenInfo")) then
                        local choice
                        if multigens.active then
                            action = ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())
                            action:setOnComplete(MGOnInfoGenerator2,getSpecificPlayer(playerNum),g,"","")
                            choice = getText("ContextMenu_NodeGenInfo")
                                --genInfoOption = context:addOption(getText("ContextMenu_NodeGenInfo"), getSpecificPlayer(playerNum), MGOnInfoGenerator2,g)
                        else
                            action = ISWalkToTimedAction:new(getSpecificPlayer(playerNum), node:getSquare())
                            action:setOnComplete(ISGeneratorInfoAction.perform,ISGeneratorInfoAction:new(getSpecificPlayer(playerNum), g),"","","")
                            choice = color.." "..getText("ContextMenu_NodeGenInfo")
                            --genInfoOption = context:addOption(getText("ContextMenu_NodeGenInfo"),ISGeneratorInfoAction:new(getSpecificPlayer(playerNum), g), ISGeneratorInfoAction.perform);
                        end
                        genInfoOption = context:addOption(choice,action,ISTimedActionQueue.add)
                    end
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)