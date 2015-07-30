
```lua
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
```

```lua
do
	require("package").preload["XXXXX"] = (
	function()
		local package
		return function(...)
			return {"THE MODULE CODE HERE"}
		end
	end)()
end
```

```lua
do require("package").preload["XXXXX"] = (function() local package;return function(...)
	return {"THE MODULE CODE HERE"}
end end)()end
```

```lua
local loadstring=loadstring;(function(name, rawcode) require"package".preload[name]=function(...)return assert(loadstring(rawcode))(...) end
local rawcode = [[THE MODULE CODE HERE]]
local loadstring=loadstring;require"package".preload["XXXXX"]=(function()return function(...)return assert(loadstring(rawcode))(...) end end)()
```

```lua
local loadstring = loadstring
local function newpreloadfunc(name, rawcode)
	return function(...)
                return assert(loadstring(rawcode))(...)
        end
end
```

```lua
local rawcode = [[THE MODULE CODE HERE]]
local name = "test"
require"package".preload[name] = newpreloadfunc(name, rawcode)
```

```lua
local name = "test"
local rawcode = [[THE MODULE CODE HERE]]
local loadstring = loadstring;require"package".preload[name]=(function()return function(...)return assert(loadstring(rawcode))(...) end end)()
```

```lua
local loadstring=loadstring;(function(name, rawcode)require"package".preload[name]=function(...)return assert(loadstring(rawcode))(...)end;end)("test",[[
THE MODULE CODE HERE
]])
```

