local onNode = function(worldobjects, square, sprite, player)
	-- sprite, northSprite
	
	local node = ISNode:new(sprite.sprite, sprite.northSprite)
	node.renderFloorHelper = true
	node.canBeAlwaysPlaced = true;
    node.modData["xp:Electricity"] = 3;
	node.modData["need:Base.MetalPipe"] = "2";
	node.modData["need:Base.SmallSheetMetal"] = "6";
    node.modData["need:Base.ElectronicsScrap"] = "5";
	node.modData["need:Radio.ElectricWire"] = "25";
	node:setEastSprite(sprite.eastSprite);
	node.player = player
	node.completionSound = "BuildMetalStructureMedium";
	getCell():setDrag(node, player);
end

local onSwitch = function(worldobjects, square, sprite, player)
	-- sprite, northSprite
	local switch = ISSwitch:new(sprite.sprite, sprite.northSprite)
	switch.renderFloorHelper = true
	switch.canBeAlwaysPlaced = true;
    switch.modData["xp:Electricity"] = 3;
	switch.modData["need:Base.MetalPipe"] = "2";
    switch.modData["need:Base.SheetMetal"] = "2";
	switch.modData["need:Base.SmallSheetMetal"] = "4";
    switch.modData["need:Base.Hinge"] = "2";
    switch.modData["need:Base.ElectronicsScrap"] = "25";
	switch.modData["need:Radio.ElectricWire"] = "30";
	switch:setEastSprite(sprite.eastSprite);
	switch.player = player
	switch.completionSound = "BuildMetalStructureMedium";
	getCell():setDrag(switch, player);
end

local craftItems = {}
local getItemAmount = function(player,item)
    local inv = player:getInventory()
    return inv:getItemCountFromTypeRecurse(item)
end

local canbuild = function(metalPipe,smallMetalSheet,metalSheet,hinge,scrapElectronics,electricalWire,player,option)
	-- create a new tooltip
	local tooltip = ISBuildMenu.addToolTip();
	-- add it to our current option
	option.toolTip = tooltip;
	local result = true;
    local electricskill = SandboxVars.PWRNODE.electric or 5
	tooltip.description = "<LINE> <LINE>" .. getText("Tooltip_craft_Needs") .. ": <LINE>";
	-- now we gonna test all the needed material, if we don't have it, they'll be in red into our toolip
	if craftItems.metalPipe < metalPipe then
		tooltip.description = tooltip.description .. ISBuildMenu.bhs .. getItemNameFromFullType("Base.MetalPipe") .. " " .. craftItems.metalPipe .. "/" .. metalPipe .. " <LINE>";
		result = false;
	elseif metalPipe > 0 then
		tooltip.description = tooltip.description .. ISBuildMenu.ghs .. getItemNameFromFullType("Base.MetalPipe") .. " " .. craftItems.metalPipe .. "/" .. metalPipe .. " <LINE>";
	end
	if craftItems.smallMetalSheet < smallMetalSheet then
		tooltip.description = tooltip.description .. ISBuildMenu.bhs .. getItemNameFromFullType("Base.SmallSheetMetal") .. " " .. craftItems.smallMetalSheet .. "/" .. smallMetalSheet .. " <LINE>";
		result = false;
	elseif smallMetalSheet > 0 then
		tooltip.description = tooltip.description .. ISBuildMenu.ghs .. getItemNameFromFullType("Base.SmallSheetMetal") .. " " .. craftItems.smallMetalSheet .. "/" .. smallMetalSheet .. " <LINE>";
	end
	if craftItems.metalSheet < metalSheet then
		tooltip.description = tooltip.description .. ISBuildMenu.bhs .. getItemNameFromFullType("Base.SheetMetal") .. " " .. craftItems.metalSheet .. "/" .. metalSheet .. " <LINE>";
		result = false;
	elseif metalSheet > 0 then
		tooltip.description = tooltip.description .. ISBuildMenu.ghs .. getItemNameFromFullType("Base.SheetMetal") .. " " .. craftItems.metalSheet .. "/" .. metalSheet .. " <LINE>";
	end
	if craftItems.hinge < hinge then
		tooltip.description = tooltip.description .. ISBuildMenu.bhs .. getItemNameFromFullType("Base.Hinge") .. " " .. craftItems.hinge .. "/" .. hinge .. " <LINE>";
		result = false;
	elseif hinge > 0 then
		tooltip.description = tooltip.description .. ISBuildMenu.ghs .. getItemNameFromFullType("Base.Hinge") .. " " .. craftItems.hinge .. "/" .. hinge .. " <LINE>";
	end
    if craftItems.scrapElectronics < hinge then
		tooltip.description = tooltip.description .. ISBuildMenu.bhs .. getItemNameFromFullType("Base.ElectronicsScrap") .. " " .. craftItems.scrapElectronics .. "/" .. scrapElectronics .. " <LINE>";
		result = false;
	elseif hinge > 0 then
		tooltip.description = tooltip.description .. ISBuildMenu.ghs .. getItemNameFromFullType("Base.ElectronicsScrap") .. " " .. craftItems.scrapElectronics .. "/" .. scrapElectronics .. " <LINE>";
	end
    if craftItems.electricalWire < hinge then
		tooltip.description = tooltip.description .. ISBuildMenu.bhs .. getItemNameFromFullType("Radio.ElectricWire") .. " " .. craftItems.electricalWire .. "/" .. electricalWire .. " <LINE>";
		result = false;
	elseif hinge > 0 then
		tooltip.description = tooltip.description .. ISBuildMenu.ghs .. getItemNameFromFullType("Radio.ElectricWire") .. " " .. craftItems.electricalWire .. "/" .. electricalWire .. " <LINE>";
	end
	if getSpecificPlayer(player):getPerkLevel(Perks.Electricity) < electricskill then
		tooltip.description = tooltip.description .. ISBuildMenu.bhs .. getText("IGUI_perks_Electricity") .. " " .. getSpecificPlayer(player):getPerkLevel(Perks.Electricit) .. "/" .. electricskill .. " <LINE>";
		result = false;
	elseif electricskill > 0 then
		tooltip.description = tooltip.description .. ISBuildMenu.ghs .. getText("IGUI_perks_Electricity") .. " " .. getSpecificPlayer(player):getPerkLevel(Perks.Electricit) .. "/" .. electricskill .. " <LINE>";
	end
	if ISBuildMenu.cheat then
		return tooltip;
	end
	if not result then
		option.onSelect = nil;
		option.notAvailable = true;
	end
	tooltip.description = " " .. tooltip.description .. " "
	return tooltip;
