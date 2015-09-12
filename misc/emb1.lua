
local loadstring = loadstring
local function newpreloadfunc(name, rawcode)
	return function(...)
                return assert(loadstring(rawcode))(...)
        end
end


local rawcode = [[
local _M = {}
_M._VERSION = "test 0.0.1"
function _M:print()
	print(self._VERSION)
end
return _M
]]
local name = "test"
require"package".preload[name] = newpreloadfunc(name, rawcode)


