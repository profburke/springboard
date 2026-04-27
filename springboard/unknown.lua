local kind = require "springboard.kind"
local unknown_mt = {}

unknown_mt.__tostring = function(item)
   return string.format("<unknown: %s>", item.name or item.id or item.ref or "opaque")
end

kind.register(unknown_mt, "unknown")

local unknown = {}
unknown.__meta = unknown_mt
unknown_mt.__index = unknown

unknown.support = function()
   return "opaque"
end

unknown.is_opaque = function()
   return true
end

unknown.is_editable = function()
   return false
end

unknown.is_movable = function()
   return false
end

return unknown
