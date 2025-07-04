



local function getCableSprite(item)
    local type = item:getType()
    print("searching for item "..type)
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

local original_ISMoveableSpriteProps_findInInventory = ISMoveableSpriteProps.findInInventory



function ISMoveableSpriteProps:findInInventory( _character, _spriteName )
    print("ISMoveableSpriteProps:findInInventory run")
    if _character and _spriteName then
        local items 			= _character:getInventory():getItems();
        local items_size 		= items:size();
        for i=0,items_size-1, 1 do
            local item = items:get(i);
            local sprite = getCableSprite(item)
            if sprite then
                if _character:getPrimaryHandItem() ~= item and _character:getSecondaryHandItem() ~= item then
                    if sprite == _spriteName then
                        print("found extension item in inventory")
                        return item;
                        
                    end
                end
            end
        end
    end
    return original_ISMoveableSpriteProps_findInInventory(self, _character, _spriteName )
end

local original_ISMoveableSpriteProps_placeMoveable = ISMoveableSpriteProps.placeMoveable

function ISMoveableSpriteProps:placeMoveable( _character, _square, _origSpriteName )
    print("ISMoveableSpriteProps:placeMoveable run")
    if instanceof(_square,"IsoGridSquare") then
            --local spriteGrid = self.sprite:getSpriteGrid();
           -- if not spriteGrid then return false; end
            --local sgrid = self:getSpriteGridInfo(_square, false);
           -- if not sgrid then return false; end
            local item = self:findInInventory( _character, _origSpriteName );
            local sprite = getCableSprite(item)
            if sprite then
                print("extension sprite found")
                if item then --and self:canPlaceMoveableInternal( _character, _square, item ) then
                    print("extension being placed")
                    self:placeMoveableInternal( _square, item, self.spriteName )
                    item:Use()
                    ISMoveableCursor.clearCacheForAllPlayers();
                    return
                end
            end
    end
    return original_ISMoveableSpriteProps_placeMoveable(self, _character, _square, _origSpriteName )
end