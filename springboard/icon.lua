local format = string.format
local kind = require "springboard.kind"
local icon_mt = {}


icon_mt.__tostring = function(i)
   return i.name
end

kind.register(icon_mt, "icon")

local icon = {}
icon.__meta = icon_mt
icon_mt.__index = icon


return icon
