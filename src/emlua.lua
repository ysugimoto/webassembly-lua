package.path = package.path .. ';/opt/emlua/?.lua'

local fs = require('filesystem')

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
    'const char*',
    file.basename,
    '',
    table.concat(file:readHex(), ', '),
    ''
  )
end

local lua_files = {}
for _, name in ipairs(arg) do
  local file = fs.new(name)
  if file:exists() then
    table.insert(lua_files, file)
  end
end

if #lua_files == 0 then
  print("No target files.")
  os.exist(1)
end

local wasm_functions = {}
for _, f in ipairs(lua_files) do
  table.insert(wasm_functions, genearte_wasm_function(f))
end

-- output C file to compile
local source = io.open('./emlua.c', 'w')
source:write(string.format(c_template, table.concat(wasm_functions, "\n")))
source:close()






