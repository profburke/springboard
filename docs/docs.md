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

`find*` methods accept either a plain substring or a Lua pattern.

Mutation:

- `reshape(flat_apps)`

`reshape` only accepts apps.

### Item Kinds

`App`

- first-class editable item

`Folder`

- first-class container
- children live in `folder.items`

`Widget`

- opaque preserved item

`Stack`

- opaque preserved item

### Hidden Internal Fields

These exist for round-trip identity/ownership and are not meant as public API:

- `ref`
- `__store`
