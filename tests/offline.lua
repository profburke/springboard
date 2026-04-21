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
  elseif kind.is(item, "widget") or kind.is(item, "stack") then
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

local ok, err = pcall(function()
  layout.reshape({ apps[1], opaque[1] })
end)
if opaque[1] then
  assert(ok == false)
  assert(err:match("layout%.reshape only supports app items"))
end
