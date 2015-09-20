
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local module_with_integrity_check = false
local modcount = 0

local core = require "aio.core"
local print_no_nl = core.print_no_nl

local function integrity_check_code()
	assert(modcount)
	print_no_nl([[
-- integrity check
--print( (__ICHECKCOUNT__ or "").." module(s) embedded.")
assert(__ICHECKCOUNT__==]].. modcount ..[[)
if not __ICHECK__ then
	error("Intergity check failed: no such __ICHECK__", 1)
end
--do for i,v in ipairs(__ICHECK__) do print(i, v) end end
if #__ICHECK__ ~= ]] .. modcount .. [[ then
	error("Intergity check failed: expect ]] .. modcount .. [[, got "..#__ICHECK__.." modules", 1)
end
-- end of integrity check
]])
end

local function integrity_modcount_incr()
	modcount = modcount+1
end


local function cmd_icheckinit()
	print_no_nl("local __ICHECK__ = {};__ICHECKCOUNT__=0;\n")
	module_with_integrity_check = true
end

local function cmd_icheck()
	integrity_check_code()
end



------------------------------------------------------------------------------

local _M = {}
_M.cmd_icheck	= cmd_icheck
_M.cmd_ichechinit	= cmd_icheckinit
_M.integrity_modcount_incr = integrity_modcount_incr
_M.module_with_integrity_check_get = function() return module_with_integrity_check end


return _M
