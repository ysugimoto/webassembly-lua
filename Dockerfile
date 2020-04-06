FROM trzeci/emscripten:sdk-tag-1.38.30-64bit
LABEL maintainer "yoshiaki sugimoto <sugimoto@wnotes.net>"

ENV LUA_VERSION 5.3.4
ENV LUAROCKS_VERSION 2.4.4
ENV PYTHON_VERSION 3.6.6

RUN apt-get update -qq -y \
    && apt-get install -y curl vim make gcc libreadline6-dev libssl-dev zlib1g-dev zip unzip \
    # Install python
    && cd /tmp \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xfz Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && make -j8 \
    && make altinstall \
    && alias python='/usr/local/bin/python3.6' \
    && pip3.6 install pyyaml \
    # Install lua
    && cd / \
    && curl -L http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz | tar xzf - \
    && cd lua-${LUA_VERSION} \
    && make linux test \
    && make install \
    # Install luarocks
    && cd /tmp \
    && curl -L https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz | tar xzf - \
    && cd luarocks-${LUAROCKS_VERSION} \
    && ./configure \
    && make build \
    && make install \
    # And, re-compile lua with "generic WASM"
    && cd /lua-${LUA_VERSION} \
    && make clean \
    && make generic CC='emcc -s WASM=1' \
    && rm -rf /tmp/Python-${PYTHON_VERSION} \
    && rm -rf /tmp/luarocks-${LUAROCKS_VERSION}

# Install commands
COPY ./src/emcc-lua /usr/local/bin/emcc-lua
COPY ./src/emcc_lua_lib /opt/emcc_lua_lib
COPY ./src/main.c /opt/main.c
COPY ./src/main.lua /opt/main.lua
RUN chmod +x /usr/local/bin/emcc-lua

ENV CC 'emcc -s WASM=1'
ENV NM 'llvm-nm'
