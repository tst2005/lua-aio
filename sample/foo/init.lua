local M = {_NAME="foo"}
M.sub1 = require "foo.subpart1"
M.sub2 = require "foo.subpart2"
return M
