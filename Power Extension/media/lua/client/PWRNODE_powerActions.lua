


require "TimedActions/ISLightActions"
require "TimedActions/ISSetComboWasherDryerMode"
require "TimedActions/ISToggleClothingDryer"
require "TimedActions/ISToggleClothingWasher"
require "TimedActions/ISToggleComboWasherDryer"
require "TimedActions/ISToggleLightAction"
local function sendUpdate(player)
    if isClient() then
        sendClientCommand(player, "PWRNODE", 'UPDATE', {})
    elseif not isServer() then
        PWRNODE_UPDATE()
    end
end

local multi = getActivatedMods():contains("MultipleGenerators") == true

function ISLightActions:perform()
    if self.character and self.lightswitch and self.mode then
        if self["perform"..self.mode] then
            self["perform"..self.mode](self);
            sendUpdate(self.character)
            if multi == true then
                sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
            end
        end
    end
    ISBaseTimedAction.perform(self)
end

function ISSetComboWasherDryerMode:perform()
	sendUpdate(self.character)
    local obj = self.object
    local args = { x = obj:getX(), y = obj:getY(), z = obj:getZ() }
    sendClientCommand(self.character, 'comboWasherDryer', 'toggle', args)
    if multi == true then
        sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
    end
    ISBaseTimedAction.perform(self)
end
function ISToggleClothingDryer:perform()
    local obj = self.object
	local args = { x = obj:getX(), y = obj:getY(), z = obj:getZ() }
	sendClientCommand(self.character, 'clothingDryer', 'toggle', args)
	sendUpdate(self.character)
    if multi == true then
        sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
    end
    ISBaseTimedAction.perform(self)
end

function ISToggleClothingWasher:perform()
    sendUpdate(self.character)
	local obj = self.object
	local args = { x = obj:getX(), y = obj:getY(), z = obj:getZ() }
	sendClientCommand(self.character, 'clothingWasher', 'toggle', args)
    if multi == true then
        sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
    end
    ISBaseTimedAction.perform(self)
end

function ISToggleComboWasherDryer:perform()
    local obj = self.object
	local args = { x = obj:getX(), y = obj:getY(), z = obj:getZ() }
	sendClientCommand(self.character, 'comboWasherDryer', 'toggle', args)
    sendUpdate(self.character)
	if multi == true then
        sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
    end
    ISBaseTimedAction.perform(self)
end

function ISToggleLightAction:perform()
    self.object:toggle()
    sendUpdate(self.character)
    ISBaseTimedAction.perform(self)
	if multi == true then
        sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
    end
end
function ISToggleStoveAction:perform()
    self.object:Toggle()
    sendUpdate(self.character)
    if multi == true then
        sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
    end
    ISBaseTimedAction.perform(self)
end

function ISRadioAction:performToggleOnOff()
    if self:isValidToggleOnOff() then
        if self.character then
            self.character:playSound(self.deviceData:getIsTurnedOn() and "TelevisionOff" or "TelevisionOn")
        end
        self.deviceData:setIsTurnedOn( not self.deviceData:getIsTurnedOn() );
        sendUpdate(self.character)
        if multi == true then
            sendClientCommand(self.character, 'mg_commands', 'update_generators', {sync=false})
        end
    end
end


local original_ISPlugGenerator_perform = ISPlugGenerator.perform
function ISPlugGenerator:perform()
    if self.plug then
        if not self.generator:getModData().switch then
            PWR.findGenSwitch(self.generator)
        end
    else
        local sData = self.generator:getModData().switch
        local switch
        if sData then
            switch = PWR.findSwitch({sData[1],sData[2],sData[3]})
        end
        local cable
        if switch then
            cable = PWR.findCable({sData[1],sData[2],sData[3]})
            switch:getModData().generator = nil
        end
        if cable then
            for _,c in pairs(cable)do
                PWR.onCablePlaced(c,true)
            end
        end
        self.generator:getModData().switch = nil
    end
    original_ISPlugGenerator_perform(self)
end
