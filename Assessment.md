# iOS Icons / Springboard: Code Assessment

*Last updated: 2026-04-21. All five original critical bugs are fixed. All CLEANUP_PLAN.md milestones are complete. This document records what remains.*

---

## Remaining C Issues

### 1. Global error state — `src/comms.c:17`
`int idevice_errno = 0;` is module-global, returned by `ios_errno()`. Should be a field on `SBConnection`. Not thread-safe and breaks with multiple connections. Low urgency for single-process CLI use.

### 2. Switch fallthrough without comment — `src/sb_ios2lua.c`
The `PLIST_ARRAY` case falls through to `default:` (which only contains a `break`). The fallthrough is harmless but lacks a `/* fall through */` comment. Will generate compiler warnings on strict settings.

### 3. Registry GC timing — `src/sb_registry.c`
Registry entries are freed when the Lua `__store` userdata is garbage-collected via `itemStoreHandle_gc`. This is correct in principle but relies on timely GC. Calling `get_layout()` twice in a long session may not promptly collect the first store. Consider explicit invalidation on a second `get_layout()` call.

### 4. Missing `const` — `src/util.c:14`
`addToTable(lua_State *L, char* libname)` — `libname` should be `const char*`. Cosmetic.

### 5. NULL bundleId guard for widget/stack element parsing — `src/sb_ios2lua.c`
Intentionally deferred. Element parsing for stacks (e.g. "Siri Suggestions", which has no `bundleIdentifier`) is commented out with a TODO. Not a regression; accepted gap pending a decision on first-class widget/stack editing.

---

## Remaining Design Decision

### 6. Web clips — item kind unresolved
Web clips are currently parsed as `App` items (`kind = "app"`). `docs/springboard-items.md` lists this as an open question. Options:
- Keep as `App` with a passthrough field (e.g. `isWebClip`) — minimal change
- Add `kind = "webclip"` as a distinct type with its own module — explicit but more surface area

No test fixture covers web clips. The decision should be made and recorded before adding mutation support for apps.

---

## Remaining Housekeeping

### 7. `springboard/init.lua` is a confusing entry point
`springboard/init.lua` (8 lines) re-exports only the raw C module (`iconlib`). A caller who writes `require "springboard"` gets the C bridge, not `Layout`/`App`/etc. Callers are expected to require submodules directly, but this is undocumented and surprising.

### 8. `cset.lua` at repo root
Leftover stub referencing the old `ios-icons.cache` path. Listed in `.gitignore` but physically present. Should be deleted.

### 9. No root `README.md`
Nothing at the repo root directs visitors to `docs/README.md`. First-time visitors on GitHub see a bare root.

### 10. `.gitignore` gaps
`src/*.o` object files are not ignored; compiled objects are present. `springboard/iconlib.so` is also not ignored (may be intentional if it's the distributed artifact).

### 11. `docs/typeanswers.md`
Present in `docs/` but referenced nowhere. Working document or leftover — should be linked or deleted.

### 12. Test runner inconsistency
`tests/offline.lua` uses plain `assert()` calls; `tests/tests.lua` uses busted. Fine standalone but complicates unified CI setup.

---

## What Is Done

All five original critical bugs are fixed:
- `bundleId` assignment — correct variable used (`src/sb_ios2lua.c`)
- `fslurp` sizeof and off-by-one — both fixed (`src/save_load.c`)
- `return math` dead code — now `return image` (`springboard/features/image.lua`)
- Global `r,g,b`/`h,s,v` leaks — all `local` (`springboard/features/image.lua`)
- Unsafe shell-out pattern — replaced with Lua file APIs

All CLEANUP_PLAN.md phases are complete:
- Centralized `kind.lua` type registry (no more per-module `type()` overrides)
- `Layout`/`App`/`Folder`/`Page` model with opaque `Widget`/`Stack`/`Unknown` items
- Opaque `ref` round-trip identity; per-layout `__store` ownership
- `set_layout` rejects file-loaded layouts unless forced
- Optional features split under `springboard/features/`; explicit `attach()` pattern
- Repo layout cleaned; `archive/` for historical material; `.gitignore` covers caches
- Offline fixture-backed tests across parse, traversal, identity, movement, and edge cases
- Docs rewritten to match the actual API

*(Completed)* Library renamed to `springboard`.
