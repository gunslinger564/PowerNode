local function getCableSprite(item)
    local type = item:getType()
    if type:contains("Orange") then
        return "PowerNodesTiles_Cords_0"
    elseif type:contains("Yellow") then
        return "PowerNodesTiles_Cords_48"
    elseif type:contains("Green") then
        return "PowerNodesTiles_Cords_96"
    elseif type:contains("Red") then
        return "PowerNodesTiles_Cords_144"
    elseif type:contains("Blue") then
        return "PowerNodesTiles_Cords_192"
    end

end

function ISMoveableCursor:getInventoryObjectList()
    local objects           = {};
    local spriteBuffer	= {};
    local items 			= self.character:getInventory():getItems();
    local items_size 		= items:size();
    for i=0,items_size-1, 1 do
        local item = items:get(i);
        local cablesprite = getCableSprite(item)
        if instanceof(item, "Moveable") then
            if self.character:getPrimaryHandItem() ~= item and self.character:getSecondaryHandItem() ~= item then
                local moveProps = ISMoveableSpriteProps.new( item:getWorldSprite() );
                if moveProps.isMoveable then
                    local ignoreMulti = false
                    if moveProps.isMultiSprite then
                        local anchorSprite = moveProps.sprite:getSpriteGrid():getAnchorSprite()
                        if spriteBuffer[anchorSprite] then
                            ignoreMulti = true
                        else
                            spriteBuffer[anchorSprite] = true
                            if moveProps.sprite ~= anchorSprite then
                                moveProps = ISMoveableSpriteProps.new(anchorSprite)
                            end
                        end
                    end
                    if not ignoreMulti then
                        table.insert(objects, { object = item, moveProps = moveProps });
                        if self.cacheInvObjectSprite and self.cacheInvObjectSprite == item:getWorldSprite() then
                            self.objectIndex = #objects;
                        end
                    end
                end
            end
        elseif cablesprite then
            local moveProps = ISMoveableSpriteProps.new( cablesprite );
            table.insert(objects, { object = item, moveProps = moveProps});
        end
    end

    if self.tryInitialInvItem then
        if instanceof(self.tryInitialInvItem, "Moveable") then
            --print("MovablesCursor attempting to set Initial Item: "..self.tryInitialInvItem:getWorldSprite());
            local moveProps = ISMoveableSpriteProps.new(self.tryInitialInvItem:getWorldSprite());
            local sprite = moveProps.sprite;
            if moveProps.isMultiSprite then
                local spriteGrid = moveProps.sprite:getSpriteGrid();
                sprite = spriteGrid:getAnchorSprite();
            end
            local spriteName = sprite:getName();
            for index,table in ipairs(objects) do
                --print("Compare "..table.object:getWorldSprite().." "..spriteName )
                if table.moveProps.sprite == sprite then
                    self.objectIndex = index;
                    self.cacheInvObjectSprite = spriteName;
                    break;
                end
            end
        else
         --   print(self.tryInitialInvItem);
        end
        self.tryInitialInvItem = nil;
    end

    return objects;
end


