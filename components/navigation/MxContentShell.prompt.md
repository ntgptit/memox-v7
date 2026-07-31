# MxContentShell

The screen shell. Every screen uses it.

## Why it exists

So screen padding and the app-bar shape are decided **once**. Without it each screen
picks its own padding, and the difference is visible the moment two screens sit next
to each other in a flow.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `title` | `string` | Already-localized. Omit for a screen with no app bar. |
| `leading` / `actions` | `ReactNode` | Usually `MxIconButton`s. |
| `padding` | `string` | Omit to take the gutter for the current width. |
| `isScrollable` | `boolean` | Opt-in — see below. |
| `floatingActionButton` | `ReactNode` | Reserves no space. |
| `navigationBar` | `ReactNode` | An `MxNavigationBar`. |

## `isScrollable` is opt-in, and it has to be

The right answer depends on what the body is.

- A body that **already scrolls** — a long list — must not be nested inside another
  scroll container.
- A **fixed** body such as a form must scroll, or it overflows the moment the screen
  gets shorter.

Measured, not assumed: a card editor inside this shell overflows by 135px in
landscape at a 2× text scale, and by 167px with the keyboard open. Portrait alone
never shows it, which is why it survives every size test that only checks portrait.

## The gutter is not a constant

16 a side costs 10% of a 320-wide screen and 8% of a 393-wide one. The gutter is the
same number and a different amount of the screen, which is what makes a narrow phone
feel padded rather than laid out — so it drops to 12 below the compact breakpoint.
Pass `padding` only when a screen genuinely differs.

## The floating action reserves no space

It overlaps content by definition, so a scrolling body still has to end with enough
bottom padding for its last item to clear the button. Pass it here rather than
stacking it into the body: the shell is what keeps it clear of the safe-area inset
and of the navigation bar.

## Rules the component enforces

- **The app bar paints the page colour, with no elevation and no tint on scroll.**
  During a review the header must stay still, because a colour shift behind the card
  reads as the card itself changing.
- **One `<h1>` per screen**, in the app bar.
- **`<main>` for the body**, so the page has a landmark to skip to.
