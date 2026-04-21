# SpringBoard Item Taxonomy

This is the working model. It should change only when fixtures or device
experiments prove something more precise.

## App

Current support:

- first-class item
- searchable by name or id
- movable by `layout.reshape`
- usable with `conn:app_image(app)`

Open questions:

- Which fields are safe to edit besides position?
- Are offloaded/restoring apps distinguishable from normal apps?
- Should App Store app, system app, and app clip entries share one model?

## Web Clip

Current support:

- probably parsed as `App` when it looks app-like

Open questions:

- Which plist fields reliably distinguish web clips from apps?
- Do web clips support image retrieval through SpringBoardServices?
- Should web clips become a separate `webclip` kind or remain `App` variants?
- What fields are safe to edit without breaking launch behavior?

## Folder

Current support:

- first-class movable container
- children are exposed as `folder.items`
- `layout.reshape` moves folders atomically
- folder contents round-trip through modeled child items

Open questions:

- Are folder children actually a flat list, or should folder pages be modeled?
- What are the capacity rules for folder pages?
- Can apps move into and out of folders safely?
- Can folders be created from scratch?
- Can folders be deleted safely?
- Can folder names be edited safely?
- What should happen to empty folders?

## Widget

Current support:

- opaque preserved item
- discoverable through `visit_items` and `opaque_items`
- not accepted by mutation helpers

Open questions:

- Which fields define identity, size, extension kind, and host app?
- Which widget families map to which layout slot sizes?
- Can widgets be moved freely between pages?
- Can widgets be created from scratch?
- Can widget configuration be preserved after movement?
- Are there widget records that do not have bundle identifiers?

## Smart Stack

Current support:

- opaque preserved item
- discoverable through `visit_items` and `opaque_items`
- not accepted by mutation helpers

Open questions:

- How are stack children ordered and configured?
- Which metadata controls rotation/suggestions behavior?
- Can stacks move as atomic containers without modeling their children?
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

- likely falls through to `App` or `Unknown`, depending on plist shape

Open questions:

- What fields distinguish App Clips from apps?
- Are App Clips persisted in the same layout plist across reboot/sync?
- Are they safely movable?
- Do they support image retrieval through the same API?

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
