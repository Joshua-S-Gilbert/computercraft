local utility = {}

local serverId = 2
local debug = true

function utility.sendMessage(message)
  rednet.send(utility.getServerId(), message)
end

function utility.log(message, force)
  if debug or force then
    print(message)
    utility.sendMessage(message)
  end
end

function utility.lock(lockFile)
  while fs.exists(lockFile) do
    sleep(0.1) -- Wait for the lock to be released
  end
  local lock = fs.open(lockFile, "w")
  if not lock then
    error("failed to make lock: " .. lockFile)
  end
  lock.close()
end

function utility.unlock(lockFile)
  lockFile = lockFile .. ".lock"
  if fs.exists(lockFile) then
    local success = pcall(fs.delete, lockFile)
    if not success then
      error("failed to delete lock: " .. lockFile)
    end
  end
end

function utility.getLock(name) return name .. ".lock" end
function utility.getServerId() return serverId end
function utility.getDebug() return debug end

function utility.readPositionFile(fileName)
  utility.lock(fileName)
  if not fs.exists(fileName) then
    utility.log("Error: missing position file: " .. fileName)
    return nil
  end
  local file = fs.open(fileName, 'r')
  local data = textutils.unserialise(file.readAll())
  file.close()
  if not data then
    utility.log("Error: corrupted position file: " .. fileName)
    return nil
  end
  utility.unlock(fileName)
  return data
end

function utility.saveFile(fileName, data)
  utility.lock(fileName)
  local file = fs.open(fileName, 'w')
  file.write(textutils.serialise(data))
  file.close()
  utility.unlock(fileName)
end

return utility