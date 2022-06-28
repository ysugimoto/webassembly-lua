# webassembly-lua

Write and compile as WebAssembly program by lua script.

**Note: this project is still under development. We have to do more improvement**

## Requirements

- [emscripten](https://github.com/kripken/emscripten)
- [lua](https://www.lua.org/) (prefer to use latest version)
- Python 3.6.5+

To avoid to polute your environment, we *strongly* prefer to use prebuilt docker image on [docker hub](https://hub.docker.com/r/ysugimoto/webassembly-lua/).

## How to use

### Write lua script

Here is example `Hello World` script:

```lua
function hello_world()
  return 'Hello, WebAssembly Lua!'
end
```

Make sure the function declares as *global* in order to access from C program.
And, also you can specify some function arguments like:

```lua
function hello_something(something):
  return ('Hello, %s!'):format(something)
end
```

Then, you need to remember what `type` of argument should be supplied and what `type` of value will return (supports `string` or `int` for now).

### Write definitions in `definition.yml`

The `definition.yml` is configuration for generate / compile WebAssembly binary. See following:

```yaml
dependencies:
  - luaposix

functions:
  hello_something:
    return : string
    args:
      - string

entry_file: hello_world.lua
output_file: hello_world.html
```

Describes each fields:

| Field                  | Type    | Default  | description                                                                    |
|:-----------------------|:-------:|:--------:|:-------------------------------------------------------------------------------|
| dependencies           | array   | -        | program dependencies. the list of modules will be installed via `luarocks`.    |
| functions              | object  | -        | Function definitions. The key is function name which will be exported on WASM. |
| functions[name].return | string  | -        | Define function return type.                                                   |
| functions[name].args   | array   | -        | Defined function argument type list.                                           |
| entry_file             | strring | main.lua | the file name of program entry.                                                |
| output_file            | strring | -        | the file name of output files.                                                 |

### Compile as WebAssembly program

On docker image, the image has `emcc-lua` command:

```shell
$ docker pull ysugimoto/webassembly-lua
$ docker run --rm -v $PWD:/src ysugimoto/webassembly-lua emcc-lua
```

The `emcc-lua` finds `definition.yml` in current working directory (in this case, `$PWD`) and start to build.
After built successfully, you can see a `hello_world.[html,js,wasm]` in your directory. The output file is named by `entry_file` in definition.yml.

### Run WebAssembly program

Open created or write HTML to run compiled WebAssembly program like:

```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>WebAssembly Lua</title>
  </head>
  <body>
    <script src="./hello_world.js"></script>
    <script>
    Module.onRuntimeInitialized = () => {
      // call your function through the Module.cwrap()
      const helloSomething = Module.cwrap('hello_something', 'string', ['string']);
      console.log(helloSomething('WebAssembly Lua'));
    };
    </script>
  </body>
</html>
```

And run local server in your favorite way (e.g python -m http.server) and access to `http://localhost:8000/hello_world.html` (port may need), then you can see `Hello, WebAssembly Lua!` message in your browser console.

## Features

- [x] Compile single lua script to WebAssembly binary
- [x] Support for return type of string and int
- [x] Support to call function with any arguments
- [x] Enable to bundle some libraries (e.g. hosted on luarocks, or Independent C libraries)

## TODOs

- [x] Support to require other lua modules which you defined as other file, installed via luarocks
- [x] Support to apply function arguments as detected types
- [x] Works with more complicated script. Now we can work on simple script.
- [ ] Support some structured return type which can use in JavaScript (Array, Object -- especially JSON --)
- [ ] Try to compile various libraries (Now we tried to bundle `luaposix`, it's fine to work)

## Author

Yoshiaki Sugimoto

## License


MIT
