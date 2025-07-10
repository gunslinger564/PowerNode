NodeRange = {}
NodeRange.GenRange = 20 -- Hardcoded and inaccessible on java side. modified to only show active chunks
NodeRange.GenTopLimit = 2 -- Hardcoded and inaccessible on java side.
NodeRange.GenBottomLimit = 3 -- Hardcoded and inaccessible on java side.
NodeRange.CurrFloors = {}
NodeRange.GenStatusLastUpdate = false -- Whether or not the generator was on last update
NodeRange.RenderActive = false


local function isInChunks(square)
    local chunk = square:getChunk()
    for _,c in pairs(NodeRange.ActiveChunks)do
        if chunk == c then return true end
    end
end



function NodeRange.Render(currGenerator, isGenActive)
    local goodColor = getCore():getGoodHighlitedColor()
    local badColor = getCore():getBadHighlitedColor()

    --print("rendering")
    if not NodeRange.ActiveChunks then
        local square = currGenerator:getSquare()
        local currX = square:getX()
        local currY = square:getY()
        NodeRange.ActiveChunks = PWR.getChunks(currX,currY,square:getZ())
    end
    local floorsToIterate = {}
    if #NodeRange.CurrFloors == 0 then
        local square = currGenerator:getSquare()
        local currX = square:getX()
        local currY = square:getY()
        local allowOutsideGens = SandboxVars.AllowExteriorGenerator
        local genRange = NodeRange.GenRange
        local minX,maxX,minY,maxY
        
        minX = currX - genRange
        maxX = currX + genRange
        minY = currY - genRange
        maxY = currY + genRange

        
        

        -- B41 LIMITS
        local minZ = math.max(0, square:getZ() - NodeRange.GenBottomLimit)
        local maxZ = math.min(8, square:getZ() + NodeRange.GenTopLimit)

        -- B42 LIMITS
        --[[local minZ = math.max(-32, square:getZ() - 3)
        local maxZ = math.min(32, square:getZ() + 3)]]

        local genRangeSquared = genRange * genRange
        for zIterator = minZ, maxZ do
            for xIterator = minX, maxX do
                for yIterator = minY, maxY do
                    --local dist = IsoUtils.DistanceTo(xIterator + 0.5, yIterator + 0.5, currX + 0.5, currY + 0.5)
                    --local dist = IsoUtils.DistanceToSquared(xIterator + 0.5, yIterator + 0.5, currX + 0.5, currY + 0.5)
                    local dist = IsoUtils.DistanceToSquared(xIterator + .5, yIterator + .5, currX + .5, currY + .5)
                    local withinRadius = math.floor(dist) <= genRangeSquared
                    if withinRadius then
                        local newSq = getCell():getOrCreateGridSquare(xIterator, yIterator, zIterator);
                        if newSq and (allowOutsideGens or not newSq:isOutside()) then
                            local floor = newSq:getFloor()
                            local isActive = isInChunks(newSq)
                            if floor and isActive then
                                --addAreaHighlight(xIterator, yIterator, xIterator+1, yIterator+1, z, squareHighlight.red, squareHighlight.green, squareHighlight.blue, squareHighlight.alpha)
                                table.insert(floorsToIterate, floor)
                            end
                            --table.insert(floorsToIterate, newSq)
                        end
                    end
                end
            end
        end
    else
        floorsToIterate = NodeRange.CurrFloors
    end
    NodeRange.CurrFloors = floorsToIterate

    local color = isGenActive and getCore():getGoodHighlitedColor() or getCore():getBadHighlitedColor()
    for i = 1, #floorsToIterate do
        local floor = floorsToIterate[i]
        floor:setHighlightColor(color)
        floor:setHighlighted(true, false)
    end
end

function NodeRange.ClearRender(isFullClear)
    for i = #NodeRange.CurrFloors, 1, -1 do
        local floor = NodeRange.CurrFloors[i]
        floor:setHighlighted(false)

        table.remove(NodeRange.CurrFloors, i)
    end
    NodeRange.ActiveChunks = nil
    if isFullClear then
        NodeRange.GenLastUpdate = nil
        NodeRange.GenStatusLastUpdate = false
    end
end

function NodeRange.Update()
    local lastGenerator = NodeRange.GenLastUpdate
    local lastUpdate = NodeRange.GenStatusLastUpdate

    -- Update variables
    NodeRange.GenLastUpdate = NodeRange.TargetGen
    NodeRange.GenStatusLastUpdate = NodeRange.GenLastUpdate:isActivated()

    if lastUpdate ~= NodeRange.GenStatusLastUpdate or lastGenerator ~= NodeRange.GenLastUpdate then
        NodeRange.ClearRender(not NodeRange.RenderActive)
        if NodeRange.RenderActive then
            NodeRange.Render(NodeRange.GenLastUpdate, NodeRange.GenStatusLastUpdate)
        end
    end
end

function NodeRange.StopUpdating()
    NodeRange.RenderActive = false
    NodeRange.ClearRender(true)
end

--[[

local legacyPrerender = ISGeneratorInfoWindow.prerender
function ISGeneratorInfoWindow:prerender(...)
    NodeRange.Update()
    legacyPrerender(self, ...)
end

local classicSetObject =ISGeneratorInfoWindow.setObject
function ISGeneratorInfoWindow:setObject(object)
    NodeRange.TargetGen = object
    classicSetObject(self, object)
end

local classicVisible = ISGeneratorInfoWindow.setVisible
function ISGeneratorInfoWindow:setVisible(visible, ...)
    print("Turning visible: "..tostring(visible))
    if visible then
        NodeRange.RenderActive = true

    else
        NodeRange.StopUpdating()
    end
    classicVisible(self, visible, ...)
end


local classicClose = ISGeneratorInfoWindow.removeFromUIManager

function ISGeneratorInfoWindow:removeFromUIManager() -- Overwrite the original method in ISCollapsableWindow. Should hopefully derive from ISCollapsableWindow and whatever THAT derives from.
    --hooked = false
    NodeRange.StopUpdating()
    classicClose(self)
end

if getActivatedMods():contains("MultipleGenerators") then -- MultipleGenerators patch
    local classicInit = ISGeneratorInfoWindow.initialise
    function ISGeneratorInfoWindow:initialise(...)
        classicInit(self, ...)
        NodeRange.TargetGen = self.generator
    end

    local classicAddToUI = ISGeneratorInfoWindow.addToUIManager
    function ISGeneratorInfoWindow:addToUIManager(...)
        NodeRange.RenderActive = true
        classicAddToUI(self, ...)
    end
end--]]