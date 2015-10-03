#!/usr/bin/env lua
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local M = {}
M._NAME = "lua-aio"
M._VERSION = "lua-aio 0.6.2"
M._LICENSE = "MIT"

local core = require("aio.core")
M.shebang	= assert(core.shebang)
M.code		= assert(core.code)
M.codehead	= assert(core.codehead) -- obsolete
M.shellcode	= assert(core.shellcode)

M.vfile	= assert(core.vfile)
M.autoaliases	= assert(core.autoaliases)
M.require	= assert(core.require)
M.luacode	= assert(core.luacode)

local mods = require "aio.mods"
M.mode		= assert(mods.mode)
M.luamod	= assert(mods.luamod)
M.rawmod	= assert(mods.rawmod)
M.mod		= assert(mods.mod)
M.finish	= assert(mods.finish)

local function wrap(f)
	return function(...)
		f(...)
		return M
	end
end

for k,v in pairs(M) do
	if type(v) == "function" then
		M[k] = wrap(v)
	end
end

local integrity = require "aio.integrity"
if integrity then
	M.icheck	= assert(integrity.cmd_icheck)
	M.ichechinit	= assert(integrity.cmd_icheckinit)
end

local rock = require "aio.rock"

--[[
for k,v in pairs(rock) do
	if type(v) == "function" then
		rock[k] = wrap(v)
	end
end
]]--

M.rock = assert(rock)

return M
