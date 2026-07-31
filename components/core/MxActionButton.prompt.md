# MxActionButton

The app's button. There is no other one.

## Use it when

A control performs something: submit, cancel, retry, delete, start a session.

Not for: switching between views of the same content (`MxPillButton` — a button
that stays pressed is a different idea), a control with no visible label
(`MxIconButton`), a row in a list (`MxListTile`).

## Variants

| Variant | For |
| --- | --- |
| `primary` | The one action a screen wants the user to take. Filled with the brand. |
| `secondary` | Everything else — alternatives, "not now", secondary paths. Outlined, and its label is deliberately **neutral** rather than the brand colour: a secondary action sits next to the review verdicts, and a hue there competes with the two colours carrying the user's actual decision. |
| `destructive` | Deletes something, or discards work. |

One `primary` per screen. Two primaries is a screen that has not decided.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `label` | `string` | Required, already-localized. |
| `onPressed` | `() => void \| null` | `null` disables. |
| `variant` | `'primary' \| 'secondary' \| 'destructive'` | Defaults to `primary`. |
| `isLoading` | `boolean` | Disables and shows a spinner. |
| `icon` | `MxIconName` | Optional leading glyph, `sm`. |
| `shouldAutofocus` | `boolean` | For `MxConfirmDialog`. |

## Rules the component enforces, so a caller cannot get them wrong

- **48 high, before padding.** The minimum touch target lives in the stylesheet,
  not in a prop, so no screen can build a button below it.
- **Loading keeps the width.** The label stays laid out and invisible; the spinner
  overlays it. A button that shrinks to spinner width moves everything beside it
  exactly when the user is waiting to see what happened.
- **Loading disables.** Otherwise a second press queues a second submit.
- **The name survives the spinner.** `aria-label` is on the button, so a
  submitting button does not announce as "button, disabled" with no name.
- **Two lines before ellipsis.** One line ellipsizes "Endgültig löschen" to "End…"
  at a 3× text scale, which on a destructive dialog leaves the user approving an
  action they can no longer read.
- **Compact loses horizontal padding, never height.** Four review actions at 320
  wide give each button 68px; 24 a side leaves 20 for the label, 12 a side leaves
  44.

## Do not

- Pass a colour, a background, or a font.
- Use `secondary` for the retry in an error state. An error state has one thing to
  do and nothing to weigh it against, so an outlined button there reads as
  optional. Use `primary`.
- Nest one inside `MxCard`'s tappable surface. One target or the other.
