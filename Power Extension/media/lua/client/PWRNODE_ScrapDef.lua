local function isNodeDefs()
local moveableDefinitions = ISMoveableDefinitions:getInstance()

local workshop = getActivatedMods():contains("TheWorkshop(new version)")


if workshop then
moveableDefinitions.addToolDefinition( "Node",   {"TW.Pliers"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addToolDefinition( "Node",   {"TW.MetalCutter"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addToolDefinition( "Switch",   {"TW.Pliers"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addToolDefinition( "Switch",   {"TW.MetalCutter"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addScrapDefinition( "Node",  {"TW.Pliers"}, {"TW.MetalCutter"},   Perks.Electricity,  1000,     "Dismantle",    true , 10);
moveableDefinitions.addScrapDefinition( "Switch",  {"TW.Pliers"}, {"TW.MetalCutter"},   Perks.Electricity,  1000,     "Dismantle",    true , 10);
else
moveableDefinitions.addToolDefinition( "Node",   {"Base.Saw"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addToolDefinition( "Node",   {"Base.Screwdriver"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addToolDefinition( "Switch",   {"Base.Saw"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addToolDefinition( "Switch",   {"Base.Screwdriver"},Perks.Electricity,      100,    "Dismantle",    true  );
moveableDefinitions.addScrapDefinition( "Node",  {"Base.Saw"}, {"Base.Screwdriver"},   Perks.Electricity,  1000,     "Dismantle",    true , 10);
moveableDefinitions.addScrapDefinition( "Switch",  {"Base.Saw"}, {"Base.Screwdriver"},   Perks.Electricity,  1000,     "Dismantle",    true , 10);
end
moveableDefinitions.addScrapItem( "Node",  "Base.MetalPipe",   2, 50, true);
moveableDefinitions.addScrapItem( "Node",  "Base.SmallSheetMetal",   6, 50, true);
moveableDefinitions.addScrapItem( "Node",  "Base.ElectronicsScrap",   5, 50, true);
moveableDefinitions.addScrapItem( "Node",  "Radio.ElectricWire",   25, 50, true);


moveableDefinitions.addScrapItem( "Switch",  "Base.MetalPipe",   2, 50, true);
moveableDefinitions.addScrapItem( "Switch",  "Base.SmallSheetMetal",   4, 50, true);
moveableDefinitions.addScrapItem( "Switch",  "Base.SheetMetal",   2, 50, true);
moveableDefinitions.addScrapItem( "Switch",  "Base.Hinge",   2, 50, true);
moveableDefinitions.addScrapItem( "Switch",  "Base.ElectronicsScrap",   25, 50, true);
moveableDefinitions.addScrapItem( "Switch",  "Radio.ElectricWire",   30, 50, true);
end

Events.OnGameBoot.Add(isNodeDefs);
