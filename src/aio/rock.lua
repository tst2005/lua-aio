
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
	local compat_env
	pcall( function() compat_env = require "compat_env" end )
	compat_env = compat_env or pcall( require, "mom" ) and require "compat_env"

	local loadfile = assert(compat_env.loadfile)
	local ok, err = loadfile(file, "t", rockspec)

	--[[
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
