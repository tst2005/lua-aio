local fback = require "bootstrap.fallback"
local load = fback.load or _G.load

local env = {require = fback.require, package=fback.package}
env._G = env
setmetatable(env, {__index = _G})

local luacode = [[return require 'foo']]
local M = assert(load(luacode, luacode, "t", env), "load fail")()
assert(M and M._NAME)

return M
