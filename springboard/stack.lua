local kind = require "springboard.kind"
local stack_mt = {}

stack_mt.__tostring = function(w)
   return string.format("<stack: %s>", w.name or "opaque")
end

kind.register(stack_mt, "stack")

local stack = {}
stack.__meta = stack_mt
stack_mt.__index = stack

stack.support = function()
   return "opaque"
end

stack.is_opaque = function()
   return true
end

stack.is_editable = function()
   return false
end

return stack
