local insert = table.insert
local kind = require "ios-icons.kind"
local fn = {}


local append = function(a, b)
   for _, v in ipairs(b) do
      insert(a, v)
   end
end


fn.select = function(tab, cond)
   assert(type(cond) == 'function', 'cond must be a predicate')
   local t = tab
   local result = {}

   if kind.is(t, "folder") then
      t = t.icons
   end
   
   for _,v in pairs(t) do
      if kind.is(v, "folder") then
         local fresult = fn.select(v.icons, cond)
         append(result, fresult)
      elseif kind.is(v, "page") then
         local fresult = fn.select(v, cond)
         append(result, fresult)
      elseif kind.is(v, "icon") then
         if cond(v) then
            insert(result, v)
         end
      end
   end

   return result
end



return fn
