local kind = require "ios-icons.kind"
local widget_mt = {}

widget_mt.__tostring = function(w)
   return "<widget: tbd>"
end

kind.register(widget_mt, "widget")

local widget = {}
widget.__meta = widget_mt
widget_mt.__index = widget

return widget
