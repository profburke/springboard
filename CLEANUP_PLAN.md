# Cleanup Plan

## Goal

Turn this repo from a partially recovered prototype into a maintainable library for:

- reading Springboard layout data from iOS devices
- manipulating that layout in Lua
- writing the modified layout back safely

This plan assumes the current priority is correctness and code structure, not new end-user features.

## Non-Goals

- building a GUI first
- expanding optional features like iTunes metadata or color analysis before the core model is sound
- preserving every historical file in the active source tree

## Current Problems

### Structural

- The Lua object model is fake-polymorphic and depends on globally overriding `type`.
- The project conflates app, icon image, and Springboard item.
- Widgets and smart stacks are detected but not cleanly modeled or round-tripped.
- Serialization depends on a weak registry lookup based on mutable fields.

### Correctness

- `bundleIdentifier` is populated with the wrong value in the C bridge.
- `ios-icons/image.lua` contains an early `return math`, leaving most of the file dead.
- `ios-icons/image.lua` leaks globals in `hsv`, `color`, and `is_dark`, making behavior order-dependent.
- `save_load.c` has broken buffer allocation and termination logic.
- Cache helpers shell out unsafely and assume path-safe inputs.

### Project Hygiene

- The repo root mixes active source, fixtures, scratch files, and archive material.
- Documentation describes stale install and usage flows.
- Tests depend too heavily on a live device and do not protect core round-trip behavior.

## Target Architecture

The cleanup should drive the codebase toward four layers.

### 1. Device Bridge

Files:

- `src/comms.c`
- `src/icons.c`
- `src/sb_ios2lua.c`
- `src/sb_lua2ios.c`
- `src/sb_registry.c`
- `src/save_load.c`

Responsibilities:

- connect to device services
- fetch Springboard plist data
- convert plist to Lua data
- convert Lua data back to plist
- preserve enough identity to write changes back safely

### 2. Core Model

Proposed location:

- `ios-icons/model/`

Responsibilities:

- define layout, page, folder, app item, widget item, stack item
- provide traversal and search helpers
- provide mutation helpers
- avoid device-specific side effects

### 3. Optional Features

Proposed location:

- `ios-icons/features/`

Candidates:

- image fetching wrappers
- icon color analysis
- iTunes lookups
- file-backed caches

These should layer on top of the core model, not shape it.

### 4. Compatibility Layer

Responsibilities:

- keep the public `require "ios-icons"` entry point stable during refactor
- map old method names to new implementations where reasonable
- isolate deprecations instead of spreading compatibility hacks through the codebase

## Data Model Direction

The current model uses "icon" as the default word for almost everything. That is the wrong abstraction.

Use these concepts instead:

- `Layout`: dock plus pages
- `Page`: ordered list of Springboard items
- `Item`: generic Springboard thing on a page or in a folder
- `AppItem`: launchable app or web clip with identifiers
- `FolderItem`: named item containing child items
- `WidgetItem`: widget entry
- `StackItem`: smart stack containing widget entries

Each item should have:

- a stable `kind`
- a stable opaque identity used for round-trip serialization
- raw source metadata preserved where needed

Example shape:

```lua
{
  kind = "app",
  ref = "opaque-stable-token",
  id = "com.apple.MobileSMS",
  bundleIdentifier = "com.apple.MobileSMS",
  name = "Messages"
}
```

Avoid these anti-patterns:

- overriding global `type`
- inferring item class from incidental fields at every call site
- using `name .. "." .. id` as durable identity

## Work Plan

## Phase 0: Stabilize The Ground

Objective:

Stop known correctness bugs before any structural refactor.

Tasks:

- Fix the `bundleIdentifier` assignment bug in `src/sb_ios2lua.c`.
- Fix `fslurp` allocation and null termination in `src/save_load.c`.
- Remove the dead early return from `ios-icons/image.lua`.
- Make `ios-icons/image.lua` stop assigning RGB/HSV temporaries into globals.
- Review `src/comms.c` and `src/icons.c` for stack discipline and error propagation issues while touching adjacent code.

Acceptance criteria:

- reading a plist into Lua exposes the real bundle identifier
- loading plist fixtures does not truncate XML
- `require "ios-icons.image"` returns the intended module table
- repeated image helper calls do not mutate global Lua state

