do --{{
local sources, priorities = {}, {};assert(not sources["bootstrap.fallback"],"module already exists")sources["bootstrap.fallback"]=([===[-- <pack bootstrap.fallback> --

-- ----------------------------------------------------------

--local assert = assert
local error, ipairs, type = error, ipairs, type
local format = string.format
--local loadfile = loadfile

local function lassert(cond, msg, lvl)
	if not cond then
		error(msg, lvl+1)
	end
	return cond
end
local function checkmodname(s)
	local t = type(s)
	if t == "string" then
	        return s
	elseif t == "number" then
		return tostring(s)
	else
		error("bad argument #1 to `require' (string expected, got "..t..")", 3)
	end
end
--
-- iterate over available searchers
--
local function iload(modname, searchers)
	lassert(type(searchers) == "table", "`package.searchers' must be a table", 2)
	local msg = ""
	for _, searcher in ipairs(searchers) do
		local loader, param = searcher(modname)
		if type(loader) == "function" then
			return loader, param -- success
		end
		if type(loader) == "string" then
			-- `loader` is actually an error message
			msg = msg .. loader
		end
	end
	error("module `" .. modname .. "' not found: "..msg, 2)
end

local function bigfunction_new(with_loaded)

	local _PACKAGE = {}
	local _LOADED = with_loaded or {}
	local _SEARCHERS  = {}

	--
	-- new require
	--
	local function _require(modname)

		modname = checkmodname(modname)
		local p = _LOADED[modname]
		if p then -- is it there?
			return p -- package is already loaded
		end

		local loader, param = iload(modname, _SEARCHERS)

		local res = loader(modname, param)
		if res ~= nil then
			p = res
		elseif not _LOADED[modname] then
			p = true
		else
			p = _LOADED[name]
		end

		_LOADED[modname] = p
		return p
	end

	_LOADED.package = _PACKAGE
	do
		local package = _PACKAGE
		package.loaded		= _LOADED
		package.searchers	= _SEARCHERS
	end
	return _require, _PACKAGE
end -- big function

local new = bigfunction_new

local with_loaded = {}
local _require, _PACKAGE = new(with_loaded)
local searchers = _PACKAGE.searchers

-- [keep] 0) already loaded package (in _PACKAGE.loaded)
-- [keep] 1) local submodule will be stored in _PACKAGE.preload[?]
-- [new ] 2) uplevel require() (follow uplevel's loaded/preload/...)
-- [new ] 3) fallback -> search in preload table but with a suffix name "fallback."

--
-- check whether library is already loaded
--
local _PRELOAD = {}
_PACKAGE.preload = _PRELOAD
local function searcher_preload(name)
	lassert(type(name) == "string", format("bad argument #1 to `require' (string expected, got %s)", type(name)), 2)
	lassert(type(_PRELOAD) == "table", "`package.preload' must be a table", 2)
	return _PRELOAD[name]
end
table.insert(searchers, searcher_preload)

--
local function search_uplevel(modname)
	local ok, ret = pcall(require, modname)
	if not ok then return false end
	return function() return ret end
end
table.insert(searchers, search_uplevel)

--
local function search_fallback(modname)
	return _PRELOAD["fallback." .. modname]
end
table.insert(searchers, search_fallback)

return setmetatable({require = _require, package = _PACKAGE}, {__call = function(_self, ...) return _require(...) end})
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
local loadstring=_G.loadstring or _G.load; local preload = require"package".preload
local add = function(name, rawcode)
	if not preload[name] then
	        preload[name] = function(...) return assert(loadstring(rawcode), "loadstring: "..name.." failed")(...) end
	else
		print("WARNING: overwrite "..name)
	end
end
for name, rawcode in pairs(sources) do add(name, rawcode, priorities[name]) end
end; --}};
local fallback = require "bootstrap.fallback"
local _require = fallback.require -- or directly fallback
local _preload = fallback.package.preload
local env

do --{{
local sources, priorities = {}, {};assert(not sources["foo.common"],"module already exists")sources["foo.common"]=([===[-- <pack foo.common> --
return {_NAME="foo.common"}
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["foo.subpart2"],"module already exists")sources["foo.subpart2"]=([===[-- <pack foo.subpart2> --
local common = require "foo.common"
common.subpart2 = "loaded"
return {_NAME="foo.subpart2"}
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["foo"],"module already exists")sources["foo"]=([===[-- <pack foo> --
local M = {_NAME="foo"}
M.sub1 = require "foo.subpart1"
M.sub2 = require "foo.subpart2"
return M
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')
assert(not sources["foo.subpart1"],"module already exists")sources["foo.subpart1"]=([===[-- <pack foo.subpart1> --
local common = require "foo.common"
common.subpart1 = "loaded"
return {_NAME="foo.subpart1"}
]===]):gsub('\\([%]%[]===)\\([%]%[])','%1%2')

local fback = require "bootstrap.fallback"
local load = fback.load or _G.load

env = {
	require = fback.require,
	package = fback.package
}
env._G = env
setmetatable(env, {__index = _G})

local load=assert(_G.load); local preload = _preload
local add = function(name, rawcode)
	if not preload[name] then
	        preload[name] = function(...) return assert(load(rawcode, rawcode, "t", env), "load: "..name.." failed")(...) end
	else
		print("WARNING: overwrite "..name)
	end
end
for name, rawcode in pairs(sources) do add(name, rawcode, priorities[name]) end
end; --}};

print("<foo>")
print("in package.preload:")
for k,v in pairs(require"package".preload) do print(" -",k,type(v)) end
--print("in package.loaded:")
--for k,v in pairs(require"package".loaded) do print(" -",k,type(v)) end

local fback = require "bootstrap.fallback"
assert(fback.package.preload == fback.require"package".preload)
print("in shadow.package.preload:")
for k,v in pairs(fback.package.preload) do print(" -",k,type(v)) end
--print("in shadow.package.loaded:")
--for k,v in pairs(fback.package.loaded) do print(" -",k,type(v)) end


--print("outside: require=", env.require)
local luacode = [[return require 'foo']]
local M = assert(load(luacode, luacode, "t", env), "load fail")()
assert(M and M._NAME)
print("shadow.require \"foo\" =", M)
print("</foo>")

return M
