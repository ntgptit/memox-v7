# MxListTile

A row in a list.

## Use it when

Anything that reads as a row: a deck, a card, a settings entry, an action in a
sheet (`MxActionSheet` builds its rows on this).

## Deliberately generic

It takes a `string` title and arbitrary nodes, **never a domain object**. The
moment a shared row knows what a deck is, every test that touches it drags the
domain in behind it — and the row stops being usable by the next feature that has
a different entity and the same layout. Build `DeckTile` and `CardTile` *on* this,
in the feature that owns them.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `title` | `string` | Required. |
| `subtitle` | `string` | Optional, quieter. |
| `leading` / `trailing` | `ReactNode` | Usually an `MxIcon` or an `MxIconButton`. |
| `onTap` | `() => void \| null` | `null` → not interactive, not greyed. |
| `isEnabled` | `boolean` | `false` → greyed and out of the focus order. |
| `isSelected` | `boolean` | Sets `aria-current` as well as the styling. |

## The two ways off

`onTap: null` and `isEnabled: false` are not the same state, and picking the wrong
one tells the user the wrong thing.

- `onTap: null` — **this row does not do anything.** A heading, a read-only fact.
  Not greyed, because nothing is unavailable.
- `isEnabled: false` — **this row does something, and not now.** Greyed, out of the
  focus order, `aria-disabled`.

## Rules the component enforces

- **Two lines then ellipsis on both title and subtitle.** At a 2× text scale an
  unbounded subtitle pushes the trailing control off a 320-wide screen, and the row
  silently loses its only action.
- **A row that does nothing is not a button.** Non-interactive rows render as a
  `div`, so the focus order does not collect tab stops that answer nothing.
- **The leading glyph is quieter than the label.** `--mx-color-on-surface-variant`,
  not the title's colour: an icon carrying the same weight as the words next to it
  leaves the eye two things to land on.
- **Compact loses horizontal padding only.** The vertical rhythm is what keeps a
  row tappable.
