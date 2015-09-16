
--[[--------------------------------------------------------------------------
	-- Dragoon Framework - A Framework for Lua/LOVE --
	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
--]]--------------------------------------------------------------------------

------------------------------------------------------------------------------

local aio = require "aio.core"
cmd_shebang	= aio.shebang
cmd_luamod	= aio.luamod
cmd_rawmod	= aio.rawmod
cmd_mod 	= aio.mod
cmd_code	= aio.code
cmd_codehead	= aio.codehead
cmd_shellcode	= aio.shellcode
cmd_mode	= aio.mode
cmd_vfile	= aio.vfile
cmd_autoaliases	= aio.autoaliases
cmd_icheck	= aio.icheck
cmd_icheckinit	= aio.ichechinit
cmd_require	= aio.require
cmd_luacode	= aio.luacode
cmd_finish	= aio.finish


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

local function rock_mod(where)
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
		for _,modname in ipairs(modules) do
			if not Done[modname] then
				local modfile = modules[modname]
				Done[modname] = true
				if type(modname) == "string" or type(modfile) == "string" then
					cmd_mod(modname, modfile)
				end
			end
		end
		for modname,modfile in pairs(modules) do
			if type(modname) == "string" and not Done[modname] then
				Done[modname] = true
				if type(modname) == "string" or type(modfile) == "string" then
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

local function rock_auto(rockfile, modname)
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
	rock_mod("build.modules")
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
