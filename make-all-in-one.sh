#!/bin/sh

cd -- "$(dirname "$0")" || exit 1

# see https://github.com/tst2005/lua-aio
# wget https://raw.githubusercontent.com/tst2005/lua-aio/aio.lua

export LUA_PATH="./?.lua;./?/init.lua;"\
"../lua-?/?.lua;../lua-?/?/init.lua;"\
"../lua-?/lua/?.lua;../lua-?/lua/?/init.lua;"\
"../lua-?/?.lua;thirdparty/git/tst2005/lua-?/?.lua;;"


lua -e '
local aio = require "aio.init"
aio.mode("raw2")

--aio.rock.auto("rockspecs/aio-0.6.0-0.rockspec.draft", "aio")
aio.mod("aio.core",             "aio/core.lua")
aio.mod("aio.mods",		"aio/modlua.lua")
aio.mod("aio.modlua", 		"aio/modlua.lua")
aio.mod("aio.modraw", 		"aio/modraw.lua")
aio.mod("aio.modraw2", 		"aio/modraw2.lua")
aio.mod("aio.rock",		"aio/rock.lua")
aio.mod("aio.integrity",	"aio/integrity.lua")
aio.finish()

aio.mod("compat_env",		"compat_env.lua")
aio.finish()

aio.code(				"aio/init.lua")
aio.finish()
' > aio-wdeps/aio.lua

lua -e '
local aio = require "aio.init"
aio.mode("raw2")

aio.rock.auto("rockspecs/aio-0.6.0-0.rockspec.draft", "aio")
' > aio.lua

