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

local function visit_all_items(items, visitor)
   for _, value in ipairs(items) do
      if kind.is(value, "page") then
         visit_all_items(value, visitor)
      else
         visitor(value)
         if kind.is(value, "folder") then
            visit_all_items(value.items, visitor)
         end
      end
   end
end

local function contains_or_matches(value, pat)
   if type(pat) ~= "string" then
      return false
   end

   return string.find(value, pat, 1, true) ~= nil
      or string.find(value, pat) ~= nil
end

local function is_movable_container_item(value)
   return kind.is(value, "app") or kind.is(value, "folder")
end

local function assert_app_item(value, operation)
   if not kind.is(value, "app") then
      error(string.format("%s only supports app items; found %s", operation, kind.of(value)))
   end
end

local function assert_page_table(value, operation)
   if type(value) ~= "table" then
      error(string.format("%s requires a page table; found %s", operation, type(value)))
   end
end

local function remove_from_items(items, target)
   for idx, value in ipairs(items) do
      if value == target then
         table.remove(items, idx)
         return true
      end

      if kind.is(value, "folder") and remove_from_items(value.items or {}, target) then
         return true
      end
   end

   return false
end

local function assert_movable_container_items(items, operation)
   for idx, value in ipairs(items) do
      if not is_movable_container_item(value) then
         error(string.format(
            "%s only supports app and folder items; found %s at index %d",
            operation,
            kind.of(value),
            idx
         ))
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
   local insert = table.insert
   local result = {}

   for _, value in ipairs(tab:flatten()) do
      if contains_or_matches(value.name or "", pat) then
         insert(result, value)
      end
   end

   return result
end

layout.find = function(tab, pat)
   for _, value in ipairs(tab:flatten()) do
      if contains_or_matches(value.name or "", pat) then
         return value
      end
   end

   return nil
end

layout.find_id = function(tab, pat)
   for _, value in ipairs(tab:flatten()) do
      if contains_or_matches(value.id or "", pat) then
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

layout.visit_items = function(tab, visitor)
   assert(type(visitor) == "function", "visitor must be a function")

   each_page(tab, function(current)
      visit_all_items(current, visitor)
   end)
end

layout.opaque_items = function(tab)
   local insert = table.insert
   local result = {}

   tab:visit_items(function(item)
      if kind.is(item, "widget") or kind.is(item, "stack") or kind.is(item, "unknown") then
         insert(result, item)
      end
   end)

   return result
end

layout.has_opaque_items = function(tab)
   return #tab:opaque_items() > 0
end

layout.remove_app = function(tab, app)
   assert_app_item(app, "layout.remove_app")

   local removed = false
   each_page(tab, function(current)
      if not removed then
         removed = remove_from_items(current, app)
      end
   end)

   return removed
end

layout.move_app_to_folder = function(tab, app, folder)
   assert_app_item(app, "layout.move_app_to_folder")
   if not kind.is(folder, "folder") then
      error(string.format("layout.move_app_to_folder requires a folder; found %s", kind.of(folder)))
   end

   if not tab:remove_app(app) then
      return false
   end

   folder.items = folder.items or {}
   table.insert(folder.items, app)
   return true
end

layout.move_app_to_page = function(tab, app, target_page, position)
   assert_app_item(app, "layout.move_app_to_page")
   assert_page_table(target_page, "layout.move_app_to_page")

   if not tab:remove_app(app) then
      return false
   end

   table.insert(target_page, position or (#target_page + 1), app)
   return true
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

   assert_movable_container_items(tab, "layout.reshape")

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
