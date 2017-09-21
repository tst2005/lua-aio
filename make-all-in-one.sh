#!/bin/sh

cd -- "$(dirname "$0")" || exit 1

# see https://github.com/tst2005/lua-aio
# wget https://raw.githubusercontent.com/tst2005/lua-aio/aio.lua

export LUA_PATH="./?.lua;./?/init.lua;"\
"./src/?.lua;./src/?/init.lua;"\
"../lua-?/?.lua;../lua-?/?/init.lua;"\
"../lua-?/lua/?.lua;../lua-?/lua/?/init.lua;"\
"../lua-?/?.lua;thirdparty/git/tst2005/lua-?/?.lua;;"

[ -d generated-bundle ] || mkdir generated-bundle

luajit -e '
local aio = require "aio.init"
aio.mode("raw2")
aio.rock.auto("rockspecs/aio-0.6.3-0.rockspec.draft", "aio")
' > generated-bundle/aio.lua
