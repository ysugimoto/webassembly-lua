# webassembly-lua

Write and compile as WebAssembly program by lua script.

**Note: this project is still under development. We have to do more improvement**

## Requirements

- [emscripten](https://github.com/kripken/emscripten)
- [lua](https://www.lua.org/) (prefer to use latest version)

To avoid to polute your environment, we prefer to use prebuilt docker image on [docker image](https://hub.docker.com/r/ysugimoto/webassembly-lua/).

## How to use

### Write lua script

Here is example `Hello World` script:

```lua
local function hello_world()
  return 'Hello, WebAssembly Lua!'
end

return hello_world()
```

`webassembly-lua` will export function name as script filename.
For example, if you wrote script as `hello_world.lua`, will be compiled and exported function as `hello_world`.

__You need to return some string value in each script for now.__


### Compile as WebAssembly program

On docker image, the image has `emcc-lua` command:

```shell
$ docker pull ysugimoto/webassembly-lua
$ docker run --rm -v $PWD:/src webassembly-lua emcc-lua hello_world.lua
```

The docker image will create `wasm.js` and `wasm.wasm` file which is compiled by `emscripten`.

### Run WebAssembly program

Write HTML to run compiled WebAssembly program like:

```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>WebAssembly Lua</title>
  </head>
  <body>
    <script src="./wasm.js"></script>
    <script>
    Module.onRuntimeInitialized = () => {
      // call your function through the Module.cwrap()
      const helloWorld = Module.cwrap('hello_world', 'string');
      console.log(helloWorld());
    };
    </script>
  </body>
</html>
```

And run local server in your favorite way (e.g python -m http.server) and access to `http://localhost:8000/wasm.html` (port may need), then you can see `Hello, WebAssembly Lua!` message in your browser console.

### Multiple functions

`emcc-lua` command accepts variable-length filenames to compile:

```
$ docker run --rm -v $PWD:/src webassembly-lua emcc-lua hello_world01.lua hello_world02.lua hello_world03.lua ...
```

Then comipled binary will have functions named `hello_world01`, `hello_world02`, and `hello_world03`.

## Features

- [x] Compile single lua script to WebAssembly binary
- [x] Only support for return type of string
- [x] Only support to call function without any arguments

## TODOs

- [ ] Support other return type which can use in JavaScript (Number, Object -- especially JSON --)
- [ ] Support to require other lua modules which you defined as other file, installed via luarocks
- [ ] Support to apply function arguments as detected types
- [ ] Works with more complicated script. Now we can work on simple script.

## Author

Yoshiaki Sugimoto

## License


MIT
