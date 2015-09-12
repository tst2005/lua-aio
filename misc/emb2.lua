
local name = "test"
local rawcode = [[
local _M = {}
_M._VERSION = "test 0.0.1"
function _M:print()
	print(self._VERSION)
end
return _M
]]

local loadstring = loadstring
require"package".preload[name]=(function()return function(...)return assert(loadstring(rawcode))(...) end end)()


