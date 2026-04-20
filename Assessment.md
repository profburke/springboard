# iOS Icons: Code Assessment

## Critical Bugs

### 1. Wrong variable in bundleId assignment — `src/sb_ios2lua.c:58`
```c
// Current (wrong):
if (bundleId != NULL) { SET_STRING(L, kAppleBundleIdKey, id); }
// Should be:
if (bundleId != NULL) { SET_STRING(L, kAppleBundleIdKey, bundleId); }
```
`bundleIdentifier` silently gets the `displayIdentifier` value instead of the actual bundle ID. Every downstream feature that uses bundle IDs (icon image fetching, iTunes lookups) is broken by this.

### 2. `fslurp` buffer bugs — `src/save_load.c:82,87`
```c
// Line 82 - wrong sizeof (allocates pointer-size × len instead of 1 × len):
data = malloc(sizeof(char*) * (len + 1));  // should be sizeof(char)
// Line 87 - off-by-one null termination (silently truncates last byte of file):
data[len - 1] = '\0';  // should be data[len]
```
Loading a plist from disk can silently truncate the last byte, or allocate a buffer 8× too large on 64-bit.

### 3. Dead code due to early `return` — `ios-icons/image.lua:56`
```lua
return math   -- should be: return image
```
Everything after line 56 — `image.new`, color analysis, GraphicsMagick integration — is unreachable dead code. Color-based icon filtering is completely non-functional.

### 4. Unintentional global variable leaks — `ios-icons/image.lua:104,108,115`
```lua
r,g,b = icon.image.rgb()    -- should be: local r,g,b = ...
h,s,v = icon.image.hsv()    -- should be: local h,s,v = ...
```
These assign to globals, a classic Lua mistake.

### 5. Unsafe shell-out in cache helpers — `ios-icons/image.lua:92`
The GraphicsMagick call constructs a shell command by concatenating file paths without quoting or sanitizing. Paths from `os.tmpname()` are generally safe, but the pattern is fragile and worth fixing when touching this file.

---

## App vs. Icon Terminology Conflation

The TODO file explicitly notes: *"change icon type to app type with an icon field"*.

**The problem:** `icon` is used for three distinct things:
- An app (by far the most common case)
- A folder (a container for apps)
- The visual PNG image of an app

The word "icon" most naturally refers to a visual image, not the software artifact.

**Recommended data model:**

| Type | Description |
|------|-------------|
| `Layout` | Top-level object: dock plus pages |
| `Page` | Ordered list of Springboard items |
| `AppItem` | Launchable app or web clip with identifiers |
| `FolderItem` | Named item containing child items |
| `WidgetItem` | Single widget entry |
| `StackItem` | Smart stack containing widget entries |

Each item should carry:
- `kind` — stable string tag (`"app"`, `"folder"`, `"widget"`, `"stack"`)
- `ref` — opaque stable token used for round-trip serialization identity (separate from mutable display fields)
- `name`, `id`, `bundleIdentifier` — the user-visible and Apple-assigned fields
- original plist metadata preserved where needed

The `Layout` type replaces the current convention of treating the top-level array as anonymous. The `ref` token replaces the fragile `name .. "." .. id` registry key — renaming a display name should not break serialization lookup.

Web clips (home screen shortcuts to web pages) are currently treated as `AppItem` variants — this should be an explicit decision: same type with a flag, or a distinct `WebClipItem` kind.

Unknown item types encountered in the plist should be preserved as opaque items and passed through round-trips unchanged, rather than dropped or misclassified.

---

## Inconsistent Type System

### The `type()` override pattern is fragile

Each type module independently wraps the global `type()`:

```lua
-- icon.lua:
local oldtype = type
function type(v)
   if getmetatable(v) == icon_mt then return 'icon'
   else return oldtype(v) end
end
-- folder.lua, page.lua do the same...
```

The behavior depends on load order. The chain breaks silently if any module is reloaded. Adding a new type requires touching the override chain.

**Recommendation:** A single `ios-icons/model/kind.lua` module owns the type override and the metatable registry. All item modules register into it. Checks become `kind.is(v, "app")` instead of `type(v) == 'icon'`.

### Types have wildly inconsistent richness

| Type | Methods |
|------|---------|
| `icons` (collection) | flatten, find, find_all, find_id, visit, reshape, dock |
| `page` | `__tostring` only |
| `folder` | `__tostring` only |
| `icon` (app) | `__tostring` only; image methods injected at runtime by graphics.lua |
| `widget` | Stub — `__tostring` returns `"<widget: tbd>"` |
| `stack` | Stub — `__tostring` returns `"<stack: tbd>"` |

The three optional-injection modules (`graphics.on_icons`, `itunes.on_icons`) add methods to objects at runtime, invisible to anyone reading the type definitions. Feature attachment should be explicit — e.g., `features.graphics.attach(layout, conn)` — rather than hidden side effects on the base objects.

---

