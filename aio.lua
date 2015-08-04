#!/bin/sh
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
]]
_=nil
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

-- $0 --mod <modname1 pathtofile1> [--mod <modname2> <pathtofile2>] [-- <file> [files...]]
-- $0 {--mod ...|--code ...} [-- files...]
-- $0 --autoaliases

-- TODO: support -h|--help and help/usage text

local deny_package_access = false
local module_with_integrity_check = false
local modcount = 0
local mode = "lua"

--local argv = arg and (#arg -1) or 0
local io = require"io"
local result = {}
local function output(data)
	result[#result+1] = data
end


local function cat(dirfile)
	assert(dirfile)
	local fd = assert(io.open(dirfile, "r"))
	local data = fd:read('*a')
	fd:close()
	return data
end

local function head(dirfile, n)
	assert(dirfile)
	local fd = assert(io.open(dirfile, "r"))
	local data = nil
	for i = 1,n,1 do
		local line = fd:read('*l')
		if not line then break end
		data = ( (data and data .. "\n") or ("") ) .. line
	end
	fd:close()
	return data
end


local function extractshebang(data)
	if data:sub(1,1) ~= "#" then
		return data, nil
	end
	local b, e, shebang = data:find("^([^\n]+)\n")
	return data:sub(e+1), shebang
end

local function dropshebang(data)
	local data, shebang = extractshebang(data)
	return data
end

local function get_shebang(data)
	local data, shebang = extractshebang(data)
	return shebang or false
end

assert( get_shebang("abc") == false )
assert( get_shebang("#!/bin/cool\n#blah\n") == "#!/bin/cool" )
assert( get_shebang("#!/bin/cool\n#blah") == "#!/bin/cool" )
assert( get_shebang("#!/bin/cool\n") == "#!/bin/cool" )
--assert( get_shebang("#!/bin/cool") == "#!/bin/cool" )
assert( get_shebang("# !/bin/cool\n") == "# !/bin/cool" )


do -- selftest
	local data, shebang = extractshebang
[[#!/bin/sh
test
]]
	assert(shebang=="#!/bin/sh")
	assert(data=="test\n")

	local data, shebang = extractshebang
[[blah blah
test
]]
	assert(shebang==nil)
	assert(data=="blah blah\ntest\n")

end -- end of selftests

local function print_no_nl(data)
	output(data)
end

-- this is a workaround needed when the last character of the module content is end of line and the last line is a comment.
local function autoeol(data)
	local lastchar = data:sub(-1, -1)
	if lastchar ~= "\n" then
		return data .. "\n"
	end
	return data
end

-- TODO: embedding with rawdata (string) and eval the lua code at runtime with loadstring
local function rawpack_module(modname, modpath)
	assert(modname)
	assert(modpath)

	local b = [[do local loadstring=loadstring;(function(name, rawcode)require"package".preload[name]=function(...)return assert(loadstring(rawcode))(...)end;end)("]] .. modname .. [[", (]].."[["
	local e = "]]"..[[):gsub('\\([%]%[])','%1'))end]]

--	if deny_package_access then
--		b = [[do require("package").preload["]] .. modname .. [["] = (function() local package;return function(...)]]
--		e = [[end end)()end;]]
--	end

	if module_with_integrity_check then
		e = e .. [[__ICHECK__[#__ICHECK__+1] = ]].."'"..modname.."'"..[[;__ICHECKCOUNT__=(__ICHECKCOUNT__+1);]]
	end

	-- TODO: improve: include in function code a comment with the name of original file (it will be shown in the trace error message) ?
	local d = "-- <pack "..modname.."> --" -- error message keep the first 45 chars max
	print_no_nl(
		b .. d .."\n"
		.. autoeol(extractshebang(cat(modpath))):gsub('([%]%[])','\\%1')
		.. e .."\n"
	)
	modcount = modcount + 1 -- for integrity check
end

local rawpack2_init_done = false
local rawpack2_finish_done = false


local function rawpack2_init()
	print_no_nl([[do local sources = {};]])
end

local function rawpack2_module(modname, modpath)
	assert(modname)
	assert(modpath)
	if not rawpack2_init_done then
		rawpack2_init_done = not rawpack2_init_done
		rawpack2_init()
	end
	local b = [[sources["]] .. modname .. [["]=(]].."[["
	local e = "]]"..[[):gsub('\\([%]%[])','%1')]]
	local d = "-- <pack "..modname.."> --" -- error message keep the first 45 chars max
	print_no_nl(
		b .. d .."\n"
		.. autoeol(extractshebang(cat(modpath))):gsub('([%]%[])','\\%1')
		.. e .."\n"
	)
	--modcount = modcount + 1 -- for integrity check
end

local function rawpack2_finish()
	print_no_nl(
[[
local loadstring=loadstring; local preload = require"package".preload
for name, rawcode in pairs(sources) do preload[name]=function(...)return loadstring(rawcode)(...)end end
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

local function pack_module(modname, modpath)
	assert(modname)
	assert(modpath)

	local b = [[require("package").preload["]] .. modname .. [["] = function(...)]]
	local e = [[end;]]

	if deny_package_access then
		b = [[do require("package").preload["]] .. modname .. [["] = (function() local package;return function(...)]]
		e = [[end end)()end;]]
	end

	if module_with_integrity_check then
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
	modcount = modcount + 1 -- for integrity check
end

local function datapack(data, tagsep)
	local tagsep = tagsep and tagsep or ''
	local c = data:sub(1,1)
	if c == "\n" or c == "\r" then
		return "["..tagsep.."["..c..data.."]"..tagsep.."]"
	end
	return "["..tagsep.."["..data.."]"..tagsep.."]"
end

local function datapack_with_unpackcode(data, tagsep)
	return "(" .. datapack(data:gsub("%]", "\\]"), tagsep) .. ")" .. [[:gsub( "\\%]", "]" )]]
end

local function pack_vfile(filename, filepath)
	local data = cat(filepath)
	data = "--fakefs ".. filename .. "\n" .. data
	local code = "do local p=require'package';p.fakefs=(p.fakefs or {});p.fakefs[\"" .. filename .. "\"]=" .. datapack_with_unpackcode(data, '==') .. ";end\n"
--	local code = "local x = " .. datapack_with_unpackcode(data) .. ";io.write(x)"
	output(code)
end

local function autoaliases_code()
	print_no_nl[[
do -- preload auto aliasing...
	local p = require("package").preload
	for k,v in pairs(p) do
		if k:find("%.init$") then
			local short = k:gsub("%.init$", "")
			if not p[short] then
				p[short] = v
			end
		end
	end
end
]]
end

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

local function cmd_shebang(file)
	local shebang = get_shebang(head(file, 1).."\n")
	print_no_nl( shebang and shebang.."\n" or "")
end

local function cmd_luamod(name, file)
	pack_module(name, file)
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
local function cmd_code(file)
	print_no_nl(dropshebang(cat(file)))
end
local function cmd_codehead(n, file)
	print_no_nl( dropshebang( head(file, n).."\n" ) )
end
local function cmd_mode(newmode)
	local modes = {lua=true, raw=true, raw2=true}
	if modes[newmode] then
		mode = newmode
	else
		error("invalid mode", 2)
	end
end
local function cmd_vfile(filename, filepath)
	pack_vfile(filename, filepath)
end
local function cmd_autoaliases()
	autoaliases_code()
end
local function cmd_icheck()
	integrity_check_code()
end
local function cmd_icheckinit()
	print_no_nl("local __ICHECK__ = {};__ICHECKCOUNT__=0;\n")
	module_with_integrity_check = true
end
local function cmd_require(modname)
	assert(modname:find('^[a-zA-Z0-9%._-]+$'), "error: invalid modname")
	local code = [[require("]]..modname..[[")]] -- FIXME: quote
	print_no_nl( code.."\n" )
end
local function cmd_luacode(data)
	local code = data -- FIXME: quote
	print_no_nl( code.."\n" )
end
local function cmd_finish()
	finish()
	io.write(table.concat(result or {}, ""))
	result = nil
end

local _M = {}
_M._VERSION = "lua-aio 0.3"
_M._LICENSE = "MIT"

_M.shebang	= cmd_shebang
_M.luamod	= cmd_luamod
_M.rawmod	= cmd_rawmod
_M.mod		= cmd_mod
_M.code		= cmd_code
_M.codehead	= cmd_codehead
_M.mode		= cmd_mode
_M.vfile	= cmd_vfile
_M.autoaliases	= cmd_autoaliases
_M.icheck	= cmd_icheck
_M.ichechinit	= cmd_icheckinit
_M.require	= cmd_require
_M.luacode	= cmd_luacode
_M.finish	= cmd_finish

return _M
