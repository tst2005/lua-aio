#!/bin/sh

cd -- "$(dirname "$0")" || exit 1

# see https://github.com/tst2005/lua-aio
# wget https://raw.githubusercontent.com/tst2005/lua-aio/aio.lua

#export LUA_PATH="./?.lua;./?/init.lua;"\
#"./src/?.lua;./src/?/init.lua;"\
#"../lua-?/?.lua;../lua-?/?/init.lua;"\
#"../lua-?/lua/?.lua;../lua-?/lua/?/init.lua;"\
#"../lua-?/?.lua;thirdparty/git/tst2005/lua-?/?.lua;;"

LUA_PATH="./?.lua;./?/init.lua;./src/?.lua;./src/?/init.lua;./lua-?/generated-bundle/?.lua;;"

[ -d generated-bundle ] || mkdir generated-bundle

LUA_PATH="$LUA_PATH" \
	${LUA:-luajit} -e '
local aio = require "aio"
--aio.mode("raw2")
aio.rock.auto("rockspecs/aio-0.6.3-0.rockspec.draft", "aio")
' > generated-bundle/tmp_aio.lua && mv -f generated-bundle/tmp_aio.lua generated-bundle/aio.lua

[ -d generated-bundle/aio ] || mkdir generated-bundle/aio
echo 'return {_BUNDLE=true,_BUNDLE_FORMAT="v0.1.0.alpha1",_BUNDLEFOR="aio"}' > generated-bundle/aio/__bundle.lua
