#!/usr/bin/env lua

--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

-- $0 --mod <modname1 pathtofile1> [--mod <modname2> <pathtofile2>] [-- <file> [files...]]
-- $0 {--mod ...|--code ...} [-- files...]

-- TODO: support -h|--help and help/usage text

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

local function print_no_nl(data)
	output(data)
end

local function pack_module(modname, modpath)
	assert(modname)
	assert(modpath)

	-- TODO: improve: include in function code a comment with the name of original file (it will be shown in the trace error message) ?
	-- like [[...-- <pack ]]..modname..[[> --
	print_no_nl(
		[[do require("package").preload["XXXXX"] = (function() local package;return function(...)]]
		.. "-- <pack "..modname.."> --".."\n"
		.. cat(modpath) ..
		[[end end)()end]]
	)
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

local i = 1
while i <= #arg do
	local a1 = arg[i]; i=i+1
	if a1 == "--code" then
		local file=arg[i]; i=i+1
		print_no_nl(cat(file))
	elseif a1 == "--mod" then
		local name=arg[i]; i=i+1
		local file=arg[i]; i=i+1
		pack_module(name, file)
	elseif a1 == "--file" then
		local filename = arg[i]; i=i+1
		local filepath = arg[i]; i=i+1
		pack_file(filename, filepath)
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

