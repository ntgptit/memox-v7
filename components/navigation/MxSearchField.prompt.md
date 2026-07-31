# MxSearchField

Filtering a list by what the user types.

## Use it when

A list is long enough that scanning it is work: decks, cards, a picker.

Not for form input — that is `MxTextField`, which requires a persistent label this
one deliberately does not have.

## Why it is not `MxTextField` with an icon

Search differs in three ways, and all three are visible:

1. **No persistent label.** The leading glyph and the placeholder together are the
   name, and there is no value to re-read later.
2. **A clear affordance**, which a form field does not have.
3. **It reports as you type**, not on submit.

Sharing the input would mean a `variant` on `MxTextField` that turns off the one
prop it makes required.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `value` / `onChanged` | `string` / `(v) => void` | Controlled. |
| `placeholder` | `string` | Visible hint. |
| `semanticLabel` | `string` | **Required.** The placeholder is not a name. |
| `clearLabel` | `string` | **Required.** Names the clear button. |
| `onSubmitted` | `(v) => void` | Optional — a live filter has nothing to submit. |

## It does not debounce and it does not search

Both belong to the caller. How long to wait depends on what the query costs, and a
shared control guessing at that is wrong on the one screen where the read is
expensive.

## Rules the component enforces

- **The clear button appears only when there is something to clear.** A permanently
  visible one is a control that does nothing, and the user finds that out by pressing
  it.
- **Escape clears rather than blurring.** A user who has typed a query into a filter
  wants the list back, not the focus gone.
- **The clear button is 32, not 48 — and that is deliberate.** It sits *inside* a
  48-high row, so the row is what the thumb aims at and this is the last few pixels
  of it. A 48-square button here would make the field 64 high.
- **The browser's own clear affordance is suppressed.** It appears on one engine, at
  a size no guideline covers, and would stand beside the one this component draws.
- **Focus shifts hue, never stroke width**, like every other input.
