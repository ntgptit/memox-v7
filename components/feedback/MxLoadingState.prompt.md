# MxLoadingState

Something is happening and there is nothing to show yet.

## Use it when

A screen or a region has no data to render. Usually reached through `MxAsyncView`
rather than directly.

Not for: a button mid-submit (`MxActionButton isLoading`), or progress with a known
total (`MxProgressBar`).

## The one rule

**`semanticsLabel` is required.** A bare spinner is invisible to a screen reader —
it announces nothing at all, so the user is told neither that something is
happening nor when it stops. Already-localized, and it names what is loading:
"Loading your decks", not "Loading".

## Why a spinner and not a skeleton

Skeletons exist to mask network latency. These reads are local and finish in
single-digit milliseconds, so a skeleton would render a fake layout for less than
a frame and then replace it — motion that says "slow" about something that is not.
Revisit when a read crosses a network.

## Rules the component enforces

- **`role="status"`, `aria-live="polite"`.** A loading state is worth announcing at
  the next pause, not worth interrupting for.
- **No track behind the arc.** A faint ring behind the spinner reads as a second
  ring nobody asked for.
- **Reduced motion slows it; it does not stop it.** A stopped spinner is a lie
  about whether the app is doing anything, and it is the only signal the user has.
