local kind = require "springboard.kind"
local page = require "springboard.page"
local layout_mt = {}

local function wrap_page(items)
   if kind.is(items, "page") then
      return items
   end

   return setmetatable(items or {}, page.__meta)
end

local function each_page(layout, visitor)
   visitor(layout.dock, true)
   for _, current in ipairs(layout.pages) do
      visitor(current, false)
   end
end

local function visit_items(items, visitor)
   for _, value in ipairs(items) do
      if kind.is(value, "folder") then
         visit_items(value.items, visitor)
      elseif kind.is(value, "page") then
         visit_items(value, visitor)
      elseif kind.is(value, "app") then
         visitor(value)
      end
   end
end

layout_mt.__tostring = function(layout)
   local result = "Layout\n\n"

   result = result .. "Dock " .. tostring(layout.dock)
   for idx, current in ipairs(layout.pages) do
      result = result .. "Page " .. idx .. " " .. tostring(current)
   end

   result = result .. "\n"
   return result
end

kind.register(layout_mt, "layout")

local layout = {}
layout.__meta = layout_mt
layout_mt.__index = layout

layout.new = function(dock, pages)
   local normalized_pages = {}

   for idx, current in ipairs(pages or {}) do
      normalized_pages[idx] = wrap_page(current)
   end

   return setmetatable({
      dock = wrap_page(dock),
      pages = normalized_pages,
   }, layout_mt)
end

layout.flatten = function(tab)
   local insert = table.insert
   local result = {}

   each_page(tab, function(current)
      visit_items(current, function(app)
         insert(result, app)
      end)
   end)

   return result
end

layout.find_all = function(tab, pat)
   local strfind = string.find
   local insert = table.insert
   local result = {}

   for _, value in ipairs(tab:flatten()) do
      if strfind(value.name or "", pat) then
         insert(result, value)
      end
   end

   return result
end

layout.find = function(tab, pat)
   local strfind = string.find

   for _, value in ipairs(tab:flatten()) do
      if strfind(value.name or "", pat) then
         return value
      end
   end

   return nil
end

layout.find_id = function(tab, pat)
   local strfind = string.find

   for _, value in ipairs(tab:flatten()) do
      if strfind(value.id or "", pat) then
         return value
      end
   end

   return nil
end

layout.visit = function(tab, visitor)
   assert(type(visitor) == "function", "visitor must be a function")

   each_page(tab, function(current)
      visit_items(current, visitor)
   end)
end

local dockMax = 4
local pageMax = 9
-- TODO: handle fillPercent
-- TODO: pass in page size as a parameter with a default (x = x or default)
layout.reshape = function(tab, fillPercent)
   local pages = {}
   local dock = {}
   local current_page = {}
   local count = 1
   local insert = table.insert

   for i, value in ipairs(tab) do
      if i < dockMax then
         insert(dock, value)
      elseif i == dockMax then
         insert(dock, value)
         current_page = {}
         count = 1
      elseif count % pageMax ~= 0 then
         insert(current_page, value)
         count = count + 1
      else
         insert(current_page, value)
         insert(pages, wrap_page(current_page))
         current_page = {}
         count = 1
      end
   end

   if #current_page > 0 then
      insert(pages, wrap_page(current_page))
   end

   return layout.new(wrap_page(dock), pages)
end

return layout
