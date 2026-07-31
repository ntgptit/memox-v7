# MxProgressBar

How far through something the user is.

## Use it when

There is a total and a position in it: cards reviewed in a session, an import
running, a multi-step form.

Not for: "something is happening, no idea how long" on a whole screen — that is
`MxLoadingState`. Not for a button mid-submit — `MxActionButton` owns that.

## Determinate vs indeterminate

They say different things and are not interchangeable.

- `value: 0.4` — **"nearly half done."** Use it whenever a total exists.
- `value: null` — **"this is running."** Only when there genuinely is no total.

Faking the second with the first is how a progress indicator becomes decoration
nobody trusts.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `value` | `number \| null` | 0–1, clamped. `null` = indeterminate. |
| `semanticLabel` | `string` | **Required**, already-localized. |
| `label` | `string` | Optional visible caption. |
| `valueLabel` | `string` | Already-localized and already formatted: "3 of 20". |

## Rules the component enforces

- **The fill is `focus-ring`, not `primary`.** Dark `primary` measures 2.81:1
  against the surface it sits on — under the 3.0 floor a graphic needs. It is held
  at a luminance that keeps a filled button from being the brightest thing on a
  navy page, which is the opposite of what an indicator wants. `focus-ring` is the
  same hue at the intensity meant to pull attention: 5.36:1 dark, 7.41:1 light.
- **`value` is clamped.** A caller that computes 21/20 gets a full bar, not one
  painting outside its own radius.
- **Indeterminate reports no percentage.** `aria-valuenow` is omitted rather than
  set to 0, so the reader does not announce "0 percent" for something that has no
  percent.
- **Reduced motion pulses in place.** A bar that stops moving says "finished",
  which is the one thing an indeterminate bar must not say.

## Do not

- Format the number here. `valueLabel` arrives localized and pluralised from the
  screen that owns the copy — a shared component doing its own would do it in one
  language.
