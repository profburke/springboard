local kind = require "ios-icons.kind"
local stack_mt = {}

stack_mt.__tostring = function(w)
   return "<stack: tbd>"
end

kind.register(stack_mt, "stack")

local stack = {}
stack.__meta = stack_mt
stack_mt.__index = stack

return stack
