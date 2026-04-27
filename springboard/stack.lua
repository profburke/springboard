local kind = require "springboard.kind"
local grid = require "springboard.grid"
local stack_mt = {}

stack_mt.__tostring = function(w)
   return string.format("<stack: %s>", w.name or "opaque")
end

kind.register(stack_mt, "stack")

local stack = {}
stack.__meta = stack_mt
stack_mt.__index = stack

stack.support = function()
   return "movable"
end

stack.is_opaque = function()
   return true
end

stack.is_editable = function()
   return false
end

stack.is_movable = function()
   return true
end

stack.grid_size = function(self)
   return grid.normalize(self.gridSize)
end

stack.slot_size = function(self)
   return grid.size(self.gridSize)
end

stack.slot_count = function(self)
   local size = self:slot_size()
   return size and size.slots or nil
end

return stack
