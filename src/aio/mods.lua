
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local config = require "aio.config"

config.mode = config.mode or "raw2" -- the default mode
config.validmodes = {lua=true, raw=true, raw2=true}

local mods = {}
mods.lua = require "aio.modlua"
mods.raw = require "aio.modraw"
mods.raw2 = require "aio.modraw2"

local _M = {}

local function cmd_mode(newmode)
	if not config.validmodes[newmode] then
		error("invalid mode "..newmode, 2)
	end
	config.mode = newmode
end
_M.mode		= assert(cmd_mode)

local function cmd_inpreload(preload)
	assert( type(preload)=="string", "argument #1 must be a lua code string")
	config.preload = preload
end
_M.inpreload		= assert(cmd_inpreload)



local function cmd_luamod(name, file)
	mods.lua.pack_mod(name, file)
end
_M.luamod	= cmd_luamod

local function cmd_rawmod(name, file)
	if config.mode == "raw2" then
		mods.raw2.pack_mod(name, file)
	else
		mods.raw.pack_mod(name, file)
	end
end
_M.rawmod	= cmd_rawmod

local function cmd_mod(name, file)
	local mode = config.mode
	if mode == "lua" then
		mods.lua.pack_mod(name, file)
	elseif mode == "raw" then
		mods.raw.pack_mod(name, file)
	elseif mode == "raw2" then
		mods.raw2.pack_mod(name, file)
	else
		error("invalid mode "..mode, 2)
	end
end
_M.mod		= cmd_mod


local core = require "aio.core"
local finish_print = assert(core.finish_print)
local function cmd_finish()
	local finish = mods[config.mode].pack_finish
	if finish then
		finish()
	end
	finish_print()
end
_M.finish	= cmd_finish

return _M
