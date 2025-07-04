




local function OnServerCommand(module, command, args)
    if module == "PWRNODE" then
            if command == "TURNON" then
                print("Turn on command received")
                PWR.TurnON(args)
            elseif command == "TURNOFF" then
                print("Turn off command received")
                PWR.shutDown(args)
            elseif command == "UPDATEGEN" then
                local g,val = args[1],args[2]
                local gen = PWR.findGenerator(g.x,g.y,g.z)
                if gen then
                    gen:setTotalPowerUsing(val)
                end
            elseif command == "CHECK" then
                for _, c in pairs(args.squares)do
                    local sq = getSquare(c[1],c[2],c[3])
                    if sq and not sq:haveElectricity() then
                        local chunk = sq:getChunk()
                        if chunk then
                            local center = args.center
                            chunk:addGeneratorPos(center[1],center[2],center[3])
                        end
                    end
                end
            elseif command == "PRINT" then
                print(args[1])
            end
    end
end
Events.OnServerCommand.Add(OnServerCommand)
