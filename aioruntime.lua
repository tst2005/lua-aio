
local priorities = {}
local loadstring=_G.loadstring or _G.load; local preload = require"package".preload

--[[
local unpack = table.unpack or _G.unpack
local list_by_col = function()
		print("preload:")
		local buf = {}
		local max = 5
		local sizemax = 0
		local hand = function(buf)
			return ("%-"..(sizemax+1).."s"):rep(#buf):format(unpack(buf))
		end
		local keys = {}
		for k in pairs(preload) do keys[#keys+1]=k end
		table.sort(keys)
		local all = {}
		for _,k in pairs(keys) do
			sizemax = (#k>sizemax) and #k or sizemax
			if #buf >= max then
				all[#all+1] = buf
				buf = {}
			end
			buf[#buf+1] = k
		end
		if #buf > 0 then
			all[#all+1] = buf
		end
		buf = nil
		for _,g in ipairs(all) do
			print(hand(g))
		end
		return
end
]]--

local count = function()
	local KB, x = collectgarbage"count"
	return ("%1.1f MB"):format( KB / 1024 ), x
end

local _M = {
	add = function(name, rawcode, pri)
		--print("add", name, #rawcode, pri)
		local p = priorities[name]
		if not preload[name] or p and (pri or 0) > p then
			priorities[name] = pri or 0
			if preload[name] then
				print( "overwrite "..name)
			end
			preload[name] = function(...) return assert(loadstring(rawcode), "loadstring: "..name.." failed")(...) end
--		else
--			print( ("module %q not overwritten"):format(name), "p", p, "pri", pri )
		end
	end,
	list = function(self)
		print("preload:")
		local keys = {}
		for k in pairs(preload) do keys[#keys+1]=k end --("%-10s"):format(k) end
		table.sort(keys)
		for _,k in ipairs(keys) do
			print(" - "..k)
		end
		--print(table.concat(keys, "\n"))
		return self
	end,
	gcstop = function(self)
		collectgarbage"stop"
		print(count() )
		return self
	end,
	gcstart = function(self)
		print(count())
		collectgarbage"restart"
		print(count())
		return self
	end,
	compact = function(self)
		print("avant:", count() )
		for k in pairs(preload) do
			preload[k]=nil
		end
		collectgarbage("collect")
		print("apres:", count() )
		return self
	end,
	count = function(self) print( count() ) return self end,
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
