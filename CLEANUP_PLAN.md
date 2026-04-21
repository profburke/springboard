# Cleanup Plan

## Goal

Keep turning this repo into a maintainable `springboard` library for:

- reading SpringBoard layout data from iOS devices
- manipulating that layout in Lua
- writing modified layout data back safely

The priority is still correctness, explicit behavior, and testability. Not feature sprawl.

## Current State

Completed:

- project/library rename to `springboard`
- fake global `type` override removed
- explicit `kind` classification added
- `Layout` / `Page` / `App` / `Folder` model introduced
- folder children normalized to `folder.items`
- folders made movable as atomic containers
- apps can move into folders and back out to pages
- folder capacity validation is opt-in because the real limits vary
- apps and web clips are move-only; field editing/create/delete are unsupported
- folders are move-only containers; create/delete are unsupported and empty folders are allowed
- widget movement is plausible once `gridSize`/slot validation exists
- App Clips are out of scope unless raw SpringBoard fixtures prove otherwise
- widgets, stacks, and unknown payloads made explicit opaque item kinds
- reshape restricted to movable apps and folders
- round-trip identity moved to opaque `ref`
- per-layout ownership moved to hidden `__store` handle
- layout provenance added via `__source`
- `set_layout` rejects file-loaded layouts unless forced
- docs rewritten to match the current API
- offline fixture-backed tests added

Still weak:

- widgets and smart stacks are preserved but not first-class
- optional feature modules are still mixed into the main package surface
- cache helpers still deserve a security and API cleanup
- repo layout still has historical clutter and archive material in active view
- device-backed integration coverage is still thin and manual

## Non-Goals

- building a GUI first
- first-class widget/stack editing before the data is understood
- broad backward compatibility with `ios-icons`
- expanding optional metadata/image features before the core is tighter

## Current Architecture

### Device Bridge

Files:

- `src/comms.c`
- `src/layout.c`
- `src/sb_ios2lua.c`
- `src/sb_lua2ios.c`
- `src/sb_registry.c`
- `src/save_load.c`

Responsibilities:

- connect to device services
- fetch SpringBoard plist data
- convert plist to Lua model objects
- convert Lua model objects back to plist
- preserve round-trip identity via `ref` and `__store`

### Core Model

Files:

- `springboard/init.lua`
- `springboard/layout.lua`
- `springboard/page.lua`
- `springboard/app.lua`
- `springboard/folder.lua`
- `springboard/widget.lua`
- `springboard/stack.lua`
- `springboard/unknown.lua`
- `springboard/kind.lua`

Responsibilities:

- define the model surface
- provide traversal and search helpers
- provide safe layout reshaping for movable app/folder flows
- provide basic app/folder movement helpers
- provide opt-in validation for target-specific folder capacity
- make opaque unsupported items discoverable instead of silently dropping them

### Optional Features

Current files:

- `springboard/image.lua`
- `springboard/graphics.lua`
- `springboard/cache.lua`
- `springboard/itunes.lua`

These work, but they are still not cleanly separated from the core library.

## Data Model Direction

Use these concepts:

- `Layout`: top-level dock plus pages
- `Page`: ordered list of items
- `Item`: generic SpringBoard thing
- `App`: launchable app or web clip style entry
- `Folder`: named item containing child items
- `Widget`: opaque preserved widget item
- `Stack`: opaque preserved smart stack item
- `Unknown`: opaque fallback for unrecognized item payloads

Each parsed item should continue to have:

- a stable `kind`
- an opaque stable `ref`
- a hidden `__store` handle for round-trip ownership
- raw metadata preserved where needed

Example shape:

```lua
{
  kind = "app",
  ref = "item:42",
  id = "com.apple.MobileSMS",
  bundleIdentifier = "com.apple.MobileSMS",
  name = "Messages"
}
```

Avoid regressing into:

- global `type` overrides
- treating every item as an “icon”
- identity derived from mutable fields like `name .. "." .. id`
- pretending opaque items are editable when they are not
- allowing create/delete/edit operations without plist evidence

## Phase Status

### Phase 0: Stabilize The Ground

Status: complete

Delivered:

- fixed `bundleIdentifier` assignment
- fixed `fslurp` allocation/termination
- removed the dead `image.lua` early return
- stopped `image.lua` from leaking globals
- fixed a cache-key bug in image color helpers

### Phase 1: Replace The Type System

Status: complete

Delivered:

- explicit `springboard.kind`
- real metatable-based classification
- traversal no longer depends on patched built-ins

### Phase 2: Define A Real Core Model

Status: complete for the current scope

Delivered:

