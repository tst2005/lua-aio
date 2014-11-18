#!/usr/bin/env lua

--[[
{{license}}
]]--

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

local function pack_module_begin()
	print_no_nl(
[[
do -- package block
	local package = require("package")
]]
	)
end

local function pack_module_end()
	print_no_nl(
[[end -- package block

-- main --
]]
	)
end

local function pack_module(modname, modpath)
	assert(modname)
	assert(modpath)

--	pack_module_begin
	print_no_nl(
[[	do -- <pack ]]..modname..[[> --
		local _tmp_
		do -- protect package
			local package -- refuse to catch package upvalue

			function _tmp_(...)
]]
.. cat(modpath) ..
[[			end -- function _tmp_
		end
		package.preload["]]..modname..[["] = _tmp_
	end -- </pack ]]..modname..[[> --
]]
	)
--	pack_module_end
end


local MODULE_BEGIN=0

local i = 1
while i <= #arg do
	local a1 = arg[i]; i=i+1
	if a1 == "--code" then
		if MODULE_BEGIN == 1 then
			pack_module_end()
			MODULE_BEGIN=0
		end
		local file=arg[i]; i=i+1
		print_no_nl(cat(file))
	elseif a1 == "--mod" then
		if MODULE_BEGIN == 0 then
			pack_module_begin()
			MODULE_BEGIN=1
		end
		local name=arg[i]; i=i+1
		local file=arg[i]; i=i+1
		pack_module(name, file)
	elseif a1 == "--" then
		break
	else
		error("error "..a1)
	end
end

if MODULE_BEGIN == 1 then
	pack_module_end()
	MODULE_BEGIN=0
end

if i <= #arg then
	for j=i,#arg,1 do
		print_no_nl(cat(arg[j]))
	end
end

