local kind = require "springboard.kind"
local widget_mt = {}

widget_mt.__tostring = function(w)
   return string.format("<widget: %s>", w.name or "opaque")
end

kind.register(widget_mt, "widget")

local widget = {}
widget.__meta = widget_mt
widget_mt.__index = widget

widget.support = function()
   return "opaque"
end

widget.is_opaque = function()
   return true
end

widget.is_editable = function()
   return false
end

return widget
