# Tests

## Offline

Run this by default:

```sh
lua tests/offline.lua
```

This uses plist fixtures and does not require a connected iOS device. It covers
parse behavior, traversal, model invariants, opaque item policy, app/folder
movement, validation, and Lua-to-plist round-trip behavior.

## Device-Backed

[`tests.lua`](tests.lua) is an integration test file. It requires:

- a connected iOS device
- working SpringBoardServices access
- Busted and its Lua dependencies

Do not run it as the default correctness check. It can touch live device state
if destructive tests are enabled.
