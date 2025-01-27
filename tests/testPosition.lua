local position = require("position")
local utility = require("utility")

-- Function to handle commands
local function executeCommand(command)
    local success, pos
    if command == "up" then
        success, pos = position.up()
    elseif command == "down" then
        success, pos = position.down()
    elseif command == "forward" then
        success, pos = position.forward()
    elseif command == "back" then
        success, pos = position.back()
    elseif command == "left" then
        success, pos = position.turn("left")
    elseif command == "right" then
        success, pos = position.turn("right")
    else
        utility.log("Invalid command received: " .. command)
        return
    end

    if success then
        utility.log("Command executed successfully: " .. command)
        utility.log(string.format("Current position: (%d, %d, %d, %s)", pos.x, pos.y, pos.z, pos.direction))
    else
        utility.log("Failed to execute command: " .. command)
    end
end

-- Main program
local function main()
    utility.log("Starting turtle position program...")
    
    -- Step 1: Calibrate the turtle
    local calibrated, pos = position.calibrate()
    if not calibrated then
        utility.log("Failed to calibrate the turtle. Exiting program.")
        return
    end

    utility.log(string.format("Turtle calibrated successfully. Current position: (%d, %d, %d, %s)", pos.x, pos.y, pos.z, pos.direction))

    -- Step 2: Listen for commands from the server
    while true do
        utility.log("Waiting for command from server...")
        local senderId, command = rednet.receive()

        if not senderId or not command then
            utility.log("Failed to receive command from server.")
        else
            utility.log("Received command: " .. command)
            executeCommand(command)
        end
    end
end

-- Run the main function
main()
