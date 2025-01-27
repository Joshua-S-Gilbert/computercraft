local mining = {}
local position = require("position") -- Include the position module

local progressFile = "mining_progress"

-- Function to load mining progress
local function loadProgress()
    if fs.exists(progressFile) then
        local file = fs.open(progressFile, "r")
        local progress = textutils.unserialize(file.readAll())
        file.close()
        return progress
    else
        return nil -- No progress found
    end
end

-- Function to save mining progress
local function saveProgress(progress)
    local file = fs.open(progressFile, "w")
    file.write(textutils.serialize(progress))
    file.close()
end

-- Function to check if inventory is full
local function isInventoryFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

-- Function to handle vein mining (connected ores)
local function mineVein()
    local directions = {
        { inspect = turtle.inspect, move = position.forward, back = position.back },
        { inspect = turtle.inspectUp, move = position.up, back = position.down },
        { inspect = turtle.inspectDown, move = position.down, back = position.up },
    }

    for _, dir in ipairs(directions) do
        local success, data = dir.inspect()
        if success and data.name:find("ore") then
            dir.move()
            mineVein() -- Recursively mine connected ores
            dir.back()
        end
    end
end

-- Function to mine a single layer
local function mineLayer(xStart, xEnd, zStart, zEnd, yLevel)
    local pos = position.load()
    local xDir = 1 -- Direction of movement along X

    for z = zStart, zEnd do
        for x = xStart, xEnd, xDir do
            -- Check for interrupt: inventory full or need to refuel
            if isInventoryFull() then
                return "inventory_full", { x = pos.x, z = pos.z, y = yLevel }
            end

            if fs.exists("refuel_interrupt") then
                return "refuel", { x = pos.x, z = pos.z, y = yLevel }
            end

            -- Mine the block in front
            if turtle.detect() then
                local success, data = turtle.inspect()
                if success and data.name:find("ore") then
                    mineVein()
                else
                    turtle.dig()
                end
            end

            -- Move forward to the next block
            if x ~= xEnd then
                position.forward()
            end
        end

        -- Move to the next row
        if z ~= zEnd then
            if xDir == 1 then
                position.turn("right")
                position.forward()
                position.turn("right")
            else
                position.turn("left")
                position.forward()
                position.turn("left")
            end
            xDir = -xDir -- Reverse X direction
        end
    end
    return "layer_complete", nil
end

-- Main mining function
function mining.startMining(chunkInfo)
    -- Load progress or start fresh
    local progress = loadProgress() or {
        xStart = chunkInfo.xStart,
        yStart = chunkInfo.yStart,
        zStart = chunkInfo.zStart,
    }

    local xStart, xEnd = chunkInfo.xStart, chunkInfo.xEnd
    local zStart, zEnd = chunkInfo.zStart, chunkInfo.zEnd
    local yStart, yEnd = progress.yStart, chunkInfo.yEnd

    -- Start mining
    print("Starting mining operation...")
    for y = yStart, yEnd, -3 do -- Skip 3 layers at a time
        print("Mining layer at Y level:", y)
        local result, interruptData = mineLayer(xStart, xEnd, zStart, zEnd, y)

        -- Handle interrupts
        if result == "inventory_full" then
            print("Inventory full. Stopping mining.")
            saveProgress({ xStart = interruptData.x, yStart = interruptData.y, zStart = interruptData.z })
            return "inventory_full"
        elseif result == "refuel" then
            print("Refuel required. Stopping mining.")
            saveProgress({ xStart = interruptData.x, yStart = interruptData.y, zStart = interruptData.z })
            return "refuel"
        end

        -- Move down to the next layer
        if y > yEnd then
            for _ = 1, 3 do
                turtle.digDown()
                position.down()
            end
        end

        -- Save progress after completing each layer
        saveProgress({ xStart = xStart, yStart = y, zStart = zStart })
    end

    -- Mining complete
    print("Mining operation complete.")
    if fs.exists(progressFile) then
        fs.delete(progressFile) -- Clean up progress file
    end
    return "complete"
end

return mining
