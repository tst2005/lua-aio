#!/usr/bin/env lua
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local mods = {}
mods.lua = require "aio.modlua"
mods.raw = require "aio.modraw"
mods.raw2 = require "aio.modraw2"

local _M = {}

local function cmd_mode(newmode)
	local modes = {lua=true, raw=true, raw2=true}
	if modes[newmode] then
		mode = newmode
	else
		error("invalid mode", 2)
	end
end
_M.mode		= cmd_mode

local function cmd_luamod(name, file)
	mods.lua.pack_mod(name, file)
end
_M.luamod	= cmd_luamod

local function cmd_rawmod(name, file)
        if mode == "raw2" then
                mods.raw2.pack_mod(name, file)
        else
                mods.raw.pack_mod(name, file)
        end
end
_M.rawmod	= cmd_rawmod

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


local core = require "aio.core"
local finish_print = assert(core.finish_print)
local function cmd_finish()
	local finish = mods[mode].finish
	if finish then
		finish()
	end
        finish_print()
end
_M.finish	= cmd_finish

return _M
