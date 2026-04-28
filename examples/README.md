# Examples

These examples require a connected iOS device.

- `left-dock.lua`: prints fields for the left-most dock item
- `print-all.lua`: prints the current parsed layout
- `dump-image.lua`: writes the left-most dock app image to `leftdock.png`
- `dump-plist.lua`: writes a raw SpringBoardServices layout dump to `springboard.plist`

`dump-plist.lua` is a read-only backup/research helper. It does not parse and
reserialize through the Lua model.

No example currently writes a modified layout back to a device. Use
`conn:set_layout(layout)` only after reading the write-safety notes in
[`../docs/README.md`](../docs/README.md).

For selector/mutation examples using the current layout API, see
[`../docs/layout-recipes.md`](../docs/layout-recipes.md).
