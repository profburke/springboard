local graphics = {}
local image = require "springboard.features.image"
local fn = require "springboard.fn"

function graphics.attach(layout, conn)
   if not layout then error("layout must be provided") end
   if not conn then error("connection must be provided") end

   layout:visit(function(app)
      if app.bundleIdentifier then
         app.imagedata = function() return conn:app_image(app) end
         app.image = image.new(app)
      end
   end)

   layout.with_image = function(tbl)
      return fn.select(tbl:flatten(), function(i) return i.image end)
   end

   layout.with_color = function(tbl, c)
      return fn.select(tbl:with_image(), function(i)
         return i.image.color() == c
      end)
   end

   layout.with_hue_range = function(tbl, lo, hi)
      return fn.select(tbl:with_image(), function(i)
         local h = i.image.hsv()
         return h >= lo and h <= hi
      end)
   end

   layout.dark = function(tbl)
      return fn.select(tbl:with_image(), function(i)
         return i.image.is_dark()
      end)
   end

   layout.cache_colors = function(current_layout)
      for _, i in ipairs(current_layout:with_image()) do
         i.image.color()
      end
   end

   return layout
end

graphics.on_layout = graphics.attach

return graphics
