local kind = require "springboard.kind"
local app_mt = {}

app_mt.__tostring = function(app)
   return app.name
end

kind.register(app_mt, "app")

local app = {}
app.__meta = app_mt
app_mt.__index = app

app.support = function()
   return "movable"
end

app.is_opaque = function()
   return false
end

app.is_editable = function()
   return false
end

app.is_movable = function()
   return true
end

app.slot_count = function()
   return 1
end

return app
