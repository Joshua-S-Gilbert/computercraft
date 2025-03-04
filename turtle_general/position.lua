local utility = require("utility")

local position = {}

local positionFile = "turtle_position"
local pos = { x = 0, y = 0, z = 0, direction = "north" }

function position.getGPSPosition()
  local x, y, z = gps.locate(2)
  if not x then
      utility.log("Failed to retrieve GPS position.")
      return nil -- Return nil if GPS fails
  end
  return { x = x, y = y, z = z }
end

-- Load the current position from file
-- this has different functionality than utility.readPositionFile(). do not remove it
local function load()
  if fs.exists(positionFile) then -- assume knows location
      utility.lock(utility.getLock(positionFile))
      local file = fs.open(positionFile, "r")
      pos = textutils.unserialize(file.readAll())
      file.close()
      utility.unlock(utility.getLock(positionFile))
      return true
  else  -- assume first time finding location
    local gpsPos = position.getGPSPosition()
    if not gpsPos then
        utility.log("GPS locate failed in load().")
        utility.sendMessage("bot is lost")
        return false
    end
    pos.x, pos.y, pos.z = gpsPos.x, gpsPos.y, gpsPos.z
    pos.direction = "north"
    utility.saveFile(positionFile)
    return true
  end
end

-- turns turtle while tracking position data. accepts "left" and "right"
function position.turn(turnType)
  if not load() then return false, pos end
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
  utility.saveFile(positionFile)
  return true, pos
end

-- moves turtle up while tracking position data
function position.up()
  if not load() then return false, pos end
  local success = turtle.up()
  if success then
    pos.y = pos.y+1
    utility.saveFile(positionFile)
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

-- moves turtle down while tracking position data
function position.down()
  if not load() then return false, pos end
  local success = turtle.down()
  if success then
    pos.y = pos.y-1
    utility.saveFile(positionFile)
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

-- moves turtle forward while tracking position data
function position.forward()
  if not load() then return false, pos end
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
    utility.saveFile(positionFile)
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

-- moves turtle back while tracking position data
function position.back()
  if not load() then return false, pos end
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
    utility.saveFile(positionFile)
    utility.log(string.format("Moved to (%d, %d, %d).", pos.x, pos.y, pos.z))
  end
  return success, pos
end

-- support function for calibration
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
  utility.saveFile(positionFile)
end

-- support function for calibration
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

-- calibrates the current position and direction the turtle is facing
function position.calibrate()
  local gpsPos = position.getGPSPosition()
  if not gpsPos then
    return false, pos
  end
  pos.x,pos.y,pos.z = gpsPos.z, gpsPos.y,gpsPos.z
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

return position