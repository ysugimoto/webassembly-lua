FROM trzeci/emscripten
LABEL maintainer "yoshiaki sugimoto <sugimoto@wnotes.net>"

RUN apt-get update -qq -y
RUN apt-get install -y curl vim make gcc libreadline6-dev libssl-dev zlib1g-dev zip unzip

ENV LUA_VERSION 5.3.4
ENV LUAROCKS_VERSION 2.4.4
ENV PYTHON_VERSION 3.6.6

# Install python3.6
RUN cd /tmp && \
  wget https://www.python.org/ftp/python/3.6.6/Python-${PYTHON_VERSION}.tgz && \
  tar xfz Python-${PYTHON_VERSION}.tgz && \
  cd Python-${PYTHON_VERSION} && \
  ./configure --enable-optimizations && \
  make -j8 && \
  make altinstall

RUN alias python='/usr/local/bin/python3.6'

# Intall yaml
RUN pip3.6 install pyyaml

# Install lua runtime
RUN cd / && \
  curl -L http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz | tar xzf - && \
  cd /lua-${LUA_VERSION} && \
  make linux test && \
  make install

# Install luarocks
RUN cd / && \
  curl -L https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz | tar xzf - && \
  cd /luarocks-${LUAROCKS_VERSION} && \
  ./configure && \
  make build && \
  make install

# And, re-compile lua with "generic WASM"
RUN cd /lua-${LUA_VERSION} && \
  make clean && \
  make generic CC='emcc -s WASM=1'

# Install commands
COPY ./src/emcc-lua /usr/local/bin/emcc-lua
COPY ./src/emcc_lua_lib /opt/emcc_lua_lib
COPY ./src/main.c /opt/main.c
COPY ./src/main.lua /opt/main.lua
RUN chmod +x /usr/local/bin/emcc-lua

ENV CC 'emcc -s WASM=1'
ENV NM 'llvm-nm'
