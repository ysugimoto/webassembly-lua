# Hello World

This is minimum example for display "Hello World in your browser console.

## Build

Build wasm binary with docker image:

```
$ docker run --rm -v $PWD:/src ysugimoto/wabassembly-lua emcc-lua
```

And, start local server (eg python):

```
python -m http.server
```

Access in your browser:

```
http://localhost:8000
```


