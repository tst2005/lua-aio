#!/bin/sh

cd -- "$(dirname "$0")" || exit 1

# see https://github.com/tst2005/lua-aio
# wget https://raw.githubusercontent.com/tst2005/lua-aio/aio.lua #FIXME

luajit -e '
local aio = require "aio-bootstrap"
--aio.mode("raw2")
aio.mod("mini.compat-env",	"mini/compat-env.lua")
aio.mod("mini.class", 		"mini/class.lua")
aio.finish()

aio.code(			"aio-bootstrap.lua")
aio.finish()
'  > aio-full.lua

