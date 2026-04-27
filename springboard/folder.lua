local format = string.format
local kind = require "springboard.kind"
local folder_mt = {}


folder_mt.__tostring = function(f)
   return format('<folder: %s>', f.name)
end

kind.register(folder_mt, "folder")

local folder = {}
folder.__meta = folder_mt
folder_mt.__index = folder

folder.support = function()
   return "movable"
end

folder.is_opaque = function()
   return false
end

folder.is_editable = function()
   return false
end

folder.is_movable = function()
   return true
end

folder.slot_count = function()
   return 1
end

folder.count = function(f)
   return #(f.items or {})
end

return folder
