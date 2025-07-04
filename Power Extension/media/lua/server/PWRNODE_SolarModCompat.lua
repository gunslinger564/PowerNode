
if isClient() then return end

if getActivatedMods():contains("ISA_41") then
    local SPowerbank = require "Powerbank/ISAPowerbank_server"

    local original_SPowerbank_updateDrain = SPowerbank.updateDrain

    function SPowerbank:updateDrain()
        original_SPowerbank_updateDrain(self)
        print("SPowerbank:updateDrain run")
        if self.node then
            local node = PWR.getNode(self.node.x,self.node.y,self.node.z)
            print("node data found")
            local sandbox = SandboxVars.ISA
            local isaS = sandbox.DrainCalc == 1
         if node and node.state then
            local total = node.realTotalPower
            if isaS then
               total = total * 920
            else
               total = total * 800
            end
            self.drain = self.drain + total
            self.node.added = true
         end
            self:saveData(true)
        end
    end
end