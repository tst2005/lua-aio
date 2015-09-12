
do
local sources = {}

sources["test"]=[[
local _M = {}
_M._VERSION = "test 0.0.1"
function _M:print()
	print(self._VERSION)
end
return _M
]]

sources["test2"]=[[
return {print=function() print("test2 0.0.1") end}
]]

local loadstring=loadstring; local preload = require"package".preload
for name, rawcode in pairs(sources) do
	preload[name]=function(...)return loadstring(rawcode)(...)end
end
end --/do
