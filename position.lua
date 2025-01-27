local utility = require("utility")

local position = {}

local positionFile = "turtle_position"
local pos = { x = 0, y = 0, z = 0, direction = "north" }

-- Load the current position from file
function position.load()
  if fs.exists(positionFile) then -- assume knows location
      utility.lock(utility.getLock(positionFile))
      local file = fs.open(positionFile, "r")
      pos = textutils.unserialize(file.readAll())
      file.close()
      utility.unlock(utility.getLock(positionFile))
      return true
  else  -- assume first time finding location
      pos.x, pos.y, pos.z = gps.locate(2)
      if not pos.x then
        print("gps locate failed.")
        utility.log("gps locate failed.")
        utility.sendMessage("bot is lost")
        return false
      end
      if not position.calibrate() then
        utility.log("failed to calibrate")
        return false
      end
      position.save()
      return true
  end
end

-- Save the current position to file
function position.save()
  utility.lock(utility.getLock(positionFile))
  local file = fs.open(positionFile, "w")
  file.write(textutils.serialize(pos))
  file.close()
  utility.unlock(utility.getLock(positionFile))
end

function position.turn(turnType)
  if not position.load() then return false, pos end
  local directions = { "north", "east", "south", "west" }
  local dirIndex = 1
  for i,dir in ipairs(directions) do
    if dir == pos.direction then
      dirIndex = i
      break
    end
  end
  if turnType == "left" then
    dirIndex = ((dirIndex - 1) % 4) + 1 -- Ensure dirIndex is always 1-4
  elseif turnType == "right" then
    dirIndex = ((dirIndex - 1) % 4) + 1
  end
  pos.direction = directions[dirIndex]
  utility.log(string.format("turned to (%s), index: (%d).", pos.direction, dirIndex))
  position.save()
  return true, pos
end

function position.up()
  if not position.load() then return false, pos end
  local success = turtle.up()
  if success then
    pos.y = pos.y+1
    position.save()
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

function position.down()
  if not position.load() then return false, pos end
  local success = turtle.down()
  if success then
    pos.y = pos.y-1
    position.save()
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

function position.forward()
  if not position.load() then return false, pos end
  local success = turtle.forward()
  if success then
    if pos.direction == "north" then
      pos.z = pos.z - 1
    elseif pos.direction == "east" then
        pos.x = pos.x + 1
    elseif pos.direction == "south" then
        pos.z = pos.z + 1
    elseif pos.direction == "west" then
        pos.x = pos.x - 1
    end
    position.save()
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

function position.back()
  if not position.load() then return false, pos end
  local success = turtle.back()
  if success then
    if pos.direction == "north" then
      pos.z = pos.z + 1
    elseif pos.direction == "east" then
        pos.x = pos.x - 1
    elseif pos.direction == "south" then
        pos.z = pos.z - 1
    elseif pos.direction == "west" then
        pos.x = pos.x + 1
    end
    position.save()
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

local function getDirection(x1,z1)
  if pos.x > x1 then
    pos.direction = "east"
  elseif pos.x < x1 then
      pos.direction = "west"
  elseif pos.z > z1 then
      pos.direction = "south"
  elseif pos.z < z1 then
      pos.direction = "north"
  end
  utility.log(string.format("current direction %s.", pos.direction))
  position.save()
end

local function calibrationMove()
  local attempts = {
    { move = position.forward, revert = position.back },
    { move = position.back, revert = position.forward },
  }
  local startPos = pos
  for _, attempt in ipairs(attempts) do
    if attempt.move() then
        getDirection(startPos.x, startPos.z)
        attempt.revert()
        return true
    end
  end
  return false
end

function position.calibrate()
  if not position.load() then return false, pos end
  if calibrationMove() then
    return true, pos
  else
    position.turn("left")
    local success = calibrationMove()
    position.turn("right")
    if success then
      return true, pos
    end
  end
  utility.sendMessage(string.format("failed to calibrate, turtle stuck. location: (%d %d %d)", pos.x, pos.y, pos.z))
  utility.lock(positionFile)
  fs.delete(positionFile)
  utility.unlock(positionFile)
  return false, pos
end
