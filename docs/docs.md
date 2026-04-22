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

- `flatten()`
- `find(query)`
- `find_all(query)`
- `find_id(query)`
- `visit(fn)`
- `visit_items(fn)`
- `opaque_items()`
- `has_opaque_items()`
- `validate([options])`
- `remove_app(app)`
- `move_app_to_folder(app, folder)`
- `move_app_to_page(app, page[, position])`

`find*` methods accept either a plain substring or a Lua pattern.

Mutation:

- `reshape(flat_items)`

`reshape` accepts apps and folders. Folders move as atomic containers.

`validate({ folder_capacity = N })` reports folder capacity issues when a caller
provides an explicit limit. No folder limit is enforced by default.

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

- opaque preserved item
- research indicates widgets can move once grid-size validation exists
- `gridSize` metadata is parsed when present
- `grid_size()`, `slot_size()`, and `slot_count()` expose verified slot dimensions

`Stack`

- opaque preserved item
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
