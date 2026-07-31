# MxIcon

The app's icon set, as a closed registry.

## Use it when

Any glyph anywhere. There is no second way to draw one.

## Do not

- **Pass artwork.** No `src`, no `children`, no inline SVG at a call site. The set
  is closed on purpose: the moment a caller can supply a shape, two screens draw
  two different bins and no reviewer can tell a variant from a paste.
- **Pass a pixel size.** `size` is `sm | md | lg`, mirroring `AppIconSize`. A free
  number is how a design system acquires eleven icon sizes.
- **Pass a colour.** Every glyph inherits `currentColor`, so an icon inside a
  control is the control's colour. Colouring one independently is how a glyph and
  its label drift apart when someone restyles one of them.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `name` | `MxIconName` | Required. An unknown name renders nothing and warns. |
| `size` | `'sm' \| 'md' \| 'lg'` | Defaults to `md`. 16 / 24 / 40. |
| `label` | `string` | Already-localized. **Omit it by default.** |

## The label rule

An icon is decorative unless it is the content.

- Beside its own text — a button, a list row, a pill: **no `label`**. The icon is
  `aria-hidden`, and the text is what gets announced. Supplying one has the reader
  say the same thing twice.
- Standing alone as the meaning — an empty state's illustration, a status glyph
  with no text: **`label` required**, and it says what the thing means, not what
  the glyph looks like. "No cards due", not "check circle".
- An icon-only control: the label belongs on the **control**, not here. See
  `MxIconButton`, which requires one.

## Geometry

24 grid, round caps and joins, and a stroke weight per step — 1.75 / 1.5 / 1.25
in grid units. Left to scale with the box, a 1.5 stroke is 2.5 device px at `lg`,
which makes an empty state's illustration the heaviest mark on the screen, and
1.0 at `sm`, where it starts to break up. The set reads as one weight at all three
sizes rather than one number at all three sizes.
