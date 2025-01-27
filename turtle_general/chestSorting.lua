local navigation = require("navigation")

local chestSorting = {}

local serverId = 2

local function serverRequest(tx)
  rednet.send(serverId, tx)
  local senderId, message = rednet.receive(5)
  if senderId == serverId and message then
    return textutils.unserialise(message)
  else
    print("failed to get " .. tx)
    return nil
  end
end

local function dumpItems(slot, direction)
  turtle.select(slot)
  local dropped = false
  if direction == "left" then
    turtle.turnLeft()
    dropped = turtle.drop()
    turtle.turnRight()
  elseif direction == "right" then
    turtle.turnRight()
    dropped = turtle.drop()
    turtle.turnLeft()
  end
  if not dropped then
    turtle.dropDown()
  end
end

function chestSorting.sortItems()
  local chestLocations = serverRequest("requestChestLocations")
  if not chestLocations then
    print("failed to get chest locations")
    return
  end
  
  local idlePosition = serverRequest("requestIdlePosition")
  if not idlePosition then
    print("failed to get idle position")
    return
  end
  local idlex, idley, idlez = idlePosition.x, idlePosition.y, idlePosition.z

  local startLocations = serverRequest("requestStorageLocation")
  if not startLocations then
    print("failed to get start locations")
    return
  end
  local startx, starty, startz, passageAxis = startLocations.x, startLocations.y, startLocations.z1, startLocations.passageAxis

  for slot = 1,16 do
    local item = turtle.getItemDetail(slot)
    if item then
      local itemName = item.name
      local chest = chestLocations[itemName]
      if chest then
        if passageAxis == 'x' then
          navigation.navigateTo(chest.x, starty, startz)
          local direction = (chestz<startz) and "left" or "right"
          dumpItems(slot, direction)
        elseif passageAxis == 'z' then
          navigation.navigateTo(startx, starty, chest.z)
          local direction = (chest.x < startx) and "left" or "right"
          dumpItems(slot, direction)
        end
      else
        turtle.select(slot)
        turtle.dropDown()
      end
    end
  end

  navigation.navigateTo(startx, starty, startz)
end

return chestSorting