- `Layout` object with `dock` and `pages`
- `App` model replacing the old icon fiction
- `folder.items`
- folders movable as atomic containers
- app movement into folders and back out to pages
- opt-in folder capacity validation
- explicit opaque `Widget`, `Stack`, and `Unknown` item kinds

Remaining later:

- decide how web clips should be represented if they need distinct behavior
- represent widget movement safely using `gridSize`

### Phase 3: Rebuild Serialization Identity

Status: complete

Delivered:

- opaque `ref` identity
- per-layout `__store` ownership
- round-trip no longer depends on mutable display fields

### Phase 4: Decide Opaque Item Policy

Status: complete for now

Decision:

- widgets, smart stacks, and unknown payloads are opaque preserved items
- they are discoverable via `visit_items`, `opaque_items`, and `has_opaque_items`
- mutation helpers do not accept them

Not in scope yet:

- first-class widget/stack editing

### Phase 5: Split Core And Optional Features

Status: pending

Objective:

Keep the core library narrow and predictable.

Tasks:

- decide whether `app_image` remains a connection method or becomes an attached feature
- move image/color/iTunes/cache helpers behind a cleaner optional feature boundary
- ensure the base library loads without optional tooling installed
- replace shell-heavy cache helpers with direct Lua file APIs where possible

Acceptance criteria:

- core layout read/write works without optional extras installed
- optional features fail clearly and locally

### Phase 6: Clean The Repo Layout

Status: partially complete

Already done:

- active package is now `springboard/`
- docs and fixture-backed tests live in sensible directories

Still to do:

- move or quarantine archive material that still competes with active source
- clean root-level scratch/legacy files
- review tracked local data artifacts and decide what belongs in git
- tighten ignore rules for generated caches and dumps

Acceptance criteria:

- repo root contains active entry points and real docs, not drift
- archive material is visibly archive-only

### Phase 7: Rewrite Tests Around Fixtures

Status: mostly complete

Already done:

- added a fixture-backed offline test covering:
  - layout load
  - app traversal/search
  - opaque item discovery
  - `ref` / `__store` invariants
  - app/folder reshape policy
  - unknown item parsing
  - Lua-to-plist round-trip assertions
  - app/folder movement round-trip assertions
  - file provenance invariants
- documented the split between offline tests and device-backed integration tests
- made file-loaded layouts savable so offline round-trip tests do not require a device

Still to do:

- add edge-case fixtures for missing names / missing bundle identifiers
- cover any supported write-path helpers that are still undocumented or untested

Acceptance criteria:

- most correctness checks run without a device
- regressions in parse/identity/traversal fail offline
- device-backed tests are explicit integration tests, not the default safety net

### Phase 8: Keep Docs Honest

Status: started, not done

Already done:

- rewrote `docs/README.md`
- rewrote `docs/docs.md`

Still to do:

- add a clear write-safety section
- document any integration-test/device prerequisites
- remove or archive stale examples that describe unsupported APIs

Acceptance criteria:

- a new reader can tell what is safe, what is risky, and what is unsupported

## Recommended Execution Order From Here

1. Phase 7
2. Phase 5
3. Phase 6
4. Phase 8

Reason:

- tests should pin current behavior before more refactoring
- optional features are the next biggest source of design drift
- repo cleanup is useful but lower leverage than locking behavior down
- docs should be tightened again after the remaining structural cleanup settles

## Milestones

### Milestone A: Safe Core

Status: complete

Included:

- Phase 0
- Phase 1
- Phase 2
- Phase 3
- Phase 4
- baseline docs/tests work

Outcome:

- the core library is no longer lying about its model or relying on fragile identity hacks

### Milestone B: Testable Core

Status: active

Includes:

- finish Phase 7
- tighten Phase 8 around supported vs unsupported behavior

Outcome:

- the current model is locked down by offline tests and honest docs

### Milestone C: Maintainable Project

Status: pending

Includes:

- Phase 5
- Phase 6

Outcome:

- the project surface becomes cleaner to extend without reintroducing confusion

## Immediate Next Tasks

1. Add fixtures that exercise missing names / missing bundle identifiers.
2. Audit `springboard/image.lua`, `springboard/cache.lua`, `springboard/graphics.lua`, and `springboard/itunes.lua` for optional-dependency boundaries.
3. Identify root/archive files that should be moved, ignored, or deleted.

## Open Questions

These are the remaining real decisions:

1. Does `app_image` stay in the core connection API, or should it become an optional feature?
2. Do web clips deserve their own explicit item kind, or are they fine as `App` for now?
3. Which old example files are still worth keeping once the docs are fully aligned?
