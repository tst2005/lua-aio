#!/usr/bin/env lua
do --{{
local sources, priorities = {}, {};assert(not sources["aio.integrity"],"module already exists")sources["aio.integrity"]=([===[-- <pack aio.integrity> --

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
_M.cmd_icheckinit	= cmd_icheckinit
_M.integrity_modcount_incr = integrity_modcount_incr
_M.module_with_integrity_check_get = function() return module_with_integrity_check end


return _M
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.compat_env"],"module already exists")sources["aio.compat_env"]=([===[-- <pack aio.compat_env> --
--[[
  compat_env - see README for details.
  (c) 2012 David Manura.  Licensed under Lua 5.1/5.2 terms (MIT license).
--]]

local M = {_TYPE='module', _NAME='compat_env', _VERSION='0.2.2.20120406'}

local function check_chunk_type(s, mode)
  local nmode = mode or 'bt' 
  local is_binary = s and #s > 0 and s:byte(1) == 27
  if is_binary and not nmode:match'b' then
    return nil, ("attempt to load a binary chunk (mode is '%s')"):format(mode)
  elseif not is_binary and not nmode:match't' then
    return nil, ("attempt to load a text chunk (mode is '%s')"):format(mode)
  end
  return true
end

local IS_52_LOAD = pcall(load, '')
if IS_52_LOAD then
  M.load     = _G.load
  M.loadfile = _G.loadfile
else
  -- 5.2 style `load` implemented in 5.1
  function M.load(ld, source, mode, env)
    local f
    if type(ld) == 'string' then
      local s = ld
      local ok, err = check_chunk_type(s, mode)
      if not ok then return ok, err end
      local err; f, err = loadstring(s, source)
      if not f then return f, err end
    elseif type(ld) == 'function' then
      local ld2 = ld
      if (mode or 'bt') ~= 'bt' then
        local first = ld()
        local ok, err = check_chunk_type(first, mode)
        if not ok then return ok, err end
        ld2 = function()
          if first then
            local chunk=first; first=nil; return chunk
          else return ld() end
        end
      end
      local err; f, err = load(ld2, source); if not f then return f, err end
    else
      error(("bad argument #1 to 'load' (function expected, got %s)")
            :format(type(ld)), 2)
    end
    if env then setfenv(f, env) end
    return f
  end

  -- 5.2 style `loadfile` implemented in 5.1
  function M.loadfile(filename, mode, env)
    if (mode or 'bt') ~= 'bt' then
      local ioerr
      local fh, err = io.open(filename, 'rb'); if not fh then return fh,err end
      local function ld()
        local chunk; chunk,ioerr = fh:read(4096); return chunk
      end
      local f, err = M.load(ld, filename and '@'..filename, mode, env)
      fh:close()
      if not f then return f, err end
      if ioerr then return nil, ioerr end
      return f
    else
      local f, err = loadfile(filename); if not f then return f, err end
      if env then setfenv(f, env) end
      return f
    end
  end
end

if _G.setfenv then -- Lua 5.1
  M.setfenv = _G.setfenv
  M.getfenv = _G.getfenv
else -- >= Lua 5.2
  local debug = require "debug"
  -- helper function for `getfenv`/`setfenv`
  local function envlookup(f)
    local name, val
    local up = 0
    local unknown
    repeat
      up=up+1; name, val = debug.getupvalue(f, up)
      if name == '' then unknown = true end
    until name == '_ENV' or name == nil
    if name ~= '_ENV' then
      up = nil
      if unknown then
        error("upvalues not readable in Lua 5.2 when debug info missing", 3)
      end
    end
    return (name == '_ENV') and up, val, unknown
  end

  -- helper function for `getfenv`/`setfenv`
  local function envhelper(f, name)
    if type(f) == 'number' then
      if f < 0 then
        error(("bad argument #1 to '%s' (level must be non-negative)")
              :format(name), 3)
      elseif f < 1 then
        error("thread environments unsupported in Lua 5.2", 3) --[*]
      end
      f = debug.getinfo(f+2, 'f').func
    elseif type(f) ~= 'function' then
      error(("bad argument #1 to '%s' (number expected, got %s)")
            :format(type(name, f)), 2)
    end
    return f
  end
  -- [*] might simulate with table keyed by coroutine.running()
  
  -- 5.1 style `setfenv` implemented in 5.2
  function M.setfenv(f, t)
    local f = envhelper(f, 'setfenv')
    local up, val, unknown = envlookup(f)
    if up then
      debug.upvaluejoin(f, up, function() return up end, 1) --unique upval[*]
      debug.setupvalue(f, up, t)
    else
      local what = debug.getinfo(f, 'S').what
      if what ~= 'Lua' and what ~= 'main' then -- not Lua func
        error("'setfenv' cannot change environment of given object", 2)
      end -- else ignore no _ENV upvalue (warning: incompatible with 5.1)
    end
    return f  -- invariant: original f ~= 0
  end
  -- [*] http://lua-users.org/lists/lua-l/2010-06/msg00313.html

  -- 5.1 style `getfenv` implemented in 5.2
  function M.getfenv(f)
    if f == 0 or f == nil then return _G end -- simulated behavior
    local f = envhelper(f, 'setfenv')
    local up, val = envlookup(f)
    if not up then return _G end -- simulated behavior [**]
    return val
  end
  -- [**] possible reasons: no _ENV upvalue, C function
end


return M
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.core"],"module already exists")sources["aio.core"]=([===[-- <pack aio.core> --

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

if false then -- selftest
assert( get_shebang("abc") == false )
assert( get_shebang("#!/bin/cool\n#blah\n") == "#!/bin/cool" )
assert( get_shebang("#!/bin/cool\n#blah") == "#!/bin/cool" )
assert( get_shebang("#!/bin/cool\n") == "#!/bin/cool" )
--assert( get_shebang("#!/bin/cool") == "#!/bin/cool" ) -- FIXME
assert( get_shebang("# !/bin/cool\n") == "# !/bin/cool" )
assert( get_shebang("# /bin/cool !\nxxx\n") == "# /bin/cool !" )
end


if false then -- selftest
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
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.mods"],"module already exists")sources["aio.mods"]=([===[-- <pack aio.mods> --

--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local config = require "aio.config"

config.mode = config.mode or "raw2" -- the default mode
config.validmodes = {lua=true, raw=true, raw2=true}

local mods = {}
mods.lua = require "aio.modlua"
mods.raw = require "aio.modraw"
mods.raw2 = require "aio.modraw2"

local _M = {}

local function cmd_mode(newmode)
	if not config.validmodes[newmode] then
		error("invalid mode "..newmode, 2)
	end
	config.mode = newmode
end
_M.mode		= assert(cmd_mode)

local function cmd_inpreload(preload)
	assert( type(preload)=="string", "argument #1 must be a lua code string")
	config.preload = preload
end
_M.inpreload		= assert(cmd_inpreload)



local function cmd_luamod(name, file)
	mods.lua.pack_mod(name, file)
end
_M.luamod	= cmd_luamod

local function cmd_rawmod(name, file)
	if config.mode == "raw2" then
		mods.raw2.pack_mod(name, file)
	else
		mods.raw.pack_mod(name, file)
	end
end
_M.rawmod	= cmd_rawmod

local function cmd_mod(name, file)
	local mode = config.mode
	if mode == "lua" then
		mods.lua.pack_mod(name, file)
	elseif mode == "raw" then
		mods.raw.pack_mod(name, file)
	elseif mode == "raw2" then
		mods.raw2.pack_mod(name, file)
	else
		error("invalid mode "..mode, 2)
	end
end
_M.mod		= cmd_mod


local core = require "aio.core"
local finish_print = assert(core.finish_print)
local function cmd_finish()
	local finish = mods[config.mode].pack_finish
	if finish then
		finish()
	end
	finish_print()
end
_M.finish	= cmd_finish

return _M
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.rock"],"module already exists")sources["aio.rock"]=([===[-- <pack aio.rock> --

--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

------------------------------------------------------------------------------

local core = require "aio.core"
local cmd_shebang	= assert(core.shebang)
local cmd_code		= assert(core.code)
local cmd_codehead	= assert(core.codehead)
local cmd_shellcode	= assert(core.shellcode)
local cmd_vfile		= assert(core.vfile)
local cmd_autoaliases	= assert(core.autoaliases)
local cmd_require	= assert(core.require)
local cmd_luacode	= assert(core.luacode)


local mods = require "aio.mods"
local cmd_mode		= assert(mods.mode)
local cmd_luamod	= assert(mods.luamod)
local cmd_rawmod	= assert(mods.rawmod)
local cmd_mod 		= assert(mods.mod)
local cmd_finish	= assert(mods.finish)

local rockspec = {} -- rockspecs file will be loaded into this isolated env
--local rock_loaded = false
local rockfile

local function rock_file(file)
	local compat_env = require "aio.compat_env"
	local loadfile = assert(compat_env.loadfile)
	local ok, err = loadfile(file, "t", rockspec)

	--[[
	local load = require "aio.load"
	local fd = io.open(file, "r")
	local content = fd:read("*a")
	fd:close()
	local ok, err = load(content, file, "t", rockspec)
	]]--

	if not ok then
		error(err, 2)
	end
	ok()

	local build = rockspec.build
	if not( type(build) == "table" and type(build.type) == "string") then
		return nil, "invalid rockspec file "..file
	end
	rockfile = file
end

local function rock_mod(where, but)
	local build = rockspec.build
	if where ~= "build.modules" then
		error("not implemented yet [1a]", 2)
	end
	local modules = build.modules

	if build.type == "builtin" then
		if type(modules) ~= "table" then
			error("missing build.modules table in file "..rockfile ,2)
		end

		local Done = {}
		-- try to support order with i-table items
		for _,modname in ipairs(modules) do
			if not Done[modname] and modname ~= but then
				local modfile = modules[modname]
				Done[modname] = true
				if type(modname) == "string" and type(modfile) == "string" then
					cmd_mod(modname, modfile)
				end
			end
		end
		for modname,modfile in pairs(modules) do
			if type(modname) == "string" and not Done[modname] and modname ~= but then
				Done[modname] = true
				if type(modname) == "string" and type(modfile) == "string" then
					cmd_mod(modname, modfile)
				end
			end
		end
	elseif build.type == "none" then
		-- .install.lua ?
		error(rockfile..": build.type == none", 2)
	elseif build.type == "make" then
		error(rockfile..": use make, skipped", 2)
	else
		error(rockfile..": build.type == "..build.type, 2)
	end
end

local function rock_get_binfile()
	local build = rockspec.build
	local t_bin = build and build.install and build.install.bin

	if not t_bin then return nil end

	local cnt = 0
	for k,v in pairs(t_bin) do
		cnt=cnt+1
	end
	if cnt>1 then
		return nil
		--error(where.." containts more than one entry in file "..rockfile, 2)
	end
	local _k, v = next(t_bin)
	return v
end

local function rock_code(where)
	local build = rockspec.build
	if where ~= "build.install.bin" and where ~= "build.install.lua" then
		error("not implemented yet [2a]", 2)
	end

	assert(where == "build.install.bin")
	local v = rock_get_binfile()
	cmd_code(v)
end

local function rock_auto(rockfile, modname, custom)
	rock_file(rockfile)
	local file
	if modname then
		file = rock_get_binfile() or
			rockspec.build and rockspec.build.modules and (
				rockspec.build.modules[modname] or
				rockspec.build.modules[modname..".init"]
			)
		assert(file)
	end
	if file then
		cmd_shebang(file)
		cmd_shellcode(file)
	end
	if type(custom) == "function" then
		custom()
	end
	rock_mod("build.modules", modname)
	cmd_finish()
	cmd_autoaliases()
	if file then
		cmd_code(file)
	end
	cmd_finish()
end

local rock = {
	file = rock_file,
	mod  = rock_mod,
	code = rock_code,
	auto = rock_auto,
}

return rock
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.modraw"],"module already exists")sources["aio.modraw"]=([===[-- <pack aio.modraw> --

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

-- quoting solution 2 : prefix the pattern of '\[===\[', '\]===\]' with '\' ; FIXME: for now it quote \]===\] or \[===\] or \]===\[ or \[===\[
--	local quote       = function(s) return s:gsub('([%]%[\]===\[%]%[])','\\%1') end
--	local unquotecode = [[:gsub('\\([%]%[\]===\[%]%[])','%1')]]

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
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.modraw2"],"module already exists")sources["aio.modraw2"]=([===[-- <pack aio.modraw2> --

--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local core = require "aio.core"
local config = require "aio.config"

local print_no_nl = assert(core.print_no_nl)
local autoeol, extractshebang, cat = core.autoeol, core.extractshebang, core.cat
assert( autoeol and extractshebang and cat )

local integrity = require "aio.integrity"
local module_with_integrity_check_get = integrity.module_with_integrity_check_get
local integrity_modcount_incr = integrity.integrity_modcount_incr
assert( module_with_integrity_check_get and integrity_modcount_incr)

local rawpack2_init_done = false
local rawpack2_finish_done = false

local function rawpack2_init()
	print_no_nl([[do --{{
local sources, priorities = {}, {};]])
end

local function rawpack2_module(modname, modpath)
	assert(modname)
	assert(modpath)

-- quoting solution 1 : prefix all '[', ']' with '\'
--	local quote       = function(s) return s:gsub('([%]%[])','\\%1') end
--	local unquotecode = [[:gsub('\\([%]%[])','%1')]]

-- quoting solution 2 : prefix the pattern of '\[===\[', '\]===\]' with '\' ; FIXME: for now it quote \]===\] or \[===\] or \]===\[ or \[===\[
	local quote       = function(s) return s:gsub('([%]%[]===)([%]%[])','\\%1\\%2') end
	local unquotecode = [[:gsub('\\([%]%[]===)\\([%]%[])','%1%2')]]

	if not rawpack2_init_done then
		rawpack2_init_done = not rawpack2_init_done
		if rawpack2_finish_done then rawpack2_finish_done = false end
		rawpack2_init()
	end
	local b = [[assert(not sources["]] .. modname .. [["],"module already exists")]]..[[sources["]] .. modname .. [["]=(]].."\[===\["
	local e = "\]===\])".. unquotecode

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
	local loadstring=_G.loadstring or _G.load; local preload = ]] ..( config.preload or [[require"package".preload]] ).. "\n"..
[[	add = function(name, rawcode)
		if not preload[name] then
			preload[name] = function(...) return assert(loadstring(rawcode), "loadstring: "..name.." failed")(...) end
		else
			print("WARNING: overwrite "..name)
		end
	end
end
for name, rawcode in pairs(sources) do add(name, rawcode, priorities[name]) end
end; --}};
]]
)
end

local function finish()
	if rawpack2_init_done and not rawpack2_finish_done then
		rawpack2_finish_done = not rawpack2_finish_done
		rawpack2_finish()
		rawpack2_init_done = false
	end
end

------------------------------------------------------------------------------

local M = {}

M.pack_mod	= assert(rawpack2_module)
M.pack_finish	= assert(finish)

return M
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.modlua"],"module already exists")sources["aio.modlua"]=([===[-- <pack aio.modlua> --

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
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["aio.config"],"module already exists")sources["aio.config"]=([===[-- <pack aio.config> --
return {}
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
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
end; --}};
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
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local M = {}
M._NAME = "lua-aio"
M._VERSION = "lua-aio 0.6.3"
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
M.inpreload	= assert(mods.inpreload)
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
