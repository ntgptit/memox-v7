# MxIconButton

An action with no visible label.

## Use it when

An app-bar action, a row's overflow menu, a field's clear button — anywhere the
glyph alone is the control and there is no room for words.

## The one rule

**`semanticLabel` is required.** It is why this component exists rather than a
`<button>` with an icon inside. An icon-only control with no label is a blank
button to a screen reader: the user is told there is something pressable and
nothing about what it does. If the label were optional it would be omitted,
because omitting it changes nothing anyone can see.

Write what the action **does**, not what the glyph looks like. "Delete deck", not
"bin". "Search cards", not "magnifier".

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `icon` | `MxIconName` | Required. |
| `semanticLabel` | `string` | Required, already-localized. |
| `onPressed` | `() => void \| null` | `null` disables. |
| `tooltip` | `string` | Only when the visible text should differ from the label. |

## Rules the component enforces

- **48x48, always.** The minimum lives in the stylesheet, not in a prop, so there
  is nothing for a screen to pass.
- **Keyboard focus draws a ring, not a tint.** Material's default focus tint alone
  measures 1.15:1 against the surface in both modes; WCAG 1.4.11 asks 3:1. On its
  own that tint marks the focused control for people who can already see where
  they are and for nobody else.
- **The label lives on the button; the icon stays decorative.** Labelling both has
  the reader announce it twice.

## Do not

- Wrap it in something that re-labels it. That takes the button's own node with it
  and loses "button", "enabled" and the activation.
- Use it where a label would fit. A named button is better than a glyph the user
  has to guess at.