## Phase 1: Replace The Type System

Objective:

Eliminate global `type` monkey-patching and replace it with explicit item classification.

Tasks:

- Introduce a shared type utility module, for example `ios-icons/model/kind.lua`.
- Replace all `type(v) == 'icon'` style checks with `kind.is(v, "app")`, `kind.is(v, "page")`, or equivalent.
- Update:
  - `ios-icons/icons.lua`
  - `ios-icons/fn.lua`
  - `ios-icons/icon.lua`
  - `ios-icons/page.lua`
  - `ios-icons/folder.lua`
  - `ios-icons/widget.lua`
  - `ios-icons/stack.lua`
- Define a minimal shared interface for item-like objects, at least `kind`, `name`, `id`, and `__tostring`.
- Make traversal helpers state explicitly whether widgets and stacks are visited, flattened, or preserved as opaque nodes.
- Keep metatables if useful, but stop mutating globals.

Acceptance criteria:

- loading model modules in any order produces identical behavior
- traversal helpers no longer depend on patched built-ins
- object classification is explicit and testable
- page, folder, app, widget, and stack objects no longer have ad hoc baseline behavior

## Phase 2: Define A Real Core Model

Objective:

Separate app items, folders, widgets, and stacks into explicit types with clear responsibilities.

Tasks:

- Introduce a `Layout` object instead of treating the top-level table as an anonymous list.
- Rename or wrap current `icon` behavior into `AppItem`.
- Make folder contents explicit child items rather than a special case inside "icon" handling.
- Decide whether web clips are represented as `AppItem` variants or a separate item kind.
- Preserve unknown item payloads so unsupported cases survive round-trip.
- Decide whether legacy helpers such as `flatten`, `find`, `find_id`, and `dock` live on `Layout`, on a compatibility wrapper, or both.

Acceptance criteria:

- the model can represent every currently detected Springboard entity without lying about what it is
- folder traversal and page traversal use the same item protocol
- unsupported items are preserved, not dropped or misclassified

## Phase 3: Rebuild Serialization Identity

Objective:

Make Lua-to-plist conversion reliable.

Tasks:

- Replace registry keys built from `name` and `id` with opaque stable references.
- Store the mapping from Lua item to original plist node using a generated token or registry-backed userdata strategy.
- Ensure copied nodes for folders and nested items do not lose identity unexpectedly.
- Document which fields are user-editable and which are derived.

Acceptance criteria:

- reordering items without renaming them round-trips correctly
- renaming display strings does not break lookup of original plist nodes
- collisions between items with missing or duplicate names cannot corrupt serialization

## Phase 4: Decide Widget And Stack Policy

Objective:

Stop pretending partial support is acceptable.

Decision:

- widgets and smart stacks are currently treated as opaque unsupported items that are preserved but not editable

Tasks if fully supported later:

- parse `elements` safely
- guard NULL `bundleIdentifier` values during parse instead of crashing
- represent widget and stack children explicitly
- teach traversal and serialization code how to preserve them

Tasks under the current opaque policy:

- parse them into opaque item objects
- block unsafe mutations on those objects
- keep them visible to traversal code in a defined way rather than silently dropping them
- document the limitation clearly

Acceptance criteria:

- no crash path for stacks containing items with missing bundle identifiers
- support level is explicit in code and docs
- opaque items are discoverable via dedicated traversal helpers without being treated as apps

## Phase 5: Split Core And Optional Features

Objective:

Keep the core library narrow and predictable.

Tasks:

- Move `ios-icons/image.lua`, `ios-icons/graphics.lua`, `ios-icons/cache.lua`, and `ios-icons/itunes.lua` behind an optional feature layer.
- Ensure the base library can load without GraphicsMagick, JSON, or socket dependencies.
- Replace shell-based cache helpers with Lua file APIs where possible.
- Make feature attachment explicit, for example `features.graphics.attach(layout, conn)`.
- Decide whether image-fetching stays a method on `AppItem`, moves behind an attached feature, or is exposed as a separate service object.

Acceptance criteria:

- core layout read/write works without optional tooling installed
- optional features fail clearly and locally rather than poisoning the base module

