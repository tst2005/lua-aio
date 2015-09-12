
local _M = {}
_M._VERSION = "0.0.1"
function _M:print()
	print([[test]].." "..self._VERSION)
end
return _M

