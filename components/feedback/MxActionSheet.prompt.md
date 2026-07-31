# MxActionSheet

The mobile action menu: a list of things you can do to one object.

## Use it when

A row or a screen has three or more actions and no room for them. Two actions are
usually two buttons.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `actions` | `MxActionSheetAction[]` | `{ label, onPressed, icon?, variant?, isEnabled? }`. |
| `title` | `string` | Optional, already-localized. Names the object, not the menu. |
| `onDismiss` | `() => void` | Escape and the barrier. |

## It decides nothing

Which actions exist, whether "Create card" belongs beside "Create deck", whether
either applies here — all of that is the caller's, and arrives as a list. A sheet
that knew about content types would have to know about schedulers next, and then
about permissions.

## Unavailable rows stay visible

`isEnabled: false` greys the row and blocks the callback; it does not remove it.
Hiding an unavailable action makes the menu change shape between visits, and the
user cannot learn where anything is.

**Disabled wins over destructive.** A greyed row that is still red reads as
available and dangerous, which is the worst of both.

## The glyph is quieter than the label — except when it is the warning

A normal row's icon is `on-surface-variant`: a glyph carrying the same weight as
the words next to it leaves the eye two things to land on. A destructive row's icon
keeps the full colour, because there it is part of the warning, and quieting it
would leave red text beside a neutral bin.

## It does not close itself

Dismissal belongs to the caller that opened it, for the same reason
`MxConfirmDialog` does not close itself: the sheet does not know whether the action
it just fired succeeded.

## Rules the component enforces

- **Bottom-anchored, with a drag handle and safe-area padding.** A sheet sits
  exactly where the home indicator and the keyboard are.
- **It scrolls**, and caps at 80% of the viewport, so a long menu never covers the
  thing it is acting on.
- **`role="menu"` / `role="menuitem"`**, labelled by the title when there is one.