## Incomplete Implementations

### Widgets and Stacks
`widget.lua` and `stack.lua` are stubs with no fields. The elements parsing in `sb_ios2lua.c:73–77` is commented out because a stack containing "Siri Suggestions" (no `bundleIdentifier`) causes a crash. The fix is to guard against NULL `bundleId` in `parseNode()` before calling `SET_STRING`.

Policy decision required before implementing: are widgets and stacks **fully editable** in this pass, or **opaque-but-preserved**? Either is acceptable but the choice drives how much work is involved.

### `icons:swap()` referenced in README but doesn't exist
`docs/README.md` shows `icons:swap(a, b)` as a core use case, but `icons.lua` has no such method. Implement it or remove it from the docs.

### `icons:flatten()` ignores widgets and stacks
The flatten/visit/find functions only handle `'icon'`, `'page'`, and `'folder'` — widgets and stacks are silently skipped.

---

## Directory Structure

**Current layout:**
```
ios-icons.lua           ← entry point (require "ios-icons")
ios-icons/              ← module directory
    icon.lua, icons.lua, folder.lua, page.lua, ...
    iconlib.so          ← compiled C module
src/                    ← C source files
```

`ios-icons.lua` at the root is a one-line shim. Standard Lua module layout allows `ios-icons/init.lua` to serve `require "ios-icons"`, eliminating the split. This is a pure rename.

The repo root currently mixes active source, scratch files, fixtures, and archive material. Proposed clean layout:
- `src/` — C bridge source
- `ios-icons/` — Lua package
- `tests/fixtures/` — saved plists and offline samples
- `examples/` — working examples only
- `docs/` — actual docs
- `archive/` — explicitly non-active material (replaces `oldstuff/`)

`.iTunesJson*/` caches should not be in the repo at all — add them to `.gitignore`.

---

## Registry & Memory Issues (`src/sb_registry.c`)

The registry stores raw plist pointers as Lua lightuserdata, keyed by `"<name>.<id>"`.

1. **Memory leak:** Pointers are never freed. Calling `get_icons()` twice leaks the first set.
2. **Key collision risk:** An app named `"foo.bar"` with id `"baz"` collides with name `"foo"`, id `"bar.baz"`.
3. **`NEVER_NULL` macro** silently substitutes `""` for NULL name or id, hiding misidentification.
4. **Renaming breaks lookup:** If a display name changes, the old registry entry is unreachable and the item can't be serialized back.

The proposed `ref` opaque token (see Data Model above) solves this cleanly — the round-trip key is assigned at parse time and is independent of mutable display fields.

---

## Other C Code Issues

- **Global error state:** `idevice_errno` is a global in `comms.c`; it should be a field on `SBConnection`.
- **Missing `const`:** Many read-only `char*` parameters lack `const` qualifiers.
- **`sb_ios2lua.c` switch fallthrough:** The `PLIST_ARRAY` case falls through to `default:` without a `break`. The `lua_rawseti` at the bottom runs for both — appears intentional but needs a comment.
- **Hardcoded retry count:** 3 retries in `icons.c` deserves a named constant.

---

## Testing Gap

Most tests require a live device. There are no offline fixture tests for the plist↔Lua conversion, traversal, or serialization identity. These are exactly the paths that contain the bugs above. Offline fixtures covering simple pages, folders, widgets, stacks, and edge cases (missing names, missing bundle IDs) would catch regressions without needing hardware.

---

## Open Questions

These need answers before the deeper refactor work can be considered done:

1. **Widget/stack policy:** Fully editable in the first cleanup pass, or opaque-but-preserved?
2. **Lua version target:** Is 5.1/5.2 compatibility a real requirement, or can the code target one version cleanly? The code was originally Lua 4.x and has drifted.
3. **API compatibility:** Should old method names (`icons()`, `get_icons()`, etc.) be preserved via a compatibility shim during the rename/refactor, or is a clean break acceptable?
4. **`oldstuff/`:** Keep in-repo as archive, or remove entirely?

---

## Recommended Fix Priority

1. Fix the critical bugs (bundleId, fslurp buffer, `return math`, global vars)
2. Rename `icon` → `AppItem`; introduce `Layout` as a named type
3. Consolidate `type()` override into a single `kind.lua` module
4. Fix the registry — introduce opaque `ref` token, clear on `get_icons()`, remove `NEVER_NULL`
5. Fix and complete widget/stack support (guard NULL bundleId; decide edit vs. preserve policy)
6. Implement `icons:swap()` (in README, core use case)
7. Move `ios-icons.lua` → `ios-icons/init.lua`; clean up repo layout; gitignore caches
8. Add offline fixture tests for parse and round-trip
9. Make feature attachment explicit; move image/color/iTunes behind optional layer
10. Rewrite docs after the code stops lying

*(Optional — breaking change)* Rename the library to `springboard`. The library is about iOS Springboard, not just icons, and the current name is misleading.
