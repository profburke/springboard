# springboard

`springboard` is a Lua library with a C bridge for reading and writing iOS
SpringBoard layout data over USB.

It is not a generic icon library. The current model is:

- `Layout`
- `Page`
- `App`
- `Folder`
- `Widget`, `Stack`, and `Unknown` as opaque preserved items

## Current Status

What works:

- connect to a device and fetch the current layout
- load a saved plist fixture from disk
- save a raw device layout plist without parsing
- traverse/search apps in a layout
- save a modified layout back to plist
- write a modified layout back to a device
- preserve widgets and smart stacks during round-trip

What does not work yet:

- first-class widget editing
- first-class smart stack editing
- unknown item editing
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
- `__source`: `"device"` or `"file"`

`App` fields commonly present:

- `name`
- `id`
- `bundleIdentifier`
- `ref`
- `__store`

Apps are move-only. Editing fields, creating apps, and deleting apps are not
supported.

`Folder` fields:

- `name`
- `id`
- `ref`
- `items`
- `__store`

Folders are movable as atomic containers. Their contents are modeled as one
flat `folder.items` list.

Folder capacity is not enforced by default. Reports vary by iOS version and
device class. Use `layout:validate({ folder_capacity = N })` if you want to
apply a known limit for a specific target.

Creating and deleting folders is unsupported. Empty folders are allowed.

`Widget` / `Stack` / `Unknown`:

- preserved as opaque items
- include `ref` and `__store`
- report `:support() == "opaque"`
- report `:is_editable() == false`

Research indicates widgets should be movable once grid-size validation exists.
Widget `gridSize` values include `small`, `medium`, `large`, and iPad-only
`xtralarge`.

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
- `layout:validate([options])`

Folder/app mutation helpers:

- `layout:remove_app(app)`
- `layout:move_app_to_folder(app, folder)`
- `layout:move_app_to_page(app, page[, position])`

Mutation helper:

- `layout.reshape(flat_items)`

`layout.reshape(...)` accepts apps and folders. Folders move as atomic
containers. Passing widgets, stacks, unknown items, or other non-movable items
is an error.

## Device API

Connection methods:

- `conn:layout()`
- `conn:get_layout()`
- `conn:save_raw_layout_plist(path)`
- `conn:set_layout(layout)`
- `conn:set_layout(layout, { force = true })`
- `conn:app_image(app)`
- `conn:wallpaper()`
- `conn:devicename()`
- `conn:disconnect()`

Library methods:

- `springboard.connect([udid])`
- `springboard.ios_errno()`
- `springboard.load_plist(path)`

`springboard.load_plist(path)` is for fixtures, inspection, and research. It is
not the normal import-and-write workflow.

## Round-Trip Identity

Each parsed item gets an opaque `ref` like `item:42`.

That `ref` is what round-trip serialization uses to recover the original plist
node. It no longer depends on mutable fields like `name` or `id`.

## Raw Plist Dumps

Use `conn:save_raw_layout_plist(path)` when you need a research/debug backup of
exactly what SpringBoardServices returned.

Do not use `layout:save_plist(path)` for raw capture. That method saves the
current Lua model back to plist and can normalize structures the model does not
fully understand yet.

## Write Safety

Layouts fetched from a device have `layout.__source == "device"`. Layouts loaded
from disk have `layout.__source == "file"`.

`conn:set_layout(layout)` refuses file-loaded layouts by default. If you really
intend to restore or experiment with a local plist, call:

```lua
conn:set_layout(layout, { force = true })
```

That force flag is deliberately noisy. A local plist can be stale, edited,
device-specific, or structurally invalid for the connected phone.

## Opaque Item Policy

Widgets, smart stacks, and unknown items are currently:

- parsed as explicit item kinds
- preserved during round-trip
- discoverable via `layout:visit_items(...)` and `layout:opaque_items()`
- not modeled internally beyond their top-level item record
- not supported by mutation helpers

That is deliberate. First-class support needs more research.

See [`springboard-items.md`](/Users/matt/Projects/ios-icons/docs/springboard-items.md)
for the current item taxonomy and open questions.

## Tests

Offline fixture-backed test:

```sh
lua tests/offline.lua
```

That test covers parse behavior, traversal, model invariants, app/folder
movement, validation, opaque items, and Lua-to-plist round-trip behavior.

The existing [`tests/tests.lua`](/Users/matt/Projects/ios-icons/tests/tests.lua)
file is device-backed integration coverage. It assumes a connected iOS device
and should not be treated as the default safety net.