function ISMoveableCursor:isValid( _square )
    if not self.floorSprite then
        self.floorSprite = IsoSprite.new();
        self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png');
    end

    self.currentMoveProps   = nil;
    self.origMoveProps      = nil;
    self.canCreate          = nil;
    self.objectSprite       = nil;
    self.origSpriteName     = nil;
    self.colorMod           = {r=1,g=0,b=0};
    self.yOffset            = 0;

    if ISMoveableCursor.mode[self.player] == "pickup" or ISMoveableCursor.mode[self.player] == "rotate" then
        self.objectIndex    = self.currentSquare ~= _square and -1 or self.objectIndex;
    end
    if _square ~= self.currentSquare then
        self.objectListCache = nil;
    end
    self.currentSquare  = _square;

    --if self.currentSquare == nil or not self.currentSquare:isCouldSee(self.player) then
    if self.currentSquare == nil then
        self:setInfoPanel( _square, nil, nil );
        self.cursorFacing = nil;
        self.joypadFacing = nil;
        return false;
    end

    if getPlayerRadialMenu(self.player) and getPlayerRadialMenu(self.player):isReallyVisible() then
        self:setInfoPanel( _square, nil, nil )
        self.cursorFacing = nil
        self.joypadFacing = nil
        return false
    end

    if self.character:getCharacterActions():isEmpty() then
        self.character:faceLocation(_square:getX(), _square:getY())
    end

    self.canSeeCurrentSquare = _square and _square:isCouldSee(self.player);

    if ISMoveableCursor.mode[self.player] == "pickup" then
        local objects = self.objectListCache or self:getObjectList();
        self.objectListCache = objects;

        if #objects > 0 then
            if self.objectIndex > #objects or self.objectIndex < 1 then self.objectIndex = 1 end
            if self.objectIndex >= 1 and self.objectIndex <= #objects then
                local object = not objects[self.objectIndex].isWall and objects[self.objectIndex].object or nil;
                local moveProps = objects[self.objectIndex].moveProps;

                if moveProps and moveProps.sprite then
                    --self:setInfoPanel( _square, object, moveProps );
                    self.currentMoveProps   = moveProps;
                    self.origMoveProps      = moveProps;
                    self.canCreate          = moveProps:canPickUpMoveable( self.character, _square, object );
                    self.colorMod           = ISMoveableCursor.normalColor; --self.canCreate and ISMoveableCursor.normalColor or ISMoveableCursor.invalidColor;
                    self.objectSprite       = nil; --moveProps.sprite; disabled object sprite for pickup
                    self.origSpriteName     = moveProps.spriteName;
                    --self.cursorFacing = nil;
                    self.yOffset            = moveProps:getYOffsetCursor(); -- this is updated in moveprops in canPickUpMoveable function
                    self:setInfoPanel( _square, object, moveProps );
                    return true;
                end
            end
        end
    elseif ISMoveableCursor.mode[self.player] == "place" then
        local objects = self.objectListCache or self:getInventoryObjectList();
        self.objectListCache = objects;

        if #objects > 0 then
            if self.objectIndex > #objects or self.objectIndex < 1 then self.objectIndex = 1 end
            if self.objectIndex >= 1 and self.objectIndex <= #objects then
                local item = objects[self.objectIndex].object;
                local moveProps = objects[self.objectIndex].moveProps;
                self.origMoveProps = moveProps;
                local origName = moveProps.spriteName;

                if moveProps and moveProps:hasFaces() then
                    local faceIndex;
                    if moveProps.isTableTop and not moveProps.ignoreSurfaceSnap then    -- adjustment for tabletops, they should always try to snap first if parent table has faces.
                        faceIndex = moveProps:snapFaceToSquare( _square ) or self.cursorFacing;
                    else
                        faceIndex = self.cursorFacing or moveProps:snapFaceToSquare( _square );
                    end
                    if faceIndex and moveProps:getIndexedFaces()[faceIndex] then
                        local tryMoveProps = ISMoveableSpriteProps.new( moveProps:getIndexedFaces()[faceIndex] );
                        if tryMoveProps and tryMoveProps.isMoveable and tryMoveProps.sprite then
                            --self.faceIndex = faceIndex;
                            moveProps = tryMoveProps;
                        end
                    end
                end

                if moveProps and moveProps.sprite then
                    --self:setInfoPanel( _square, item, moveProps );
                    self.currentMoveProps       = moveProps;
                    self.canCreate              = moveProps:canPlaceMoveable( self.character, _square, item );
                    self.colorMod               = self.canCreate and ISMoveableCursor.normalColor or ISMoveableCursor.invalidColor;
                    local csprite = getCableSprite(item)
                    if csprite then
                        self.cacheInvObjectSprite   = csprite;
                    else
                        self.cacheInvObjectSprite   = item:getWorldSprite();
                    end
                    self.objectSprite           = moveProps.sprite;
                    self.origSpriteName         = origName;
                    --self.cursorFacing = nil;
                    self.yOffset                = moveProps:getYOffsetCursor(); -- this is updated in moveprops in canPlaceMoveable function
                    self:setInfoPanel( _square, item, moveProps );
                    return true;
                end

            end
        end
    elseif ISMoveableCursor.mode[self.player] == "rotate" then
        local rotateObject = self.objectListCache or self:getRotateableObject();
        self.objectListCache = rotateObject;
        if rotateObject then
            local object = rotateObject.object;
            local moveProps = rotateObject.moveProps;
            self.origMoveProps = moveProps;
            local origProps = moveProps;
            local origName = moveProps.spriteName;
            if moveProps and moveProps:hasFaces() then
                local faces = moveProps:getIndexedFaces();

                if self.objectIndex < 1 then
                    self.objectIndex = moveProps:getFaceIndex();
                end

                if self.objectIndex > #faces or self.objectIndex < 1 then self.objectIndex = 1 end
                local faceIndex = self.cursorFacing or self.objectIndex;

                if faceIndex >= 1 and faceIndex <= #faces and faces[faceIndex] then
                    local tryMoveProps = ISMoveableSpriteProps.new( faces[faceIndex] );
                    if tryMoveProps and tryMoveProps.isMoveable and tryMoveProps.sprite then
                        --self.faceIndex = faceIndex;
                        moveProps = tryMoveProps;
                    end
                end

                if moveProps and moveProps.sprite then
                    --self:setInfoPanel( _square, object, moveProps, faces[faceIndex] );
                    self.currentMoveProps   = moveProps;
                    self.canCreate          = moveProps:canRotateMoveable( _square, object, origProps ); --FIXME
                    self.colorMod           = self.canCreate and ISMoveableCursor.normalColor or ISMoveableCursor.invalidColor; --ISMoveableCursor.normalColor;
                    self.objectSprite       = moveProps.sprite;
                    self.origSpriteName     = origName;
                    self.yOffset            = moveProps:getYOffsetCursor();
                    self:setInfoPanel( _square, object, moveProps, faces[faceIndex] );
                    --self.cursorFacing = nil;
                    return true;
                end
            end
            if moveProps and moveProps.sprite and moveProps:canRotateDirection() then
                self.currentMoveProps   = moveProps;
                self.canCreate          = moveProps:canRotateMoveable( _square, object, origProps );
                self.colorMod           = self.canCreate and ISMoveableCursor.normalColor or ISMoveableCursor.invalidColor;
                self.objectSprite       = moveProps.sprite;
                self.origSpriteName     = origName;
                self.yOffset            = moveProps:getYOffsetCursor();
                self:setInfoPanel( _square, object, moveProps );
                return true;
            end
        end
    elseif ISMoveableCursor.mode[self.player] == "scrap" then
        local objects = self.objectListCache or self:getScrapObjectList();
        self.objectListCache = objects;
        if #objects > 0 then
            if self.objectIndex > #objects or self.objectIndex < 1 then self.objectIndex = 1 end
            if self.objectIndex >= 1 and self.objectIndex <= #objects then
                local object = objects[self.objectIndex].object;
                local moveProps = objects[self.objectIndex].moveProps;
                if moveProps and moveProps.sprite then
                    self.currentMoveProps   = moveProps;
                    self.origMoveProps      = moveProps;
                    self.canCreate          = moveProps:canScrapObject( self.character ).canScrap;
                    self.colorMod           = ISMoveableCursor.normalColor;
                    self.objectSprite       = nil;
                    self.origSpriteName     = moveProps.spriteName;
                    self.yOffset            = moveProps:getYOffsetCursor();
                    self:setInfoPanel( _square, object, moveProps );
                    return true;
                end
            end
        end
    end

    self:setInfoPanel( _square, nil, nil );
    self.cursorFacing = nil;
    self.joypadFacing = nil;
    return false;
