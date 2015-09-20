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

local mode = "raw2" -- the default mode

local _M = {}
_M._NAME = "lua-aio"
_M._VERSION = "lua-aio 0.6"
_M._LICENSE = "MIT"

local core = require("aio.core")
_M.shebang	= core.shebang
_M.code		= core.code
_M.codehead	= core.codehead -- obsolete
_M.shellcode	= core.shellcode

_M.vfile	= core.vfile
_M.autoaliases	= core.autoaliases
_M.require	= core.require
_M.luacode	= core.luacode

local mods = {}
mods.lua = require "aio.modlua"
mods.raw = require "aio.modraw"
mods.raw2 = require "aio.modraw2"


local function cmd_mode(newmode)
	local modes = {lua=true, raw=true, raw2=true}
	if modes[newmode] then
		mode = newmode
	else
		error("invalid mode", 2)
	end
end
_M.mode		= cmd_mode

--[[
local function cmd_luamod(name, file)
	mods.lua.pack_mod(name, file)
end
_M.luamod	= aio.luamod

local function cmd_rawmod(name, file)
        if mode == "raw2" then
                mods.raw2.pack_mod(name, file)
        else
                mods.raw.pack_mod(name, file)
        end
end
_M.rawmod	= aio.rawmod
]]--

local function cmd_mod(name, file)
	if mode == "lua" then
		mods.lua.pack_mod(name, file)
	elseif mode == "raw" then
		mods.raw.pack_mod(name, file)
	elseif mode == "raw2" then
		mods.raw2.pack_mod(name, file)
	else
		error("invalid mode "..name, 2)
	end
end
_M.mod		= cmd_mod

local finish_print = aio.finish_print
local function cmd_finish()
	if mods[mode].finish then
		mods[mode].finish()
	end
        finish_print()
end
_M.finish	= cmd_finish


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

local integrity = require "aio.integrity"
if integrity then
	_M.icheck	= integrity.cmd_icheck
	_M.ichechinit	= integrity.cmd_icheckinit
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
