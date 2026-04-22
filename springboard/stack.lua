local kind = require "springboard.kind"
local stack_mt = {}

stack_mt.__tostring = function(w)
   return string.format("<stack: %s>", w.name or "opaque")
end

kind.register(stack_mt, "stack")

local stack = {}
stack.__meta = stack_mt
stack_mt.__index = stack

local grid_sizes = {
   small = { width = 2, height = 2, slots = 4 },
   medium = { width = 4, height = 2, slots = 8 },
   large = { width = 4, height = 4, slots = 16 },
}

stack.support = function()
   return "opaque"
end

stack.is_opaque = function()
   return true
end

stack.is_editable = function()
   return false
end

stack.grid_size = function(self)
   return self.gridSize
end

stack.slot_size = function(self)
   return grid_sizes[self:grid_size()]
end

stack.slot_count = function(self)
   local size = self:slot_size()
   return size and size.slots or nil
end

return stack
