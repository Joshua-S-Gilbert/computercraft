local navigation = {}
local position = require("position")
local utility = require("utility")

-- Default blacklist: blocks that should not be broken
local defaultBlacklist = {
    ["minecraft:chest"] = true,
    ["minecraft:ender_chest"] = true,
    ["minecraft:shulker_box"] = true,
    ["minecraft:barrel"] = true,
    ["minecraft:beacon"] = true,
}

-- Function to navigate to a target position
-- @param targetPos Table {x, y, z, direction} The target position to navigate to.
-- @param traversalOrder Array {"x", "y", "z"} The order in which to traverse axes.
-- @param breakBlocks Boolean Whether to break blocks in the way.
-- @param blacklist Table List of block names that cannot be broken. Uses defaultBlacklist if nil.
function navigation.navigateTo(targetPos, traversalOrder, breakBlocks, blacklist)
    local currentPos = utility.readPositionFile("turtle_position")
    if not currentPos then
        utility.log("navigation couldnt determine current position")
        return false
    end

    -- Use the default blacklist if none is provided
    blacklist = blacklist or defaultBlacklist

    local function turnTo(targetDirection)
        local directions = { "north", "east", "south", "west" }
        local currentIndex, targetIndex
    
        for i, dir in ipairs(directions) do
            if dir == currentPos.direction then currentIndex = i end
            if dir == targetDirection then targetIndex = i end
        end
    
        local turns = (targetIndex - currentIndex + 4) % 4 -- Normalize to avoid negative numbers
        for _ = 1, turns do
            _, currentPos = position.turn("right")
        end
    end

    -- Helper to move in a given direction (handles block breaking if enabled)
    local function move(axis, targetValue)
        while currentPos[axis] ~= targetValue do
            -- Determine which direction to turn and face
            if axis == "x" then
                if currentPos.x < targetValue then
                    turnTo("east")
                elseif currentPos.x > targetValue then
                    turnTo("west")
                end
            elseif axis == "z" then
                if currentPos.z < targetValue then
                    turnTo("south")
                elseif currentPos.z > targetValue then
                    turnTo("north")
                end
            end

            -- Handle movement
            if breakBlocks then
                if turtle.detect() then
                    local success, data = turtle.inspect()
                    if success and blacklist[data.name] then
                        utility.log("Blocked by non-breakable object: " .. (data.name or "unknown"))
                        return false
                    end
                    turtle.dig() -- Break block if not blacklisted
                end
            elseif turtle.detect() then
                utility.log("Obstacle encountered at (" .. currentPos.x .. ", " .. currentPos.y .. ", " .. currentPos.z .. ", " .. currentPos.direction .. ")")
                return false
            end

            -- Move forward
            local moveSuccess, updatedPos = position.forward()
            if not moveSuccess then
                utility.log("Failed to move forward at (" .. currentPos.x .. ", " .. currentPos.y .. ", " .. currentPos.z .. ", " .. currentPos.direction .. ")")
                return false
            end
            currentPos = updatedPos
        end
        return true
    end

    -- Traverse according to the specified order
    for _, axis in ipairs(traversalOrder) do
        if not move(axis, targetPos[axis]) then
            return false -- Stop navigation on failure
        end
    end

    -- Orient to the final direction
    if targetPos.direction then
        while currentPos.direction ~= targetPos.direction do
            _, currentPos = position.turn("right")
        end
    end

    utility.log("Navigation to (" .. targetPos.x .. ", " .. targetPos.y .. ", " .. targetPos.z .. ") complete.")
    return true
end

return navigation
