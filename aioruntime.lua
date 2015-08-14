
local priorities = {}
local loadstring=loadstring; local preload = require"package".preload

local _M = {
	add = function(name, rawcode, pri)
		--print("add", name, #rawcode, pri)
		local p = priorities[name]
		if not preload[name] or p and (pri or 0) > p then
			priorities[name] = pri or 0
			if preload[name] then
				print( "overwrite "..name)
			end
			preload[name] = function(...) return assert(loadstring(rawcode))(...) end
--		else
--			print( ("module %q not overwritten"):format(name), "p", p, "pri", pri )
		end
	end,
}
return _M

--[[
local sources, priorities = {}, {}
]]--

--[[
local add
if not pcall(function() add = require"aioruntime".add end) then
	local loadstring=loadstring; local preload = require"package".preload
	add = function(name, rawcode)
		preload[name] = function(...) return loadstring(rawcode)(...) end
	end
end
for name, rawcode in pairs(sources) do add(name, rawcode, priorities[name]) end
]]--
