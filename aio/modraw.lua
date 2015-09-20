
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

local rawpack2_init_done = false
local rawpack2_finish_done = false


local function rawpack2_init()
	print_no_nl([[do local sources, priorities = {}, {};]])
end

local function rawpack2_module(modname, modpath)
	assert(modname)
	assert(modpath)

-- quoting solution 1 : prefix all '[', ']' with '\'
--	local quote       = function(s) return s:gsub('([%]%[])','\\%1') end
--	local unquotecode = [[:gsub('\\([%]%[])','%1')]]

-- quoting solution 2 : prefix the pattern of '[===[', ']===]' with '\' ; FIXME: for now it quote ]===] or [===] or ]===[ or [===[
	local quote       = function(s) return s:gsub('([%]%[]===)([%]%[])','\\%1\\%2') end
	local unquotecode = [[:gsub('\\([%]%[]===)\\([%]%[])','%1%2')]]

	if not rawpack2_init_done then
		rawpack2_init_done = not rawpack2_init_done
		if rawpack2_finish_done then rawpack2_finish_done = false end
		rawpack2_init()
	end
	local b = [[assert(not sources["]] .. modname .. [["])]]..[[sources["]] .. modname .. [["]=(]].."[===["
	local e = "]===])".. unquotecode

	local d = "-- <pack "..modname.."> --" -- error message keep the first 45 chars max
	print_no_nl(
		b .. d .."\n"
		.. quote(autoeol(extractshebang(cat(modpath))))
		.. e .."\n"
	)
	--integrity_modcount_incr() -- for integrity check
end

--local function rawpack2_finish()
--	print_no_nl(
--[[
--local loadstring=_G.loadstring or _G.load; local preload = require"package".preload
--for name, rawcode in pairs(sources) do preload[name]=function(...)return loadstring(rawcode)(...)end end
--end;
--]]
--)
--end

local function rawpack2_finish()
	print_no_nl(
[[
local add
if not pcall(function() add = require"aioruntime".add end) then
        local loadstring=_G.loadstring or _G.load; local preload = require"package".preload
        add = function(name, rawcode)
		if not preload[name] then
		        preload[name] = function(...) return assert(loadstring(rawcode), "loadstring: "..name.." failed")(...) end
		else
			print("WARNING: overwrite "..name)
		end
        end
end
for name, rawcode in pairs(sources) do add(name, rawcode, priorities[name]) end
end;
]]
)
end

local function finish()
	if rawpack2_init_done and not rawpack2_finish_done then
		rawpack2_finish_done = not rawpack2_finish_done
		rawpack2_finish()
	end
end


local function cmd_rawmod(name, file)
	if mode == "raw2" then
		rawpack2_module(name, file)
	else
		rawpack_module(name, file)
	end
end

local function cmd_mod(name, file)
	if mode == "lua" then
		pack_module(name, file)
	elseif mode == "raw" then
		rawpack_module(name, file)
	elseif mode == "raw2" then
		rawpack2_module(name, file)
	else
		error("invalid mode when using --mod", 2)
	end
end


------------------------------------------------------------------------------

local _M = {}

_M.shebang	= cmd_shebang
_M.luamod	= cmd_luamod
_M.rawmod	= cmd_rawmod
_M.mod		= cmd_mod
_M.code		= cmd_code
_M.codehead	= cmd_codehead -- obsolete
_M.shellcode	= cmd_shellcode
_M.mode		= cmd_mode
_M.vfile	= cmd_vfile
_M.autoaliases	= cmd_autoaliases
_M.require	= cmd_require
_M.luacode	= cmd_luacode
_M.finish	= cmd_finish

return _M
