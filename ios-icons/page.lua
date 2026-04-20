local format = string.format
local kind = require "ios-icons.kind"


local page_mt = {}
page_mt.__tostring = function(p)
   local result = "{\n"
   local count = 0
   for _, i in ipairs(p) do
      result = result .. "  " .. tostring(i) .. "\n"
      count = count + 1
      if count % 4 == 0 then
         result = result .. "\n"
         count = 0
      end
   end

   result = result .. "}\n"
   return result
end

kind.register(page_mt, "page")

local page = {}
page.__meta = page_mt
page_mt.__index = page


return page