end

--tweaked copy of vanilla function for building wooden crate
local buildNodeMenu = function(subMenu, player,square,worldObjects)
    local nSprite = {sprite = "PowerNodesTiles_4",northSprite = "PowerNodesTiles_4"}
    local sSprite = {sprite = "PowerNodesTiles_0",northSprite = "PowerNodesTiles_0"}
    local nodeOption = subMenu:addOption(getText("ContextMenu_Node"), worldObjects, onNode, square, nSprite, player);
    local switchOption = subMenu:addOption(getText("ContextMenu_Switch"), worldObjects, onSwitch, square, sSprite, player);
    local nToolTip,sToolTip = canbuild(2,6,0,0,5,25,player,nodeOption),canbuild(2,4,2,2,25,30,player,switchOption)
    nToolTip:setName(getText("Tooltip_PowerNode"));
    nToolTip.description = getText("Tooltip_PowerNode_description") .. nToolTip.description;
    nToolTip:setTexture(nSprite.sprite);
    sToolTip:setName(getText("Tooltip_GeneratorSwitch"));
    sToolTip.description = getText("Tooltip_GeneratorSwitch_description") .. sToolTip.description;
    sToolTip:setTexture(sSprite.sprite);
    if craftItems.pliers <= 0 or craftItems.metalCutter <= 0 then
        nodeOption.notAvailable = true
        nodeOption.onSelect = nil
        switchOption.notAvailable = true
        switchOption.onSelect = nil
    end
end
local workshop = getActivatedMods():contains("TheWorkshop(new version)")
Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldObjects, test)
    local square = nil
    local player = getSpecificPlayer(playerNum)
        craftItems = {}
        for _,obj in pairs(worldObjects)do
            if square then break end
            square = square or obj:getSquare()
        end
        if square then
			local Coption,Moption = context:getOptionFromName(getText("ContextMenu_Build")),context:getOptionFromName(getText("ContextMenu_MetalWelding"))
			local under
			if Coption then
				under = getText("ContextMenu_Build")
			elseif Moption then
				under = getText("ContextMenu_MetalWelding")
			end
			local nodeOption
			if under then
				nodeOption = context:insertOptionAfter(under,getText("ContextMenu_NodeBuilding"), worldObjects, nil);
			else
				nodeOption = context:addOption(getText("ContextMenu_NodeBuilding"), worldObjects, nil);
			end
            local subMenuN = ISContextMenu:getNew(context);
            craftItems.metalPipe = getItemAmount(player,"Base.MetalPipe")
            craftItems.smallMetalSheet = getItemAmount(player,"Base.SmallSheetMetal")
            craftItems.metalSheet = getItemAmount(player,"Base.SheetMetal")
            craftItems.hinge = getItemAmount(player,"Base.Hinge")
            craftItems.scrapElectronics = getItemAmount(player,"Base.ElectronicsScrap")
            craftItems.electricalWire = getItemAmount(player,"Radio.ElectricWire")
            if workshop then
                craftItems.pliers = getItemAmount(player,"TW.Pliers")
                craftItems.metalCutter = getItemAmount(player,"TW.MetalCutter")
            else
                craftItems.pliers = getItemAmount(player,"Base.Saw")
                craftItems.metalCutter = getItemAmount(player,"Base.Screwdriver")
            end
           if craftItems.pliers > 0 and craftItems.metalCutter > 0 then
            context:addSubMenu(nodeOption, subMenuN);
            buildNodeMenu(subMenuN, playerNum,square,worldObjects)
           end
        end
end)