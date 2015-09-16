#!/usr/bin/env lua
_=[[
        for name in luajit lua5.3 lua-5.3 lua5.2 lua-5.2 lua5.1 lua-5.1 lua; do
                : ${LUA:="$(command -v "$name")"}
        done
        if [ -z "$LUA" ]; then
                echo >&2 "ERROR: lua interpretor not found"
                exit 1
        fi
        LUA_PATH='./?.lua;./?/init.lua;./lib/?.lua;./lib/?/init.lua;;'
        exec "$LUA" "$0" "$@"
        exit $?
]] and nil
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------


local _M = {}
_M._NAME = "lua-aio"
_M._VERSION = "lua-aio 0.6"
_M._LICENSE = "MIT"

local aio = require("aio.core")

_M.shebang	= aio.shebang
_M.luamod	= aio.luamod
_M.rawmod	= aio.rawmod
_M.mod		= aio.mod
_M.code		= aio.code
_M.codehead	= aio.codehead -- obsolete
_M.shellcode	= aio.shellcode
_M.mode		= aio.mode
_M.vfile	= aio.vfile
_M.autoaliases	= aio.autoaliases
_M.icheck	= aio.icheck
_M.ichechinit	= aio.icheckinit
_M.require	= aio.require
_M.luacode	= aio.luacode
_M.finish	= aio.finish

local function wrap(f)
	return function(...)
		f(...)
		return _M
	end
end

for k,v in pairs(_M) do
	if type(v) == "function" then
		_M[k] = wrap(v)
	end
end

local rock = require "aio.rock"

--[[
for k,v in pairs(rock) do
	if type(v) == "function" then
		rock[k] = wrap(v)
	end
end
]]--

_M.rock = rock

return _M
