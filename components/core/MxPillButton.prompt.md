# MxPillButton

One of N, and you can see which.

## Use it when

Switching between views of the same content: a filter row, a sort order, a
"due / all / archived" segmented set. The whole group is always visible.

Not for: performing something (`MxActionButton` — a button that stays pressed is a
different idea), a row (`MxListTile`), navigating between top-level sections
(`MxNavigationBar`).

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `label` | `string` | Required, already-localized. |
| `isSelected` | `boolean` | Required. Sets `aria-pressed` as well as the fill. |
| `onPressed` | `() => void \| null` | `null` disables. |
| `icon` | `MxIconName` | Optional, `sm`, decorative. |
| `semanticLabel` | `string` | Only when the visible label is an abbreviation. |

## Rules the component enforces

- **Selected borrows the navigation bar's indicator pair.** "This one is active"
  looks the same whether it is a tab or a filter.
- **No checkmark.** The group is always visible in full, so the selected pill is
  legible by contrast alone, and a tick would shift the label sideways on every
  change.
- **48 tall to the finger, 32 tall to the eye.** The padding is outside the visible
  shape, so the pill stays the size it was drawn while the target clears the floor.
- **Selection is announced.** `aria-pressed`, not colour alone.

## The abbreviation case

When the visible text is short-hand, `semanticLabel` replaces it for assistive
technology and the visible text is hidden from the tree — so the reader says "sort
by name" once rather than "A dash Z, sort by name".

## Do not

- Render a group of one. A pill with nothing to switch to is a label.
- Use `isSelected` for a "current step" in a sequence. That is `MxBreadcrumb`: a
  path has a last element, a pill group has a chosen one.
