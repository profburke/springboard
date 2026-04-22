local kind = require "springboard.kind"
local widget_mt = {}

widget_mt.__tostring = function(w)
   return string.format("<widget: %s>", w.name or "opaque")
end

kind.register(widget_mt, "widget")

local widget = {}
widget.__meta = widget_mt
widget_mt.__index = widget

local grid_sizes = {
   small = { width = 2, height = 2, slots = 4 },
   medium = { width = 4, height = 2, slots = 8 },
   large = { width = 4, height = 4, slots = 16 },
}

widget.support = function()
   return "opaque"
end

widget.is_opaque = function()
   return true
end

widget.is_editable = function()
   return false
end

widget.grid_size = function(self)
   return self.gridSize
end

widget.slot_size = function(self)
   return grid_sizes[self:grid_size()]
end

widget.slot_count = function(self)
   local size = self:slot_size()
   return size and size.slots or nil
end

return widget
