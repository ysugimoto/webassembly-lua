# Markdown editor example using wasm lua

This is example of markdown editor.

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


