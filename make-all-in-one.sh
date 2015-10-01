#!/bin/sh

cd -- "$(dirname "$0")" || exit 1

# see https://github.com/tst2005/lua-aio
# wget https://raw.githubusercontent.com/tst2005/lua-aio/aio.lua

export LUA_PATH="./?.lua;./?/init.lua;"\
"./src/?.lua;./src/?/init.lua;"\
"../lua-?/?.lua;../lua-?/?/init.lua;"\
"../lua-?/lua/?.lua;../lua-?/lua/?/init.lua;"\
"../lua-?/?.lua;thirdparty/git/tst2005/lua-?/?.lua;;"

if false; then
lua -e '
local aio = require "aio.init"
aio.mode("raw2")

--aio.rock.auto("rockspecs/aio-0.6.0-0.rockspec.draft", "aio")
aio.mod("aio.core",             "lib/aio/core.lua")
aio.mod("aio.mods",		"lib/aio/modlua.lua")
aio.mod("aio.modlua", 		"lib/aio/modlua.lua")
aio.mod("aio.modraw", 		"lib/aio/modraw.lua")
aio.mod("aio.modraw2", 		"lib/aio/modraw2.lua")
aio.mod("aio.rock",		"lib/aio/rock.lua")
aio.mod("aio.integrity",	"lib/aio/integrity.lua")
aio.finish()

aio.mod("compat_env",		"compat_env.lua")
aio.finish()

aio.code(			"lib/aio/init.lua")
aio.finish()
' > aio-wdeps/aio.lua
fi

#LUA_PATH="$LUA_PATH"
luajit -e '
local aio = require "aio.init"
aio.mode("raw2")
aio.rock.auto("rockspecs/aio-0.6.0-0.rockspec.draft", "aio")
' > aio.lua

