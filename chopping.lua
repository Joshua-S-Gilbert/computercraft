local position = require("position")
local refuel = require("refuel")

local jobStartPos = "job_start_pos"

-- Function to check for refuel interrupt
local function checkRefuelInterrupt()
    local needsRefuel, refuelPosition = refuel.checkRefuel()
    if needsRefuel then
        print("Refuel required. Navigating to refuel station...")
        refuel.refuel(refuelPosition)
        return true
    end
    return false
end

-- Recursive function to chop the tree
local function chopTree(startX, startZ)
    local pos = position.load()


    -- Check for refuel before each operation
    if checkRefuelInterrupt() then
        return
    end

    -- Check for wood blocks in all horizontal directions
    for _, dir in ipairs(directions) do
        if dir.turn == "left" then
            position.turn(pos, "left")
            turtle.turnLeft()
        elseif dir.turn == "right" then
            position.turn(pos, "right")
            turtle.turnRight()
        elseif dir.turn == "back" then
            position.turn(pos, "right")
            turtle.turnRight()
            position.turn(pos, "right")
            turtle.turnRight()
        end

        if turtle.detect() then
            turtle.dig()
            dir.move()
            position.update(pos, dir.update)
            chopTree(startX, startZ) -- Recurse to chop connected logs
            dir.back()
            position.update(pos, "back")
        end

        -- Reset orientation after checking
        if dir.turn == "left" then
            position.turn(pos, "right")
            turtle.turnRight()
        elseif dir.turn == "right" then
            position.turn(pos, "left")
            turtle.turnLeft()
        elseif dir.turn == "back" then
            position.turn(pos, "left")
            turtle.turnLeft()
            position.turn(pos, "left")
            turtle.turnLeft()
        end
    end

    -- Check above for logs
    if turtle.detectUp() then
        turtle.digUp()
        turtle.up()
        position.update(pos, "up")
        chopTree(startX, startZ)
        turtle.down()
        position.update(pos, "down")
    end

    -- Check below for logs
    if turtle.detectDown() then
        turtle.digDown()
        turtle.down()
        position.update(pos, "down")
        chopTree(startX, startZ)
        turtle.up()
        position.update(pos, "up")
    end
end

-- Main function to start wood chopping
local function chopWood()
    print("Starting wood chopping operation...")

    -- Ensure the turtle is calibrated
    if not position.calibrate() then
        print("Position calibration failed. Ensure GPS is available.")
        return
    end

    -- Save initial position for return
    local initialPos = position.load()
    fs.open(jobStartPos, 'w')
    fs.write(textutils.serialise(initialPos))
    fs.close()

    -- Start by digging the initial log and moving forward
    if turtle.detect() then
        turtle.dig()
        turtle.forward()
        position.update(initialPos, "forward")
    end

    -- Start chopping the tree
    chopTree(initialPos.x, initialPos.z)

    -- Return to starting position and orientation
    print("Returning to initial position...")
    navigation.navigateTo(initialPos.x, initialPos.y, initialPos.z, true)
end

chopWood()
