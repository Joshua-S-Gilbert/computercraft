local navigation = require("navigation")
local utility = require("utility")

local refuel = {}

-- Configurable settings
local safetyBufferPercent = 10 -- Safety buffer as a percentage
local refuelInterruptFile = "refuel_interrupt" -- File signaling the need to refuel
local positionFile = "turtle_position"
local jobStartPos = "job_start_pos"
local jobPausePos = "job_pause_pos"
local pos = { x = 0, y = 0, z = 0, direction = "north" }
local validFuels = {"minecraft:coal", "minecraft:charcoal"}

-- Function to calculate Manhattan distance between two points
local function calculateDistance(x1, y1, z1, x2, y2, z2)
    return math.abs(x1 - x2) + math.abs(y1 - y2) + math.abs(z1 - z2)
end

-- Function to create the refuel interrupt file
local function createRefuelInterrupt()
    local file = fs.open(refuelInterruptFile, "w")
    file.write("Refuel required")
    file.close()
end

-- Function to delete the refuel interrupt file
local function clearRefuelInterrupt()
    if fs.exists(refuelInterruptFile) then
        fs.delete(refuelInterruptFile)
    end
end

local function contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- consumes all charcoal or coal for fuel
local function refuelTurtle()
    local refuelled = false
    for slot = 1,16 do
        local item = turtle.getItemDetail(slot)
        if item and contains(validFuels, item.name) then
            turtle.refuel()
            refuelled = true
        end
    end
    return refuelled
end

function refuel.checkRefuel()
    -- get current position
    pos = utility.readPositionFile(positionFile)
    if not pos then
        utility.log("failed to load current position in refuel.checkRefuel()")
        return false
    end

    -- save current job progress location
    local jobPause = pos

    -- get refuel position
    utility.sendMessage("requestRefuelPosition")
    local senderId, message = rednet.receive(5)
    if not senderId or not message then
        utility.log("failed to get refuel position")
        return false
    end
    local refuelPosition = textutils.unserialise(message)

    
    -- get job starting location
    local jobStart = utility.readPositionFile(jobStartPos)
    if not jobStart then
        utility.log("failed to load job start position in refuel.checkRefuel()")
        return false
    end

    -- find distances
    local distanceToJobStart = calculateDistance(pos.x, pos.y, pos.z, jobStart.x, jobStart.y, jobStart.z)
    local distanceToRefuel = calculateDistance(jobStart.x, jobStart.y, jobStart.z, refuelPosition.x, refuelPosition.y, refuelPosition.z)
    local totalDistance = distanceToJobStart + distanceToRefuel

    local currentFuel = turtle.getFuelLevel()
    local safetyBuffer = math.floor((currentFuel * safetyBufferPercent) / 100)
    local refuelThreshold = (totalDistance * 2) + safetyBuffer

    if currentFuel < refuelThreshold then
        utility.log("low fuel: " .. currentFuel .. "distance to refuel: " .. totalDistance)
        createRefuelInterrupt()
        navigation.navigateTo(jobStart.x, jobStart.y, jobStart.z, false)
        navigation.navigateTo(refuelPosition.x, refuelPosition.y, refuelPosition.z, true)
        if refuelTurtle() then utility.log("successfully refueled turtle")
        else utility.log("failed to refuel turtle") end
        navigation.navigateTo(jobStart.x, jobStart.y, jobStart.z, false)
        navigation.navigateTo(jobPause.x, jobPause.y, jobPause.z, true)
        clearRefuelInterrupt()
    else
        clearRefuelInterrupt()
        -- utility.log("fuel is sufficient: " .. currentFuel .. "fuel remaining. safetyBuffer: " .. safetyBuffer)
    end
end

return refuel
