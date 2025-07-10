
ISNode = ISBuildingObject:derive("ISNode");
ISSwitch = ISBuildingObject:derive("ISSwitch");

function ISNode:new(sprite, northSprite)
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();
	o:setSprite(sprite);
	o:setNorthSprite(northSprite);
	o.isContainer = false;
	o.blockAllTheSquare = false;
	o.name = getText("Tooltip_PowerNode");
	o.dismantable = true;
	o.canBeAlwaysPlaced = true;
    o.canBeLockedByPadlock = false;
	return o;
end
function ISNode:create(x, y, z, north, sprite)
	local cell = getWorld():getCell();
	self.sq = cell:getGridSquare(x, y, z);
	self.javaObject = IsoThumpable.new(cell, self.sq, sprite, north, self);
	buildUtil.setInfo(self.javaObject, self);
	buildUtil.consumeMaterial(self);
	-- the wooden wall have 200 base health + 100 per carpentry lvl
	self.javaObject:setMaxHealth(100);
	self.javaObject:setHealth(100);
	-- the sound that will be played when our door frame will be broken
	self.javaObject:setBreakSound("BreakObject");

	local sharedSprite = getSprite(self:getSprite())
	if self.sq and sharedSprite and sharedSprite:getProperties():Is("IsStackable") then
		local props = ISMoveableSpriteProps.new(sharedSprite)
		self.javaObject:setRenderYOffset(props:getTotalTableHeight(self.sq))
	end

	-- add the item to the ground
    self.sq:AddSpecialObject(self.javaObject);
	self.javaObject:transmitCompleteItemToServer();
end
function ISSwitch:new(sprite, northSprite)
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();
	o:setSprite(sprite);
	o:setNorthSprite(northSprite);
	o.isContainer = false;
	o.blockAllTheSquare = false;
	o.name = getText("Tooltip_GeneratorSwitch");
	o.dismantable = true;
	o.canBeAlwaysPlaced = true;
    o.canBeLockedByPadlock = false;
	return o;
end

function ISSwitch:create(x, y, z, north, sprite)
	local cell = getWorld():getCell();
	self.sq = cell:getGridSquare(x, y, z);
	self.javaObject = IsoThumpable.new(cell, self.sq, sprite, north, self);
	buildUtil.setInfo(self.javaObject, self);
	buildUtil.consumeMaterial(self);
	-- the wooden wall have 200 base health + 100 per carpentry lvl
	self.javaObject:setMaxHealth(100);
	self.javaObject:setHealth(100);
	-- the sound that will be played when our door frame will be broken
	self.javaObject:setBreakSound("BreakObject");

	local sharedSprite = getSprite(self:getSprite())
	if self.sq and sharedSprite and sharedSprite:getProperties():Is("IsStackable") then
		local props = ISMoveableSpriteProps.new(sharedSprite)
		self.javaObject:setRenderYOffset(props:getTotalTableHeight(self.sq))
	end

	-- add the item to the ground
    self.sq:AddSpecialObject(self.javaObject);
	self.javaObject:transmitCompleteItemToServer();
end
