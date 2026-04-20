local kind = require "springboard.kind"
local app_mt = {}

app_mt.__tostring = function(app)
   return app.name
end

kind.register(app_mt, "app")

local app = {}
app.__meta = app_mt
app_mt.__index = app

return app
