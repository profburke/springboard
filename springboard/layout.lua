local kind = require "springboard.kind"
local page = require "springboard.page"
local layout_mt = {}

local default_dock_capacity = 4
local default_page_capacity = 24

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
   return kind.is(value, "app")
      or kind.is(value, "folder")
      or kind.is(value, "widget")
      or kind.is(value, "stack")
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

local function item_slot_count(value)
   if type(value) ~= "table" then
      return nil
   end

   if kind.is(value, "app") or kind.is(value, "folder") then
      return 1
   end

   if (kind.is(value, "widget") or kind.is(value, "stack")) and type(value.slot_count) == "function" then
      return value:slot_count()
   end

   return nil
end

local function resolve_capacities(options)
   if options == nil then
      return default_dock_capacity, default_page_capacity
   end

   assert(type(options) == "table", "options must be a table")

   local dock_capacity = options.dock_capacity or default_dock_capacity
   local page_capacity = options.page_capacity or default_page_capacity

   assert(type(dock_capacity) == "number", "dock_capacity must be a number")
   assert(type(page_capacity) == "number", "page_capacity must be a number")
   assert(dock_capacity >= 0, "dock_capacity must be non-negative")
   assert(page_capacity > 0, "page_capacity must be positive")

   return dock_capacity, page_capacity
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
            "%s only supports app, folder, widget, and stack items; found %s at index %d",
            operation,
            kind.of(value),
            idx
         ))
      end

      local slots = item_slot_count(value)
      if slots == nil then
         error(string.format(
            "%s cannot determine slot size for %s at index %d",
            operation,
            kind.of(value),
            idx
         ))
      end
   end
end

local function collect_capacity_issues(items, limit, where, issues)
   local used = 0

   for _, item in ipairs(items) do
      local slots = item_slot_count(item)
      if slots == nil then
         table.insert(issues, {
            kind = "unknown_slot_footprint",
            item = item,
            location = where,
            message = string.format(
               "%s contains %s with unknown slot footprint",
               where,
               kind.of(item)
            ),
         })
      else
         used = used + slots
      end
   end

   if used > limit then
      table.insert(issues, {
         kind = where == "dock" and "dock_capacity" or "page_capacity",
         limit = limit,
         count = used,
         location = where,
         message = string.format("%s consumes %d slots; limit is %d", where, used, limit),
      })
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

layout.validate = function(tab, options)
   local issues = {}
   local folder_capacity = options and options.folder_capacity
   local dock_capacity = options and options.dock_capacity
   local page_capacity = options and options.page_capacity

   if folder_capacity ~= nil then
      assert(type(folder_capacity) == "number", "folder_capacity must be a number")
      tab:visit_items(function(item)
         if kind.is(item, "folder") and #(item.items or {}) > folder_capacity then
            table.insert(issues, {
               kind = "folder_capacity",
               item = item,
               limit = folder_capacity,
               count = #(item.items or {}),
               message = string.format(
                  "folder %s contains %d items; limit is %d",
                  item.name or item.ref or "<unnamed>",
                  #(item.items or {}),
                  folder_capacity
               ),
            })
         end
      end)
   end

   if dock_capacity ~= nil then
      assert(type(dock_capacity) == "number", "dock_capacity must be a number")
      collect_capacity_issues(tab.dock, dock_capacity, "dock", issues)
   end

   if page_capacity ~= nil then
      assert(type(page_capacity) == "number", "page_capacity must be a number")
      for index, current in ipairs(tab.pages) do
         collect_capacity_issues(current, page_capacity, string.format("page %d", index), issues)
      end
   end

   return issues
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
   return tab:move_item_to_page(app, target_page, position)
end

layout.remove_item = function(tab, item)
   if not is_movable_container_item(item) then
      error(string.format("layout.remove_item only supports movable items; found %s", kind.of(item)))
   end

   local removed = false
   each_page(tab, function(current)
      if not removed then
         removed = remove_from_items(current, item)
      end
   end)

   return removed
end

layout.move_item_to_page = function(tab, item, target_page, position)
   if not is_movable_container_item(item) then
      error(string.format("layout.move_item_to_page only supports movable items; found %s", kind.of(item)))
   end
   assert_page_table(target_page, "layout.move_item_to_page")

   if target_page == tab.dock and item_slot_count(item) ~= 1 then
      error(string.format("layout.move_item_to_page does not support %s in the dock", kind.of(item)))
   end

   if not tab:remove_item(item) then
      return false
   end

   table.insert(target_page, position or (#target_page + 1), item)
   return true
end

layout.reshape = function(tab, options)
   local pages = {}
   local dock = {}
   local current_page = {}
   local dock_slots = 0
   local page_slots = 0
   local dock_closed = false
   local insert = table.insert
   local dock_capacity, page_capacity = resolve_capacities(options)

   assert_movable_container_items(tab, "layout.reshape")

   for _, value in ipairs(tab) do
      local slots = item_slot_count(value)

      if slots > page_capacity then
         error(string.format(
            "layout.reshape cannot place %s consuming %d slots into page capacity %d",
            kind.of(value),
            slots,
            page_capacity
         ))
      end

      if not dock_closed and slots == 1 and dock_slots + slots <= dock_capacity then
         insert(dock, value)
         dock_slots = dock_slots + slots
      else
         dock_closed = true
         if page_slots + slots > page_capacity and #current_page > 0 then
            insert(pages, wrap_page(current_page))
            current_page = {}
            page_slots = 0
         end

         insert(current_page, value)
         page_slots = page_slots + slots
      end
   end

   if #current_page > 0 then
         insert(pages, wrap_page(current_page))
   end

   return layout.new(wrap_page(dock), pages)
end

return layout
