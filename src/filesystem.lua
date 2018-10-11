local file = {}

local function last_index(str, substring)
  local pos = string.find(str, substring, 1, true)
  if not pos then
    return -1
  end

  while true do
    new_pos = string.find(str, substring, pos + 1, true)
    if not new_pos then
      break
    end
    pos = new_pos
  end

  return pos
end

local function to_hex(buffer)
  local hex = {}
  for c in buffer:gmatch('.') do
    table.insert(hex, ('0x%02x'):format(string.byte(c)))
  end
  return hex
end

file.new = function(filename)
  local instance = { path = filename }

  local basename = filename
  local slash = last_index(basename, '/')
  if slash > -1 then
    basename = string.sub(basename, slash + 1)
  end
  local dot = last_index(basename, '.')
  if dot > -1 then
    basename = string.sub(basename, 1, dot - 1)
  end

  instance.basename = basename

  instance.exists = function(self)
    local fp = io.open(instance.path, 'r')
    if fp then
      fp:close()
      return true
    end
    return false
  end

  instance.readHex = function(self)
    local fp = io.open(instance.path, 'r')
    local buffer = fp:read('*all')
    local ok = fp:close()
    if ok then
      return to_hex(buffer)
    end
    return {}
  end

  return instance
end

return file
