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
aio.mod("aio.config",		"src/aio/config.lua")
aio.mod("aio.core",             "src/aio/core.lua")
aio.mod("aio.mods",		"src/aio/modlua.lua")
aio.mod("aio.modlua", 		"src/aio/modlua.lua")
aio.mod("aio.modraw", 		"src/aio/modraw.lua")
aio.mod("aio.modraw2", 		"src/aio/modraw2.lua")
aio.mod("aio.rock",		"src/aio/rock.lua")
aio.mod("aio.integrity",	"src/aio/integrity.lua")
aio.finish()

aio.mod("compat_env",		"compat_env.lua")
aio.finish()

aio.code(			"src/aio/init.lua")
aio.finish()
' > aio-wdeps/aio.lua
fi

luajit -e '
local aio = require "aio.init"
--aio.use("aioruntime", false) -- NOT IMPLEMENTED YET
aio.mode("raw2")

local f = function()
	aio.mod("bootstrap.fallback",	"fallback.lua")
	--aio.mod("bootstrap.compat_env",	"compat_env.lua")
	aio.finish()

	aio.luacode[[
local fallback = require "bootstrap.fallback"
local _require = fallback.require -- or directly fallback
local _preload = fallback.package.preload
]]
	aio.finish()
	aio.inpreload("_preload")
	aio.rock.file("rockspecs/aio-0.6.2-0.rockspec.draft")
	aio.rock.mod("build.modules")
	aio.finish()
end

--aio.rock.auto("rockspecs/aio-0.6.2-0.rockspec.draft", "aio")
f()

aio.inpreload(nil) -- restore default
aio.finish()

aio.code("src/aio/shadowinit.lua")
aio.finish()

' > aio.lua

