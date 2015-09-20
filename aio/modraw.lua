
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local function output(data)

local function print_no_nl(data)



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
local integrity_modcount_incr = integrity.integrity_modcount_incr


-- TODO: embedding with rawdata (string) and eval the lua code at runtime with loadstring
local function rawpack_module(modname, modpath)
	assert(modname)
	assert(modpath)

-- quoting solution 1 : prefix all '[', ']' with '\'
	local quote       = function(s) return s:gsub('([%]%[])','\\%1') end
	local unquotecode = [[:gsub('\\([%]%[])','%1')]]

-- quoting solution 2 : prefix the pattern of '[===[', ']===]' with '\' ; FIXME: for now it quote ]===] or [===] or ]===[ or [===[
--	local quote       = function(s) return s:gsub('([%]%[]===[%]%[])','\\%1') end
--	local unquotecode = [[:gsub('\\([%]%[]===[%]%[])','%1')]]

	local b = [[do local loadstring=_G.loadstring or _G.load;(function(name, rawcode)require"package".preload[name]=function(...)return assert(loadstring(rawcode), "loadstring: "..name.." failed")(...)end;end)("]] .. modname .. [[", (]].."[["
	local e = "]])".. unquotecode .. ")end"

--	if deny_package_access then
--		b = [[do require("package").preload["]] .. modname .. [["] = (function() local package;return function(...)]]
--		e = [[end end)()end;]]
--	end

	if module_with_integrity_check_get() then
		e = e .. [[__ICHECK__[#__ICHECK__+1] = ]].."'"..modname.."'"..[[;__ICHECKCOUNT__=(__ICHECKCOUNT__+1);]]
	end

	-- TODO: improve: include in function code a comment with the name of original file (it will be shown in the trace error message) ?
	local d = "-- <pack "..modname.."> --" -- error message keep the first 45 chars max
	print_no_nl(
		b .. d .."\n"
		.. quote(autoeol(extractshebang(cat(modpath)))) --:gsub('([%]%[])','\\%1')
		.. e .."\n"
	)
	--integrity_modcount_incr() -- for integrity check
end

------------------------------------------------------------------------------

local M = {}

M.pack_mod	= assert(rawpack_module)
M.pack_finish	= nil

return M
