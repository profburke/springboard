local image = {}

local cache = require "springboard.features.cache"
cache = cache.new("./.ios-icon-colors", function(app)
   return app.id .. ".rgb"
end)

local dark_cutoff = 100

local function hsv_to_color(h, s, v)
   if v < 60 then return "black"
   elseif s < 0.1 then return "gray"
   elseif h < 15 then return "red"
   elseif h < 45 then return "orange"
   elseif h < 80 then return "yellow"
   elseif h < 150 then return "green"
   elseif h < 250 then return "blue"
   else return "red"
   end
end

local function rgb_to_hsv(r, g, b)
   local sorted, min, max, v, delta, h, s

   sorted = { r, g, b }
   table.sort(sorted)
   min = sorted[1]
   max = sorted[3]
   v = max

   delta = max - min
   if max == 0 then
      s = 0
      h = -1
      return h, s, v
   else
      s = delta / max
   end

   if r == max then
      h = (g - b) / delta
   elseif g == max then
      h = 2 + (b - r) / delta
   else
      h = 4 + (r - g) / delta
   end

   h = h * 60
   if h < 0 then h = h + 360 end

   return h, s, v
end

local function graphics_magick(args)
   local cmd = { "gm", "convert" }
   for _, arg in ipairs(args) do
      cmd[#cmd + 1] = string.format("%q", arg)
   end

   local ok, _, rc = os.execute(table.concat(cmd, " "))
   if not ok or rc ~= 0 then
      error("GraphicsMagick command failed")
   end
end

function image.new(app)
   return {
      save = function(path)
         local fd = assert(io.open(path, "wb"))
         fd:write(app.imagedata())
         fd:close()
      end,

      rgb = function()
         local data = cache.get(app, app.image.make_rgb)
         local r, g, b = string.byte(data, 1, 3)
         return r, g, b
      end,

      make_rgb = function()
         local pngfile = os.tmpname() .. ".png"
         local rgbfile = os.tmpname() .. ".rgb"

         app.image.save(pngfile)
         graphics_magick({
            pngfile,
            "-colors", "16",
            "-resize", "1x1!",
            "RGB:" .. rgbfile,
         })

         local fd = assert(io.open(rgbfile, "rb"))
         local data = fd:read("*all")
         fd:close()
         os.remove(pngfile)
         os.remove(rgbfile)
         return data
      end,

      hsv = function()
         local r, g, b = app.image.rgb()
         return rgb_to_hsv(r, g, b)
      end,

      color = function()
         local h, s, v = app.image.hsv()
         local result = hsv_to_color(h, s, v)
         app.image.color = function() return result end
         return result
      end,

      is_dark = function()
         local _, _, v = app.image.hsv()
         return v < dark_cutoff
      end,
   }
end

return image
