-- last_index finds last index of substring is found
-- @param string str - source string
-- @param string substring - find substring
-- @return int pos - index number. if substring is not found, returns -1
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

-- Convert string to hex array
-- @param string buffer
-- @return table hex
local function to_hex(buffer)
  local hex = {}
  for c in buffer:gmatch('.') do
    table.insert(hex, ('0x%02x'):format(string.byte(c)))
  end
  return hex
end

-- Get file basename
-- @param string path
-- @return string
local function basename(path)
  local basename = path
  local slash = last_index(basename, '/')
  if slash > -1 then
    basename = string.sub(basename, slash + 1)
  end
  local dot = last_index(basename, '.')
  if dot > -1 then
    basename = string.sub(basename, 1, dot - 1)
  end
  return basename
end

-- Check file existence
-- @param string path
-- @return bool - true if file exists
local function file_exists(path)
  local fp = io.open(path, 'r')
  if fp then
    fp:close()
    return true
  end
  return false
end

-- Read file contents as hex table
-- @param string path
-- @return table
local function read_as_hex(path)
  local fp = io.open(path, 'r')
  local buffer = fp:read('*all')
  local ok = fp:close()
  if ok then
    return to_hex(buffer)
  end
  return {}
end

-----------------------------------------------------------
-- Main process
-----------------------------------------------------------

-- Generate C file template
local c_template = [[
#ifdef __cplusplus
extern "C" {
#endif
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#ifdef __cplusplus
}
#endif

#include <stdio.h>
#include <stdlib.h>
#include <emscripten.h>

// lua source bytes

// wasm function definitions
%s
]]

-- Geneare wasm function string
-- @param string file
local function genearte_wasm_function(file)
  local wasm_function = [[
EMSCRIPTEN_KEEPALIVE
%s %s(%s) {
  lua_State *lua = luaL_newstate();
  luaL_openlibs(lua);

  static const unsigned char lua_program[] = {%s};

  int res = luaL_dostring(lua, (const char *)lua_program);
  size_t len = 0;
  const char *value = lua_tolstring(lua, lua_gettop(lua), &len);

  lua_close(lua);
  return %svalue;
}
]]
  return string.format(
    wasm_function,
    'const char*', -- TODO: support other return types
    basename(file),
    '', -- TODO: support arguments
    table.concat(read_as_hex(file), ', '),
    ''
  )
end

-- Main function
local function main(args)

  -- Collect exist lua files
  local lua_files = {}
  for _, file in ipairs(args) do
    if file_exists(file) then
      table.insert(lua_files, file)
    end
  end

  if #lua_files == 0 then
    print("No target files.")
    os.exit(1)
  end

  -- Geneate wasm function codes
  local wasm_functions = {}
  for _, f in ipairs(lua_files) do
    table.insert(wasm_functions, genearte_wasm_function(f))
  end

  -- output C file to compile
  local source = io.open('./emlua.c', 'w')
  source:write(string.format(c_template, table.concat(wasm_functions, "\n")))
  source:close()
end

main(arg)
