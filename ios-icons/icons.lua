local kind = require "ios-icons.kind"
local icons_mt = {}
icons_mt.__tostring = function(i)
   local result = "Icon Set\n\n"

   -- TODO: what if there are no icons in the dock? Is the first page still
   --       at index 2?
   
   result = result .. "Dock " .. tostring(i[1])

   for idx = 2,#i do
      result = result .. "Page " .. idx - 1 .. " " .. tostring(i[idx])
   end

   result = result .. "\n"
   return result
end

kind.register(icons_mt, "icons")

local icons = {}
icons.__meta = icons_mt
icons_mt.__index = icons



icons.flatten = function(tab)
   local insert = table.insert
   local result = {}
   
   local function flatten(tab)
      for _,v in pairs(tab) do
         if kind.is(v, "icon") then
            insert(result, v)
         elseif kind.is(v, "page") then
            flatten(v)
         elseif kind.is(v, "folder") then
            flatten(v.icons)
         end
      end
   end

   flatten(tab)
   return result
end




icons.dock = function(tab)
   return tab[1]
end




icons.find_all = function(tab, pat)
   local strfind = string.find
   local insert = table.insert
   local result = {}
   local all_icons = tab:flatten()

   for _,v in pairs(all_icons) do
      if strfind(v.name or '', pat) then
         insert(result, v)
      end
   end
   
   return result
end




icons.find = function(tab, pat)
   local strfind = string.find
   local all_icons = tab:flatten()

   for _,v in pairs(all_icons) do
      if strfind(v.name or '', pat) then
         return v
      end
   end
   
   return nil
end




icons.find_id = function(tab, pat)
   local strfind = string.find
   local all_icons = tab:flatten()

   for _,v in pairs(all_icons) do
      if strfind(v.id or '', pat) then
         return v
      end
   end

   return nil
end




icons.visit = function(tab, visitor)
   assert(type(visitor) == 'function', 'visitor must be a function')
   for _,v in pairs(tab) do
      if kind.is(v, "folder") then
         icons.visit(v.icons, visitor)
      elseif kind.is(v, "page") then
         icons.visit(v, visitor)
      elseif kind.is(v, "icon") then
         visitor(v)
      end
   end
end


local dockMax = 4
local pageMax = 9
-- TODO: handle fillPercent
-- TODO: pass in page size as a parameter with a default (x = x or default)
icons.reshape = function(tab, fillPercent)
   local result = {}
   local page = {}
   local count = 1
   local insert = table.insert
   
   for i,v in ipairs(tab) do
      if i < dockMax then
         insert(page, v)
      elseif i == dockMax then
         insert(page, v)
         insert(result, page)
         page = {}
         count = 1
      elseif count % pageMax ~= 0 then
         insert(page, v)
         count = count + 1
      else
         insert(page, v)
         insert(result, page)
         page = {}
         count = 1
      end
   end
   
   return result
end


return icons