end

local function addCable(item,char,obj,sq)
    local nfull
    if item:getType():contains("ExtensionCord")then
        local inv = char:getInventory()
        local cables = inv:FindAll(item:getType())
        if cables then
            for i=0,cables:size()-1 do
                local c = cables:get(i)
                if c then
                    if c:getUsedDelta() >= 1.0 then
                    else
                        nfull = c
                        break
                    end
                end
            end
        end
        if nfull then
            nfull:setUsedDelta(nfull:getUsedDelta() + .05)
            triggerEvent("OnObjectAboutToBeRemoved", obj)
            sq:transmitRemoveItemFromSquare(obj)
            return
        else
           -- char:getInventory():AddItem(item)
            item:setUsedDelta(.05)
           -- triggerEvent("OnObjectAboutToBeRemoved", obj)
           -- sq:transmitRemoveItemFromSquare(obj)
           -- return
        end
    end
    return item
end

function ISMoveableSpriteProps:pickUpMoveableInternal( _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating )
    --if _object and self:canPickUpMoveable( _character, _square, not _sprInstance and _object or nil ) then
    local objIsIsoWindow = self.type == "Window" and instanceof(_object,"IsoWindow");
    local item 	= self:instanceItem(_spriteName);
    item = addCable(item,_character,_object,_square)    --only place i modify this function
    if item or (objIsIsoWindow and _object:isDestroyed()) then      
        local windowGotSmashed = false;
        if not objIsIsoWindow or not _object:isDestroyed() then    
            if not _rotating and self:doBreakTest( _character ) then
                if self.type ~= "Window" then
                    self:playBreakSound( _character, _object );
                    self:addBreakDebris( _square );
                elseif objIsIsoWindow then
                    if not _object:isDestroyed() then              
                        _object:smashWindow();
                        windowGotSmashed = true;
                    end
                end
            elseif item then
                if instanceof(_object, "IsoThumpable") then
                    item:getModData().name = _object:getName() or ""
                    item:getModData().health = _object:getHealth()
                    item:getModData().maxHealth = _object:getMaxHealth()
                    item:getModData().thumpSound = _object:getThumpSound()
                    item:getModData().color = _object:getCustomColor()
                    if _object:hasModData() then
                        item:getModData().modData = copyTable(_object:getModData())
                    end
                else
                    if _object:hasModData() and _object:getModData().movableData then
                        item:getModData().movableData = copyTable(_object:getModData().movableData)
                    end

                    if _object:hasModData() and _object:getModData().itemCondition then
                        item:setConditionMax(_object:getModData().itemCondition.max);
                        item:setCondition(_object:getModData().itemCondition.value);
                    end
                end
                if _createItem then
                    if self.isMultiSprite then
                        _square:AddWorldInventoryItem(item, ZombRandFloat(0.1,0.9), ZombRandFloat(0.1,0.9), 0);
                    else
                        _character:getInventory():AddItem(item);        
                    end
                end
            end
        end

        
        if instanceof(_object,"IsoLightSwitch") and _sprInstance==nil then
            _object:setCustomSettingsToItem(item);
        end

        if instanceof(_object, "IsoMannequin") then
            _object:setCustomSettingsToItem(item)
        end

        if self.type == "WallOverlay" then
            if _object:getSprite() and _spriteName and (_object:getSprite():getName() == _spriteName) then
                triggerEvent("OnObjectAboutToBeRemoved", _object) -- Hack for RainCollectorBarrel, Trap, etc
                _square:transmitRemoveItemFromSquare(_object)
            elseif _sprInstance then
                local sprList = _object:getChildSprites();
                local sprIndex = sprList and sprList:indexOf(_sprInstance) or -1
                if sprIndex == -1 then
                else
                    _object:RemoveAttachedAnim(sprIndex)
                    if isClient() then _object:transmitUpdatedSpriteToServer() end
                end
            end
        elseif self.type == "FloorTile" then
            local floor = _square:getFloor();
            local moveableDefinitions = ISMoveableDefinitions:getInstance();
            if moveableDefinitions and moveableDefinitions.floorReplaceSprites then
                local repSprs = moveableDefinitions.floorReplaceSprites;
                local floor = _square:getFloor();
                local spr = getSprite( repSprs[ ZombRand(1,#repSprs) ] );
                if floor and spr then
                    floor:setSprite(spr);
                    if isClient() then floor:transmitUpdatedSpriteToServer(); end --:transmitCompleteItemToServer(); end
                end
            end
        elseif self.isoType == "IsoBrokenGlass" then
            -- add random damage to hands if no gloves
            if not _character:getClothingItem_Hands() and ZombRand(3) == 0 then
                local handPart = _character:getBodyDamage():getBodyPart(BodyPartType.FromIndex(ZombRand(BodyPartType.ToIndex(BodyPartType.Hand_L),BodyPartType.ToIndex(BodyPartType.Hand_R) + 1)))
                handPart:setScratched(true, true);
                -- possible glass in hands
                if ZombRand(5) == 0 then
                    handPart:setHaveGlass(true);
                end
            end
            triggerEvent("OnObjectAboutToBeRemoved", _object)
            _square:transmitRemoveItemFromSquare(_object)
        elseif self.type == "Window" then
            if objIsIsoWindow and not windowGotSmashed then
                if isClient() then _square:transmitRemoveItemFromSquare(_object) end
                _square:RemoveTileObject(_object);
            end
        elseif not _sprInstance then --Objects, Vegitation, WallObjects etc
            if self.isoType == "IsoRadio" or self.isoType == "IsoTelevision" then
                if instanceof(_object,"IsoWaveSignal") then
                    local deviceData = _object:getDeviceData();
                    if deviceData then
                        item:setDeviceData(deviceData);
                    else
                        print("Warning: device data missing?>?")
                    end
                end
            end
            if self.spriteProps and not self.spriteProps:Is(IsoFlagType.waterPiped) then
                --print("water check");
                if _object:hasModData() then
                    --print("water check mod data");
                    if _object:getModData().waterAmount then
                        item:getModData().waterAmount = _object:getModData().waterAmount;
                        item:getModData().taintedWater = _object:isTaintedWater();
                    end
                else
                    --print("water check no mod");
                    local waterAmount = tonumber(_object:getWaterAmount());
                    if waterAmount then
                        item:getModData().waterAmount = waterAmount;
                        item:getModData().taintedWater = _object:isTaintedWater();
                end
                end
                --print("ITEM WATER AMOUNT = "..tostring(item:getModData().waterAmount));
            end
            triggerEvent("OnObjectAboutToBeRemoved", _object) -- Hack for RainCollectorBarrel, Trap, etc
            _square:transmitRemoveItemFromSquare(_object)
        end
        _square:RecalcProperties();
        _square:RecalcAllWithNeighbours(true);

        --ISMoveableCursor.clearCacheForAllPlayers();

        triggerEvent("OnContainerUpdate")

        IsoGenerator.updateGenerator(_square)
        return item;
    end
    --end
end
local cTiles = "PowerNodesTiles_Cords_"
local function lookAroundForCables(x,y,z,color)
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
local function sortThisCable(cbls,mod)
    local tex
        if cbls.NORTH and cbls.SOUTH and cbls.EAST and cbls.WEST then
                tex = cTiles..(mod + 9)
        elseif cbls.NORTH and cbls.SOUTH and cbls.EAST then
                tex = cTiles..(mod + 10)
        elseif cbls.NORTH and cbls.SOUTH and cbls.WEST then
                tex = cTiles..(mod + 7)
        elseif cbls.NORTH and cbls.EAST and cbls.WEST then
                tex = cTiles..(mod + 8)
        elseif cbls.SOUTH and cbls.EAST and cbls.WEST then
                tex = cTiles..(mod + 6)
        elseif (cbls.SOUTH or cbls.NORTH) and cbls.WEST == nil and cbls.EAST == nil then
                tex = cTiles..(mod + 3)
        elseif (cbls.WEST or cbls.EAST) and cbls.NORTH == nil and cbls.SOUTH == nil then
                tex = cTiles..mod
        elseif (cbls.NORTH and cbls.WEST) and cbls.EAST == nil and cbls.SOUTH == nil then
                tex = cTiles..(mod + 1)
        elseif (cbls.NORTH and cbls.EAST) and cbls.SOUTH == nil and cbls.WEST == nil then
                tex = cTiles..(mod + 5)
        elseif (cbls.SOUTH and cbls.WEST) and cbls.NORTH == nil and cbls.EAST == nil then
                tex = cTiles..(mod + 2)
        elseif (cbls.SOUTH and cbls.EAST) and cbls.NORTH == nil and cbls.WEST == nil then
                tex = cTiles..(mod + 4)
        end
        return tex
end


local original_ISMoveableCursor_render = ISMoveableCursor.render

function ISMoveableCursor:render( _x, _y, _z, _square )
    if self.objectSprite then
        local c = PWR.getColor(self.objectSprite:getName())
        if c then
            local mod = PWR.getMod(c)
           local cbls = lookAroundForCables( _x, _y, _z,c)
           local nsprite = sortThisCable(cbls,mod)
           if nsprite then
            local sprite = getSprite(nsprite)
            self.objectSprite = sprite
           end
        end
    end
        original_ISMoveableCursor_render(self, _x, _y, _z, _square )
end