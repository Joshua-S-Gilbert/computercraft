local position = require("position")
local navigation = require("navigation")
local mining = require("mining")
local chestSorting = require("chest_sorting")
local refuel = require("refuel")

local serverId = 2 -- Server ID for requests

local function requestChunkInfo()
    print("Requesting chunk info from server...")
    rednet.send(serverId, "requestChunkInfo")
    local senderId, message = rednet.receive(5) -- Wait for 5 seconds
    if senderId == serverId and message then
        return textutils.unserialize(message)
    else
        print("No chunk available for mining.")
        return nil
    end
end

local function main()
    -- Initial setup: ensure position is calibrated
    if not position.calibrate() then
        print("Position calibration failed. Ensure GPS is available.")
        return
    end

    while true do
        print("Checking for a chunk to mine...")
        local chunkInfo = requestChunkInfo()

        if not chunkInfo then
            print("No chunks to mine. Returning to idle position.")
            -- Request idle position from the server
            rednet.send(serverId, "requestIdlePosition")
            local senderId, message = rednet.receive(5)
            if senderId == serverId and message then
                local idlePosition = textutils.unserialize(message)
                navigation.navigateTo(idlePosition.x, idlePosition.y, idlePosition.z, true)
                print("Turtle is idle.")
            end
            os.sleep(10) -- Wait before checking again
        else
            print("Received chunk to mine. Navigating to starting position...")
            navigation.navigateTo(chunkInfo.xStart, chunkInfo.yStart, chunkInfo.zStart, true)

            local miningResult = mining.startMining(chunkInfo)
            while miningResult == "inventory_full" or miningResult == "refuel" do
                if miningResult == "inventory_full" then
                    print("Inventory full. Sorting items...")
                    -- Request storage start location
                    rednet.send(serverId, "requestStorageLocation")
                    local senderId, message = rednet.receive(5)
                    if senderId == serverId and message then
                        local storageStartLocation = textutils.unserialize(message)
                        navigation.navigateTo(storageStartLocation.x, storageStartLocation.y, storageStartLocation.z, true)
                        chestSorting.sortItems()
                    else
                        print("Failed to get storage start location.")
                    end
                elseif miningResult == "refuel" then
                    print("Fuel is low. Refueling...")
                    local needsRefuel, refuelPosition = refuel.checkRefuel()
                    if needsRefuel and refuelPosition then
                        refuel.refuel(refuelPosition)
                    else
                        print("Failed to refuel. Manual intervention required.")
                        return
                    end
                end

                -- After addressing the interrupt, check the other condition
                if refuel.checkRefuel() then
                    print("Fuel is still low. Refueling again...")
                    local _, refuelPosition = refuel.checkRefuel()
                    refuel.refuel(refuelPosition)
                elseif isInventoryFull() then
                    print("Inventory still full. Sorting items again...")
                    rednet.send(serverId, "requestStorageLocation")
                    local senderId, message = rednet.receive(5)
                    if senderId == serverId and message then
                        local storageStartLocation = textutils.unserialize(message)
                        navigation.navigateTo(storageStartLocation.x, storageStartLocation.y, storageStartLocation.z, true)
                        chestSorting.sortItems()
                    end
                end

                -- Return to the mining chunk after handling interrupts
                print("Returning to mining position...")
                navigation.navigateTo(chunkInfo.xStart, chunkInfo.yStart, chunkInfo.zStart, true)
                miningResult = mining.startMining(chunkInfo)
            end
        end
    end
end

main()
