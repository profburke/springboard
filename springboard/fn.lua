local insert = table.insert
local kind = require "springboard.kind"
local fn = {}


local append = function(a, b)
   for _, v in ipairs(b) do
      insert(a, v)
   end
end


fn.select = function(tab, cond)
   assert(type(cond) == 'function', 'cond must be a predicate')
   local result = {}

   local function collect(items)
      for _, value in ipairs(items) do
         if kind.is(value, "folder") then
            collect(value.items)
         elseif kind.is(value, "page") then
            collect(value)
         elseif kind.is(value, "app") then
            if cond(value) then
               insert(result, value)
            end
         end
      end
   end

   if kind.is(tab, "layout") then
      collect(tab.dock)
      for _, page in ipairs(tab.pages) do
         collect(page)
      end
   elseif kind.is(tab, "folder") then
      collect(tab.items)
   else
      collect(tab)
   end

   return result
end



return fn
