#!/usr/bin/env lua
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

local M = {}
M._NAME = "lua-aio-ng"
M._VERSION = "lua-aio-ng 0.1.0alpha"
M._LICENSE = "MIT"

local table = require "table"
--local string = require "string"

local class = require "mini.class"
local instance = assert(class.instance)

local aio_class = class("aio", {
	init = function(self)
		-- config
		local config = {}
		self.config = config

		-- core
		self.io = require "io"
		self.deny_package_access = false
		self.result = {}

		-- mods
		config.mode = config.mode or "raw2" -- the default mode
		config.validmodes = {
			lua	= true,
		--	raw	= true, -- not included
			raw2	= true,
		}
		assert(self.config.validmodes[self.config.mode])

		-- drawraw
		self.raw2_pack_init_done = false
		self.raw2_pack_finish_done = false

		-- rock
		self.rockspec = {} -- rockspecs file will be loaded into this isolated env
		--local rock_loaded = false
		self.rockfile = nil

	end
})

function aio_class:finish_print()
	self.io.write(table.concat(self.result or {}, ""))
	self.result = {}
	--return self ?
end

function aio_class:print_no_nl(data)
	self.result[#self.result+1] = data
	return data --return self ?
end

function aio_class:cat(dirfile)
	assert(dirfile)
	local fd = assert(self.io.open(dirfile, "r"))
	local data = fd:read('*a')
	fd:close()
	return data
end

function aio_class:head(dirfile, n)
	assert(dirfile)
	if not n or n < 1 then return "" end
	local fd = assert(self.io.open(dirfile, "r"))
	local data = {}
	for _i = 1,n,1 do
		local line = fd:read('*l')
		if not line then break end
		data[#data+1] = line
	end
	fd:close()
	return table.concat(data, "\n")
end

function aio_class:headgrep(dirfile, patn)
	assert(dirfile)
	-- by default match: <anything> + \n + "_=[[" + \n + <anything> + \n + "]] and nil" + \n
	patn = patn or "^(.+\n_=%[%[\n.*\n%]%] and nil\n)" -- FIXME


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

	local fd = assert(io.open(dirfile, "r"))
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

function aio_class:extractshebang(data)
	if data:sub(1,1) ~= "#" then
		return data, nil
	end
	local _b, e, shebang = data:find("^([^\n]+)\n")
	return data:sub(e+1), shebang
end

function aio_class:dropshebang(data)
	local data2, _shebang = self:extractshebang(data)
	return data2
end

function aio_class:get_shebang(data)
	local _data2, shebang = self:extractshebang(data)
	return shebang or false
end

-- this is a workaround needed when the last character of the module content is end of line and the last line is a comment.
function aio_class:autoeol(data)
	local lastchar = data:sub(-1, -1)
	if lastchar ~= "\n" then
		return data .. "\n"
	end
	return data
end

function aio_class:datapack(data, tagsep)
	tagsep = tagsep or ''
	local c = data:sub(1,1)
	if c == "\n" or c == "\r" then
		return "["..tagsep.."["..c..data.."]"..tagsep.."]"
	end
	return "["..tagsep.."["..data.."]"..tagsep.."]"
end

function aio_class:datapack_with_unpackcode(data, tagsep)
	return "(" .. self:datapack(data:gsub("%]", "\\]"), tagsep) .. ")" .. [[:gsub( "\\%]", "]" )]]
end

function aio_class:pack_vfile(filename, filepath)
	local data = self:cat(filepath)
	data = "--fakefs ".. filename .. "\n" .. data
	local code = "do local p=require'package';p.fakefs=(p.fakefs or {});p.fakefs[\"" .. filename .. "\"]=" .. self:datapack_with_unpackcode(data, '==') .. ";end\n"
--	local code = "local x = " .. datapack_with_unpackcode(data) .. ";io.write(x)"
	self:rint_no_nl(code)
end

function aio_class:autoaliases_code()
	self:print_no_nl[[
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

-- public method

function aio_class:shebang(file)
	local shebang = self:get_shebang( self:head(file, 1).."\n")
	self:print_no_nl( shebang and shebang.."\n" or "")
end

function aio_class:code(file)
	self:print_no_nl( self:dropshebang(self:cat(file)) )
end
function aio_class:codehead(n, file)
	self:print_no_nl( self:dropshebang( self:head(file, n).."\n" ) )
end
function aio_class:shellcode(file, patn)
	self:print_no_nl( self:headgrep(file, patn) )
	--self:print_no_nl( self:dropshebang( self:headgrep(file, patn).."\n" ) )
end

function aio_class:vfile(filename, filepath)
	self:pack_vfile(filename, filepath)
end
function aio_class:autoaliases()
	self:autoaliases_code()
end
function aio_class:require(modname)
	assert(modname:find('^[a-zA-Z0-9%._-]+$'), "error: invalid modname")
	local code = [[require("]]..modname..[[")]] -- FIXME: quote
	self:print_no_nl( code.."\n" )
end
function aio_class:luacode(data)
	local code = data -- FIXME: quote
	self:print_no_nl( code.."\n" )
end

-- ########################## END OF core


--## modlua ##--

--local integrity = require "aio.integrity"
--local module_with_integrity_check_get = integrity.module_with_integrity_check_get

function aio_class:lua_pack_mod(modname, modpath)
	assert(modname)
	assert(modpath)

	local b = [[require("package").preload["]] .. modname .. [["] = function(...)]]
	local e = [[end;]]

	local deny_package_access = self.deny_package_access
	if deny_package_access then
		b = [[do require("package").preload["]] .. modname .. [["] = (function() local package;return function(...)]]
		e = [[end end)()end;]]
	end

--	if module_with_integrity_check_get() then
--		e = e .. [[__ICHECK__[#__ICHECK__+1] = ]].."'"..modname.."'"..[[;__ICHECKCOUNT__=(__ICHECKCOUNT__+1);]]
--	end

	-- TODO: improve: include in function code a comment with the name of original file (it will be shown in the trace error message) ?
	-- like [[...-- <pack ]]..modname..[[> --
	self:print_no_nl(
		b
		.. "-- <pack "..modname.."> --".."\n"
		.. self:autoeol(self:extractshebang(self:cat(modpath)))
		.. e .."\n"
	)
	--integrity_modcount_incr() -- for integrity check
end
--## /modlua ##--



--## modraw ##--

--local integrity = require "aio.integrity"
--local module_with_integrity_check_get = integrity.module_with_integrity_check_get
--local integrity_modcount_incr = integrity.integrity_modcount_incr
--assert( module_with_integrity_check_get and integrity_modcount_incr)


function aio_class:raw2_pack_init()
	self:print_no_nl([[do --{{
local sources, priorities = {}, {};]])
end

function aio_class:raw2_pack_mod(modname, modpath)
	assert(modname)
	assert(modpath)

-- quoting solution 1 : prefix all '[', ']' with '\'
--	local quote       = function(s) return s:gsub('([%]%[])','\\%1') end
--	local unquotecode = [[:gsub('\\([%]%[])','%1')]]

-- quoting solution 2 : prefix the pattern of '[===[', ']===]' with '\' ; FIXME: for now it quote ]===] or [===] or ]===[ or [===[
	local quote       = function(s) return s:gsub('([%]%[]===)([%]%[])','\\%1\\%2') end
	local unquotecode = [[:gsub('\\([%]%[]===)\\([%]%[])','%1%2')]]

	if not self.raw2_pack_init_done then
		self.raw2_pack_init_done = not self.raw2_pack_init_done
		if self.raw2_pack_finish_done then self.raw2_pack_finish_done = false end
		self:raw2_pack_init()
	end
	local b = [[assert(not sources["]] .. modname .. [["],"module already exists")]]..[[sources["]] .. modname .. [["]=(]].."[===["
	local e = "]===])".. unquotecode

	local d = "-- <pack "..modname.."> --" -- error message keep the first 45 chars max
	self:print_no_nl(
		b .. d .."\n"
		.. quote(self:autoeol(self:extractshebang(self:cat(modpath))))
		.. e .."\n"
	)
	--integrity_modcount_incr() -- for integrity check
end

function aio_class:raw2_pack_finish() -- without aioruntime
	if self.raw2_pack_init_done and not self.raw2_pack_finish_done then
		self.raw2_pack_finish_done = not self.raw2_pack_finish_done

		self:print_no_nl(
[[local loadstring=_G.loadstring or _G.load; local preload = ]] ..( self.config.preload or [[require"package".preload]] ).. "\n"..
[[local add = function(name, rawcode)
	if not preload[name] then
	        preload[name] = function(...) return assert(loadstring(rawcode), "loadstring: "..name.." failed")(...) end
	else
		print("WARNING: overwrite "..name)
	end
end
for name, rawcode in pairs(sources) do add(name, rawcode, priorities[name]) end
end; --}};
]])

		self.raw2_pack_init_done = false
	end
end

--## /modraw ##--

--## suite de mods ##--


function aio_class:mode(newmode)
	local config = self.config
	if not config.validmodes[newmode] then
		error("invalid mode "..tostring(newmode), 2)
	end
	config.mode = newmode
end

function aio_class:inpreload(preload)
	assert( preload==nil or type(preload)=="string", "argument #1 must be a lua code string")
	self.config.preload = preload
end

function aio_class:luamod(name, file)
	self:lua_pack_mod(name, file)
end

function aio_class:rawmod(name, file)
        if self.config.mode == "raw2" then
                self:raw2_pack_mod(name, file)
        else
                self:raw_pack_mod(name, file)
        end
end

function aio_class:mod(name, file)
	local mods = self.config.validmodes
	local mode = self.config.mode
	if not mods[mode] then
		error("invalid mode "..tostring(mode), 2)
	end
	if mode == "lua" then
		self:lua_pack_mod(name, file)
	elseif mode == "raw" then
		self:raw_pack_mod(name, file)
	elseif mode == "raw2" then
		self:raw2_pack_mod(name, file)
	end
end

function aio_class:finish()
	local mods = self.config.validmodes
	local mode = self.config.mode
	if not mods[mode] then
		error("invalid mode "..mode, 2)
	end
	if self[mode.."_pack_finish"] then
		self[mode.."_pack_finish"](self)
	end
        self:finish_print()
end


--local integrity = require "aio.integrity"
--if integrity then
--	M.icheck	= assert(integrity.cmd_icheck)
--	M.ichechinit	= assert(integrity.cmd_icheckinit)
--end

--local rock = require "aio.rock"
--
--for k,v in pairs(rock) do
--	if type(v) == "function" then
--		rock[k] = wrap(v)
--	end
--end
--
--M.rock = assert(rock)




function aio_class:rock_file(file)
	local compat_env
	pcall( function() compat_env = require "compat_env" end )
--	compat_env = compat_env or pcall( require, "mom" ) and require "compat_env"
--FIXME: compatenv w/loadfile
	local loadfile = assert(compat_env.loadfile)
	local ok, err = loadfile(file, "t", self.rockspec)

	--[[
	local fd = io.open(file, "r")
	local content = fd:read("*a")
	fd:close()
	local ok, err = load(content, file, "t", self.rockspec)
	]]--

	if not ok then
		error(err, 2)
	end
	ok()

	local build = self.rockspec.build
	if not( type(build) == "table" and type(build.type) == "string") then
		return nil, "invalid rockspec file "..file
	end
	self.rockfile = file
end

function aio_class:rock_mod(where, but)
	local build = self.rockspec.build
	if where ~= "build.modules" then
		error("not implemented yet [1a]", 2)
	end
	local modules = build.modules

	if build.type == "builtin" then
		if type(modules) ~= "table" then
			error("missing build.modules table in file "..self.rockfile ,2)
		end

		local Done = {}
		-- try to support order with i-table items
		for _,modname in ipairs(modules) do
			if not Done[modname] and modname ~= but then
				local modfile = modules[modname]
				Done[modname] = true
				if type(modname) == "string" and type(modfile) == "string" then
					self:mod(modname, modfile)
				end
			end
		end
		for modname,modfile in pairs(modules) do
			if type(modname) == "string" and not Done[modname] and modname ~= but then
				Done[modname] = true
				if type(modname) == "string" and type(modfile) == "string" then
					self:mod(modname, modfile)
				end
			end
		end
	elseif build.type == "none" then
		-- .install.lua ?
		error(self.rockfile..": build.type == none", 2)
	elseif build.type == "make" then
		error(self.rockfile..": use make, skipped", 2)
	else
		error(self.rockfile..": build.type == "..build.type, 2)
	end
end

function aio_class:rock_get_binfile()
	local build = self.rockspec.build
	local t_bin = build and build.install and build.install.bin

	if not t_bin then return nil end

	local cnt = 0
	for _k,_v in pairs(t_bin) do
		cnt=cnt+1
	end
	if cnt>1 then
		return nil
		--error(where.." containts more than one entry in file "..self.rockfile, 2)
	end
	local _k, v = next(t_bin)
	return v
end

function aio_class:rock_code(where)
	--local build = self.rockspec.build
	if where ~= "build.install.bin" and where ~= "build.install.lua" then
		error("not implemented yet [2a]", 2)
	end

	assert(where == "build.install.bin")
	local v = self:rock_get_binfile()
	self:code(v)
end

function aio_class:rock_auto(rockfile, modname, custom)
	local rockspec = self.rockspec
	self:rock_file(rockfile)
	local file
	if modname then
		file = self:rock_get_binfile() or
			rockspec.build and rockspec.build.modules and (
				rockspec.build.modules[modname] or
				rockspec.build.modules[modname..".init"]
			)
		assert(file)
	end
	if file then
		self:shebang(file)
		self:shellcode(file)
	end
	if type(custom) == "function" then
		custom()
	end
	self:rock_mod("build.modules", modname)
	self:finish()
	self:autoaliases()
	if file then
		self:code(file)
	end
	self:finish()
end

local exposed = {
	"shebang",
	"code",
	"codehead", -- obsolete
	"shellcode",
	"vfile",
	"autoaliases",
	"require",
	"luacode",
	"mode",
	"inpreload",
	"luamod",
	"rawmod",
	"mod",
	"finish",
	-- rocks
	"rock_file",
	"rock_mod",
	"rock_code",
	"rock_auto",
}

local definst = instance(aio_class)

local function wrapall(M, definst, meths)
	for _i,meth in ipairs(meths) do
		assert(definst[meth], "no such method "..meth)
		M[meth] = function(...)
			return definst[meth](definst, ...)
			--return M
		end
	end
end

wrapall(M, definst, exposed)

M.rock = {
	file = M.rock_file,
	mod  = M.rock_mod,
	code = M.rock_code,
	auto = M.rock_auto,
}

--setmetatable(M, {__call = function(_self, ...) return instance(aio_class, ...) end})

return M
