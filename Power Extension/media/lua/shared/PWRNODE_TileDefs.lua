    local vals1 = IsoWorld.PropertyValueMap:get("Material") or ArrayList.new()


    
    if not vals1:contains("Node") then vals1:add("Node")
    end
    if not vals1:contains("Switch") then vals1:add("Switch")
    end
    IsoWorld.PropertyValueMap:put("Material",vals1)
    Events.OnLoadedTileDefinitions.Add(function(manager)
    for i=0,7 do
        local props = manager:getSprite("PowerNodesTiles_"..i):getProperties();
        local obj = "Node"
        if i < 4 then
            obj = "Switch"
        end
        props:Set("Material", obj, false);
        props:CreateKeySet();
    end
    end)