local position = require("position")
local refuel = require("refuel")
local utility = require("utility")
local navigation = require("navigation")

local jobStartPos = "job_start_pos"
local positionFile = "turtle_position"

-- Recursive function to chop the tree
local function chopTree()
    -- 1. Refuel check
    if not refuel.checkRefuel() then
        utility.log("Refuel failed, stopping tree chopping.")
        return false
    end

    -- 2. Horizontal wood detection
    for _ = 1, 4 do
        position.turn("left") -- Turn to the next direction
        if turtle.detect() then
            turtle.dig()
            local success, pos = position.forward()
            if success then
                chopTree() -- Recurse to chop connected logs
                position.back() -- Return to the previous position
            end
        end
    end

    -- 3. Check above for logs
    if turtle.detectUp() then
        turtle.digUp()
        local success, pos = position.up()
        if success then
            chopTree() -- Recurse upwards
            position.down() -- Return to the previous position
        end
    end

    -- 4. Check below for logs (rare case)
    if turtle.detectDown() then
        turtle.digDown()
        local success, pos = position.down()
        if success then
            chopTree() -- Recurse downwards
            position.up() -- Return to the previous position
        end
    end
end

-- Main function to start wood chopping
local function chopWood()
    print("Starting wood chopping operation...")

    -- Ensure the turtle is calibrated
    local success, initialPos = utility.readPositionFile(positionFile)
    if not success then
        utility.log("chopWood failed to execute")
        return false
    end

    -- Save the starting position
    utility.saveFile(jobStartPos, initialPos)

    -- Start the recursive chopping process
    chopTree()

    -- Return to the starting position and orientation
    print("Returning to starting position...")
    navigation.navigateTo(initialPos.x, initialPos.y, initialPos.z, true)
    return true
end

chopWood()
