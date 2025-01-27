local navigation = {}
local position = require("position") -- Include the position module

-- Function to navigate to a target position
function navigation.navigateTo(targetX, targetY, targetZ, yFirst)
    local pos = position.load()
    local x, y, z = pos.x, pos.y, pos.z

    print("Navigating to target:", targetX, targetY, targetZ)
    print("Current position:", x, y, z)

    if yFirst then
        -- Adjust Y first
        while y ~= targetY do
            if y < targetY then
                turtle.digUp()
                position.up()
                y = y + 1
            else
                turtle.digDown()
                position.down()
                y = y - 1
            end
        end
    end

    -- Move along X-axis
    if x < targetX then
        while pos.direction ~= "east" do
            position.turn("right")
            pos = position.load()
        end
    elseif x > targetX then
        while pos.direction ~= "west" do
            position.turn("right")
            pos = position.load()
        end
    end
    while x ~= targetX do
        turtle.dig()
        position.forward()
        pos = position.load()
        x = pos.x
    end

    -- Move along Z-axis
    if z < targetZ then
        while pos.direction ~= "south" do
            position.turn("right")
            pos = position.load()
        end
    elseif z > targetZ then
        while pos.direction ~= "north" do
            position.turn("right")
            pos = position.load()
        end
    end
    while z ~= targetZ do
        turtle.dig()
        position.forward()
        pos = position.load()
        z = pos.z
    end

    if not yFirst then
        -- Adjust Y last
        while y ~= targetY do
            if y < targetY then
                turtle.digUp()
                position.up()
                y = y + 1
            else
                turtle.digDown()
                position.down()
                y = y - 1
            end
        end
    end

    print("Arrived at target position:", targetX, targetY, targetZ)
end

return navigation
