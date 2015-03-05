--[[
do -- package block
	local package = require("package")
	do
		local _tmp_
		do
			local package -- refuse to catch package upvalue
			function _tmp_(...)
print("THE MODULE CODE HERE")
			end -- function _tmp_
		end
		package.preload["XXXXX"] = _tmp_
	end
end
]]--

--[[
do
	require("package").preload["XXXXX"] = (
	function()
		local package
		return function(...)
			return {"THE MODULE CODE HERE"}
		end
	end)()
end
]]--

--[[
do require("package").preload["XXXXX"] = (function() local package;return function(...)
	return {"THE MODULE CODE HERE"}
end end)()end
]]--

