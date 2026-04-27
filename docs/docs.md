## API Summary

### Library

`springboard.connect([udid])`

- opens a connection to the default or specified device

`springboard.ios_errno()`

- returns the last connection error code

`springboard.load_plist(path)`

- loads a saved SpringBoard plist from disk into a file-sourced `Layout`
- intended for fixtures, inspection, and research

Top-level model modules:

- `springboard.kind`
- `springboard.layout`
- `springboard.page`
- `springboard.app`
- `springboard.folder`
- `springboard.widget`
- `springboard.stack`
- `springboard.unknown`

### Connection

`conn:layout()` / `conn:get_layout()`

- fetches the current device layout

`conn:save_raw_layout_plist(path)`

- writes the raw SpringBoardServices layout plist to disk without parsing

`conn:set_layout(layout)`

- writes the given layout back to the device
- refuses file-sourced layouts unless forced

`conn:set_layout(layout, { force = true })`

- writes a file-sourced layout intentionally
- unsafe unless the plist is known-good for the target device

`conn:app_image(app)`

- returns PNG bytes for the given app
- core API; optional color/image analysis lives under `springboard.features`

`conn:wallpaper()`

- returns PNG bytes for the current home screen wallpaper

`conn:devicename()`

- returns the device name

`conn:disconnect()`

- closes the device connection

### Layout

Fields:

- `dock`
- `pages`
- `__source`

Methods:

- `clone()`
- `flatten()`
- `find(query)`
- `find_all(query)`
- `find_id(query)`
- `visit(fn)`
- `visit_items(fn)`
- `opaque_items()`
- `has_opaque_items()`
- `find_page_of(item)`
- `find_container_of(item)`
- `append_page([index])`
- `validate([options])`
- `remove_item(item)`
- `move(item, page[, position])`
- `move_item_to_page(item, page[, position])`
- `move_item_to_new_page(item[, index])`
- `move_before(item, anchor)`
- `move_after(item, anchor)`
- `move_all(items, page[, position])`
- `move_matching(query, page[, position])`
- `move_to_page_start(item, page)`
- `move_to_page_end(item, page)`
- `move_to_dock(item[, position])`
- `swap(left, right)`
- `pack_pages([options])`
- `preview(fn)`
- `transact_move(item, page[, position[, validate_options]])`
- `transaction(fn)`
- `remove_app(app)`
- `move_app_to_folder(app, folder[, position])`
- `move_app_before_in_folder(app, folder, anchor)`
- `move_app_after_in_folder(app, folder, anchor)`
- `move_apps_into_folder(apps, folder[, position])`
- `move_app_out_of_folder(app, page[, position])`
- `move_app_before_item(app, anchor)`
- `move_app_after_item(app, anchor)`
- `move_app_to_page(app, page[, position])`

`find*` methods accept either a plain substring or a Lua pattern.

Mutation:

- `reshape(flat_items[, options])`

`reshape` accepts apps, folders, widgets, and stacks. They are packed as a
compacted layout using slot footprints. Unknown items are rejected.

`validate({ folder_capacity = N })` reports folder capacity issues when a caller
provides an explicit limit. `validate({ dock_capacity = N, page_capacity = M })`
reports compacted slot-capacity issues. No device-specific limit is enforced by
default.

`move_before` and `move_after` place an item relative to another item. If the
anchor is inside a folder, apps can move into that folder through the same API.

`move_app_to_folder` accepts an optional insertion position. The explicit
`move_app_before_in_folder` and `move_app_after_in_folder` helpers target
folder-child ordering directly.

`move_item_to_new_page` creates a page and moves the item there. `append_page`
creates an empty page at the end or at a specified index.

`swap` exchanges two items only if both destination containers can legally hold
the other item. `pack_pages` compacts the current top-level item order using
`reshape` slot rules.

`move_all` and `move_matching` provide bulk movement. `move_matching` accepts a
string query or predicate function.

`preview` runs against a cloned working layout and never mutates the original.
`transact_move` performs a single move via the transaction path and can validate
before commit.

`transaction(fn)` runs `fn` against a cloned working layout and commits only on
success.

### Item Kinds

`App`

- first-class move-only item
- field editing, creation, and deletion are unsupported

`Folder`

- first-class movable container
- children live in a flat `folder.items` list
- apps can move into and out of folders
- creation and deletion are unsupported
- empty folders are allowed
- `count()` returns the number of contained items

`Widget`

- movable atomic opaque item
- `gridSize` metadata is parsed when present
- `grid_size()`, `slot_size()`, and `slot_count()` expose verified slot dimensions

`Stack`

- movable atomic opaque item
- `gridSize` metadata is parsed when present
- `grid_size()`, `slot_size()`, and `slot_count()` expose verified slot dimensions

`Unknown`

- opaque preserved fallback for unrecognized item payloads

### Hidden Internal Fields

These exist for round-trip identity/ownership and are not meant as public API:

- `ref`
- `__store`
- `__source`

### Optional Features

Optional feature loaders:

- `springboard.features.graphics()`
- `springboard.features.image()`
- `springboard.features.itunes()`
- `springboard.features.cache()`

The core library does not load optional JSON, socket, cache, or GraphicsMagick
dependencies.
