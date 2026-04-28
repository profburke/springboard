# Layout Recipes

These examples assume you already have a `layout` from `conn:layout()` and will
call `conn:set_layout(layout)` yourself only after reviewing the result.

All examples below operate on compacted layout semantics. They do not preserve
intentional sparse-page gaps on iOS 18+/26.

## Move One App To A New Page

```lua
local safari = layout:find_app({ id = "com.apple.mobilesafari" })
assert(safari, "Safari not found")

layout:move_item_to_new_page(safari)
```

## Move All Dock Apps To Page 1

```lua
layout:move_matching({ in_dock = true }, layout:page(1), 1)
```

## Move The First Matching App Into A Folder

```lua
local utilities = layout:find_folder({ name = "Utilities" })
assert(utilities, "Utilities folder not found")

layout:move_first_into_folder("Calculator", utilities, 1)
```

## Reorder Items Relative To An Anchor

```lua
local safari = layout:find_app("Safari")
local messages = layout:find_app("Messages")
assert(safari and messages, "Required apps not found")

layout:move_before(safari, messages)
```

## Move An App Out Of A Folder

```lua
local folder = layout:find_folder({ name = "Utilities" })
local app = layout:folder_items(folder)[1]
assert(folder and app, "Folder or child app missing")

layout:move_app_out_of_folder(app, layout:page(1), 1)
```

## Pack A Layout After Manual Moves

```lua
layout:pack_pages({
  dock_capacity = 4,
  page_capacity = 24,
})
```

## Make Several Changes Safely

```lua
local ok, err = layout:transaction(function(working)
  local page1 = working:page(1)
  local safari = working:find_app("Safari")
  local messages = working:find_app("Messages")

  assert(safari and messages and page1, "Required items missing")

  working:move_before(safari, messages)
  working:move_to_page_end(messages, page1)
  working:pack_pages({ dock_capacity = 4, page_capacity = 24 })
end)

assert(ok, err)
```

## Preview Without Mutating

```lua
local ok, preview = layout:preview(function(working)
  local page1 = working:page(1)
  working:move_first("Safari", page1, 1)
  working:pack_pages({ dock_capacity = 4, page_capacity = 24 })
end)

assert(ok, "preview failed")
print(preview)
```

## Filter By Kind And Location

```lua
local page1_widgets = layout:find_items({
  kind = "widget",
  page = 1,
})

local folder_apps = layout:find_items({
  kind = "app",
  in_folder = true,
})
```

## Use A Predicate For Custom Selection

```lua
local japanese_apps = layout:find_items(function(item)
  return springboard.kind.is(item, "app")
     and item.name
     and item.name:match("Japanese")
end)
```
