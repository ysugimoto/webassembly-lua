import os
import sys
import yaml
from .helper import shell_exec, debug_print

class Definition():
    dependencies = []
    functions = []
    entry_file = ''
    output_file = ''

    def __init__(self, definition_file):
        if not os.path.isfile(definition_file):
            print('{} is not exists. need to place it'.format(definition_file))
            sys.exit(1)

        with open(definition_file, mode='r') as definition:
            data = yaml.load(definition)
            self.dependencies = data.get('dependencies', [])
            self.functions = data.get('functions', [])
            self.entry_file = data.get('entry_file', '')
            self.output_file = data.get('output_file', '')

    def get_entry_file(self):
        if not self.entry_file:
            return os.path.join(os.getcwd(), 'main.lua')

        return os.path.abspath(self.entry_file)

    def get_output_file(self):
        if self.output_file:
            return self.output_file

        return '{}.html'.format(os.path.splitext(os.path.basename(self.entry_file))[0])


    def install_dependencies(self, local_module_dir):
        for mod in self.dependencies:
            print('Install module {} via luarocks...'.format(mod))
            # install locally
            shell_exec('luarocks', '--tree={}'.format(local_module_dir), '--deps-mode=one', 'install', mod)


    def make_function_delarations(self):
        template = '''
EMSCRIPTEN_KEEPALIVE
{} {}({}) {{
  if (wasm_lua_state == NULL) {{
    wasm_lua_state = luaL_newstate();
    boot_lua(wasm_lua_state);
  }}
  // Push arguments
  lua_getglobal(wasm_lua_state, "{}");
  if (!lua_isfunction(wasm_lua_state, -1)) {{
    printf("function {} is not defined globaly in lua runtime\\n");
    lua_settop(wasm_lua_state, 0);
    {}
  }}
{}

  // Call lua function
  if (lua_pcall(wasm_lua_state, {}, 1, 0)) {{
    printf("failed to call {} function\\n");
    printf("error: %s\\n", lua_tostring(wasm_lua_state, -1));
    lua_settop(wasm_lua_state, 0);
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
                    push_arguments.append('  lua_pushnumber(wasm_lua_state, arg_{});'.format(i))
                elif arg == 'string':
                    arguments.append('const char* arg_{}'.format(i))
                    push_arguments.append('  lua_pushstring(wasm_lua_state, arg_{});'.format(i))

            failed_return_value = ''
            capture_return_value = ''
            if return_type == 'int':
                failed_return_value = 'return 0;'
                capture_return_value = '''  if (lua_isinteger(wasm_lua_state, -1)) {
    int return_value = lua_tointeger(wasm_lua_state, -1);
    lua_settop(wasm_lua_state, 0);
    return return_value;
  }
  return 0;'''
            elif return_type == 'string':
                failed_return_value = 'return "";'
                capture_return_value = '''  if (lua_isstring(wasm_lua_state, -1)) {
    const char* return_value = lua_tostring(wasm_lua_state, -1);
    lua_settop(wasm_lua_state, 0);
    return return_value;
  }
  lua_close(wasm_lua_state);
  return "";'''
                return_type = 'const char* '

            function = template.format(
                    return_type,
                    name,
                    ', '.join(arguments),
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