## Phase 6: Clean The Repo Layout

Objective:

Make it obvious which files matter.

Proposed structure:

- `src/`: C bridge
- `ios-icons/`: Lua package
- `tests/fixtures/`: saved plists and offline samples
- `examples/`: supported examples only
- `docs/`: actual docs
- `archive/` or `oldstuff/`: explicitly non-active material

Tasks:

- move scratch and one-off files out of the repo root or delete them if obsolete
- quarantine `oldstuff/` as archive-only
- decide whether `.iTunesJson*` belongs in git at all; likely it does not
- add ignore rules for generated files, caches, and local dumps
- move the package entry point from `ios-icons.lua` to `ios-icons/init.lua` once compatibility shims are in place
- keep the old entry point as a thin forwarder during the transition, then remove it after the rename settles

Acceptance criteria:

- repo root contains only active project entry points and docs
- archived experiments no longer compete visually with active source
- module entry points follow standard Lua package layout rather than split root/package shims

## Phase 7: Rewrite Tests Around Fixtures

Objective:

Test the code that actually breaks.

Tasks:

- Add fixture plist files covering:
  - simple pages
  - folders
  - widgets
  - smart stacks
  - edge cases with missing names or bundle identifiers
- Add offline tests for:
  - plist to Lua parse
  - Lua to plist round-trip
  - find and traversal helpers
  - widget and stack traversal semantics
  - serialization identity stability
- Add regression tests for:
  - `bundleIdentifier` preserving the real bundle id
  - `load_plist` not truncating the final byte
  - `require "ios-icons.image"` returning the image module
- Add either tests for `icons:swap()` or remove it from docs and examples if it is not part of the supported API.
- Keep device-backed integration tests, but isolate and mark them clearly.

Acceptance criteria:

- most correctness tests run with no device attached
- docs examples refer only to helpers that actually exist and are covered by tests
- structural regressions fail fast in CI-compatible conditions

## Phase 8: Rewrite Docs After The Code Stops Lying

Objective:

Make the docs match reality.

Tasks:

- rewrite `docs/README.md`
- remove references to missing scripts and stale install steps
- document supported item kinds and unsupported cases
- provide one safe read-only example and one explicitly destructive write example

Acceptance criteria:

- a new reader can understand what the library does, what it does not do, and how risky write operations are

## Recommended Execution Order

Do the work in this order:

1. Phase 0
2. Phase 1
3. Phase 3
4. Phase 2
5. Phase 4
6. Phase 5
7. Phase 7
8. Phase 6
9. Phase 8

Reason:

- correctness bugs should not survive into refactors
- type and identity issues are the highest leverage problems
- repo cleanup and docs can wait until the model and serialization story are stable

## Proposed Milestones

### Milestone A: Safe Core

Includes:

- Phase 0
- Phase 1
- Phase 3

Outcome:

- the library stops corrupting or misclassifying data for core app and folder flows

### Milestone B: Honest Model

Includes:

- Phase 2
- Phase 4

Outcome:

- the code has an explicit and truthful representation of Springboard entities

### Milestone C: Maintainable Project

Includes:

- Phase 5
- Phase 6
- Phase 7
- Phase 8

Outcome:

- the project becomes testable, readable, and easier to extend into a CLI or TUI

## Immediate Next Tasks

If execution starts now, the first concrete tasks should be:

1. Patch `src/sb_ios2lua.c` to store the real `bundleIdentifier`.
2. Patch `src/save_load.c` to fix buffer sizing and null termination.
3. Patch `ios-icons/image.lua` to return the actual module.
4. Add an offline plist fixture and a minimal test that asserts parse correctness for app and folder items.
5. Replace global `type` overrides with a shared explicit kind check.

## Open Questions

These need answers before deeper refactor work is considered done:

1. Should widgets and smart stacks be editable in the first cleanup pass, or only preserved?
2. Is Lua 5.1/5.2 compatibility still a real requirement, or can the code target one version cleanly?
3. Do you want the public API to keep old method names like `icons()` and `get_icons()`, or is a compatibility shim acceptable during transition?
4. Is `oldstuff/` intended as archival source to preserve in-repo, or should it move out entirely?
