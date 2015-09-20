
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local deny_package_access = false

--local argv = arg and (#arg -1) or 0
local io = require"io"

local result = {}

local function finish_print()
	io.write(table.concat(result or {}, ""))
	result = {}
end

local function print_no_nl(data)
	result[#result+1] = data
	return data
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
	if not n or n < 1 then return "" end
	local fd = assert(io.open(dirfile, "r"))
	local data = nil
	for _i = 1,n,1 do
		local line = fd:read('*l')
		if not line then break end
		data = ( (data and data .. "\n") or ("") ) .. line
	end
	fd:close()
	return data
end

local function headgrep(dirfile, patn)
	assert(dirfile)
	patn = patn or "^(.+\n_=%[%[\n.*\n%]%] and nil\n)"

	local fd = assert(io.open(dirfile, "r"))

	local function search_begin_in_line(line)
		--if line == "_=[[" then -- usual simple case
		--	return line, "\n", 0
		--end
		local a,b,c,d = line:match( "^(%s*_%s*=%s*%[)(=*)(%[)(.*)$" ) -- <space> '_' <space> '=[' <=> '[' <code>
		if not a then
			return nil, nil, nil
		end
		return a..b..c, d.."\n", #b
	end
	local function search_2_first_line(fd)
		local count = 0
		while true do -- search in the 2 first non-empty lines
			local line = fd:read("*l")
			if not line then break end
			if count > 2 then break end
			if not (line == "" or line:find("^%s+$")) then -- ignore empty line
				count = count +1
				local b, code, size = search_begin_in_line(line)
				if b then
					return b, code, size
				end
			end
		end
		return nil
	end
	local function search_end(fd, code, size)
		local data = code
		local patn = "^(.*%]"..("="):rep(size).."%][^\n]*\n)"
		local match
		while true do
			match = data:match(patn)
			if match then return match end
			local line = fd:read("*l")
			if not line then break end
			data = data..line.."\n"
		end
		return match
	end

	local b, code, size = search_2_first_line(fd)

	local hdata
	if b then
		local match = search_end(fd, code, size)
		if match then
			hdata = b..match -- shellcode found
		else print("no match search_end")
		end
		-- openshell code found, but not the end
	else
		hdata = "" -- no shellcode
	end
	fd:close()
	return hdata -- result: string or nil(error)
end


local function extractshebang(data)
	if data:sub(1,1) ~= "#" then
		return data, nil
	end
	local _b, e, shebang = data:find("^([^\n]+)\n")
	return data:sub(e+1), shebang
end

local function dropshebang(data)
	local data2, _shebang = extractshebang(data)
	return data2
end

local function get_shebang(data)
	local _data2, shebang = extractshebang(data)
	return shebang or false
end

assert( get_shebang("abc") == false )
assert( get_shebang("#!/bin/cool\n#blah\n") == "#!/bin/cool" )
assert( get_shebang("#!/bin/cool\n#blah") == "#!/bin/cool" )
assert( get_shebang("#!/bin/cool\n") == "#!/bin/cool" )
--assert( get_shebang("#!/bin/cool") == "#!/bin/cool" ) -- FIXME
assert( get_shebang("# !/bin/cool\n") == "# !/bin/cool" )
assert( get_shebang("# /bin/cool !\nxxx\n") == "# /bin/cool !" )



do -- selftest
	do
	local data, shebang = extractshebang(
[[#!/bin/sh
test
]]
)
	assert(shebang=="#!/bin/sh")
	assert(data=="test\n")
	end

	do
	local data, shebang = extractshebang(
[[blah blah
test
]]
)
	assert(shebang==nil)
	assert(data=="blah blah\ntest\n")
	end

end -- end of selftests

-- this is a workaround needed when the last character of the module content is end of line and the last line is a comment.
local function autoeol(data)
	local lastchar = data:sub(-1, -1)
	if lastchar ~= "\n" then
		return data .. "\n"
	end
	return data
end


local function datapack(data, tagsep)
	tagsep = tagsep or ''
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
	print_no_nl(code)
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



local function cmd_shebang(file)
	local shebang = get_shebang(head(file, 1).."\n")
	print_no_nl( shebang and shebang.."\n" or "")
end

local function cmd_code(file)
	print_no_nl(dropshebang(cat(file)))
end
local function cmd_codehead(n, file)
	print_no_nl( dropshebang( head(file, n).."\n" ) )
end
local function cmd_shellcode(file, patn)
	print_no_nl( headgrep(file, patn) )
	--print_no_nl( dropshebang( headgrep(file, patn).."\n" ) )
end

local function cmd_vfile(filename, filepath)
	pack_vfile(filename, filepath)
end
local function cmd_autoaliases()
	autoaliases_code()
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

------------------------------------------------------------------------------

local _M = {}

_M.shebang	= cmd_shebang
_M.code		= cmd_code
_M.codehead	= cmd_codehead -- obsolete
_M.shellcode	= cmd_shellcode
_M.vfile	= cmd_vfile
_M.autoaliases	= cmd_autoaliases
_M.require	= cmd_require
_M.luacode	= cmd_luacode
_M.finish_print = finish_print

_M.cat = cat
_M.head = head
_M.headgrep = headgrep
_M.extractshebang = extractshebang
_M.dropshebang = dropshebang
_M.get_shebang = get_shebang
_M.autoeol = autoeol
_M.print_no_nl = print_no_nl

return _M
