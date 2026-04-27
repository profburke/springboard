# SpringBoard Item Taxonomy

This is the working model. It should change only when fixtures or device
experiments prove something more precise.

Supporting research notes live in
[`research-notes.md`](/Users/matt/Projects/ios-icons/docs/research-notes.md).

## App

Current support:

- first-class item
- searchable by name or id
- movable by `layout.reshape`
- usable with `conn:app_image(app)`
- move-only; editing fields is unsupported
- creating or deleting apps is unsupported

Open questions:

- Are offloaded/restoring apps distinguishable from normal apps?
- Should system apps and App Store apps share one model permanently?

## Web Clip

Current support:

- probably parsed as `App` when it looks app-like
- move-only if represented
- editing fields is unsupported
- creating or deleting web clips is unsupported

Open questions:

- Which plist fields reliably distinguish web clips from apps?
- Do web clips support image retrieval through SpringBoardServices?
- Should web clips become a separate `webclip` kind or remain `App` variants?

## Folder

Current support:

- first-class movable container
- children are exposed as a flat `folder.items` list
- `layout.reshape` moves folders atomically
- folder contents round-trip through modeled child items
- apps can move into and out of folders
- apps move out of folders by moving them to a target page or dock
- capacity is not enforced by default
- callers may use `layout:validate({ folder_capacity = N })` when targeting a known limit
- creating or deleting folders is unsupported
- empty folders are allowed

Open questions:

- What are the exact capacity rules by iOS version and device class?
- Can folder names be edited safely?

## Widget

Current support:

- first-class movable opaque item
- discoverable through `visit_items` and `opaque_items`
- accepted by `layout.reshape` and `move_item_to_page`
- research indicates widgets are safe to move if slot size is respected
- creating, deleting, and editing widgets is unsupported
- `gridSize` defines widget slot size: `small`, `medium`, `large`, or `extraLarge` on iPad
- parsed metadata includes `gridSize`, `widgetIdentifier`, `containerBundleIdentifier`, and `elementType` when present
- `grid_size()`, `slot_size()`, and `slot_count()` expose verified slot dimensions
- compacted layout validation can account for widget slot usage
- exact sparse-page gap placement is unsupported because the plist does not expose coordinates

Open questions:

- Can widget configuration be preserved after movement?
- Are there widget records that do not have bundle identifiers?
- Where does iOS store sparse home screen gap coordinates, if anywhere accessible?

## Smart Stack

Current support:

- first-class movable opaque item
- discoverable through `visit_items` and `opaque_items`
- accepted by `layout.reshape` and `move_item_to_page`
- `gridSize` metadata is parsed when present
- `grid_size()`, `slot_size()`, and `slot_count()` expose verified slot dimensions
- compacted layout validation can account for stack slot usage
- exact sparse-page gap placement is unsupported because the plist does not expose coordinates

Open questions:

- How are stack children ordered and configured?
- Which metadata controls rotation/suggestions behavior?
- Can widgets be added to or removed from a stack safely?
- How should missing bundle identifiers inside stack elements be handled?

## Placeholder

Current support:

- likely falls through to `App` or `Unknown`, depending on plist shape

Open questions:

- What plist shape represents downloading, restoring, or offloaded apps?
- Is a placeholder safely movable?
- Does it carry a stable bundle id?
- Can it become a normal app without layout corruption after round-trip?

## App Clip

Current support:

- out of scope for SpringBoard layout modeling
- research indicates App Clips appear in App Library, not SpringBoard layout state

Open questions:

- Revisit only if a raw SpringBoard plist fixture proves otherwise.

## System Pseudo-Item

Current support:

- should fall through to `Unknown` if it does not look app-like

Examples may include Siri Suggestions or future Apple-managed layout records.

Open questions:

- Which pseudo-items appear in SpringBoard layout state on modern iOS?
- Are any safely movable?
- Do they require special placement rules?
- Should any become named model kinds?

## Unknown

Current support:

- first-class opaque fallback
- receives `ref` and `__store`
- preserved during round-trip
- discoverable through `visit_items` and `opaque_items`
- rejected by mutation helpers

Open questions:

- What raw metadata should be exposed for debugging?
- Should unknown items include their original plist key summary?
- Should unknown items be movable only after explicit opt-in?
