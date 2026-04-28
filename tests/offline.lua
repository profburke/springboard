package.path = './?.lua;./?/init.lua;' .. package.path
package.cpath = './?.so;./?/?.so;' .. package.cpath

local springboard = require "springboard"
local cache = springboard.features.cache()
local image = springboard.features.image()
local kind = springboard.kind

assert(type(springboard.connect) == "function")
assert(type(springboard.load_plist) == "function")
assert(type(springboard.iconlib) == "table")
assert(springboard.kind == require "springboard.kind")
assert(springboard.layout == require "springboard.layout")
assert(springboard.app == require "springboard.app")
assert(type(springboard.features.graphics) == "function")
assert(type(springboard.features.itunes) == "function")

local function collect_kinds(layout)
  local counts = {}
  layout:visit_items(function(item)
    local k = kind.of(item)
    counts[k] = (counts[k] or 0) + 1
  end)
  return counts
end

local function first_folder(layout)
  local folder
  layout:visit_items(function(item)
    if not folder and kind.is(item, "folder") then
      folder = item
    end
  end)
  return folder
end

local function assert_same_counts(left, right)
  assert(#left.dock == #right.dock)
  assert(#left.pages == #right.pages)
  for idx = 1, #left.pages do
    assert(#left.pages[idx] == #right.pages[idx])
  end

  local left_kinds = collect_kinds(left)
  local right_kinds = collect_kinds(right)
  for k, count in pairs(left_kinds) do
    assert(right_kinds[k] == count)
  end
  for k, count in pairs(right_kinds) do
    assert(left_kinds[k] == count)
  end
end

local function assert_grid_metadata(item, expected_grid_size, expected_slots)
  assert(item:grid_size() == expected_grid_size)
  assert(item:slot_count() == expected_slots)
  local slot_size = item:slot_size()
  assert(slot_size.slots == expected_slots)
  assert(type(slot_size.width) == "number")
  assert(type(slot_size.height) == "number")
end

local function index_of(items, target)
  for index, item in ipairs(items) do
    if item == target then
      return index
    end
  end
  return nil
end

local fixture = "tests/fixtures/springboard-layout-sample.plist"
local layout = springboard.load_plist(fixture)

assert(type(layout) == "table")
assert(kind.of(layout) == "layout")
assert(type(layout.dock) == "table")
assert(type(layout.pages) == "table")
assert(type(layout.__store) == "userdata")
assert(layout.__source == "file")
assert(type(layout.save_plist) == "function")
assert(#layout.dock > 0)

local apps = layout:flatten()
assert(#apps > 0)

local first = layout.dock[1]
assert(kind.of(first) == "app")
assert(type(first.name) == "string")
assert(type(first.id) == "string")
assert(type(first.ref) == "string")
assert(first.ref:match("^item:%d+$"))
assert(type(first.__store) == "userdata")

assert(layout:find(first.name) ~= nil)
assert(layout:find_id(first.id) ~= nil)
assert(layout:find_all(".*")[1] ~= nil)

local saw_folder = false
local saw_opaque = false
local item_count = 0
layout:visit_items(function(item)
  item_count = item_count + 1
  assert(type(item.ref) == "string")
  assert(type(item.__store) == "userdata")

  if kind.is(item, "folder") then
    saw_folder = true
    assert(type(item.items) == "table")
    if #item.items > 0 then
      assert(type(item.items[1].ref) == "string")
    end
  elseif kind.is(item, "widget") or kind.is(item, "stack") or kind.is(item, "unknown") then
    saw_opaque = true
    assert(item:is_opaque() == true)
    assert(item:is_editable() == false)
    if kind.is(item, "widget") or kind.is(item, "stack") then
      assert(item:support() == "movable")
      assert(item:is_movable() == true)
      assert(type(item.grid_size) == "function")
      assert(type(item.slot_size) == "function")
      assert(type(item.slot_count) == "function")
    else
      assert(item:support() == "opaque")
    end
  end
end)

assert(item_count >= #apps)
assert(saw_folder)

local opaque = layout:opaque_items()
assert(layout:has_opaque_items() == (#opaque > 0))
if #opaque > 0 then
  saw_opaque = true
end

assert(saw_opaque)

local sample_widget
layout:visit_items(function(item)
  if not sample_widget and kind.is(item, "widget") then
    sample_widget = item
  end
end)
if sample_widget then
  assert_grid_metadata(sample_widget, "medium", 8)
  assert(sample_widget.gridSize == "medium")
  assert(type(sample_widget.widgetIdentifier) == "string")
  assert(type(sample_widget.containerBundleIdentifier) == "string")
  assert(sample_widget.elementType == "widget")
end

local selector_layout = springboard.load_plist(fixture)
local selector_folder = first_folder(selector_layout)
local selector_widget = selector_layout:widgets()[1]
local selector_folder_child_count = 0
for _, folder_item in ipairs(selector_layout:folders()) do
  selector_folder_child_count = selector_folder_child_count + #folder_item.items
end
local selector_page_one_count = 0
selector_layout:visit_items(function(item)
  if selector_layout:find_page_of(item) == selector_layout.pages[1] then
    selector_page_one_count = selector_page_one_count + 1
  end
end)
assert(#selector_layout:items() >= #selector_layout:apps())
assert(#selector_layout:apps() == #selector_layout:flatten())
assert(#selector_layout:folders() >= 1)
assert(#selector_layout:widgets() >= 1)
assert(type(selector_layout:stacks()) == "table")
assert(type(selector_layout:unknown_items()) == "table")
assert(selector_layout:find_item("Safari").id == "com.apple.mobilesafari")
assert(selector_layout:find_app({ id = "com.apple.mobilesafari" }).name == "Safari")
assert(selector_layout:find_folder({ name = selector_folder.name }) == selector_folder)
assert(#selector_layout:find_items({ kind = "widget", gridSize = "medium" }) >= 1)
assert(#selector_layout:find_items({ in_dock = true }) == #selector_layout.dock)
assert(#selector_layout:find_items({ in_folder = true }) == selector_folder_child_count)
assert(#selector_layout:find_items({ page = 1 }) == selector_page_one_count)
assert(selector_layout:page(1) == selector_layout.pages[1])
assert(selector_layout:page_items(1) == selector_layout.pages[1])
assert(selector_layout:items_on_page(1) == selector_layout.pages[1])
assert(selector_layout:dock_items() == selector_layout.dock)
assert(selector_layout:folder_items(selector_folder) == selector_folder.items)
assert(selector_layout:items_in_container(selector_folder) == selector_folder.items)
assert(selector_layout:items_in_container(selector_layout.dock) == selector_layout.dock)
if selector_widget then
  assert(selector_layout:find_items(function(item)
    return kind.is(item, "widget") and item == selector_widget
  end)[1] == selector_widget)
end

local selector_move_layout = springboard.load_plist(fixture)
local selector_move_page = selector_move_layout:append_page()
assert(selector_move_layout:move_first("Safari", selector_move_page, 1) == true)
assert(selector_move_page[1].name == "Safari")
assert(selector_move_layout:move_all_matching({ in_dock = true }, selector_move_page, 1) == true)
assert(#selector_move_layout.dock == 0)
assert(#selector_move_page == 4)

local selector_folder_move_layout = springboard.load_plist(fixture)
local selector_folder_target = first_folder(selector_folder_move_layout)
assert(selector_folder_move_layout:move_first_into_folder("Safari", selector_folder_target, 1) == true)
assert(selector_folder_target.items[1].name == "Safari")

local api_layout = springboard.load_plist(fixture)
local api_apps = api_layout:flatten()
local api_folder = first_folder(api_layout)
local api_top_app = api_apps[1]
local api_second_app = api_apps[2]
local api_folder_app = api_folder and api_folder.items[1] or nil
local api_widget
api_layout:visit_items(function(item)
  if not api_widget and kind.is(item, "widget") then
    api_widget = item
  end
end)

if api_top_app and api_second_app then
  local cloned = api_layout:clone()
  assert(kind.of(cloned) == "layout")
  assert(cloned ~= api_layout)
  assert(cloned.dock ~= api_layout.dock)
  assert(cloned.dock[1] ~= api_layout.dock[1])
  assert(cloned.dock[1].id == api_layout.dock[1].id)
  assert(cloned:move_after(cloned.dock[1], cloned.dock[2]) == true)
  assert(cloned.dock[2].id == api_top_app.id)
  assert(api_layout.dock[1].id == api_top_app.id)
end

if api_top_app and api_folder and api_folder_app then
  assert(api_layout:find_container_of(api_top_app) == api_layout.dock)
  assert(api_layout:find_page_of(api_top_app) == api_layout.dock)
  assert(api_layout:find_container_of(api_folder_app) == api_folder)
  assert(api_layout:find_page_of(api_folder_app) ~= nil)
  assert(api_layout:move_before(api_top_app, api_folder_app) == true)
  assert(api_layout:find_container_of(api_top_app) == api_folder)
  assert(api_folder.items[1] == api_top_app)
end

if api_widget and api_second_app then
  local widget_page = api_layout:find_page_of(api_widget)
  assert(widget_page ~= nil)
  assert(api_layout:find_container_of(api_widget) == widget_page)
  assert(api_layout:move_before(api_second_app, api_widget) == true)
  assert(api_layout:find_page_of(api_second_app) == widget_page)
  assert(api_layout:find_container_of(api_second_app) == widget_page)
  assert(api_layout:move_after(api_second_app, api_widget) == true)
end

local transaction_layout = springboard.load_plist(fixture)
local transaction_first = transaction_layout.dock[1]
local transaction_second = transaction_layout.dock[2]
local ok_tx, tx_result = transaction_layout:transaction(function(working)
  assert(working ~= transaction_layout)
  assert(working:move_after(working.dock[1], working.dock[2]) == true)
  return "committed"
end)
assert(ok_tx == true)
assert(tx_result == "committed")
assert(transaction_layout.dock[2].id == transaction_first.id)
assert(transaction_layout.dock[1].id == transaction_second.id)

local rollback_layout = springboard.load_plist(fixture)
local rollback_first = rollback_layout.dock[1]
local rollback_second = rollback_layout.dock[2]
local rollback_ok, rollback_err = rollback_layout:transaction(function(working)
  working:move_after(working.dock[1], working.dock[2])
  error("boom")
end)
assert(rollback_ok == false)
assert(rollback_err:match("boom"))
assert(rollback_layout.dock[1].id == rollback_first.id)
assert(rollback_layout.dock[2].id == rollback_second.id)

local cancel_layout = springboard.load_plist(fixture)
local cancel_first = cancel_layout.dock[1]
local cancel_second = cancel_layout.dock[2]
local cancel_ok = cancel_layout:transaction(function(working)
  working:move_after(working.dock[1], working.dock[2])
  return false
end)
assert(cancel_ok == false)
assert(cancel_layout.dock[1].id == cancel_first.id)
assert(cancel_layout.dock[2].id == cancel_second.id)

local page_api_layout = springboard.load_plist(fixture)
local page_count_before = #page_api_layout.pages
local appended_page = page_api_layout:append_page()
assert(kind.of(appended_page) == "page")
assert(#appended_page == 0)
assert(#page_api_layout.pages == page_count_before + 1)
assert(page_api_layout.pages[#page_api_layout.pages] == appended_page)

local new_page_layout = springboard.load_plist(fixture)
local new_page_item = new_page_layout.dock[1]
local inserted_page = new_page_layout:move_item_to_new_page(new_page_item, 1)
assert(kind.of(inserted_page) == "page")
assert(new_page_layout.pages[1] == inserted_page)
assert(inserted_page[1] == new_page_item)
assert(new_page_layout:find_page_of(new_page_item) == inserted_page)

local swap_layout = springboard.load_plist(fixture)
local swap_first = swap_layout.dock[1]
local swap_second = swap_layout.dock[2]
assert(swap_layout:swap(swap_first, swap_second) == true)
assert(swap_layout.dock[1] == swap_second)
assert(swap_layout.dock[2] == swap_first)

local swap_folder_layout = springboard.load_plist(fixture)
local swap_folder = first_folder(swap_folder_layout)
local swap_folder_child = swap_folder and swap_folder.items[1] or nil
local swap_dock_app = swap_folder_layout.dock[1]
if swap_folder and swap_folder_child and swap_dock_app then
  assert(swap_layout ~= nil)
  assert(swap_folder_layout:swap(swap_dock_app, swap_folder_child) == true)
  assert(swap_folder.items[1] == swap_dock_app)
  assert(swap_folder_layout.dock[1] == swap_folder_child)
end

local swap_invalid_layout = springboard.load_plist(fixture)
local swap_invalid_folder = first_folder(swap_invalid_layout)
local swap_invalid_child = swap_invalid_folder and swap_invalid_folder.items[1] or nil
local swap_invalid_widget
swap_invalid_layout:visit_items(function(item)
  if not swap_invalid_widget and kind.is(item, "widget") then
    swap_invalid_widget = item
  end
end)
if swap_invalid_child and swap_invalid_widget then
  local swap_ok, swap_err = pcall(function()
    swap_invalid_layout:swap(swap_invalid_child, swap_invalid_widget)
  end)
  assert(swap_ok == false)
  assert(swap_err:match("cannot place widget into folder"))
end

local pack_layout = springboard.layout.new(
  {},
  {
    { apps[1] },
    { apps[2] },
    { apps[3] },
    { apps[4] },
    { apps[5] },
  }
)
pack_layout.__source = "file"
pack_layout:pack_pages({ dock_capacity = 4, page_capacity = 24 })
assert(#pack_layout.dock == 4)
assert(pack_layout.dock[1] == apps[1])
assert(pack_layout.dock[4] == apps[4])
assert(#pack_layout.pages == 1)
assert(pack_layout.pages[1][1] == apps[5])
assert(pack_layout.__source == "file")

local relative_layout = springboard.load_plist(fixture)
local relative_folder = first_folder(relative_layout)
local relative_folder_child = relative_folder and relative_folder.items[1] or nil
local relative_app = relative_layout.dock[1]
local relative_anchor = relative_layout.pages[1] and relative_layout.pages[1][1] or nil
if relative_folder and relative_folder_child and relative_app and relative_anchor then
  assert(relative_layout:move_app_out_of_folder(relative_folder_child, relative_layout.dock) == true)
  assert(relative_layout.dock[#relative_layout.dock] == relative_folder_child)
  assert(relative_layout:move_app_before_item(relative_app, relative_anchor) == true)
  assert(relative_layout.pages[1][1] == relative_app)
  assert(relative_layout:move_app_after_item(relative_app, relative_anchor) == true)
  assert(relative_layout.pages[1][2] == relative_app)
end

local batch_layout = springboard.load_plist(fixture)
local batch_app_one = batch_layout.dock[1]
local batch_app_two = batch_layout.dock[2]
local batch_target_page = batch_layout.pages[1]
assert(batch_layout:move_all({ batch_app_one, batch_app_two }, batch_target_page, 1) == true)
assert(batch_target_page[1] == batch_app_one)
assert(batch_target_page[2] == batch_app_two)

local matching_layout = springboard.load_plist(fixture)
local matching_page = matching_layout:append_page()
assert(matching_layout:move_matching("Safari", matching_page, 1) == true)
assert(matching_page[1].name == "Safari")

local folder_batch_layout = springboard.load_plist(fixture)
local folder_batch_folder = first_folder(folder_batch_layout)
local folder_batch_apps = folder_batch_layout:flatten()
if folder_batch_folder and #folder_batch_apps >= 2 then
  assert(folder_batch_layout:move_apps_into_folder({ folder_batch_apps[1], folder_batch_apps[2] }, folder_batch_folder, 1) == true)
  assert(folder_batch_folder.items[1] == folder_batch_apps[1])
  assert(folder_batch_folder.items[2] == folder_batch_apps[2])
end

local page_move_layout = springboard.load_plist(fixture)
local page_move_item = page_move_layout.dock[1]
local page_move_target = page_move_layout.pages[1]
assert(page_move_layout:move_to_page_end(page_move_item, page_move_target) == true)
assert(page_move_target[#page_move_target] == page_move_item)
assert(page_move_layout:move_to_page_start(page_move_item, page_move_target) == true)
assert(page_move_target[1] == page_move_item)
assert(page_move_layout:move_to_dock(page_move_item, 1) == true)
assert(page_move_layout.dock[1] == page_move_item)

local preview_layout = springboard.load_plist(fixture)
local preview_first = preview_layout.dock[1]
local preview_second = preview_layout.dock[2]
local preview_ok, preview_working, preview_label = preview_layout:preview(function(working)
  working:move_after(working.dock[1], working.dock[2])
  return "preview"
end)
assert(preview_ok == true)
assert(preview_label == "preview")
assert(preview_working.dock[2].id == preview_first.id)
assert(preview_layout.dock[1].id == preview_first.id)
assert(preview_layout.dock[2].id == preview_second.id)

local transact_layout = springboard.load_plist(fixture)
local transact_item = transact_layout.dock[1]
local transact_target = transact_layout.pages[1]
local transact_ok, transact_result = transact_layout:transact_move(transact_item, transact_target, 1)
assert(transact_ok == true)
assert(transact_result == true)
assert(transact_layout.pages[1][1].id == transact_item.id)

local transact_fail_layout = springboard.load_plist(fixture)
local transact_fail_item = transact_fail_layout.dock[1]
local transact_fail_target = transact_fail_layout.pages[1]
local fail_ok, fail_issues = transact_fail_layout:transact_move(
  transact_fail_item,
  transact_fail_target,
  1,
  { page_capacity = 0 }
)
assert(fail_ok == false)
assert(type(fail_issues) == "string" or type(fail_issues) == "table")
assert(transact_fail_layout.dock[1].id == transact_fail_item.id)

local a, b, c = apps[1], apps[2], apps[3]
if a and b and c then
  local reshaped = layout.reshape({ a, b, c })
  assert(kind.of(reshaped) == "layout")
  assert(type(reshaped.dock) == "table")
  assert(type(reshaped.pages) == "table")
end

local folder = first_folder(layout)

if a and folder then
  local reshaped = layout.reshape({ a, folder })
  assert(kind.of(reshaped) == "layout")
  assert(kind.of(reshaped.dock[2]) == "folder")
  assert(reshaped.dock[2].items == folder.items)
  assert(folder:support() == "movable")
  assert(folder:is_movable() == true)
  assert(folder:is_editable() == false)
  assert(folder:is_opaque() == false)
  assert(folder:count() == #folder.items)
end

if sample_widget and a and b and c then
  local reshaped = layout.reshape({ a, b, c, sample_widget }, { page_capacity = 24 })
  assert(#reshaped.dock == 3)
  assert(kind.of(reshaped.pages[1][1]) == "widget")
  assert(reshaped.pages[1][1] == sample_widget)
end

local folder_app
if folder and #folder.items > 0 then
  folder_app = folder.items[1]
  local before = #folder.items
  assert(layout:remove_app(folder_app) == true)
  assert(#folder.items == before - 1)
  assert(layout:remove_app(folder_app) == false)
  assert(layout:move_app_to_folder(folder_app, folder) == false)
  table.insert(layout.dock, folder_app)
  assert(layout:move_app_to_folder(folder_app, folder) == true)
  assert(folder.items[#folder.items] == folder_app)
  assert(layout:move_app_to_page(folder_app, layout.dock) == true)
  assert(layout.dock[#layout.dock] == folder_app)
end

if folder and a then
  local before = #folder.items
  assert(layout:move_app_to_folder(a, folder) == true)
  assert(#folder.items == before + 1)
  assert(folder.items[#folder.items] == a)
end

local folder_position_layout = springboard.load_plist(fixture)
local folder_position_folder = first_folder(folder_position_layout)
local folder_position_apps = folder_position_layout:flatten()
if folder_position_folder and #folder_position_folder.items >= 2 and #folder_position_apps >= 3 then
  local moving = folder_position_apps[1]
  local first_child = folder_position_folder.items[1]
  local second_child = folder_position_folder.items[2]

  assert(folder_position_layout:move_app_to_folder(moving, folder_position_folder, 1) == true)
  assert(folder_position_folder.items[1] == moving)

  assert(folder_position_layout:move_app_to_page(moving, folder_position_layout.dock) == true)
  assert(folder_position_layout:move_app_before_in_folder(moving, folder_position_folder, second_child) == true)
  assert(folder_position_folder.items[2] == moving)

  assert(folder_position_layout:move_app_to_page(moving, folder_position_layout.dock) == true)
  assert(folder_position_layout:move_app_after_in_folder(moving, folder_position_folder, second_child) == true)
  assert(index_of(folder_position_folder.items, moving) == index_of(folder_position_folder.items, second_child) + 1)

  local bad_anchor_ok, bad_anchor_err = pcall(function()
    folder_position_layout:move_app_before_in_folder(folder_position_apps[2], folder_position_folder, folder_position_layout.dock[1])
  end)
  assert(bad_anchor_ok == false)
  assert(bad_anchor_err:match("anchor already inside the folder"))
end

if folder then
  assert(#layout:validate() == 0)
  local issues = layout:validate({ folder_capacity = math.max(0, #folder.items - 1) })
  assert(#issues >= 1)
  assert(issues[1].kind == "folder_capacity")
  assert(issues[1].item == folder)
end

local slot_issues = layout:validate({ dock_capacity = 4, page_capacity = 24 })
assert(#slot_issues == 0)

if sample_widget then
  local compacted = {}
  for i = 1, 17 do
    compacted[i] = apps[i]
  end
  table.insert(compacted, sample_widget)
  local overfull = springboard.layout.new({}, { compacted })
  local issues = overfull:validate({ page_capacity = 24 })
  assert(#issues == 1)
  assert(issues[1].kind == "page_capacity")
end

local ok, err = pcall(function()
  layout.reshape({ apps[1], opaque[1] })
end)
if opaque[1] then
  assert(ok == true)
end

local unknown = require "springboard.unknown"
local unknown_item = setmetatable({ ref = "synthetic:unknown" }, unknown.__meta)
assert(kind.of(unknown_item) == "unknown")
assert(unknown_item:support() == "opaque")
assert(unknown_item:is_opaque() == true)
assert(unknown_item:is_editable() == false)

local synthetic_xlarge_widget = setmetatable({ gridSize = "xtralarge" }, springboard.widget.__meta)
assert(synthetic_xlarge_widget:grid_size() == "extraLarge")
assert(synthetic_xlarge_widget:slot_size().slots == 24)
assert(synthetic_xlarge_widget:slot_count() == 24)

local synthetic_large_stack = setmetatable({ gridSize = "extraLarge" }, springboard.stack.__meta)
assert(synthetic_large_stack:grid_size() == "extraLarge")
assert(synthetic_large_stack:slot_count() == 24)

local unknown_layout = springboard.load_plist("tests/fixtures/springboard-unknown-item.plist")
local parsed_unknown = unknown_layout.dock[1]
assert(unknown_layout.__source == "file")
assert(type(unknown_layout.save_plist) == "function")
assert(kind.of(parsed_unknown) == "unknown")
assert(type(parsed_unknown.ref) == "string")
assert(type(parsed_unknown.__store) == "userdata")
assert(unknown_layout:has_opaque_items() == true)

local unknown_ok, unknown_err = pcall(function()
  layout.reshape({ parsed_unknown })
end)
assert(unknown_ok == false)
assert(unknown_err:match("layout%.reshape only supports app, folder, widget, and stack items"))

local edge_layout = springboard.load_plist("tests/fixtures/springboard-edge-cases.plist")
assert(edge_layout.__source == "file")
assert(type(edge_layout.save_plist) == "function")

local missing_name = edge_layout:find_id("com.example.missing-name")
assert(kind.of(missing_name) == "app")
assert(missing_name.name == nil)
assert(missing_name.bundleIdentifier == "com.example.missing-name")

local missing_bundle = edge_layout:find("Missing Bundle")
assert(kind.of(missing_bundle) == "app")
assert(missing_bundle.id == "com.example.missing-bundle")
assert(missing_bundle.bundleIdentifier == nil)

local edge_folder = first_folder(edge_layout)
assert(kind.of(edge_folder) == "folder")
assert(edge_folder.name == "Fixture Folder")
assert(edge_folder:count() == 2)
assert(edge_folder.items[1].name == nil)
assert(edge_folder.items[1].bundleIdentifier == "com.example.folder-child-no-name")
assert(edge_folder.items[2].name == "Folder Child No Bundle")
assert(edge_folder.items[2].bundleIdentifier == nil)

local edge_opaque = edge_layout:opaque_items()
assert(#edge_opaque == 1)
assert(kind.of(edge_opaque[1]) == "widget")
assert(edge_opaque[1].bundleIdentifier == nil)
assert_grid_metadata(edge_opaque[1], "small", 4)

local moved_widget_layout = springboard.load_plist(fixture)
local moved_widget
moved_widget_layout:visit_items(function(item)
  if not moved_widget and kind.is(item, "widget") then
    moved_widget = item
  end
end)
assert(moved_widget_layout:move_item_to_page(moved_widget, moved_widget_layout.pages[1]) == true)
assert(moved_widget_layout.pages[1][#moved_widget_layout.pages[1]] == moved_widget)
local dock_move_ok, dock_move_err = pcall(function()
  moved_widget_layout:move_item_to_page(moved_widget, moved_widget_layout.dock)
end)
assert(dock_move_ok == false)
assert(dock_move_err:match("does not support widget in the dock"))

local roundtrip_path = "/tmp/springboard-offline-roundtrip.plist"
local roundtrip = springboard.load_plist(fixture)
roundtrip:save_plist(roundtrip_path)
local reloaded = springboard.load_plist(roundtrip_path)
assert(reloaded.__source == "file")
assert(type(reloaded.save_plist) == "function")
assert_same_counts(roundtrip, reloaded)
assert(reloaded.dock[1].bundleIdentifier == roundtrip.dock[1].bundleIdentifier)

local moved = springboard.load_plist(fixture)
local moved_apps = moved:flatten()
local moved_folder = first_folder(moved)
if moved_folder and moved_apps[1] then
  local moved_id = moved_apps[1].id
  local before = moved_folder:count()
  assert(moved:move_app_to_folder(moved_apps[1], moved_folder) == true)
  assert(moved_folder:count() == before + 1)
  moved:save_plist(roundtrip_path)

  local moved_reloaded = springboard.load_plist(roundtrip_path)
  local moved_reloaded_folder = first_folder(moved_reloaded)
  assert(moved_reloaded_folder:count() == before + 1)
  assert(moved_reloaded_folder.items[#moved_reloaded_folder.items].id == moved_id)
end

edge_layout:save_plist(roundtrip_path)
local edge_reloaded = springboard.load_plist(roundtrip_path)
assert(edge_reloaded:find_id("com.example.missing-name").name == nil)
assert(edge_reloaded:find("Missing Bundle").bundleIdentifier == nil)
assert(first_folder(edge_reloaded).items[2].bundleIdentifier == nil)
assert(kind.of(edge_reloaded:opaque_items()[1]) == "widget")

os.remove(roundtrip_path)

local cache_path = "/tmp/springboard-offline-cache"
local feature_cache = cache.new(cache_path, function(item) return item.key end)
feature_cache.set({ key = "one" }, "value")
assert(feature_cache.get({ key = "one" }) == "value")
assert(feature_cache.get({ key = "two" }, function() return "generated" end) == "generated")
assert(feature_cache.get({ key = "two" }) == "generated")
assert(#feature_cache.keys() >= 2)
assert(feature_cache.remove({ key = "one" }) ~= nil)
local bad_key_ok = pcall(function()
  feature_cache.set({ key = "../bad" }, "bad")
end)
assert(bad_key_ok == false)

local fake_app = {
  id = "feature-image-test",
}
fake_app.image = image.new(fake_app)
fake_app.image.make_rgb = function()
  return string.char(10, 20, 30)
end
local r, g, b = fake_app.image.rgb()
assert(r == 10)
assert(g == 20)
assert(b == 30)
