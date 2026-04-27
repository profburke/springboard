local kind = require "springboard.kind"
local grid = require "springboard.grid"
local widget_mt = {}

widget_mt.__tostring = function(w)
   return string.format("<widget: %s>", w.name or "opaque")
end

kind.register(widget_mt, "widget")

local widget = {}
widget.__meta = widget_mt
widget_mt.__index = widget

widget.support = function()
   return "movable"
end

widget.is_opaque = function()
   return true
end

widget.is_editable = function()
   return false
end

widget.is_movable = function()
   return true
end

widget.grid_size = function(self)
   return grid.normalize(self.gridSize)
end

widget.slot_size = function(self)
   return grid.size(self.gridSize)
end

widget.slot_count = function(self)
   local size = self:slot_size()
   return size and size.slots or nil
end

return widget
