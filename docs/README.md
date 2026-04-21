# springboard

`springboard` is a Lua library with a C bridge for reading and writing iOS
SpringBoard layout data over USB.

It is not a generic icon library. The current model is:

- `Layout`
- `Page`
- `App`
- `Folder`
- `Widget` and `Stack` as opaque preserved items

## Current Status

What works:

- connect to a device and fetch the current layout
- load a saved plist fixture from disk
- traverse/search apps in a layout
- save a modified layout back to plist
- write a modified layout back to a device
- preserve widgets and smart stacks during round-trip

What does not work yet:

- first-class widget editing
- first-class smart stack editing
- safe generic mutation helpers for opaque items
- a real swap/move editing API

## Build

Requirements:

- Lua 5.4
- `libimobiledevice`
- `libplist`
- a working C toolchain

Build the C module with:

```sh
make
```

That compiles `iconlib.so` and copies it into [`springboard/`](/Users/matt/Projects/ios-icons/springboard).

## Basic Usage

```lua
local springboard = require "springboard"

local conn = springboard.connect()
local layout = conn:layout()

print(layout)
print(#layout.dock)
print(#layout.pages)

local messages = layout:find("Messages")
print(messages.name, messages.id, messages.ref)

conn:disconnect()
```

## Data Model

`Layout` fields:

- `dock`: a `Page`
- `pages`: array of `Page`
- `__store`: hidden internal handle used for round-trip ownership

`App` fields commonly present:

- `name`
- `id`
- `bundleIdentifier`
- `ref`
- `__store`

`Folder` fields:

- `name`
- `id`
- `ref`
- `items`
- `__store`

`Widget` / `Stack`:

- preserved as opaque items
- include `ref` and `__store`
- report `:support() == "opaque"`
- report `:is_editable() == false`

## Layout Helpers

App-only helpers:

- `layout:flatten()`
- `layout:find(query)`
- `layout:find_all(query)`
- `layout:find_id(query)`
- `layout:visit(fn)`

The search helpers accept either a plain substring or a Lua pattern.

All-item helpers:

- `layout:visit_items(fn)`
- `layout:opaque_items()`
- `layout:has_opaque_items()`

Mutation helper:

- `layout.reshape(flat_apps)`

`layout.reshape(...)` is intentionally app-only. Passing widgets, stacks,
folders, or other non-app items is an error.

## Device API

Connection methods:

- `conn:layout()`
- `conn:get_layout()`
- `conn:set_layout(layout)`
- `conn:app_image(app)`
- `conn:wallpaper()`
- `conn:devicename()`
- `conn:disconnect()`

Library methods:

- `springboard.connect([udid])`
- `springboard.ios_errno()`
- `springboard.load_plist(path)`

## Round-Trip Identity

Each parsed item gets an opaque `ref` like `item:42`.

That `ref` is what round-trip serialization uses to recover the original plist
node. It no longer depends on mutable fields like `name` or `id`.

## Opaque Widget/Stack Policy

Widgets and smart stacks are currently:

- parsed as explicit item kinds
- preserved during round-trip
- discoverable via `layout:visit_items(...)` and `layout:opaque_items()`
- not modeled internally beyond their top-level item record
- not supported by mutation helpers

That is deliberate. First-class support needs more research.

## Tests

Offline fixture-backed test:

```sh
lua tests/offline.lua
```

The existing [`tests/tests.lua`](/Users/matt/Projects/ios-icons/tests/tests.lua)
file is still device-backed and assumes a connected iOS device.
