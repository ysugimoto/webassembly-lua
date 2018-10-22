import os
import sys
import yaml
from .helper import shell_exec, debug_print

class Definition():
    def __init__(self, definition_file):
        if not os.path.isfile(definition_file):
            print('{} is not exists. need to place it'.format(definition_file))
            sys.exit(1)

        self.dependencies = []
        self.functions = []
        self.entry_file = ''
        with open(definition_file, mode='r') as definition:
            data = yaml.load(definition)
            self.dependencies = data.get('dependencies', [])
            self.functions = data.get('functions', {})
            self.entry_file = data.get('entry_file', '')


    def get_entry_file(self):
        if not self.entry_file:
            return os.path.join(os.getcwd(), 'main.lua')

        return os.path.abspath(self.entry_file)


    def install_dependencies(self, local_module_dir):
        for mod in self.dependencies:
            print('Install module {} via luarocks...'.format(mod))
            # install locally
            shell_exec('luarocks', '--tree={}'.format(local_module_dir), '--deps-mode=one', 'install', mod)


    def make_function_delarations(self):
        template = '''
EMSCRIPTEN_KEEPALIVE
{} {}({}) {{
  lua_State* L = luaL_newstate();
  if (boot_lua(L)) {{
    printf("failed to boot lua runtime\\n");
    lua_close(L);
    {}
  }}
  // Push arguments
  lua_getglobal(L, "{}");
  if (!lua_isfunction(L, -1)) {{
    printf("function {} is not defined globaly in lua runtime\\n");
    {} }}
{}

  // Call lua function
  if (lua_pcall(L, {}, 1, 0)) {{
    printf("failed to call {} function\\n");
    printf("error: %s\\n", lua_tostring(L, -1));
    lua_close(L);
    {}
  }}
  // Handle return values
{}
}}
'''
        wasm_functions = []
        for name, config in self.functions.items():
            arguments = []
            push_arguments = []
            return_type = config.get('return', '')
            for i, arg in enumerate(config.get('args', [])):
                if arg == 'int':
                    arguments.append('int arg_{}'.format(i))
                    push_arguments.append('  lua_pushnumber(L, arg_{});'.format(i))
                elif arg == 'string':
                    arguments.append('const char* arg_{}'.format(i))
                    push_arguments.append('  lua_pushstring(L, arg_{});'.format(i))

            failed_return_value = ''
            capture_return_value = ''
            if return_type == 'int':
                failed_return_value = 'return 0;'
                capture_return_value = '''  if (lua_isinteger(L, -1)) {
    int return_value = lua_tointeger(L, -1);
    lua_pop(L, 1);
    lua_close(L);
    return return_value;
  }
  lua_close(L);
  return 0;'''
            elif return_type == 'string':
                failed_return_value = 'return "";'
                capture_return_value = '''  if (lua_isstring(L, -1)) {
    const char* return_value = lua_tostring(L, -1);
    lua_pop(L, 1);
    lua_close(L);
    return return_value;
  }
  lua_close(L);
  return "";'''
                return_type = 'const char* '

            function = template.format(
                    return_type,
                    name,
                    ', '.join(arguments),
                    failed_return_value,
                    name,
                    name,
                    failed_return_value,
                    '\n'.join(push_arguments),
                    len(push_arguments),
                    name,
                    failed_return_value,
                    capture_return_value)
            debug_print(function)
            wasm_functions.append(function)

        return '\n'.join(wasm_functions)


