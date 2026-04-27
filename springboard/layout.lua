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

local function clone_item(item)
   if type(item) ~= "table" then
      return item
   end

   local copy = {}
   for key, value in pairs(item) do
      if key == "items" and kind.is(item, "folder") then
         local child_items = {}
         for index, child in ipairs(value or {}) do
            child_items[index] = clone_item(child)
         end
         copy[key] = child_items
      else
         copy[key] = value
      end
   end

   return setmetatable(copy, getmetatable(item))
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

local function matches_query(item, query)
   if type(query) == "function" then
      return query(item) == true
   end

   if type(query) ~= "string" then
      error(string.format("query must be a string or function; found %s", type(query)))
   end

   return contains_or_matches(item.name or "", query)
      or contains_or_matches(item.id or "", query)
      or contains_or_matches(item.ref or "", query)
      or contains_or_matches(item.widgetIdentifier or "", query)
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

local function assert_folder_item(value, operation)
   if not kind.is(value, "folder") then
      error(string.format("%s requires a folder; found %s", operation, kind.of(value)))
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

local function remove_from_container(container, index)
   if kind.is(container, "folder") then
      table.remove(container.items, index)
      return
   end

   table.remove(container, index)
end

local function insert_into_container(container, index, item)
   if kind.is(container, "folder") then
      if not kind.is(item, "app") then
         error(string.format("folder insertion only supports app items; found %s", kind.of(item)))
      end

      container.items = container.items or {}
      table.insert(container.items, index or (#container.items + 1), item)
      return
   end

   table.insert(container, index or (#container + 1), item)
end

local function container_items(container)
   if kind.is(container, "folder") then
      return container.items
   end

   return container
end

local function can_insert_into_container(tab, container, item)
   if kind.is(container, "folder") then
      return kind.is(item, "app")
   end

   if container == tab.dock then
      return item_slot_count(item) == 1
   end

   return is_movable_container_item(item)
end

local function ensure_folder_anchor(folder, anchor, operation)
   folder.items = folder.items or {}

   for index, item in ipairs(folder.items) do
      if item == anchor then
         return index
      end
   end

   error(string.format("%s requires an anchor already inside the folder", operation))
end

local function find_item_location_in_items(items, target, page_ref, parent_container)
   for index, value in ipairs(items) do
      if value == target then
         return {
            page = page_ref,
            container = parent_container or items,
            index = index,
         }
      end

      if kind.is(value, "folder") then
         local nested = find_item_location_in_items(value.items or {}, target, page_ref, value)
         if nested then
            return nested
         end
      end
   end

   return nil
end

local function find_item_location(tab, target)
   local location = find_item_location_in_items(tab.dock, target, tab.dock, nil)
   if location then
      return location
   end

   for _, current in ipairs(tab.pages) do
      location = find_item_location_in_items(current, target, current, nil)
      if location then
         return location
      end
   end

   return nil
end

local function apply_working_layout(target, source)
   for key in pairs(target) do
      target[key] = nil
   end

   for key, value in pairs(source) do
      target[key] = value
   end
end

local function page_index_of(tab, target_page)
   if target_page == tab.dock then
      return 0
   end

   for index, current in ipairs(tab.pages) do
      if current == target_page then
         return index
      end
   end

   return nil
end

local function resolve_working_page(tab, working, target_page)
   local page_index = page_index_of(tab, target_page)
   if page_index == nil then
      error("target page does not belong to layout")
   end

   if page_index == 0 then
      return working.dock
   end

   return working.pages[page_index]
end

local function find_item_by_ref(tab, ref)
   local found

   tab:visit_items(function(item)
      if not found and item.ref == ref then
         found = item
      end
   end)

   return found
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

layout.clone = function(tab)
   local pages = {}
   local dock = {}

   for index, item in ipairs(tab.dock or {}) do
      dock[index] = clone_item(item)
   end

   for page_index, current in ipairs(tab.pages or {}) do
      local cloned_page = {}
      for item_index, item in ipairs(current) do
         cloned_page[item_index] = clone_item(item)
      end
      pages[page_index] = wrap_page(cloned_page)
   end

   local copy = layout.new(wrap_page(dock), pages)
   for key, value in pairs(tab) do
      if key ~= "dock" and key ~= "pages" then
         copy[key] = value
      end
   end

   return copy
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

layout.find_page_of = function(tab, item)
   local location = find_item_location(tab, item)
   return location and location.page or nil
end

layout.find_container_of = function(tab, item)
   local location = find_item_location(tab, item)
   return location and location.container or nil
end

layout.append_page = function(tab, index)
   local new_page = wrap_page({})
   if index == nil then
      table.insert(tab.pages, new_page)
   else
      assert(type(index) == "number", "append_page index must be a number")
      table.insert(tab.pages, index, new_page)
   end

   return new_page
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

layout.move_app_to_folder = function(tab, app, folder, position)
   assert_app_item(app, "layout.move_app_to_folder")
   assert_folder_item(folder, "layout.move_app_to_folder")

   if not tab:remove_app(app) then
      return false
   end

   folder.items = folder.items or {}
   table.insert(folder.items, position or (#folder.items + 1), app)
   return true
end

layout.move_app_before_in_folder = function(tab, app, folder, anchor)
   assert_app_item(app, "layout.move_app_before_in_folder")
   assert_folder_item(folder, "layout.move_app_before_in_folder")

   local anchor_index = ensure_folder_anchor(folder, anchor, "layout.move_app_before_in_folder")
   return tab:move_app_to_folder(app, folder, anchor_index)
end

layout.move_app_after_in_folder = function(tab, app, folder, anchor)
   assert_app_item(app, "layout.move_app_after_in_folder")
   assert_folder_item(folder, "layout.move_app_after_in_folder")

   local anchor_index = ensure_folder_anchor(folder, anchor, "layout.move_app_after_in_folder")
   return tab:move_app_to_folder(app, folder, anchor_index + 1)
end

layout.move_app_to_page = function(tab, app, target_page, position)
   assert_app_item(app, "layout.move_app_to_page")
   return tab:move_item_to_page(app, target_page, position)
end

layout.move_app_out_of_folder = function(tab, app, target_page, position)
   assert_app_item(app, "layout.move_app_out_of_folder")

   if not kind.is(tab:find_container_of(app), "folder") then
      return false
   end

   return tab:move_app_to_page(app, target_page, position)
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

layout.move = function(tab, item, target_page, position)
   return tab:move_item_to_page(item, target_page, position)
end

layout.move_to_page_start = function(tab, item, target_page)
   return tab:move_item_to_page(item, target_page, 1)
end

layout.move_to_page_end = function(tab, item, target_page)
   return tab:move_item_to_page(item, target_page)
end

layout.move_to_dock = function(tab, item, position)
   return tab:move_item_to_page(item, tab.dock, position)
end

layout.move_item_to_new_page = function(tab, item, index)
   if not is_movable_container_item(item) then
      error(string.format("layout.move_item_to_new_page only supports movable items; found %s", kind.of(item)))
   end

   if not find_item_location(tab, item) then
      return false
   end

   local new_page = tab:append_page(index)
   if not tab:remove_item(item) then
      table.remove(tab.pages, index or #tab.pages)
      return false
   end

   table.insert(new_page, item)
   return new_page
end

layout.move_before = function(tab, item, anchor)
   if item == anchor then
      return true
   end

   local source = find_item_location(tab, item)
   if not source then
      return false
   end

   local target = find_item_location(tab, anchor)
   if not target then
      return false
   end

   local insert_index = target.index
   if source.container == target.container and source.index < target.index then
      insert_index = insert_index - 1
   end

   remove_from_container(source.container, source.index)
   insert_into_container(target.container, insert_index, item)
   return true
end

layout.move_after = function(tab, item, anchor)
   if item == anchor then
      return true
   end

   local source = find_item_location(tab, item)
   if not source then
      return false
   end

   local target = find_item_location(tab, anchor)
   if not target then
      return false
   end

   local insert_index = target.index + 1
   if source.container == target.container and source.index < target.index then
      insert_index = insert_index - 1
   end

   remove_from_container(source.container, source.index)
   insert_into_container(target.container, insert_index, item)
   return true
end

layout.move_app_before_item = function(tab, app, anchor)
   assert_app_item(app, "layout.move_app_before_item")
   return tab:move_before(app, anchor)
end

layout.move_app_after_item = function(tab, app, anchor)
   assert_app_item(app, "layout.move_app_after_item")
   return tab:move_after(app, anchor)
end

layout.swap = function(tab, left, right)
   if left == right then
      return true
   end

   local left_location = find_item_location(tab, left)
   if not left_location then
      return false
   end

   local right_location = find_item_location(tab, right)
   if not right_location then
      return false
   end

   if left_location.container == right_location.container then
      local container = container_items(left_location.container)
      container[left_location.index], container[right_location.index] =
         container[right_location.index], container[left_location.index]
      return true
   end

   if not can_insert_into_container(tab, left_location.container, right) then
      error(string.format("layout.swap cannot place %s into %s", kind.of(right), kind.of(left_location.container)))
   end

   if not can_insert_into_container(tab, right_location.container, left) then
      error(string.format("layout.swap cannot place %s into %s", kind.of(left), kind.of(right_location.container)))
   end

   remove_from_container(left_location.container, left_location.index)
   remove_from_container(right_location.container, right_location.index)
   insert_into_container(left_location.container, left_location.index, right)
   insert_into_container(right_location.container, right_location.index, left)
   return true
end

layout.move_all = function(tab, items, target_page, position)
   assert(type(items) == "table", "items must be a table")
   assert_page_table(target_page, "layout.move_all")

   local insert_at = position
   for _, item in ipairs(items) do
      if not tab:move_item_to_page(item, target_page, insert_at) then
         return false
      end

      if insert_at ~= nil then
         insert_at = insert_at + 1
      end
   end

   return true
end

layout.move_matching = function(tab, query, target_page, position)
   local items = {}

   tab:visit_items(function(item)
      if is_movable_container_item(item) and matches_query(item, query) then
         table.insert(items, item)
      end
   end)

   return tab:move_all(items, target_page, position)
end

layout.move_apps_into_folder = function(tab, items, folder, position)
   assert(type(items) == "table", "items must be a table")
   assert_folder_item(folder, "layout.move_apps_into_folder")

   local insert_at = position
   for _, app in ipairs(items) do
      if not tab:move_app_to_folder(app, folder, insert_at) then
         return false
      end

      if insert_at ~= nil then
         insert_at = insert_at + 1
      end
   end

   return true
end

layout.transaction = function(tab, callback)
   assert(type(callback) == "function", "transaction callback must be a function")

   local working = tab:clone()
   local packed
   local ok, err = pcall(function()
      packed = table.pack(callback(working))
   end)
   if not ok then
      return false, err
   end

   if packed[1] == false then
      return false, table.unpack(packed, 2, packed.n)
   end

   apply_working_layout(tab, working)
   return true, table.unpack(packed, 1, packed.n)
end

layout.preview = function(tab, callback)
   assert(type(callback) == "function", "preview callback must be a function")

   local working = tab:clone()
   local packed
   local ok, err = pcall(function()
      packed = table.pack(callback(working))
   end)
   if not ok then
      return false, err
   end

   return true, working, table.unpack(packed, 1, packed.n)
end

layout.transact_move = function(tab, item, target_page, position, validate_options)
   local item_ref = item and item.ref
   if type(item_ref) ~= "string" then
      error("layout.transact_move requires an item with a stable ref")
   end

   return tab:transaction(function(working)
      local working_item = find_item_by_ref(working, item_ref)
      local working_page = resolve_working_page(tab, working, target_page)
      if not working:move_item_to_page(working_item, working_page, position) then
         return false
      end

      if validate_options ~= nil then
         local issues = working:validate(validate_options)
         if #issues > 0 then
            return false, issues
         end
      end

      return true
   end)
end

layout.pack_pages = function(tab, options)
   local compacted = {}

   each_page(tab, function(current)
      for _, item in ipairs(current) do
         if not is_movable_container_item(item) then
            error(string.format(
               "layout.pack_pages only supports app, folder, widget, and stack items; found %s",
               kind.of(item)
            ))
         end

         table.insert(compacted, item)
      end
   end)

   local packed = layout.reshape(compacted, options)
   for key, value in pairs(tab) do
      if key ~= "dock" and key ~= "pages" then
         packed[key] = value
      end
   end

   apply_working_layout(tab, packed)
   return tab
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
