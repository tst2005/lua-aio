
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local core = require "aio.core"
local print_no_nl = core.print_no_nl
local autoeol, extractshebang, cat = core.autoeol, core.extractshebang, core.cat

local deny_package_access = false --FIXME: aio.config ?

local integrity = require "aio.integrity"
local module_with_integrity_check_get = integrity.module_with_integrity_check_get

local function pack_module(modname, modpath)
	assert(modname)
	assert(modpath)

	local b = [[require("package").preload["]] .. modname .. [["] = function(...)]]
	local e = [[end;]]

	if deny_package_access then
		b = [[do require("package").preload["]] .. modname .. [["] = (function() local package;return function(...)]]
		e = [[end end)()end;]]
	end

	if module_with_integrity_check_get() then
		e = e .. [[__ICHECK__[#__ICHECK__+1] = ]].."'"..modname.."'"..[[;__ICHECKCOUNT__=(__ICHECKCOUNT__+1);]]
	end

	-- TODO: improve: include in function code a comment with the name of original file (it will be shown in the trace error message) ?
	-- like [[...-- <pack ]]..modname..[[> --
	print_no_nl(
		b
		.. "-- <pack "..modname.."> --".."\n"
		.. autoeol(extractshebang(cat(modpath)))
		.. e .."\n"
	)
	--integrity_modcount_incr() -- for integrity check
end


local function cmd_luamod(name, file)
	pack_module(name, file)
end


------------------------------------------------------------------------------

local _M = {}
_M.pack_mod = cmd_luamod
return _M
