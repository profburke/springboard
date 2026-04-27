# SpringBoard Type Research Notes

These are working answers from local plist inspection and device experiments.
They are source notes, not final API docs.

## 1. App

Only safe to move. Editing fields is not allowed.
Creating or deleting apps is not allowed.

## 2. Web Clip

Only safe to move. Editing fields is not allowed.
Creating or deleting web clips is not allowed.

## 3. Folder

Safe to move. Safe to move apps in or out, with a little hand-waving around
capacity.
Creating or deleting folders is not allowed.
Empty folders are fine.

## 4. Widget

Safe to move, modulo size issues described below.
Creating or deleting widgets is not allowed.
Editing widgets is not allowed.

The `gridSize` key determines how many slots a widget takes.
Observed values are `small`, `medium`, `large`, and `extraLarge` on iPad.
Older notes may spell the last one as `xtralarge`; the library normalizes both.
The library models these as 2x2, 4x2, 4x4, and 4x6 icon-slot footprints for
compacted layout validation.

Sparse home screen placement on iOS 18+ / 26 is a separate problem. The raw
layout plist does not expose explicit row/column coordinates or placeholder
records for gaps, so exact sparse placement is not modeled yet.

## 5. Smart Stack

## 6. Placeholder

## 7. App Clip

My research indicates App Clips do not appear in SpringBoard. They only appear
in the new App Library, so we probably do not need to represent them.

## 8. System Pseudo-Item

## 9. Unknown
