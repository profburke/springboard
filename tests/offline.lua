package.path = './?.lua;./?/init.lua;' .. package.path
package.cpath = './?.so;./?/?.so;' .. package.cpath

local springboard = require "springboard"
local kind = require "springboard.kind"

local fixture = "tests/fixtures/springboard-layout-sample.plist"
local layout = springboard.load_plist(fixture)

assert(type(layout) == "table")
assert(kind.of(layout) == "layout")
assert(type(layout.dock) == "table")
assert(type(layout.pages) == "table")
assert(type(layout.__store) == "userdata")
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
    assert(item:support() == "opaque")
    assert(item:is_opaque() == true)
    assert(item:is_editable() == false)
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

local a, b, c = apps[1], apps[2], apps[3]
if a and b and c then
  local reshaped = layout.reshape({ a, b, c })
  assert(kind.of(reshaped) == "layout")
  assert(type(reshaped.dock) == "table")
  assert(type(reshaped.pages) == "table")
end

local folder
layout:visit_items(function(item)
  if not folder and kind.is(item, "folder") then
    folder = item
  end
end)

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

if folder then
  assert(#layout:validate() == 0)
  local issues = layout:validate({ folder_capacity = math.max(0, #folder.items - 1) })
  assert(#issues >= 1)
  assert(issues[1].kind == "folder_capacity")
  assert(issues[1].item == folder)
end

local ok, err = pcall(function()
  layout.reshape({ apps[1], opaque[1] })
end)
if opaque[1] then
  assert(ok == false)
  assert(err:match("layout%.reshape only supports app and folder items"))
end

local unknown = require "springboard.unknown"
local unknown_item = setmetatable({ ref = "synthetic:unknown" }, unknown.__meta)
assert(kind.of(unknown_item) == "unknown")
assert(unknown_item:support() == "opaque")
assert(unknown_item:is_opaque() == true)
assert(unknown_item:is_editable() == false)

local unknown_layout = springboard.load_plist("tests/fixtures/springboard-unknown-item.plist")
local parsed_unknown = unknown_layout.dock[1]
assert(kind.of(parsed_unknown) == "unknown")
assert(type(parsed_unknown.ref) == "string")
assert(type(parsed_unknown.__store) == "userdata")
assert(unknown_layout:has_opaque_items() == true)

local unknown_ok, unknown_err = pcall(function()
  layout.reshape({ parsed_unknown })
end)
assert(unknown_ok == false)
assert(unknown_err:match("layout%.reshape only supports app and folder items"))
