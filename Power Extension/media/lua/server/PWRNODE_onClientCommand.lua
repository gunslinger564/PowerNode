
PWR = PWR or {}

local function addNode(player,args)
    local moddata = GetNodeData()
    table.insert(moddata.ActiveNodes, args)
end

local removeNode = function(player, args)
    local globalModData = GetNodeData()
    for k, v in pairs(globalModData.ActiveNodes) do
        if v then
            if v.x == args.x and v.y == args.y and v.z == args.z then
                table.remove(globalModData.ActiveNodes, k)
                break
            end
        end
    end
end


function PWR.updateData(args)
    local moddata = GetNodeData()
    local command
    for k, v in pairs(moddata.ActiveNodes) do
        if v then
            if v.x == args.x and v.y == args.y and v.z == args.z then
                if args.toggle == true then
                    if args.state == true   then
                        command = "TURNON"
                        PWR.setChunk({"TURNON",args})
                    else
                        command = "TURNOFF"
                        PWR.setChunk({"SHUTDOWN",args})
                    end
                    args.toggle = nil
                end

                table.remove(moddata.ActiveNodes, k)
                table.insert(moddata.ActiveNodes, args)
                ModData.add("NodeData",{ActiveNodes = moddata.ActiveNodes})
                if isServer() then
                    if command ~= nil then
                        local players = getOnlinePlayers()
                        for i = 0 ,players:size()-1 do
                            local p = players:get(i)
                            sendServerCommand(p,"PWRNODE",command,args)
                        end
                    end
                    TransmitNodeData()
                end
                break
            end
        end
    end
end



function PWR.setChunk(args)
    local command,c = args[1],args[2]
    local chunks = PWR.getChunks(c.x,c.y,c.z)
    if chunks~= nil then
        for _, chunk in pairs(chunks)do
            if command == "TURNON" then
                chunk:addGeneratorPos(c.x,c.y,c.z)
            elseif command == "SHUTDOWN" then
                chunk:removeGeneratorPos(c.x,c.y,c.z)
            end
        end
    end
end

function PWR.sendPrint(args)
            local players = getOnlinePlayers()
            for i = 0 ,players:size()-1 do
                local p = players:get(i)
                sendServerCommand(p,"PWRNODE","PRINT",args)
            end
end


local function OnClientCommand(module, command, player, args)
    if module == "PWRNODE" then
        if command == "ADDNODE" then
            addNode(player,args)
        elseif command == "REMOVENODE" then
            removeNode(player, args)
        elseif command == "UPDATE" then
            PWRNODE_UPDATE()
        elseif command == 'UPDATEDATA' then
            PWR.updateData(args)
        elseif command == "SETCHUNK" then
            PWR.setChunk(args)
        elseif command == "CHECKPWR" then
            PWR.lookForPower(args.x,args.y,args.z)
        else
            local players = getOnlinePlayers()
            for i = 0 ,players:size()-1 do
                local p = players:get(i)
                sendServerCommand(p,module,command,args)
            end
        end
    end
end
Events.OnClientCommand.Add(OnClientCommand)