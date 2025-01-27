local utility = require("utility")
local position = require("position")

-- Command loop
local function main()
    -- Calibrate the turtle
    print("Calibrating...")
    if not position.calibrate() then
        utility.log("Failed to calibrate. Exiting program.")
        return
    end
    utility.log("Calibration complete.")

    -- Start listening for commands
    print("Starting command loop...")
    while true do
        -- Request command from the server
        utility.sendMessage("requestCommand")
        local senderId, command = rednet.receive()

        -- Check if the command is from the correct server
        if senderId ~= utility.getServerId() then
            utility.log("Received command from an unknown source. Ignoring.")
        elseif not command then
            utility.log("No command received from server. Retrying...")
        else
            utility.log("Executing command: " .. command)

            -- Execute the command
            local success
            if command == "up" then
                success = position.up()
            elseif command == "down" then
                success = position.down()
            elseif command == "forward" then
                success = position.forward()
            elseif command == "back" then
                success = position.back()
            elseif command == "left" then
                success = position.turn("left")
            elseif command == "right" then
                success = position.turn("right")
            else
                success = false
                utility.log("Unsupported command: " .. command)
            end

            -- Log the result of the command execution
            if success then
                utility.log("Command executed successfully: " .. command)
            else
                utility.log("Failed to execute command: " .. command)
            end
        end
    end
end

-- Run the main function
main()
