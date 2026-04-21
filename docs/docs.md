## API Summary

### Library

`springboard.connect([udid])`

- opens a connection to the default or specified device

`springboard.ios_errno()`

- returns the last connection error code

`springboard.load_plist(path)`

- loads a saved SpringBoard plist from disk into a `Layout`

### Connection

`conn:layout()` / `conn:get_layout()`

- fetches the current device layout

`conn:save_raw_layout_plist(path)`

- writes the raw SpringBoardServices layout plist to disk without parsing

`conn:set_layout(layout)`

- writes the given layout back to the device

`conn:app_image(app)`

- returns PNG bytes for the given app

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

- first-class editable item

`Folder`

- first-class movable container
- children live in a flat `folder.items` list
- apps can move into and out of folders
- `count()` returns the number of contained items

`Widget`

- opaque preserved item

`Stack`

- opaque preserved item

`Unknown`

- opaque preserved fallback for unrecognized item payloads

### Hidden Internal Fields

These exist for round-trip identity/ownership and are not meant as public API:

- `ref`
- `__store`
