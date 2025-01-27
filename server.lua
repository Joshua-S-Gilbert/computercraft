-- Define the Turtle Server
local turtleServer = {}
local turtles = {} -- Table to store turtle objects
local completedChunks = {} -- List of completed chunks
local inProgressChunks = {} -- List of chunks currently being mined
local availableChunks = {} -- List of chunks ready for assignment

-- Default positions for idle spots, storage, and refuel
local idlePositions = {
    { x = 10, y = 10, z = 10 },
    { x = 12, y = 10, z = 10 },
    { x = 14, y = 10, z = 10 },
}
local storagePosition = { x = 20, y = 10, z = 30, axis = "x" }
local refuelPosition = { x = 15, y = 10, z = 15 }
local chestLocations = {
    ["minecraft:cobblestone"] = { x = 20, z = 30 },
    ["minecraft:iron_ore"] = { x = 21, z = 30 },
    ["minecraft:gold_ore"] = { x = 22, z = 30 },
}

-- Chunk starting point and size
local initialChunk = { xStart = 0, zStart = 0 } -- Starting chunk
local chunkSize = 16 -- Size of each chunk (16x16)

-- Function to check if a chunk already exists in any list
local function chunkExists(xStart, zStart)
    for _, chunk in ipairs(completedChunks) do
        if chunk.xStart == xStart and chunk.zStart == zStart then
            return true
        end
    end
    for _, chunk in ipairs(inProgressChunks) do
        if chunk.xStart == xStart and chunk.zStart == zStart then
            return true
        end
    end
    for _, chunk in ipairs(availableChunks) do
        if chunk.xStart == xStart and chunk.zStart == zStart then
            return true
        end
    end
    return false
end

-- Function to generate a new chunk systematically
local function generateNewChunk()
    print("Generating new chunk...")

    -- Start from the initial chunk and iterate outward
    local xStart = initialChunk.xStart
    local zStart = initialChunk.zStart

    while true do
        -- Check if the chunk exists in any list
        if not chunkExists(xStart, zStart) then
            local newChunk = {
                xStart = xStart,
                yStart = 20, -- Default Y start (adjust as needed)
                zStart = zStart,
                xEnd = xStart + chunkSize - 1,
                yEnd = 5, -- Default Y end (adjust as needed)
                zEnd = zStart + chunkSize - 1,
            }
            table.insert(availableChunks, newChunk)
            print("New chunk generated:", textutils.serialize(newChunk))
            return
        end

        -- Move to the next chunk along the X or Z axis
        xStart = xStart + chunkSize
        if xStart > 256 then -- Reset X after 256 (or adjust as needed)
            xStart = initialChunk.xStart
            zStart = zStart + chunkSize
        end
    end
end

-- Function to add a turtle
local function addTurtle(id)
    if not turtles[id] then
        turtles[id] = {
            id = id,
            idlePosition = table.remove(idlePositions) or { x = 10, y = 10, z = 10 },
            lastKnownLocation = nil,
            chunkInProgress = nil,
            state = "idle",
        }
        print("Turtle " .. id .. " registered.")
    end
end

-- Handle turtle requests
local function handleRequest(senderId, message)
    if not turtles[senderId] then
        addTurtle(senderId)
    end

    local turtle = turtles[senderId]

    if message == "requestChunkInfo" then
        if turtle.chunkInProgress then
            rednet.send(senderId, textutils.serialize(turtle.chunkInProgress))
        elseif #availableChunks > 0 then
            local chunk = table.remove(availableChunks, 1)
            turtle.chunkInProgress = chunk
            table.insert(inProgressChunks, chunk)
            turtle.state = "mining"
            rednet.send(senderId, textutils.serialize(chunk))
        else
            generateNewChunk()
            local chunk = table.remove(availableChunks, 1)
            turtle.chunkInProgress = chunk
            table.insert(inProgressChunks, chunk)
            turtle.state = "mining"
            rednet.send(senderId, textutils.serialize(chunk))
        end
    elseif message == "requestIdlePosition" then
        rednet.send(senderId, textutils.serialize(turtle.idlePosition))
    elseif message == "requestStorageLocation" then
        rednet.send(senderId, textutils.serialize(storagePosition))
    elseif message == "requestChestLocations" then
        rednet.send(senderId, textutils.serialize(chestLocations))
    elseif message == "requestRefuelPosition" then
        rednet.send(senderId, textutils.serialize(refuelPosition))
    elseif message == "chunkComplete" then
        if turtle.chunkInProgress then
            table.insert(completedChunks, turtle.chunkInProgress)
            for i, chunk in ipairs(inProgressChunks) do
                if chunk == turtle.chunkInProgress then
                    table.remove(inProgressChunks, i)
                    break
                end
            end
            turtle.chunkInProgress = nil
            turtle.state = "idle"
            print("Turtle " .. senderId .. " completed a chunk.")
        end
    elseif message == "updateLocation" then
        local location = rednet.receive(5)
        if location then
            turtle.lastKnownLocation = textutils.unserialize(location)
            print("Updated location for Turtle " .. senderId .. ": ", location)
        end
    else
        print("Unknown request from Turtle " .. senderId .. ": " .. tostring(message))
    end
end

-- Main server loop
local function startServer()
    rednet.open("left") -- Adjust modem side as needed
    print("Turtle Server is running...")

    -- Pre-generate some chunks for testing
    for _ = 1, 5 do
        generateNewChunk()
    end

    while true do
        local senderId, message = rednet.receive()
        handleRequest(senderId, message)
    end
end

startServer()
