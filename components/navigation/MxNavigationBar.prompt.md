# MxNavigationBar

The bottom bar. Switching between the app's top-level sections.

## Use it when

There are two to five sibling sections and the user moves between them freely.

Not for: moving up a hierarchy (`MxBreadcrumb`), or filtering the same content
(`MxPillButton`).

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `selectedIndex` | `number` | Not clamped — see below. |
| `onDestinationSelected` | `(index) => void` | |
| `destinations` | `MxNavigationDestination[]` | `{ label, icon, selectedIcon? }`. At least two. |
| `semanticLabel` | `string` | Names the bar. |

## Render-only, and deliberately ignorant

It does not know the router, does not know what a deck is, and never navigates. A
shared component that knew the route table would drag routing into every test that
touches it — and stop being usable by any shell with a different set of
destinations.

## Out-of-range is not clamped

A bar that shows tab 0 when the router says 3 is a navigation bug wearing a working
UI. Fix the caller.

## Rules the component enforces

- **Labels always visible, on every destination.** The Material 3 default hides the
  unselected ones, which leaves three unlabelled icons and one labelled — and makes
  selection readable only as a colour difference, which is exactly what an
  accessibility review rejects.
- **120px per destination, not a fixed maximum.** With two destinations an even
  split puts them at the quarter and three-quarter marks, with a void between that
  reads as a missing tab. The cap centres them — and at four destinations the row
  wants more width than a phone has, so it disarms itself. A fixed number would have
  to be revisited every time a tab is added.
- **The bar paints the page colour**, like the app bar above it, so the chrome reads
  as one frame rather than three surfaces stacked on the content — and narrowing the
  row leaves no band edge to notice.
- **`aria-current="page"` on the selected destination**, so selection is announced
  and not only filled in.
