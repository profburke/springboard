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


return folder
