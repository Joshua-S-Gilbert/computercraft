local utility = require("utility") -- Assuming you have a utility module for logging, etc.

local serverId = os.getComputerID()
local turtleCommands = {"forward", "back", "left", "right", "up", "down"} -- Valid turtle commands

print("Turtle Command Server started. Server ID: " .. serverId)
rednet.open("back") -- Adjust this to your modem's side

-- Function to validate commands
local function validateCommand(command)
    for _, validCommand in ipairs(turtleCommands) do
        if command == validCommand then
            return true
        end
    end
    return false
end

-- Function to send a command to a specific turtle
local function sendCommand(targetId, command)
    if validateCommand(command) then
        rednet.send(targetId, command)
        print("Sent command '" .. command .. "' to Turtle ID: " .. targetId)

        -- Wait for a response
        local senderId, response = rednet.receive(5) -- Timeout after 5 seconds
        if senderId == targetId and response then
            print("Response from Turtle ID " .. targetId .. ": " .. response)
        else
            print("No response from Turtle ID " .. targetId)
        end
    else
        print("Invalid command: " .. command)
    end
end

-- Main loop
while true do
    print("\nEnter Turtle ID and Command (e.g., 5 forward): ")
    local input = read() -- Get user input
    local targetId, command = input:match("^(%d+)%s+(%S+)$") -- Parse Turtle ID and command

    if targetId and command then
        targetId = tonumber(targetId)
        sendCommand(targetId, command)
    else
        print("Invalid input. Format: <Turtle ID> <Command>")
    end
end
