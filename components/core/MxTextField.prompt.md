# MxTextField

The app's text input.

## Use it when

Any free text: a deck name, a card front, a note. Search has its own component
(`MxSearchField`) because it has a clear button and no floating label.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `value` / `onChanged` | `string` / `(v) => void` | Controlled. |
| `label` | `string` | **Required**, already-localized. |
| `hintText` | `string` | Appears with the floating label, not before it. |
| `helperText` | `string` | Standing guidance. |
| `errorText` | `string` | Non-null → error state. |
| `isEnabled` / `isReadOnly` | `boolean` | Two different states — see below. |
| `minLines` / `maxLines` | `number \| null` | `maxLines: null` grows without limit. |
| `maxLength` | `number` | Drives the counter and the cap. |
| `onSubmitted` | `(v) => void` | Single-line only. |

## Why `label` is required

A floating label is the only **persistent** name the field has. A hint-only field
is unlabelled the moment the user types — on screen and to a screen reader. There
is no prop to turn it off.

## The error rule

The state is carried by **real error text**, not by a boolean. A red outline with
no message tells a colour-blind user that something is different and not what. The
message is `role="alert"`; the helper text is not, because a helper announcing
itself on every keystroke talks over the user typing.

## `isEnabled: false` vs `isReadOnly: true`

- `isReadOnly` — focusable, selectable, copyable, not editable.
- `isEnabled: false` — greyed, and out of the focus order entirely.

## What it does not do

- **It does not trim.** Trimming would silently change what the caller validated,
  so the value it reports and the value it was given stay the same string.
- **It does not know your limits.** `maxLength` is a number the caller supplies.
  A shared input carrying a business rule is a business rule nobody can find, and
  it is wrong the moment a second screen has a different limit.
- **It does not localize.** Every string arrives ready to render.

## Rules the component enforces

- **Focus shifts hue, never stroke width.** The outline stays 1.5 in every state.
  Material's default goes 1 → 2 on focus, which makes the field jump and nudges
  anything laid out beside it.
- **Outlined, never filled.** A fill makes the field a block that competes with the
  cards around it; a stroke alone lets the page show through, so it sits correctly
  on a page or on a card with no per-screen override.
- **Disabled borders are solid, not translucent** (MX-VIS-002 R7). A translucent
  border composites against the field's fill in one place and the page in another,
  so the same disabled state read as two different greys.
