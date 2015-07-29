#!/usr/bin/env lua

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
local mode = "normal"

assert(arg)
local argv = #arg -1
local io = require"io"
local output=io.write

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

local function rawpack_module(modname, modpath)
	-- not implemented yet
	-- TODO: embedding with rawdata (string) and eval the lua code at runtime with load or loadstring
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

local function pack_file(filename, filepath)
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

local i = 1
local function shift(n)
	i=i+(n or 1)
end
while i <= #arg do
	local a1 = arg[i]; i=i+1
	if a1 == "--code" then
		local file=arg[i]; shift()
		print_no_nl(dropshebang(cat(file)))
	elseif a1 == "--codehead" then
		local n=arg[i]; shift()
		local file=arg[i]; shift()
		print_no_nl( dropshebang( head(file, n).."\n" ) )
	elseif a1 == "--shebang" then
		local file=arg[i]; shift()
		local shebang = get_shebang(head(file, 1).."\n")
		print_no_nl( shebang and shebang.."\n" or "")
	elseif a1 == "--mod" then
		local name=arg[i]; shift()
		local file=arg[i]; shift()
		if mode == "normal" then
			pack_module(name, file)
		elseif mode == "raw" then
			rawpack_module(name, file)
		else
			error("invalid mode when using --mod", 2)
		end
	elseif a1 == "--luamod" then
		local name=arg[i]; shift()
		local file=arg[i]; shift()
		pack_module(name, file)
	elseif a1 == "--rawmod" then
		local name=arg[i]; shift()
		local file=arg[i]; shift()
		rawpack_module(name, file)
	elseif a1 == "--mode" then
		local newmode=arg[i]; shift()
		if newmode == "normal" or newmode == "raw" then
			mode = newmode
		else
			error("invalid mode", 2)
		end
	elseif a1 == "--file" then
		local filename = arg[i]; shift()
		local filepath = arg[i]; shift()
		pack_file(filename, filepath)
	elseif a1 == "--autoaliases" then
		autoaliases_code()
	elseif a1 == "--icheck" then
		integrity_check_code()
	elseif a1 == "--icheckinit" then
		print_no_nl("local __ICHECK__ = {};__ICHECKCOUNT__=0;\n")
		module_with_integrity_check = true
	elseif a1 == "--require" then
		local modname = arg[i]; shift()
		assert(modname:find('^[a-zA-Z0-9%._-]+$'), "error: invalid modname")
		local code = [[require("]]..modname..[[")]]
		print_no_nl( code.."\n" )
	elseif a1 == "--" then
		break
	else
		error("error "..a1)
	end
end

if i <= #arg then
	for j=i,#arg,1 do
		print_no_nl(cat(arg[j]))
	end
end

